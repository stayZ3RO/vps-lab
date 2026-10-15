# Phase 4 - Docker App Deployment 🐳

![Status](https://img.shields.io/badge/status-deployed%20October%2014-success)
![Phase](https://img.shields.io/badge/phase-4-blue)
![App](https://img.shields.io/badge/app-Umami-success)
![Proxy](https://img.shields.io/badge/proxy-behind%20Caddy-success)

## Phase Summary

Umami 3.4.0 and PostgreSQL 16 were deployed on 2026-10-14. The public tracker
at `a.chrisalorenzo.com` serves `/script.js` and `/api/send` only; other public
paths return 404. Administration uses loopback port 3000 through Tailscale
Serve on port 8444. PostgreSQL remains on an internal-only network with no
published port.

The public DNS record is proxied through Cloudflare because origin
HTTP/HTTPS accepts Cloudflare ranges only. The deployment record also notes
the certificate issued after correcting the earlier DNS-only plan.
[Current Status](../../CURRENT-STATUS.md) is canonical for present state and
outstanding work; [CHANGELOG.md](../../CHANGELOG.md#2026-10-14-umami-deployed-public-record-proxied)
records the deployment.

## What This Phase Demonstrates

| Area | Demonstrated Skill |
|---|---|
| App deployment | Application and PostgreSQL services managed with Docker Compose |
| Exposure control | Public tracker paths only; loopback-backed administration through the tailnet |
| Configuration management | Committed `.env.example`; private host environment file kept out of git |
| DNS operations | Proxied record in the authoritative Cloudflare zone |
| Security sequencing | Private first-run administration before enabling the public route |
| Recovery preparation | Database dump script, checksum verification and systemd timer provided |

## Documentation

| Page | Purpose |
|---|---|
| [Overview](overview.md) | Current design and historical candidate comparison |
| [Step-by-Step Guide](step-by-step.md) | Current deployment and rollback procedure |
| [Validation Evidence](validation.md) | Recorded results and checks still requiring evidence |
| [Architecture Diagram](../../diagrams/phase-4-docker-app-deployment.md) | Public tracker, private administration and database boundaries |
| [Umami Config](../../configs/umami/) | Compose stack, environment example and backup tooling |
| [Archived re-scope](../archive/umami-rescope-DRAFT-2026-10-12.md) | Superseded proposal, retained as decision history |

## Completion Criteria

| Requirement | Recorded status |
|---|---|
| App chosen and justified | Complete; original comparison in [overview.md](overview.md) |
| Compose, environment example and deployment guide committed | Complete |
| Umami and PostgreSQL deployed | Recorded 2026-10-14 |
| Proxied DNS and certificate correction | Recorded 2026-10-14 |
| Tracker paths public; administration tailnet-only | Recorded deployment contract |
| Admin credential change and external backend-port checks | Execution evidence not recorded here |
| Kuma tracker monitor and site embeds | Execution evidence not recorded here |
| Backup timer installation and restore check | Tooling provided; execution evidence not recorded here |
| Redacted deployment screenshots | Not yet included |

Phase 5 public-edge monitoring is already live. Its existing monitors do not
prove that the new Umami monitor or an independent offsite check is complete.
