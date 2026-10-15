# Current Status

![Status](https://img.shields.io/badge/status-active-brightgreen)
![Current Phase](https://img.shields.io/badge/current_phase-Phase%204%20Deployed-success)
![Security](https://img.shields.io/badge/ssh-Tailscale%20Only-success)

## Project State

As of 2026-10-14, the Netcup VPS serves the public Uptime Kuma status page at
`status.chrisalorenzo.com` and self-hosted ntfy at `ntfy.chrisalorenzo.com`
through Caddy HTTPS. The blog is at `blog.chrisalorenzo.com` on Cloudflare
Pages. Kuma has tailnet-only admin via `tailscale serve` on port 8443,
backed by IPv4 loopback port 3001.

The project has completed Phase 3 and is now in:

**Phase 4 - Docker App Deployment**

Umami 3.4.0 and PostgreSQL 16 were deployed on 2026-10-14. The public
tracker at `a.chrisalorenzo.com` serves only `/script.js` and `/api/send`;
other public paths return 404. Administration uses a loopback listener on
port 3000 through Tailscale Serve on port 8444. PostgreSQL has no published
port. See [the deployment record](CHANGELOG.md#2026-10-14-umami-deployed-public-record-proxied)
and [the current guide](docs/phase-4-docker-app-deployment/step-by-step.md).

The public `status`, `ntfy` and `a` records are proxied through Cloudflare.
Since 2026-10-05, origin ingress on HTTP/HTTPS accepts Cloudflare ranges only,
including Docker-published proxy ports through `DOCKER-USER`. Direct origin
access is blocked. The Umami deployment corrected the earlier DNS-only plan.

Phase 5 public-edge monitoring is live as of 2026-09-28 (see Monitoring and
Alerts below); Phase 4 evidence and remaining integration checks are not
recorded as complete.

---

## Current Architecture State

    Internet
       |
       v
    Cloudflare DNS and proxy (origin HTTP/HTTPS accepts Cloudflare ranges only)
       ├── blog.chrisalorenzo.com -> Cloudflare Pages
       ├── stayz3ro.dev and www -> 301 to blog.chrisalorenzo.com
       └── status.chrisalorenzo.com, ntfy.chrisalorenzo.com and a.chrisalorenzo.com
           -> Netcup VPS
               ├── Caddy HTTPS -> public status page, ntfy and Umami tracker paths
               └── private SSH, Kuma and Umami admin over Tailscale

    Admin Workstation
       |
       v
    Tailscale
       |
       v
    SSH to Netcup VPS and tailscale serve to Kuma and Umami admin

---

## Phase Completion Summary

| Area | Status |
|---|---:|
| VPS provisioned | ✅ Complete |
| Hostname configured | ✅ Complete |
| Non-root sudo user configured | ✅ Complete |
| SSH service validated | ✅ Complete |
| SSH configuration validated | ✅ Complete |
| Root SSH login disabled | ✅ Complete |
| Password SSH login disabled | ✅ Complete |
| UFW firewall enabled | ✅ Complete |
| Fail2Ban enabled for SSH | ✅ Complete |
| Unattended upgrades enabled | ✅ Complete |
| Docker installed | ✅ Complete |
| Docker Compose installed | ✅ Complete |
| Tailscale installed and connected | ✅ Complete |
| Cloudflare authoritative DNS configured (Porkbun registrar) | ✅ Complete |
| Root domain record configured | ✅ Complete |
| `www` record configured | ✅ Complete |
| `apps` record configured | ✅ Complete |
| `status` record configured | ✅ Complete |
| `api` record configured | ✅ Complete |
| Local DNS validation completed | ✅ Complete |
| Public resolver validation completed | ✅ Complete |
| Public SSH blocked | ✅ Complete |
| SSH over Tailscale validated | ✅ Complete |
| Caddy reverse proxy deployed | ✅ Complete |
| Uptime Kuma deployed (public status page, tailnet-only admin) | ✅ Complete |
| Let's Encrypt certificate issued for `status.chrisalorenzo.com` | ✅ Complete |
| HTTPS validated externally | ✅ Complete |
| Security headers validated | ✅ Complete |
| Backend ports confirmed not public | ✅ Complete |
| Uptime Kuma admin account secured pre-exposure | ✅ Complete |
| Redacted Phase 3 evidence captured | ✅ Complete |

---

## Current VPS Role

| Item | Value |
|---|---|
| Provider | Netcup |
| Hostname | edge-vps |
| Role | Primary production/public services VPS |
| Operating System | Ubuntu Linux |
| Domains | chrisalorenzo.com public services; stayz3ro.dev legacy redirects |
| Domain Registrar | Porkbun |
| DNS Hosting (actual, authoritative) | Cloudflare. Porkbun's own DNS panel is not consulted by the live domain, see Lessons Learned |
| Access Method | SSH over Tailscale |
| Firewall | UFW |
| Intrusion Protection | Fail2Ban |
| Container Runtime | Docker 29.8.1 and Docker Compose |
| Public Exposure | Cloudflare-proxied HTTPS via Caddy: public Kuma status page, ntfy and Umami tracker paths; origin HTTP/HTTPS accepts Cloudflare ranges only |

---

## Current Security Posture

The VPS now uses a stronger management-plane design.

Current access and exposure model:

- SSH is blocked on the public VPS IP
- SSH is allowed through Tailscale only
- Origin HTTP/HTTPS accepts Cloudflare ranges only; Caddy redirects HTTP to HTTPS
- Proxied HTTPS serves the public status page, ntfy and Umami tracker paths
- Direct application ports remain private. The earlier external probe
  predates Umami; record a fresh backend-port check for the new stack
- Umami administration binds loopback port 3000 and uses Tailscale Serve on
  port 8444; public Umami paths other than `/script.js` and `/api/send` return 404
- Databases are not exposed
- Kuma has tailnet-only admin via `tailscale serve` on port 8443; its backend
  binds IPv4 loopback port 3001
- Public Kuma admin paths return 404. Trust Proxy is on and Primary Base URL
  is set to the private admin URL

### Domain move (2026-10-04)

- `status.chrisalorenzo.com` now uses a proxied A record (changed 2026-10-05).
  Its root returns 302
  to `/status/main`; the public page has `Sites` and `Infra` groups.
- `status.stayz3ro.dev` returns 301 to `status.chrisalorenzo.com`, preserving
  the path and query.
- `stayz3ro.dev` and `www.stayz3ro.dev` return 301 to
  `blog.chrisalorenzo.com`, preserving the path and query through a Cloudflare
  Single Redirect. They were removed from the Pages custom domains and now
  use proxied redirect-only DNS records.

---

## Monitoring and Alerts

Uptime Kuma watches the public edge. The initial 2026-09-28 configuration was:

- Six monitors: `public-blog` (`stayz3ro.dev`), `public-portfolio`
  (`chrisalorenzo.com`), and `public-status-edge` (`status.stayz3ro.dev`),
  all with certificate-expiry notices; `public-edge-https` (TCP port 443 on
  `status.stayz3ro.dev`); and `dns-stayz3ro` and `dns-chrisalorenzo` (DNS A).
- Interval 60 seconds, retries 2, retry interval 60 seconds, resend 30.
- One notification provider live: Discord (`public-edge-discord`), attached
  to all six monitors.
- A synthetic DOWN/UP test passed on 2026-09-28: DOWN after the retry
  threshold, then one recovery message. The synthetic monitor was removed
  afterwards.
- Second provider live: self-hosted ntfy (`public-edge-ntfy`), attached to
  all six monitors and tested to the phone on 2026-09-28.
- `ntfy-health` (keyword `healthy` on `https://ntfy.chrisalorenzo.com/v1/health`)
  alerts through Discord only, so a broken ntfy still pages.

On 2026-10-04, five display names changed. Each old name remains in the
monitor's `id` tag:

| Display name | `id` tag |
|---|---|
| Blog | `public-blog` |
| Portfolio | `public-portfolio` |
| HTTPS Edge | `public-edge-https` |
| DNS (stayz3ro.dev) | `dns-stayz3ro` |
| DNS (chrisalorenzo.com) | `dns-chrisalorenzo` |

`public-status-edge` and `ntfy-health` retain their names. TLS expiry warning
is set to 14 days. There are no push monitors.

The remaining monitoring follow-up is to verify the Blog, status-page and
HTTPS Edge targets use the new hosts, and add a `blog-redirect` monitor that
expects 301 without following redirects. These live changes are not recorded
as complete here.

### ntfy (live 2026-09-28)

- `binwiederhier/ntfy:v2.28.0`, pinned by digest, on the `web` network with no
  published port. Caddy serves `ntfy.chrisalorenzo.com` (proxied A record since
  2026-10-05).
- `deny-all` by default, no signup, no web app. Users: `admin`, `kuma`
  (write-only `edge-alerts`), `automation` and `alertmanager` (write-only
  `lab-alerts`, no tokens issued yet), `phone` (read-only on both).
- iOS relay enabled (`upstream-base-url`); ntfy.sh sees only message IDs.
- Kuma reaches ntfy at `http://ntfy` inside the `web` network and signs in as
  `kuma` with username and password.
- Stage 5 results: root 404, metrics 404, anonymous publish and read 403,
  `kuma` publish 200, `kuma` on `lab-alerts` 403, `kuma` read 403.
- Remove the Caddyfile and `server.yml` backups on the VPS after 2026-10-05.

No private or admin endpoint is monitored from the VPS, and no path from the
VPS into the home LAN is opened.

---

## Next Workstream

**Phase 4 - Docker App Deployment** has a recorded deployment. Remaining
items require evidence before being marked complete:

- Record the Umami admin password change and private-access check
- Record external tracker, fallback 404 and backend-port checks
- Verify the new Kuma monitor targets `https://a.chrisalorenzo.com/script.js`
- Verify blog and portfolio embeds and event collection in their own repos
- Record installation and execution of the provided database backup timer
- Capture deployment screenshots
