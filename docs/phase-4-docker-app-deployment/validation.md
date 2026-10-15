# Phase 4 - Validation Evidence 📸

![Status](https://img.shields.io/badge/status-deployment%20recorded-success)
![App](https://img.shields.io/badge/app-Umami-success)
![Domain](https://img.shields.io/badge/domain-a.chrisalorenzo.com-purple)

## Recorded Deployment

[CHANGELOG.md](../../CHANGELOG.md#2026-10-14-umami-deployed-public-record-proxied)
records Umami 3.4.0 and PostgreSQL 16 running behind Caddy on 2026-10-14,
tracker paths only on the public host, tailnet-only administration, and
certificate issuance after switching the public record to the Cloudflare
proxy. Origin HTTP/HTTPS accepts Cloudflare ranges only.

The tables below describe the current contract from
[the Umami configuration](../../configs/umami/README.md) and
[deployment guide](step-by-step.md). A committed configuration or procedure
is not execution evidence. Checks beyond the deployment record remain open
until their results are recorded.

## Validation Summary

| Area | Expected result | Evidence status |
|---|---|---|
| App and database | Umami 3.4.0 and PostgreSQL 16 running | Recorded 2026-10-14 |
| App networks and ports | `web` plus internal database network; loopback-only port 3000 for administration | Configured in compose; external probe result not recorded here |
| Database exposure | Internal-only network; no published database port | Configured in compose; external probe result not recorded here |
| Admin access | Tailscale Serve on 8444 reaches the loopback-backed listener | Tailnet-only administration recorded; sign-in check not recorded here |
| Admin credentials | Defaults replaced over the private path before public routing | Execution evidence not recorded here |
| DNS record | `a.chrisalorenzo.com` proxied in Cloudflare; public DNS returns edge addresses | Proxy correction recorded 2026-10-14 |
| Certificate | Valid HTTPS certificate for the tracker host | Issuance recorded 2026-10-14 |
| Tracker script | `/script.js` returns 200 with JavaScript content type | Public tracker contract recorded; response capture not included |
| Collection endpoint | `/api/send` accepts a valid site event | Public tracker contract recorded; event result not included |
| Public administration | Root, `/login` and `/api/websites` return 404 | Restricted public contract recorded; response capture not included |
| Security headers | HSTS, nosniff, DENY and Referrer-Policy on public responses | Expected from Caddy policy; response capture not included |
| Kuma monitor | `https://a.chrisalorenzo.com/script.js` is Up; root is deliberately 404 | Execution evidence not recorded here |
| Site embeds | Intended sites send events; previews outside `data-domains` do not | Execution evidence not recorded here |
| Database backups | Timer produces a dump and matching checksum; restore listing succeeds | Tooling committed; host execution evidence not recorded here |

## Evidence Still to Capture

- Stack health and loopback-only administration mapping
- Private sign-in after changing the initial credentials
- Cloudflare proxied DNS record and successful HTTPS tracker requests
- Public fallback 404 responses and inaccessible direct backend ports
- Valid site event visible in Umami
- Kuma tracker monitor and notification attachment
- Backup timer, checksum verification and restore check

No Phase 4 deployment screenshots are included yet. Add reviewed evidence
under `screenshots/phase-4-docker-app-deployment/` when available; retain the
recorded deployment date rather than treating missing screenshots as an
unexecuted deployment.

## Redaction Rules

Cover sensitive values with opaque boxes before publishing screenshots.
Exclude public origin addresses, tailnet addresses, credentials, account data,
SSH fingerprints and personal device identifiers. Keep website identifiers
out of screenshots unless the example deliberately needs a public identifier.

## Validation Result

Deployment and the DNS/certificate correction are recorded. Monitoring,
site integration, detailed response captures, backup execution and screenshots
remain unverified in this repository. [Current Status](../../CURRENT-STATUS.md#next-workstream)
is the canonical list of remaining work.
