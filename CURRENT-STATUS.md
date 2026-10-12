# Current Status

![Status](https://img.shields.io/badge/status-active-brightgreen)
![Current Phase](https://img.shields.io/badge/current_phase-Phase%204%20In%20Progress-yellow)
![Security](https://img.shields.io/badge/ssh-Tailscale%20Only-success)

## Project State

As of 2026-10-04, the Netcup VPS serves the public Uptime Kuma status page at
`status.chrisalorenzo.com` and self-hosted ntfy at `ntfy.chrisalorenzo.com`
through Caddy HTTPS. The blog is at `blog.chrisalorenzo.com` on Cloudflare
Pages. Kuma has tailnet-only admin via `tailscale serve` on port 8443,
backed by IPv4 loopback port 3001.

The project has completed Phase 3 and is now in:

**Phase 4 - Docker App Deployment**

App selected: **Umami** (privacy-first web analytics). Scoping, candidate
comparison, compose stack (`configs/umami/`), and the deployment runbook
(`docs/phase-4-docker-app-deployment/step-by-step.md`) were staged for
`analytics.stayz3ro.dev`. Re-scoped 2026-10-12 after the domain move: a
neutral host on `chrisalorenzo.com` (proposed `a.chrisalorenzo.com`), public
tracker, tailnet-only admin. See `docs/umami-rescope-DRAFT-2026-10-12.md`;
the staged files change at its Stage 0. The live deployment is pending.

Phase 5 public-edge monitoring is live as of 2026-09-28 (see Monitoring and
Alerts below); Phase 4 remains in progress.

---

## Current Architecture State

    Internet
       |
       v
    Cloudflare DNS
       ├── blog.chrisalorenzo.com -> Cloudflare Pages
       ├── stayz3ro.dev and www -> 301 to blog.chrisalorenzo.com
       └── status.chrisalorenzo.com and ntfy.chrisalorenzo.com -> Netcup VPS
                                      ├── Caddy HTTPS -> public status page and ntfy
                                      └── private SSH and Kuma admin over Tailscale

    Admin Workstation
       |
       v
    Tailscale
       |
       v
    SSH to Netcup VPS and tailscale serve to Kuma admin

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
| Hostname | netcup-prod-01 |
| Role | Primary production/public services VPS |
| Operating System | Ubuntu Linux |
| Domains | chrisalorenzo.com public services; stayz3ro.dev legacy redirects |
| Domain Registrar | Porkbun |
| DNS Hosting (actual, authoritative) | Cloudflare. Porkbun's own DNS panel is not consulted by the live domain, see Lessons Learned |
| Access Method | SSH over Tailscale |
| Firewall | UFW |
| Intrusion Protection | Fail2Ban |
| Container Runtime | Docker 29.8.1 and Docker Compose |
| Public Exposure | HTTPS via Caddy (`status.chrisalorenzo.com` -> public Kuma status page, `ntfy.chrisalorenzo.com` -> ntfy); blog and its legacy redirects run on Cloudflare |

---

## Current Security Posture

The VPS now uses a stronger management-plane design.

Current access and exposure model:

- SSH is blocked on the public VPS IP
- SSH is allowed through Tailscale only
- HTTP is open, redirects to HTTPS via Caddy
- HTTPS is open, serves the public status page at `status.chrisalorenzo.com` via Caddy
- Direct application ports (`3000`, `3001`) are not exposed, confirmed by
  external probe
- Databases are not exposed
- Kuma has tailnet-only admin via `tailscale serve` on port 8443; its backend
  binds IPv4 loopback port 3001
- Public Kuma admin paths return 404. Trust Proxy is on and Primary Base URL
  is set to the private admin URL

### Domain move (2026-10-04)

- `status.chrisalorenzo.com` uses a DNS-only A record. Its root returns 302
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
  published port. Caddy serves `ntfy.chrisalorenzo.com` (DNS only A record).
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

Next phase:

**Phase 4 - Docker App Deployment** (in progress, app chosen, deployment pending)

Planned tasks:

- Deploy Umami (privacy-first web analytics) behind Caddy at `analytics.stayz3ro.dev`
- Claim the Umami admin account over a private SSH tunnel before public exposure
- Add the `analytics` DNS record in the Cloudflare zone (the live zone, see Lessons Learned)
- Route it through the reverse proxy and validate external access
- Document environment variables and `.env.example` (done, `configs/umami/`)
- Add the new host as an Uptime Kuma monitor
- Wire the blog embed (separate repo, coordinated change)
- Capture deployment screenshots
