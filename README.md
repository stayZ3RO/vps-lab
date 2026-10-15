# VPS Cloud Infrastructure Lab 🚀

Machine names and SSH aliases in this repository are generic role examples.
Use private inventory for real connection targets before following commands.

![Status](https://img.shields.io/badge/status-active-brightgreen)
![Current Phase](https://img.shields.io/badge/current_phase-Docker%20App%20Deployment-blue)
![Platform](https://img.shields.io/badge/platform-Netcup%20VPS-orange)
![Docker](https://img.shields.io/badge/container_runtime-Docker-blue)
![Security](https://img.shields.io/badge/security-hardened-success)
![Access](https://img.shields.io/badge/private_access-Tailscale-purple)

## Quick Links

| Area | Link |
|---|---|
| Current Status | [CURRENT-STATUS.md](CURRENT-STATUS.md) |
| Roadmap | [ROADMAP.md](ROADMAP.md) |
| Lessons Learned | [LESSONS-LEARNED.md](LESSONS-LEARNED.md) |
| Changelog | [CHANGELOG.md](CHANGELOG.md) |
| Documentation Hub | [docs/](docs/) |
| Architecture Diagrams | [diagrams/](diagrams/) |
| Config Examples | [configs/](configs/) |
| Screenshots | [screenshots/](screenshots/) |
| Live Portfolio | [chrisalorenzo.com](https://chrisalorenzo.com/) |
| Blog | [blog.chrisalorenzo.com](https://blog.chrisalorenzo.com/) |
| Public Status | [status.chrisalorenzo.com](https://status.chrisalorenzo.com/status/main) |

---

## Building a Production-Style VPS Cloud Lab

This repository documents my VPS lab: Linux and Docker hosting, public DNS, Caddy HTTPS, uptime monitoring, and private administration. Backup and restore work is still planned.

The goal is to move beyond local-only homelab infrastructure and build practical experience with public cloud-style hosting, Linux server hardening, DNS routing, containerized deployments, and production-minded documentation.

This project is part of my broader infrastructure learning path toward cloud, network, and systems engineering roles.

---

## Why I Built This

After building out my home network infrastructure lab, I wanted to extend the same hands-on approach into public-facing cloud infrastructure.

This VPS lab gives me a place to practice:

- Managing real Linux servers exposed to the public internet
- Hardening SSH and host-level access
- Using firewall rules and brute-force protection
- Hosting containerized services with Docker
- Connecting a custom domain to public infrastructure
- Deploying services behind a reverse proxy with HTTPS
- Building monitoring, backups, and staging workflows
- Documenting infrastructure decisions like an engineer

---

## Current Architecture

    Admin Workstation
          |
          | SSH over Tailscale
          v
    Netcup VPS - edge-vps
          |
          ├── Firewall controls (UFW and DOCKER-USER)
          │     ├── HTTP/HTTPS from Cloudflare ranges only
          │     ├── Docker-published proxy ports restricted in DOCKER-USER
          │     └── SSH over tailscale0 only
          |
          ├── Fail2Ban
          │     └── SSH brute-force protection
          |
          ├── Docker Engine
          │     ├── Caddy (reverse proxy, automatic HTTPS)
          │     ├── Uptime Kuma (status.chrisalorenzo.com, public status page only)
          │     ├── ntfy (ntfy.chrisalorenzo.com, backend internal only)
          │     └── Umami (a.chrisalorenzo.com, tracker paths only; PostgreSQL internal)
          |
          ├── Tailscale
          │     └── Private SSH; loopback-backed Kuma and Umami admin via tailscale serve
          |
          └── /opt/stayz3ro
                ├── apps
                ├── backups
                ├── monitoring
                ├── proxy
                └── scripts

---

## Target Architecture

    Internet
       |
       v
    Cloudflare DNS (chrisalorenzo.com and stayz3ro.dev)
       |
       v
    Netcup VPS - Production/Public Services
       |
       ├── Reverse Proxy
       ├── HTTPS Certificates
       ├── Public Docker Apps
       └── Private Admin Access via Tailscale

    RackNerd VPS - Planned Secondary Node
       |
       ├── Staging Services
       ├── Monitoring
       ├── Backups
       └── Secondary Infrastructure

---

## Current Progress

| Phase | Status | Focus |
|---|---:|---|
| Phase 1 - VPS Baseline & Security Hardening | ✅ Complete | Secure Linux baseline |
| Phase 2 - Domain DNS & Public Routing | ✅ Complete | stayz3ro.dev DNS records and Tailscale-only SSH |
| Phase 3 - Reverse Proxy & HTTPS | ✅ Complete | Public routing and TLS |
| Phase 4 - Docker App Deployment | ✅ Deployed; evidence follow-up | Umami tracker deployed 2026-10-14; see Current Status |
| Phase 5 - Monitoring & Alerts | ✅ Public edge live | Seven Kuma monitors, Discord and self-hosted ntfy alerts since 2026-09-28 |
| Phase 6 - Backups & Disaster Recovery | ⏳ Planned | Recovery strategy |
| Phase 7 - Secondary VPS / Staging | ⏳ Planned | RackNerd staging and backup node |
| Phase 8 - AI Agent / Homelab Ops Bot | ⏳ Planned | Infrastructure assistant experiments |

---

## Completed Work

### Phase 1 - VPS Baseline & Security Hardening

Phase 1 prepared the Netcup VPS as a secure Linux baseline before deploying public services.

Highlights:

- Configured hostname: `edge-vps`
- Created a non-root sudo user
- Hardened SSH access
- Disabled root SSH login
- Disabled password-based SSH login
- Enabled UFW firewall
- Enabled Fail2Ban
- Enabled unattended security updates
- Installed Docker and Docker Compose
- Installed Tailscale
- Created `/opt/stayz3ro` folder structure
- Reviewed listening ports

### Phase 2 - Domain DNS & Public Routing

Phase 2 connected `stayz3ro.dev` to the VPS and improved the management-plane security model.

Highlights:

- Removed Porkbun parking records
- Added root domain DNS record
- Added `www`, `apps`, `status`, and `api` records
- Validated local DNS resolution
- Validated public DNS resolvers
- Confirmed SSH over Tailscale
- Removed public SSH access
- Confirmed UFW allows SSH only over `tailscale0`
- Captured redacted validation screenshots

### Phase 3 - Reverse Proxy & HTTPS

Phase 3 put Caddy in front of the VPS and served Uptime Kuma at `status.stayz3ro.dev` over HTTPS while backend ports stayed private. The 2026-10-04 domain move below records the current host.

Highlights:

- Deployed the Caddy stack on the VPS (2026-08-30)
- Issued a Let's Encrypt certificate for `status.stayz3ro.dev`, renewed automatically
- Reverse-proxied Uptime Kuma; its admin account was created over a private SSH tunnel before exposure
- HTTP redirects to HTTPS (308)
- Validated security headers and the JSON access log
- Confirmed backend ports are not public with an external probe
- Captured redacted validation screenshots

### Phase 5 - Monitoring & Alerts

Since 2026-09-28, Uptime Kuma has watched six public-edge targets plus
`ntfy-health`. Discord carries alerts for all six primary monitors; the
self-hosted ntfy provider also reaches a phone. A synthetic DOWN/UP test
validated the Discord path. An independent offsite check remains planned
because Kuma and the services share the VPS.

### Domain move (2026-10-04)

The blog now runs at `blog.chrisalorenzo.com` on Cloudflare Pages. The public
status page is `status.chrisalorenzo.com/status/main`, with `Sites` and `Infra`
groups. Its root returns 302 to `/status/main`; public admin paths return 404.
Kuma has tailnet-only admin via `tailscale serve` on port 8443, backed by IPv4
loopback port 3001. Docker is 29.8.1.

Caddy returns 301 from `status.stayz3ro.dev` to `status.chrisalorenzo.com`.
Cloudflare returns 301 from `stayz3ro.dev` and `www.stayz3ro.dev` to
`blog.chrisalorenzo.com`. Both preserve the path and query. The two old blog
hosts were removed from the Pages custom domains and use redirect-only DNS
records.

The renamed monitor displays are `Blog`, `Portfolio`, `HTTPS Edge`,
`DNS (stayz3ro.dev)` and `DNS (chrisalorenzo.com)`. Their old names remain as
`id` tags; [Current Status](CURRENT-STATUS.md#monitoring-and-alerts) records the
mapping and remaining target checks. TLS expiry warnings are set to 14 days.
There are no push monitors.

---

## Documentation

### Phase 1 - VPS Baseline & Security Hardening

| Document | Description |
|---|---|
| [Phase Home](docs/phase-1-vps-baseline-security/) | Phase 1 landing page |
| [Overview](docs/phase-1-vps-baseline-security/overview.md) | What was built and why |
| [Step-by-Step Guide](docs/phase-1-vps-baseline-security/step-by-step.md) | Commands and setup process |
| [Validation Evidence](docs/phase-1-vps-baseline-security/validation.md) | Screenshots and proof |
| [Architecture Diagram](diagrams/phase-1-vps-baseline-security.md) | Phase 1 infrastructure layout |

### Phase 2 - Domain DNS & Public Routing

| Document | Description |
|---|---|
| [Phase Home](docs/phase-2-domain-dns-public-routing/) | Phase 2 landing page |
| [Overview](docs/phase-2-domain-dns-public-routing/overview.md) | DNS and access model overview |
| [Step-by-Step Guide](docs/phase-2-domain-dns-public-routing/step-by-step.md) | DNS and SSH access implementation flow |
| [Validation Evidence](docs/phase-2-domain-dns-public-routing/validation.md) | DNS and Tailscale-only SSH proof |
| [Architecture Diagram](diagrams/phase-2-domain-dns-public-routing.md) | Public DNS and private admin access model |

### Phase 3 - Reverse Proxy & HTTPS

| Document | Description |
|---|---|
| [Phase Home](docs/phase-3-reverse-proxy-https/) | Phase 3 landing page |
| [Overview](docs/phase-3-reverse-proxy-https/overview.md) | What was built and why |
| [Step-by-Step Guide](docs/phase-3-reverse-proxy-https/step-by-step.md) | Implementation runbook and commands |
| [Validation Evidence](docs/phase-3-reverse-proxy-https/validation.md) | Screenshots and proof |
| [Architecture Diagram](diagrams/phase-3-reverse-proxy-https.md) | HTTPS edge and request flow |

### Project-Level Docs

| Document | Description |
|---|---|
| [Current Status](CURRENT-STATUS.md) | Current project state |
| [Roadmap](ROADMAP.md) | Planned phases |
| [Lessons Learned](LESSONS-LEARNED.md) | Troubleshooting notes and design decisions |
| [Changelog](CHANGELOG.md) | Project update history |

---

## Repository Structure

    configs/
      Sanitized service and security configuration examples

    diagrams/
      Architecture diagrams and infrastructure flow documentation

    docs/
      Phase-based documentation

    screenshots/
      Redacted validation screenshots and implementation evidence

    scripts/
      Local documentation validation; service backup tooling is under configs/umami/

---

## Core Tools and Services

| Category | Tools |
|---|---|
| VPS Provider | Netcup |
| Planned Secondary VPS | RackNerd |
| OS | Ubuntu Linux |
| Access | SSH over Tailscale |
| Firewall | UFW |
| Intrusion Protection | Fail2Ban |
| Updates | Unattended Upgrades |
| Containers | Docker, Docker Compose |
| Domains | chrisalorenzo.com public services; stayz3ro.dev legacy redirects |
| DNS Provider | Cloudflare (Porkbun is the registrar) |
| Reverse Proxy | Caddy |
| HTTPS | Let's Encrypt, automatic via Caddy |

---

## What This Project Demonstrates

This project demonstrates practical infrastructure skills across:

- Linux server administration
- VPS security hardening
- SSH access control
- Firewall policy management
- Brute-force protection
- Secure remote administration
- Docker runtime setup
- Public DNS routing
- Infrastructure documentation
- Cloud hosting fundamentals
- Production-minded validation

---

## Security Notes

This repository intentionally excludes:

- Public IP addresses
- Private keys
- API keys
- Provider credentials
- Tailscale authentication data
- Billing information
- Unredacted screenshots
- Production secrets

Admin dashboards, databases, Portainer, and monitoring tools should not be directly exposed to the public internet.

---

## Current Focus

Umami was deployed on 2026-10-14 at `a.chrisalorenzo.com`, with only tracker
paths public and administration through Tailscale Serve. Public service
records use the Cloudflare proxy because origin HTTP/HTTPS accepts only
Cloudflare ranges. [Current Status](CURRENT-STATUS.md) is the canonical home
for deployment details and outstanding evidence, monitoring and integration checks.

---

## Related Infrastructure Labs

This repository is part of a broader infrastructure lab portfolio.

| Repository | Focus | Relationship |
|---|---|---|
| [Home Network Infrastructure Lab](https://github.com/stayZ3RO/dns) | HA DNS, Pi-hole, Unbound, monitoring, Tailscale, Proxmox, RustDesk | Demonstrates the local infrastructure foundation and HA service layer |
| [Home Network Managed Infrastructure Lab](https://github.com/stayZ3RO/netlab) | Live UniFi routing and switching; VLAN/firewall segmentation planned | Demonstrates a managed core and documented next steps |
| [AWS Network Automation Lab](https://github.com/stayZ3RO/cloud-netlab) | CI-validated Terraform/OpenTofu VPC module and Python drift check; no cloud resources applied | Extends infrastructure practice into a scoped cloud learning lab |
