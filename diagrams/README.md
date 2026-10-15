# Architecture Diagrams 🧱

This folder contains architecture diagrams and infrastructure flow documentation for the VPS Cloud Infrastructure Lab.

The diagrams are intentionally simple and text-based so they are easy to version, review, and update as the project evolves.

---

## Diagram Index

| Diagram | Description |
|---|---|
| [Architecture Overview](architecture.md) | Canonical recorded architecture, public tracker and private administration (Mermaid) |
| [Phase 1 - VPS Baseline & Security Hardening](phase-1-vps-baseline-security.md) | Secure baseline architecture for the Netcup VPS |
| [Phase 2 - Domain DNS & Public Routing](phase-2-domain-dns-public-routing.md) | Public DNS routing and Tailscale-only SSH model |
| [Phase 3 - Reverse Proxy & HTTPS](phase-3-reverse-proxy-https.md) | HTTPS edge, host-based routing, staged service routes |
| [Phase 4 - Docker App Deployment](phase-4-docker-app-deployment.md) | Umami + PostgreSQL behind Caddy, internal-only database network |

---

## Diagram Style

Diagrams in this repo focus on:

- Clear service relationships
- Public versus private exposure
- Security boundaries
- VPS role separation
- Future expansion paths

As the project grows, this folder will include diagrams for:

- Domain DNS routing
- Reverse proxy and HTTPS flow
- Docker service layout
- Monitoring architecture
- Backup and restore flow
- Multi-VPS production/staging split
