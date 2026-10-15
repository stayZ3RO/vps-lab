# Phase 2 - Overview 🌐

![Status](https://img.shields.io/badge/status-complete-brightgreen)
![Domain](https://img.shields.io/badge/domain-stayz3ro.dev-blue)
![Security](https://img.shields.io/badge/admin_access-private-success)

## Objective

Phase 2 connected `stayz3ro.dev` to the Netcup VPS using the Porkbun DNS
workspace and validated the then-current records. Cloudflare is authoritative
now, with Porkbun as registrar; the apex serves the blog from Cloudflare Pages.

This phase also tightened administrative access by restricting SSH to the Tailscale private network.

---

## Why This Phase Matters

DNS is the public entry point for future services.

Before deploying a reverse proxy, HTTPS certificates, or public Docker applications, the domain needs to resolve to the correct VPS.

This phase creates the foundation for:

- Root website routing
- Public app subdomains
- API subdomains
- Status page routing
- HTTPS certificate issuance
- Reverse proxy configuration

---

## DNS Design

| Record | Type | Purpose |
|---|---|---|
| stayz3ro.dev | A | Phase 2 root route to Netcup VPS; now Cloudflare Pages |
| www.stayz3ro.dev | CNAME | Alias to root domain |
| apps.stayz3ro.dev | A | Future public app entry point |
| status.stayz3ro.dev | A | Future status page |
| api.stayz3ro.dev | A | Future API services |

---

## Administrative Access Design

Before this phase, SSH was available publicly through the VPS firewall baseline.

After this phase, SSH is restricted to Tailscale.

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

## Security Posture After Phase 2

| Control | Status |
|---|---:|
| Public SSH | Blocked |
| Tailscale SSH | Allowed |
| HTTP | Publicly allowed |
| HTTPS | Publicly allowed |
| Direct app ports | Blocked |
| Portainer public exposure | Avoided |
| Database public exposure | Avoided |

---

## Outcome

At the end of this phase:

- Phase 2 records were configured in Porkbun; Cloudflare is authoritative now
- Root domain and subdomains resolve publicly
- Public DNS resolvers validate the records
- SSH is restricted to Tailscale
- The VPS is ready for reverse proxy and HTTPS configuration
