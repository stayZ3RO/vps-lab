# Phase 1 - VPS Baseline Architecture 🔐

![Status](https://img.shields.io/badge/status-complete-brightgreen)
![Scope](https://img.shields.io/badge/scope-security%20baseline-blue)
![Access](https://img.shields.io/badge/access-SSH%20%2B%20Tailscale-purple)

## Purpose

This diagram represents the secure baseline architecture created during Phase 1 of the VPS Cloud Infrastructure Lab.

At this stage, the VPS is not yet hosting public applications. The focus is on secure access, limited public exposure, host-level protection, and preparation for future Docker services.

---

## Phase 1 Baseline Diagram

    Admin Workstation
          |
          | SSH Key Authentication
          | Tailscale Private Access
          v
    Netcup VPS - edge-vps
          |
          ├── Access Layer
          │     ├── Non-root sudo user
          │     ├── SSH key authentication
          │     ├── Root SSH login disabled
          │     └── Password SSH login disabled
          |
          ├── Firewall Layer
          │     └── UFW
          │           ├── SSH allowed
          │           ├── HTTP allowed
          │           └── HTTPS allowed
          |
          ├── Intrusion Protection
          │     └── Fail2Ban
          │           └── SSH jail enabled
          |
          ├── System Maintenance
          │     ├── Unattended upgrades
          │     └── Swap configured
          |
          ├── Container Runtime
          │     └── Docker Engine + Docker Compose
          |
          ├── Private Network Access
          │     └── Tailscale
          |
          └── Service Directory Layout
                └── /opt/stayz3ro
                      ├── apps
                      ├── backups
                      ├── monitoring
                      ├── proxy
                      └── scripts

---

## Public Exposure Model

Only the minimum required ports are allowed at this stage.

| Port | Purpose | Status |
|---|---|---:|
| SSH | Administrative access | Allowed |
| HTTP | Web traffic and certificate validation | Allowed |
| HTTPS | Secure public services | Allowed |

Everything else should remain blocked unless intentionally added later.

---

## Private Access Model

Tailscale provides a private administrative path for future internal tools.

Potential future private-only services:

| Service Type | Preferred Access |
|---|---|
| Portainer | Tailscale |
| Monitoring dashboards | Tailscale or restricted HTTPS |
| Admin-only apps | Tailscale |
| Internal APIs | Tailscale or Docker network |
| Databases | Internal Docker network only |

---

## Design Decisions

| Decision | Reason |
|---|---|
| Disable root SSH login | Reduces risk from direct root login attempts |
| Disable password SSH login | Forces key-based authentication |
| Enable UFW | Limits the public attack surface |
| Allow only SSH, HTTP, HTTPS | Keeps baseline exposure minimal |
| Enable Fail2Ban | Adds protection against repeated SSH failures |
| Install Docker early | Prepares for repeatable container deployments |
| Install Tailscale | Supports private admin access without exposing dashboards |
| Use /opt/stayz3ro | Keeps future services organized |

---

## Next Architecture Layer

The next diagram will be for:

**Phase 2 - Domain DNS & Public Routing**

That phase will add:

- stayz3ro.dev DNS
- Root domain routing
- www record
- Planned service subdomains
- DNS validation flow
