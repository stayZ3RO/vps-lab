# Roadmap

This roadmap tracks the planned buildout for the VPS Cloud Infrastructure Lab.

The project starts with a secure Linux baseline, then layers on DNS, HTTPS, container hosting, monitoring, backups, a secondary VPS, and future AI-assisted infrastructure operations.

---

## Phase Overview

| Phase | Status | Focus |
|---|---:|---|
| Phase 1 - VPS Baseline & Security Hardening | ✅ Complete | Secure the Netcup VPS before public hosting |
| Phase 2 - Domain DNS & Public Routing | ✅ Complete | Connected stayz3ro.dev to the VPS |
| Phase 3 - Reverse Proxy & HTTPS | ✅ Complete | Route services through HTTPS |
| Phase 4 - Docker App Deployment | ✅ Deployed; evidence follow-up | Umami deployed 2026-10-14; remaining checks in Current Status |
| Phase 5 - Monitoring & Alerts | ✅ Public edge live | Seven Kuma monitors and Discord plus self-hosted ntfy alerts since 2026-09-28; offsite check planned |
| Phase 6 - Backups & Disaster Recovery | ⏳ Planned | Build recovery and backup strategy |
| Phase 7 - Secondary VPS / Staging | ⏳ Planned | Use RackNerd for staging, monitoring, and backups |
| Phase 8 - AI Agent / Homelab Ops Bot | ⏳ Planned | Experiment with infrastructure assistant workflows |

---

## Phase 1 - VPS Baseline & Security Hardening

Status: ✅ Complete

Purpose:

Establish a secure and validated Linux server baseline before exposing applications or services to the public internet.

Completed:

- Provisioned Netcup VPS
- Configured hostname
- Created non-root sudo user
- Hardened SSH
- Disabled root SSH login
- Disabled password SSH login
- Enabled UFW firewall
- Allowed only SSH, HTTP, and HTTPS
- Enabled Fail2Ban for SSH protection
- Enabled unattended upgrades
- Installed Docker and Docker Compose
- Installed Tailscale
- Created /opt/stayz3ro folder structure
- Reviewed listening ports
- Captured validation screenshots

---

## Phase 2 - Domain DNS & Public Routing

Status: ✅ Complete

Purpose:

Connect the stayz3ro.dev domain to the VPS and establish a clean DNS foundation for public services.

Completed:

- Configured Porkbun DNS records
- Removed default parking records
- Added root domain record
- Added www record
- Added apps, status, and api records
- Validated local DNS resolution
- Validated public resolvers
- Restricted SSH to Tailscale
- Captured redacted DNS and security screenshots

Phase 2 subdomain plan (historical snapshot; current hosts are in
[Current Status](CURRENT-STATUS.md)):

| Subdomain | Intended Purpose |
|---|---|
| stayz3ro.dev | Main landing page or portfolio |
| www.stayz3ro.dev | Web alias |
| apps.stayz3ro.dev | Public app entry point |
| status.stayz3ro.dev | Status or uptime page |
| lab.stayz3ro.dev | Lab services |
| api.stayz3ro.dev | API services |

---

## Phase 3 - Reverse Proxy & HTTPS

Status: ✅ Complete

Purpose:

Deploy a reverse proxy to route public services securely through HTTPS.

Completed:

- Chose Caddy (automatic HTTPS, no admin port, no database)
- Configured HTTP to HTTPS routing (`308` redirect)
- Issued a Let's Encrypt TLS certificate for `status.stayz3ro.dev`
- Routed `status.stayz3ro.dev` to Uptime Kuma; `apps`/`api` staged for later
- Application ports never published to the host
- Documented proxy design (`configs/caddy/README.md`)
- Validated HTTPS externally (curl + browser)
- Secured Uptime Kuma's admin account before public exposure

See `CHANGELOG.md` and `LESSONS-LEARNED.md` for the full deployment record,
including the DNS zone mismatch that blocked the first deploy attempt.

---

## Phase 4 - Docker App Deployment

Status: ✅ Umami deployed 2026-10-14; evidence follow-up remains

Umami 3.4.0 and PostgreSQL 16 run behind Caddy. The proxied public host
`a.chrisalorenzo.com` exposes `/script.js` and `/api/send` only. Administration
uses loopback port 3000 through Tailscale Serve on 8444. Origin HTTP/HTTPS
accepts Cloudflare ranges only.

Completed in the repository: compose stack, `.env.example`, deployment guide,
validation checklist and daily database backup tooling. The deployment and
certificate correction are recorded in [CHANGELOG.md](CHANGELOG.md#2026-10-14-umami-deployed-public-record-proxied).
[Current Status](CURRENT-STATUS.md#next-workstream) owns remaining checks;
monitoring, site embeds, timer installation and screenshots are not marked
complete without their evidence.

---

## Phase 5 - Monitoring & Alerts

Status: ✅ Public edge live since 2026-09-28; offsite check still planned

Purpose:

Watch public sites, HTTPS, DNS, and ntfy health from Uptime Kuma on the VPS.

Completed:

- Six public-edge monitors and one ntfy-health monitor
- Discord and self-hosted ntfy notification paths
- Real synthetic DOWN/UP test for the Discord path
- Final wiring recorded without secrets

Remaining:

- Independent offsite check for full VPS outages
- Verify the moved Blog, status-page and HTTPS Edge targets and add the
  `blog-redirect` monitor for the old blog host's 301
- VPS host-health and screenshot work, if scoped separately

---

## Phase 6 - Backups & Disaster Recovery

Status: ⏳ Planned

Purpose:

Create a backup and restore strategy for hosted services.

Planned tasks:

- Define backup targets
- Back up Docker volumes
- Back up app data
- Back up databases
- Test restore process
- Document recovery steps
- Plan offsite backups

---

## Phase 7 - Secondary VPS / Staging

Status: ⏳ Planned

Purpose:

Use the RackNerd VPS as a secondary node for staging, monitoring, backups, and experiments.

Planned tasks:

- Provision RackNerd VPS
- Apply same baseline security hardening
- Configure staging services
- Add monitoring responsibilities
- Configure offsite backup target
- Document role separation between VPS nodes

---

## Phase 8 - AI Agent / Homelab Ops Bot

Status: ⏳ Planned

Purpose:

Experiment with an AI-assisted infrastructure helper that can answer quick questions about VPS and homelab status.

Planned capabilities:

- Query uptime status
- Summarize service health
- Check documentation
- Provide quick operational reminders
- Support private access through secure channels
- Avoid exposing privileged systems publicly
