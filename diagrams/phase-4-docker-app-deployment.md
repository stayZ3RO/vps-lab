# Phase 4 - Docker App Deployment 🐳

![Status](https://img.shields.io/badge/status-deployed%20October%2014-success)
![App](https://img.shields.io/badge/app-Umami-success)
![Proxy](https://img.shields.io/badge/proxy-behind%20Caddy-success)
![Domain](https://img.shields.io/badge/domain-a.chrisalorenzo.com-purple)

## Purpose

Umami 3.4.0 and PostgreSQL 16 were deployed on 2026-10-14. The public host
`a.chrisalorenzo.com` serves tracker paths only through Cloudflare and Caddy.
The dashboard uses loopback-backed Tailscale Serve; PostgreSQL stays internal.
See [the recorded deployment](../CHANGELOG.md#2026-10-14-umami-deployed-public-record-proxied)
and [the current guide](../docs/phase-4-docker-app-deployment/step-by-step.md).

---

## Request Flow

    Internet Visitor / Blog Reader
         |
         |  https://a.chrisalorenzo.com
         v
     Public DNS Resolver  ->  Cloudflare zone (proxied a record)
                              ->  Cloudflare edge -> restricted VPS origin
         |
         v
     Netcup VPS - edge-vps
         |
         ├── HTTP/HTTPS from Cloudflare ranges only (including DOCKER-USER)
         ├── SSH is Tailscale only
         v
     Caddy container  (published on 80 / 443 / 443-udp)
         |
         ├── :80  ->  redirect to :443
         ├── automatic Let's Encrypt cert (a.chrisalorenzo.com)
         ├── JSON access log  -> /var/log/caddy/access.log
         |
         ├── status.chrisalorenzo.com -> public Kuma status page only
         └── a.chrisalorenzo.com -> /script.js and /api/send -> umami:3000
                                   all other public paths -> 404
                    |
                    v
             external "web" Docker network
             (public traffic passes through Caddy; admin publish is loopback only)
                    |
                    v
     umami container
         |
         | umami_internal network (internal: true - no route outside,
         |                          NOT attached to "web")
         v
     umami-db container  (PostgreSQL 16, port 5432 internal)
         |     reachable by the umami container only
         |
         └── umami_db_data named volume
             (first stateful data on the VPS -> Phase 6 backup target)

Site embed example (integration evidence not recorded here, Cloudflare Pages)
         |
         | <script src="https://a.chrisalorenzo.com/script.js"
         |         data-website-id="...">
         v
     analytics events flow to Umami through the same public HTTPS path

---

## Administrative Access

    Admin Workstation
         |
         | Tailscale
         v
     Netcup VPS Tailscale IP
         |
         | SSH; Kuma admin through tailscale serve on port 8443
         | Umami admin through tailscale serve on port 8444 to loopback port 3000
         v
     edge-vps

---

## Exposure Model After Phase 4

| Traffic | Exposure |
|---|---|
| Origin HTTP / HTTPS | Cloudflare ranges only; proxied DNS required |
| Public HTTPS | Cloudflare fronts Caddy for status, ntfy and Umami tracker |
| Kuma admin | Tailnet-only through `tailscale serve`; public admin paths return 404 |
| `a.chrisalorenzo.com` (Umami) | Public `/script.js` and `/api/send` only; other paths 404 |
| Umami app port (3000) | Loopback publish; admin available through Tailscale Serve on 8444 |
| PostgreSQL (5432) | Internal-only network, unreachable from `web` or the host |
| `apps` / `api` subdomains | Not routed yet (staged in Caddyfile) |
| Caddy admin API | Disabled |
| SSH | Tailscale only |

---

## Design Decisions

| Decision | Reason |
|---|---|
| Umami over Shlink / Vikunja | Feeds the active portfolio/blog goals directly; smallest abuse surface for a first stateful service - full comparison in the Phase 4 overview |
| Neutral `a` subdomain | Current tracker host; replaces the original analytics hostname |
| Proxied Cloudflare record | Origin HTTP/HTTPS accepts Cloudflare ranges only; DNS-only bypasses that required path |
| Postgres on an `internal: true` network | Database unreachable from the `web` network, Caddy, or the host - exposure control by default |
| Loopback-only app publish | Enables private administration without publishing an app port to the internet |
| Private first-run administration | Change default credentials through the tailnet before enabling public tracker routing |
| `umami_db_data` named volume | Analytics data persists across restarts and becomes the first real backup target (Phase 6) |
| Kuma monitor target | Use `/script.js`, since the root deliberately returns 404; execution evidence remains to record |

---

## Next Architecture Layer

**Phase 5 - Monitoring & Alerts**

Umami is a deployed stateful workload. Backup tooling is committed; timer,
restore, site-integration and tracker-monitor evidence remains to record.
The separate public-edge monitoring work in Phase 5 is already live.
[Current Status](../CURRENT-STATUS.md#next-workstream) owns outstanding checks.
