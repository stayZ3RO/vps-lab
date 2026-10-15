# Phase 3 - Reverse Proxy & HTTPS 🔒

![Status](https://img.shields.io/badge/status-in%20progress-yellow)
![Proxy](https://img.shields.io/badge/proxy-Caddy-blue)
![TLS](https://img.shields.io/badge/tls-Let's%20Encrypt-success)
![Domain](https://img.shields.io/badge/domain-stayz3ro.dev-purple)

## Purpose

This diagram represents the public HTTPS edge introduced in Phase 3.

A single reverse proxy (Caddy) terminates TLS for `stayz3ro.dev`, serves a
static landing page, and is staged to route future backend services without
exposing their ports.

---

## Request Flow

    Internet User
         |
         |  https://stayz3ro.dev
         v
    Public DNS Resolver  ->  stayz3ro.dev A record  ->  Netcup VPS public IP
         |
         v
    Netcup VPS - edge-vps
         |
         ├── UFW: only 80/tcp, 443/tcp public (SSH is Tailscale only)
         |
         v
    Caddy container  (published on 80 / 443 / 443-udp)
         |
         ├── :80  ->  redirect to :443
         ├── automatic Let's Encrypt cert  (HTTP-01 challenge on :80)
         ├── JSON access log  -> /var/log/caddy/access.log
         |
         ├── stayz3ro.dev          ->  file_server  /srv  (static page)
         ├── www.stayz3ro.dev      ->  308 redirect to apex
         |
         └── [Phase 4, staged/disabled]
                apps.stayz3ro.dev    ->  reverse_proxy  app:3000
                status.stayz3ro.dev  ->  reverse_proxy  uptime-kuma:3001
                api.stayz3ro.dev     ->  reverse_proxy  api:8000
                     |
                     v
             internal "web" Docker network
             (backend ports never published to the host)

---

## Administrative Access (unchanged from Phase 2)

    Admin Workstation
         |
         | Tailscale
         v
    Netcup VPS Tailscale IP
         |
         | SSH
         v
    edge-vps

---

## Exposure Model After Phase 3

| Traffic | Exposure |
|---|---|
| HTTP (80) | Public - redirects to HTTPS, serves ACME challenge |
| HTTPS (443) | Public - static landing page only |
| `www` subdomain | Public - redirects to apex |
| `apps` / `status` / `api` | Not routed yet (staged in Caddyfile) |
| Backend app ports | Internal Docker network only, never published |
| Caddy admin API | Disabled |
| SSH | Tailscale only |

---

## Design Decisions

| Decision | Reason |
|---|---|
| Caddy over NPM / Traefik | One config file, automatic TLS, no admin port, no database - smallest attack surface on a public node |
| Static page served in Phase 3 | Gives HTTPS something real to serve before apps exist; externally verifiable |
| `admin off` | The Caddy admin API is not needed and should not be listening |
| JSON access logs from day one | Structured logs ready for a log stack in Phase 5 |
| Backend routes staged but commented | Keeps Phase 4 wiring visible without exposing anything early |
| `caddy_data` named volume | Persists issued certs and ACME account across restarts; avoids Let's Encrypt rate limits |

---

## Next Architecture Layer

**Phase 4 - Docker App Deployment**

That phase will bring up the first backend container on the `web` network and
enable one of the staged `reverse_proxy` routes.
