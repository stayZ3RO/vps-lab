# Changelog 📝

![Status](https://img.shields.io/badge/status-active-brightgreen)
![Phase 1](https://img.shields.io/badge/phase_1-complete-success)
![Phase 2](https://img.shields.io/badge/phase_2-complete-success)
![Phase 3](https://img.shields.io/badge/phase_3-complete-success)
![Next](https://img.shields.io/badge/next-Docker%20App%20Deployment-blue)

This changelog tracks major documentation and infrastructure milestones for the VPS Cloud Infrastructure Lab.

---

## 2026-10-14: Umami deployed, public record proxied

- Umami 3.4.0 and PostgreSQL 16 running on edge-01 behind Caddy; the public
  host serves only `/script.js` and `/api/send`, admin stays tailnet-only.
- The re-scope's DNS-only record did not work: since the 2026-10-05
  firewall change only Cloudflare ranges reach 80/443, so Let's Encrypt
  timed out on the challenge and so would visitors. The record is now
  proxied; the certificate issued on the next attempt. The re-scope note
  cited the `status` record's DNS-only precedent, which had already been
  reversed on 2026-10-05.
- Added `CLIENT_IP_HEADER: CF-Connecting-IP` to the Umami compose file so
  visitor addresses are the real ones, not Cloudflare's.

## Current State

| Phase | Status |
|---|---:|
| Phase 1 - VPS Baseline & Security Hardening | ✅ Complete |
| Phase 2 - Domain DNS & Public Routing | ✅ Complete |
| Phase 3 - Reverse Proxy & HTTPS | ✅ Complete |
| Phase 4 - Docker App Deployment | 🚧 In Progress |
| Phase 5 - Monitoring & Alerts | ✅ Public edge live since 2026-09-28 |

---

## 2026-09-28 to 2026-10-04

- The 2026-10-04 domain move put the blog at `blog.chrisalorenzo.com`, the
  public Kuma page at `status.chrisalorenzo.com/status/main`, and Kuma admin
  behind tailnet-only `tailscale serve`. Five monitor display names changed;
  old names remain as `id` tags. New-host target checks and a `blog-redirect`
  monitor remain pending.
- [#21](https://github.com/stayZ3RO/vps-lab/pull/21) added the public-edge
  monitor and Discord alert execution packet. Six primary monitors and a real
  synthetic DOWN/UP test were recorded on 2026-09-28.
- [#22](https://github.com/stayZ3RO/vps-lab/pull/22) added the self-hosted ntfy
  execution packet; [#23](https://github.com/stayZ3RO/vps-lab/pull/23) recorded
  ntfy live on the VPS, its Kuma provider, and the seventh `ntfy-health`
  monitor.
- [#24](https://github.com/stayZ3RO/vps-lab/pull/24) rewrote documentation in
  plain voice without changing the deployed services.

---

# Phase 1 - VPS Baseline & Security Hardening

Status: ✅ Complete

## Added

- Main project README
- Current status document
- Roadmap document
- Lessons learned document
- Phase 1 overview
- Phase 1 step-by-step guide
- Phase 1 validation evidence
- Phase 1 architecture diagram
- Screenshot evidence folder
- Sanitized SSH configuration example
- Sanitized UFW rules example
- Sanitized Fail2Ban jail example
- Scripts folder placeholder
- Config folder structure

## Completed

- Provisioned Netcup VPS
- Configured hostname as `netcup-prod-01`
- Created non-root sudo user
- Confirmed sudo access
- Validated SSH service status
- Validated SSH configuration syntax
- Disabled root SSH login
- Disabled password-based SSH login
- Enabled UFW firewall
- Allowed SSH, HTTP, and HTTPS
- Enabled Fail2Ban for SSH
- Enabled unattended upgrades
- Installed Docker
- Installed Docker Compose
- Installed Tailscale
- Created `/opt/stayz3ro` service folder structure
- Reviewed listening ports
- Captured redacted validation screenshots

## Documentation Improvements

- Restructured repo to match phase-based infrastructure documentation style
- Moved screenshots into a top-level screenshots folder
- Embedded Phase 1 validation screenshots directly in the validation page
- Added project-level roadmap and current status
- Added lessons learned for operational reflection
- Added sanitized config examples for security controls
- Polished the main README for clearer project presentation

---

# Phase 2 - Domain DNS & Public Routing

Status: ✅ Complete

## Added

- Phase 2 documentation folder
- Phase 2 overview
- Phase 2 step-by-step guide
- Phase 2 validation evidence
- Phase 2 screenshot evidence folder
- Phase 2 DNS routing diagram
- Phase 2 screenshot index
- Project-level navigation links for Phase 2

## Completed

- Removed Porkbun parking DNS records
- Added root domain A record for `stayz3ro.dev`
- Added `www` CNAME record
- Added `apps` subdomain A record
- Added `status` subdomain A record
- Added `api` subdomain A record
- Validated local DNS resolution
- Validated public resolver DNS results
- Confirmed SSH listening state
- Validated SSH over Tailscale
- Removed public SSH firewall rules
- Blocked public SSH access
- Confirmed UFW allows SSH only over Tailscale
- Confirmed HTTP and HTTPS remain public for future reverse proxy traffic
- Captured and redacted Phase 2 screenshots

## Security Improvement

Administrative SSH access is now restricted to the Tailscale private network.

Final management-plane model:

| Access | Status |
|---|---:|
| Public SSH | Blocked |
| Tailscale SSH | Allowed |
| Public HTTP | Allowed |
| Public HTTPS | Allowed |
| Direct app ports | Blocked |
| Admin dashboards | Not publicly exposed |

## Validation Evidence

Phase 2 validation screenshots cover:

- Porkbun DNS records
- Local DNS resolution
- Public resolver validation
- UFW state before public SSH cleanup
- SSH listening port
- Tailscale SSH success
- Final UFW Tailscale-only SSH state
- Public SSH blocked test

---

## Phase 3 - Reverse Proxy & HTTPS

Status: ✅ Complete

Reverse proxy platform chosen: **Caddy** (automatic HTTPS, no admin port,
no database, config-as-code. See `configs/caddy/README.md` for the full
Caddy-vs-NPM-vs-Traefik comparison).

Correction made 2026-08-30: the original build targeted the `stayz3ro.dev`
apex + `www` with a static landing page. Between build and deploy, the
apex was claimed by a separate Astro blog on Cloudflare Pages (see
the private operations CHANGELOG, 2026-08-29 entry). The Caddy config, compose
stack, and all four Phase 3 docs were retargeted: this VPS now serves
`status.stayz3ro.dev` reverse-proxied to Uptime Kuma; the apex/`www` are
never served here. `apps` and `api` remain staged for later.

Deployed 2026-08-30, all 11 runbook steps executed and validated on
`netcup-prod-01` (`docs/phases/phase-3-reverse-proxy-https/step-by-step.md`):

- `Caddyfile` + `docker-compose.yml` (Caddy + Uptime Kuma) deployed;
  `docker compose up -d` brought both containers up healthy
- Let's Encrypt certificate obtained for `status.stayz3ro.dev`
  (`tls-alpn-01` challenge, verified via multi-perspective validators)
- HTTP → HTTPS redirect (`308`), HSTS + security headers, JSON access
  logging all confirmed live
- Backend ports (`3000`, `3001`) confirmed not publicly reachable
- Uptime Kuma admin account created **before** public exposure, over a
  private SSH tunnel to the container's internal Docker network IP, not
  through the public hostname, closing the unauthenticated-first-run-setup
  window before the certificate made the hostname discoverable via
  Certificate Transparency logs
- `apps`/`api` subdomains remain staged (commented) for future services
- Redacted evidence screenshots captured for all 9 runbook evidence items
- Committed and pushed to branch `phase-03-reverse-proxy-https`

**Real blocker hit during deploy, not anticipated by the plan: DNS was
being edited in the wrong place.** `stayz3ro.dev`'s actual registry-delegated
nameservers are Cloudflare's (`felipe.ns.cloudflare.com` /
`melissa.ns.cloudflare.com`), not Porkbun's own DNS panel. The domain's
nameservers were switched to Cloudflare when the blog moved to Cloudflare
Pages, orphaning Porkbun's DNS hosting without removing write access to it.
Records edited in the Porkbun panel were never consulted by the live
internet. Full root-cause writeup: see "Confirm Which DNS Zone Is Actually
Live" in `LESSONS-LEARNED.md`.
- Merge to `master`

---

# Phase 4 - Docker App Deployment

Status: 🚧 In Progress (app selected, configs and runbook staged; live deployment pending)

App selected 2026-08-30: **Umami**, privacy-first, cookieless web analytics
at `analytics.stayz3ro.dev` (Umami + PostgreSQL), chosen over Shlink and
Vikunja. Rationale and candidate comparison:
`docs/phase-4-docker-app-deployment/overview.md`. The selection optimizes for
the lab's portfolio/blog goals (real analytics for the Cloudflare Pages blog
and the portfolio), a first stateful service (creating a concrete backup
target for Phase 6), and the smallest abuse surface for a first public app.

## Added

- Phase 4 documentation folder: scoping overview (candidates, tradeoffs,
  decision record) and landing README
- `configs/umami/`: Docker Compose stack (Umami + PostgreSQL), `.env.example`
  template, README with architecture and first-run security notes
- Umami stack design: app joins the external `web` network (reached only via
  Caddy); Postgres on an `internal: true` network unreachable from `web` or
  the host; no published ports
- Staged `analytics.{$SITE_DOMAIN}` route in `configs/caddy/Caddyfile`
  (commented until the runbook enables it)
- Phase 4 step-by-step runbook: SSH-tunnel admin claim before exposure
  (default-credential race, per the Phase 3 CT-log lesson), Cloudflare-zone
  DNS record (DNS-only), Caddy validation and restart with a brief edge
  interruption, external validation, port probes, Uptime Kuma monitor, and
  blog-embed coordination
- Phase 4 validation checklist (pending execution)
- Phase 4 architecture diagram (`diagrams/phase-4-docker-app-deployment.md`)

## Captured Since Scoping

- The 9 Phase 3 evidence screenshots were located (they had been taken during
  the 2026-08-30 deploy session but not carried into the repo), redacted
  (OCR-assisted detection - IPs, workstation hostname, ACME order URLs - with
  layered verification passes per the redaction-sweep lessons), and embedded
  in `docs/phase-3-reverse-proxy-https/validation.md` and
  `screenshots/phase-3-reverse-proxy-https/`. Item 06 (`www` redirect) was
  confirmed not applicable post-retarget; a bonus item 10 (Cloudflare zone
  as found during the DNS-zone-mismatch fix) was added. Committed after the
  visual pass (PR #11).

## Pending

- Execute the runbook on `netcup-prod-01`
- Wire the embed script into the Astro blog (separate repo)

---

## 2026-10-05: Public-edge firewall fix (Cloudflare-only access)

Prompted by an external attack-surface review that found `status` and
`ntfy` resolving directly to the VPS's own IP instead of through the
Cloudflare proxy.

## Completed

- Confirmed ntfy's `auth-default-access: deny-all` is correctly enforced
  (live test: both an anonymous read and an anonymous publish returned
  403). The review's "no auth gate" read came from the open CORS header
  alone, not an actual authenticated-endpoint test.
- Enabled Cloudflare proxying for the `status` and `ntfy` DNS records.
- Replaced UFW's broad 80/443 allow rules with per-range Cloudflare-only
  allow rules, then found UFW was never actually in the traffic path:
  Caddy publishes 80/443 through Docker, which filters forwarded
  container traffic through its own `DOCKER-USER` chain ahead of UFW's
  `INPUT` chain. Added the real fix directly to `DOCKER-USER`: an
  `ESTABLISHED,RELATED` accept, an accept for each Cloudflare IP range on
  80/443 tcp and 443 udp, and a final deny for everything else on those
  ports.
- Installed `iptables-persistent` (not previously present) and saved the
  rule set so it survives a reboot.
- Verified with a live request forced at the raw IP from outside: it
  times out, while the normal domain keeps answering correctly.
- See `LESSONS-LEARNED.md`, "UFW Does Not See Docker's Published Ports,"
  for the full root-cause writeup.
