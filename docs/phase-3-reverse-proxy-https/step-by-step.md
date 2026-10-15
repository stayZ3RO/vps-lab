# Phase 3 - Step-by-Step Guide 🛠️

![Status](https://img.shields.io/badge/status-executed-success)
![Scope](https://img.shields.io/badge/scope-Reverse%20Proxy%20%2B%20HTTPS-blue)
![Proxy](https://img.shields.io/badge/proxy-Caddy-success)

## Purpose

This guide is the implementation runbook for deploying the Caddy reverse proxy
and issuing HTTPS certificates for `stayz3ro.dev`.

All eleven steps were executed on 2026-08-30. See [validation.md](validation.md)
for the execution record. The commands below preserve the original deployment
procedure; [Current Status](../../CURRENT-STATUS.md) records later domain,
proxy and ingress changes.

---

## Implementation Flow

| Step | Task | Status |
|---|---|---:|
| 1 | Confirm prerequisites (DNS, firewall, Docker) | ✅ Executed 2026-08-30 |
| 2 | Check out the repo on the VPS | ✅ Executed 2026-08-30 |
| 3 | Create `.env` from the template | ✅ Executed 2026-08-30 |
| 4 | Validate the Caddyfile | ✅ Executed 2026-08-30 |
| 5 | Bring up the stack | ✅ Executed 2026-08-30 |
| 6 | Confirm certificate issuance | ✅ Executed 2026-08-30 |
| 7 | Validate HTTPS externally | ✅ Executed 2026-08-30 |
| 8 | Validate security headers; `www` redirect not applicable after retarget | ✅ Executed 2026-08-30 |
| 9 | Confirm access log is writing | ✅ Executed 2026-08-30 |
| 10 | Confirm backend ports are not public | ✅ Executed 2026-08-30 |
| 11 | Capture redacted screenshots | ✅ Executed 2026-08-30 |

---

## Step 1 - Confirm Prerequisites

DNS (from the workstation):

    dig +short stayz3ro.dev
    dig +short www.stayz3ro.dev

Expected: apex returns the Netcup VPS public IP; `www` resolves to the apex.

Firewall (on the VPS):

    sudo ufw status verbose

Expected: `80/tcp` and `443/tcp` allowed; SSH allowed only on `tailscale0`.

Docker (on the VPS):

    docker version
    docker compose version

Expected: both report versions without error.

Nothing else may be bound to port 80 or 443:

    sudo ss -tulpen | grep -E ':80 |:443 '

Expected: no output.

---

## Step 2 - Check Out the Repo on the VPS

Clone into the proxy service directory created in Phase 1:

    cd /opt/stayz3ro/proxy
    git clone https://github.com/stayZ3RO/vps-lab.git .
    # or, if already cloned:
    git pull

Confirm the Caddy config is present:

    ls configs/caddy

Expected: `Caddyfile`, `docker-compose.yml`, `.env.example`, `README.md`.

---

## Step 3 - Create the Environment File

    cd /opt/stayz3ro/proxy/configs/caddy
    cp .env.example .env
    nano .env

Set:

| Variable | Value |
|---|---|
| `SITE_DOMAIN` | `stayz3ro.dev` |
| `ACME_EMAIL` | a real, monitored inbox (used for Let's Encrypt expiry notices) |

Create the log directory (bind-mounted by the compose file):

    mkdir -p logs

`.env` and `logs/` are gitignored - they stay on the VPS only.

---

## Step 4 - Validate the Caddyfile

    docker run --rm -v "$PWD/Caddyfile:/etc/caddy/Caddyfile:ro" \
      -e SITE_DOMAIN -e ACME_EMAIL \
      caddy:2-alpine caddy validate --config /etc/caddy/Caddyfile

Expected: `Valid configuration`.

---

## Step 5 - Bring Up the Stack

    docker compose up -d
    docker compose ps

Expected: the `caddy` container is `running`, ports `80`, `443`, and
`443/udp` published.

---

## Step 6 - Confirm Certificate Issuance

    docker compose logs caddy | grep -iE 'certificate|obtain|error'

Expected: lines showing the certificate for `status.stayz3ro.dev` was
obtained. No ACME errors.

If issuance fails, the usual causes are: DNS not yet propagated, port 80
blocked, or something else already bound to port 80.

---

## Step 7 - Validate HTTPS Externally

From the workstation (not the VPS):

    curl -I http://status.stayz3ro.dev
    curl -I https://status.stayz3ro.dev
    curl -Iv https://status.stayz3ro.dev 2>&1 | grep -E 'subject:|issuer:|SSL certificate verify'

Expected:

- `http://` returns `308` with `Location: https://status.stayz3ro.dev/`
- `https://` returns `200`
- Certificate issuer is Let's Encrypt; verification succeeds

Open `https://status.stayz3ro.dev` in a browser and confirm the padlock and
the Uptime Kuma UI.

---

## Step 8 - Validate Security Headers

    curl -I https://status.stayz3ro.dev

Expected:

- Response includes `strict-transport-security`, `x-content-type-options`,
  `x-frame-options`, `referrer-policy`
- no `server: Caddy` header

---

## Step 9 - Confirm the Access Log Is Writing

On the VPS:

    tail -n 5 configs/caddy/logs/access.log

Expected: JSON lines, one per request, including the requests from Step 7-8.

---

## Step 10 - Confirm Backend Ports Are Not Public

From the workstation:

    curl -sS -m 5 http://<VPS_PUBLIC_IP>:3000 ; echo "exit=$?"
    curl -sS -m 5 http://<VPS_PUBLIC_IP>:8000 ; echo "exit=$?"

Expected: connection refused or timeout (non-zero exit). Only 80 and 443
answer.

Optional, if `nmap` is available:

    nmap -Pn -p 22,80,443,3000,8000 <VPS_PUBLIC_IP>

Expected: `80` and `443` open; `22`, `3000`, `8000` closed/filtered.

---

## Step 11 - Capture Screenshots

Capture and redact:

| # | Evidence | Purpose |
|---|---|---|
| 01 | `docker compose ps` | Caddy running, ports published |
| 02 | `docker compose logs` cert issuance | Let's Encrypt certificate obtained |
| 03 | `curl -I http://` -> 308 | HTTP redirects to HTTPS |
| 04 | `curl -Iv https://` cert chain | Valid Let's Encrypt certificate |
| 05 | Browser padlock on `status.stayz3ro.dev`, Uptime Kuma loaded | Public HTTPS works, real service reachable |
| 07 | Response headers | Security headers present |
| 08 | `access.log` JSON lines | Structured logging active |
| 09 | Backend port probe refused | App ports not public |

Redact public IPv4/IPv6, Tailscale IPs, and the ACME email before committing.

---

## Rollback

    cd /opt/stayz3ro/proxy/configs/caddy
    docker compose down

This stops and removes the container. Ports 80/443 are released. The
`caddy_data` volume (certificates) is kept unless you add `-v`.

Firewall and SSH posture are unchanged by this phase, so rollback is limited
to stopping the container.

---

## Phase Result

When all steps pass, `https://status.stayz3ro.dev` is publicly reachable with
a valid certificate, HTTP redirects to HTTPS, backend ports remain private,
and the proxy is staged for additional service routing.
