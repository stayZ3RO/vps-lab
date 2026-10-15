# Architecture Notes

The [architecture overview](../../diagrams/architecture.md) is the canonical
current diagram. [Current Status](../../CURRENT-STATUS.md) records the live
service contract and remaining work; [ROADMAP.md](../../ROADMAP.md) records
planned backup and secondary-node work.

The earlier Phase 1 target scaffold has been folded into those files. Public
services use Cloudflare-proxied HTTPS; origin HTTP/HTTPS accepts Cloudflare
ranges only. SSH and loopback-backed Kuma and Umami administration use the
tailnet. Umami exposes tracker paths only, and PostgreSQL has no published port.
