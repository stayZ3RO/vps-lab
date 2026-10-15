# Phase 2 - Domain DNS & Public Routing 🌐

![Status](https://img.shields.io/badge/status-complete-brightgreen)
![DNS](https://img.shields.io/badge/dns-Porkbun-orange)
![Domain](https://img.shields.io/badge/domain-stayz3ro.dev-blue)
![SSH](https://img.shields.io/badge/ssh-Tailscale%20Only-success)

## Purpose

This diagram represents the public DNS routing and private administrative access model created during Phase 2.

---

## DNS Routing Model

    Internet User
         |
         v
    Public DNS Resolver
         |
         v
    stayz3ro.dev DNS Records
         |
         v
    Netcup VPS Public IP
         |
         ├── HTTP  - port 80
         └── HTTPS - port 443

---

## Configured DNS Records

| Record | Type | Target |
|---|---|---|
| stayz3ro.dev | A | Netcup VPS |
| www.stayz3ro.dev | CNAME | stayz3ro.dev |
| apps.stayz3ro.dev | A | Netcup VPS |
| status.stayz3ro.dev | A | Netcup VPS |
| api.stayz3ro.dev | A | Netcup VPS |

---

## Administrative Access Model

    Admin Workstation
         |
         | Tailscale
         v
    Netcup VPS Tailscale IP
         |
         | SSH
         v
    edge-vps

Public SSH is blocked.

---

## Firewall Posture After Phase 2

| Traffic | Exposure |
|---|---|
| SSH | Tailscale only |
| HTTP | Public |
| HTTPS | Public |
| App ports | Blocked |
| Admin dashboards | Private only |
| Database ports | Blocked |

---

## Next Architecture Layer

The next phase will add:

- Reverse proxy
- HTTPS certificates
- Domain-based service routing
- Public app routing through ports 80 and 443
