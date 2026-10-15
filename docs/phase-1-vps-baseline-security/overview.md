# Phase 1 - VPS Baseline & Security Hardening 🔐

---

## Quick Navigation

| Page | Link |
|---|---|
| Phase 1 Home | [README](README.md) |
| Overview | [overview.md](overview.md) |
| Step-by-Step Guide | [step-by-step.md](step-by-step.md) |
| Validation Evidence | [validation.md](validation.md) |
| Architecture Diagram | [Diagram](../../diagrams/phase-1-vps-baseline-security.md) |

---


![Status](https://img.shields.io/badge/status-complete-brightgreen)
![Provider](https://img.shields.io/badge/provider-Netcup-orange)
![OS](https://img.shields.io/badge/os-Ubuntu%20Linux-blue)
![Security](https://img.shields.io/badge/security-hardened-success)
![Access](https://img.shields.io/badge/private_access-Tailscale-purple)

## Overview

Phase 1 established the secure foundation for the VPS Cloud Infrastructure Lab.

Before connecting a domain, deploying a reverse proxy, or hosting public applications, the VPS needed to be configured as a hardened Linux server with controlled administrative access, limited public exposure, and documented validation evidence.

This phase converted a fresh public VPS into a secure baseline host ready for future Docker-based services.

---

## Objective

Prepare the Netcup VPS as a secure, production-ready Linux server before adding:

- Domain DNS
- Reverse proxy routing
- HTTPS certificates
- Public Docker applications
- Monitoring
- Backups
- AI infrastructure assistant experiments

The focus of this phase was not to deploy applications yet. The focus was to make sure the server was safe and stable enough to host them later.

---

## Why This Phase Matters

A newly provisioned VPS is immediately exposed to the public internet.

That means SSH scanning, login attempts, and general background noise from the internet begin almost immediately. Before running public services, the server needs a hardened baseline.

This phase answers the question:

> Is this VPS secure enough to become the public-facing foundation for future services?

---

## Phase 1 Outcome

| Area | Result |
|---|---|
| VPS provider | Netcup |
| Hostname | edge-vps |
| Operating system | Ubuntu Linux |
| Admin model | Non-root sudo user |
| SSH access | Key-based authentication |
| Root SSH login | Disabled |
| Password SSH login | Disabled |
| Firewall | UFW enabled |
| Public ports | SSH, HTTP, HTTPS only |
| Brute-force protection | Fail2Ban enabled |
| Automatic updates | Unattended upgrades enabled |
| Container runtime | Docker and Docker Compose |
| Private admin access | Tailscale |
| Service layout | /opt/stayz3ro |

---

## Baseline Architecture

    Admin Workstation
          |
          | SSH Key Authentication / Tailscale
          v
    Netcup VPS - edge-vps
          |
          ├── UFW Firewall
          │     ├── SSH
          │     ├── HTTP
          │     └── HTTPS
          |
          ├── Fail2Ban
          │     └── SSH brute-force protection
          |
          ├── Docker Engine
          │     └── Future container workloads
          |
          ├── Tailscale
          │     └── Private administrative access
          |
          └── /opt/stayz3ro
                ├── apps
                ├── backups
                ├── monitoring
                ├── proxy
                └── scripts

---

## What Was Built

### Secure Administrative Access

The VPS was configured to avoid direct root-based administration.

Implemented:

- Non-root sudo user
- SSH key-based access
- Root SSH login disabled
- Password-based SSH login disabled
- SSH configuration validated before reload

Why it matters:

- Reduces exposure from direct root login attempts
- Removes password authentication from the public internet
- Creates a safer daily administration model

---

### Host-Level Firewall Baseline

UFW was enabled with a minimal allowlist.

Current public exposure:

| Port | Purpose |
|---|---|
| SSH | Server administration |
| HTTP | Web traffic and certificate validation |
| HTTPS | Secure public services |

All other incoming traffic is denied by default.

Why it matters:

- Keeps the attack surface small
- Prevents accidental exposure of future app ports
- Creates a clean baseline before reverse proxy deployment

---

### SSH Brute-Force Protection

Fail2Ban was enabled for SSH.

Purpose:

- Monitor repeated failed login attempts
- Temporarily ban abusive sources
- Add an extra defensive layer on top of SSH hardening

Fail2Ban does not replace SSH keys or firewalling, but it strengthens the baseline.

---

### Automatic Security Updates

Unattended upgrades were enabled.

Purpose:

- Keep security patches flowing automatically
- Reduce risk from outdated packages
- Support a more production-minded server baseline

---

### Docker Runtime Readiness

Docker and Docker Compose were installed and validated.

Purpose:

- Prepare for future containerized services
- Support repeatable deployments
- Enable future reverse proxy, application, monitoring, and automation stacks

No public Docker applications were deployed in this phase.

---

### Private Admin Access

Tailscale was installed and connected.

Purpose:

- Provide private administrative access
- Reduce the need to expose dashboards publicly
- Prepare for future private services such as Portainer, monitoring, or internal tools

Design decision:

> Public services should go through HTTPS and a reverse proxy. Admin services should stay private whenever possible.

---

### Service Directory Layout

A clean service layout was created under /opt/stayz3ro.

    /opt/stayz3ro
    ├── apps
    ├── backups
    ├── monitoring
    ├── proxy
    └── scripts

Purpose:

- Keep services organized
- Separate apps, proxy, monitoring, backups, and scripts
- Make future documentation and operations cleaner

---

## Security Posture After Phase 1

| Control | Status |
|---|---:|
| Non-root sudo user | ✅ Enabled |
| Root SSH login | ✅ Disabled |
| Password SSH login | ✅ Disabled |
| SSH key authentication | ✅ Enabled |
| UFW firewall | ✅ Enabled |
| Fail2Ban SSH jail | ✅ Active |
| Unattended upgrades | ✅ Enabled |
| Tailscale private access | ✅ Connected |
| Docker installed | ✅ Complete |
| Direct app port exposure | ✅ Avoided |
| Public database exposure | ✅ Avoided |

---

## Validation Evidence

Phase 1 was validated with screenshots and command output covering:

- Hostname configuration
- Operating system version
- SSH service status
- SSH config validation
- UFW firewall rules
- Fail2Ban status
- Unattended upgrades
- Swap and memory state
- Docker and Docker Compose
- Tailscale status
- VPS folder structure
- Listening ports

View evidence:

[Phase 1 Validation Evidence](validation.md)

---

## Related Documentation

| Document | Purpose |
|---|---|
| [Step-by-Step Guide](step-by-step.md) | Commands and implementation flow |
| [Validation Evidence](validation.md) | Screenshots and proof of completion |
| [Architecture Diagram](../../diagrams/phase-1-vps-baseline-security.md) | Phase 1 infrastructure layout |

---

## Key Takeaway

Phase 1 did not focus on deploying apps.

It focused on something more important:

> Building a secure foundation before exposing services to the public internet.

With this baseline complete, the VPS is ready for the next phase: domain DNS and public routing.
