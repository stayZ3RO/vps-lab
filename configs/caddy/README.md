# Caddy Reverse Proxy ⚙️

Reverse proxy and automatic HTTPS for the VPS Cloud Infrastructure Lab.

Phase: **Phase 3 - Reverse Proxy & HTTPS**

---

## Files

| File | Purpose |
|---|---|
| `Caddyfile` | Proxy + TLS + static site config (public-safe, no secrets) |
| `docker-compose.yml` | Caddy container stack |
| `.env.example` | Template for `SITE_DOMAIN` and `ACME_EMAIL` |
| `logs/` | JSON access logs (gitignored, created at runtime) |

---

## Why Caddy

| Option | Verdict |
|---|---|
| **Caddy** | Chosen. Single config file, automatic Let's Encrypt issuance and renewal, no admin port, no database. Smallest attack surface for a public node. |
| Nginx Proxy Manager | Rejected. Adds a database and an admin dashboard port that would then need Tailscale-only lockdown - cuts against the "administration lives on Tailscale" model. Its database stores proxy config, not logs. |
| Traefik | Deferred. Strong Docker-native / Kubernetes-ingress option; heavier config for a single-service start. A good later on-ramp when the Kubernetes track begins. |

Access logging (the "corp practice" requirement) is a config option, not a
reason to pick a heavier proxy - Caddy emits structured JSON access logs here.

---

## What is exposed

| Surface | Exposure |
|---|---|
| `https://stayz3ro.dev` and `https://www.stayz3ro.dev` | Cloudflare 301 redirects to the blog at `blog.chrisalorenzo.com`; not served by this VPS |
| `https://status.chrisalorenzo.com/status/main` | Public Kuma status page; root returns 302 here and public admin paths return 404 |
| `https://status.stayz3ro.dev` | Caddy 301 redirect to the new status host, preserving path and query |
| `https://ntfy.chrisalorenzo.com` | Public HTTPS edge for self-hosted ntfy |
| `https://a.chrisalorenzo.com` | Umami deployed 2026-10-14; public `/script.js` and `/api/send` only, other paths 404 |
| `apps` / `api` subdomains | Staged in `Caddyfile`, disabled pending their app deployments |
| Kuma admin | Tailnet-only through `tailscale serve` on port 8443 |
| Umami admin | Loopback port 3000 through Tailscale Serve on 8444 |
| Backend application ports | Internal Docker networks; Kuma and Umami admin listeners bind IPv4 loopback |
| Caddy admin API | Disabled (`admin off`) |

---

Since 2026-10-05, the `status` and `ntfy` records use the Cloudflare proxy.
The `a` record also requires proxying: origin HTTP/HTTPS accepts Cloudflare
ranges only, including Docker-published ports through `DOCKER-USER`. The
repository keeps the Umami Caddy block commented as a deployment template;
[Current Status](../../CURRENT-STATUS.md) records the active deployment.

## Stage 0b: deployment gates (2026-10-04 cutover record)

These checks were the gates before Stage 3b restricted the public status
routes. The recorded current state uses Docker 29.8.1 and has no push monitors.
Before enabling the Kuma loopback mapping on a new deployment, check the Docker
server version on the VPS:

```bash
docker version --format '{{.Server.Version}}'
```

Require Docker Engine 28.0.0 or newer. Earlier releases can expose a
localhost-published port to other hosts on the same L2 segment; see
[Docker's port-publishing warning](https://docs.docker.com/engine/network/port-publishing/).
If the server is older or its version cannot be checked, stop before enabling
the mapping. Handle any upgrade as a separate approved change.

After recreating only Kuma as directed in Stage 0b, check from this directory:

```bash
docker compose ps --format '{{.Name}} {{.Status}} {{.Ports}}'
curl -sS -o /dev/null -w 'kuma loopback %{http_code}\n' http://127.0.0.1:3001/
```

Require `127.0.0.1:3001->3001/tcp`, no wildcard or IPv6 port 3001 mapping,
and loopback HTTP `302`.

From a separate machine off the tailnet, with working public DNS and no HTTP
proxy, first confirm the public HTTPS host responds, then check port 3001:

```bash
curl --noproxy '*' -sS -m 10 -o /dev/null -w 'https %{http_code}\n' https://status.chrisalorenzo.com/
curl --noproxy '*' -sS -m 5 -o /dev/null -w 'http=%{http_code} connects=%{num_connects}\n' http://status.chrisalorenzo.com:3001/
```

Require a normal HTTPS response and `http=000 connects=0` on port 3001,
with curl reporting connection refusal or timeout (exit 7 or 28). DNS failure,
proxy failure, a successful TCP connection or a failing HTTPS control does not
pass this gate. If the test fails, stop and use the Stage 0b rollback; do not
continue to the public route restriction.

Before Stage 3b, check every push client. Configure its protected destination
as `$KUMA_TS_URL/api/push/<token>` on a host with the required tailnet access.
Verify one real client run and its monitor returning UP. Record client names
and results only; keep tokens and full push URLs out of Git and logs. If no
push clients exist, record that after checking. Any unverified client blocks
Stage 3b: the public host will reject `/api/push/*`, including requests redirected
from the old status hostname.

## Initial setup on a new host

On the VPS, over Tailscale SSH:

    cd <repo>/configs/caddy
    test -e .env || cp .env.example .env
    # edit .env - set ACME_EMAIL to a real inbox
    mkdir -p logs
    docker compose up -d
    docker compose ps

## Update config

Edit the bind-mounted Caddyfile in place, then validate and restart. The admin
API is disabled, so `caddy reload` cannot work. The restart briefly interrupts
public routes on this VPS:

    cd /opt/stayz3ro/proxy/configs/caddy || exit 1
    docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile &&
      docker restart caddy

If validation fails, stop and correct the Caddyfile; do not restart.

## Certificate persistence

Issued certificates and the ACME account live in the `caddy_data` named
volume. Do not delete it - Let's Encrypt rate limits (50 certs/week per
registered domain) make repeated re-issuance costly.

---

## Security notes

- `.env` is gitignored. Never commit it.
- `logs/` is gitignored.
- No public IPs, keys, or account data belong in this folder.
- HSTS is set to 1 year in the `Caddyfile`. Lower it while testing if unsure.
