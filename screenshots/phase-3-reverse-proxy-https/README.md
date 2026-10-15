# Phase 3 - Screenshot Evidence 📸

This folder contains redacted validation screenshots for Phase 3: Reverse
Proxy & HTTPS.

Captured during the 2026-08-30 deploy session on `edge-vps` and from
the admin workstation, then redacted (OCR-assisted: IP / hostname / URL
detection with bounding-box redaction, plus a human visual pass).

---

## Screenshot Index

| # | Evidence | File | Purpose |
|---|---|---|---|
| 01 | `docker compose ps` | [01-docker-compose-ps.png](01-docker-compose-ps.png) | Caddy + Uptime Kuma running; only 80/443/443-udp published |
| 02 | Certificate issuance (access log grep) | [02-certificate-issuance-access-log-redacted.png](02-certificate-issuance-access-log-redacted.png) | Let's Encrypt certificate obtained for `status.stayz3ro.dev` |
| 03 | `curl -I http://` | [03-http-308-redirect-redacted.png](03-http-308-redirect-redacted.png) | HTTP returns 308 redirect to HTTPS |
| 04 | `curl -Iv https://` | [04-valid-certificate-chain-redacted.png](04-valid-certificate-chain-redacted.png) | Valid Let's Encrypt certificate chain |
| 05 | Browser padlock | [05-browser-padlock-uptime-kuma.png](05-browser-padlock-uptime-kuma.png) | Public HTTPS on `status.stayz3ro.dev`, Uptime Kuma loaded |
| 07 | Response headers | [07-security-headers-redacted.png](07-security-headers-redacted.png) | Security headers present (HSTS, Referrer-Policy) |
| 08 | `access.log` | [08-json-access-log-redacted.png](08-json-access-log-redacted.png) | Structured JSON logging active |
| 09 | Backend port probe | [09-backend-ports-not-public-redacted.png](09-backend-ports-not-public-redacted.png) | App ports (3000/3001) not reachable publicly |
| 10 | Cloudflare zone (bonus) | [10-cloudflare-dns-zone-fix.png](10-cloudflare-dns-zone-fix.png) | The live Cloudflare zone pre-fix: only the blog CNAMEs - where the `status` A record then had to be added |

Note on numbering: the original checklist's item 06 (`www` -> apex redirect)
was **not applicable** by deploy time - the apex/`www` moved to Cloudflare
Pages before Phase 3 deployed, and this VPS never serves them (see the
Phase 3 CHANGELOG entry). Item 10 was added after the fact: it documents
the DNS zone mismatch root cause found during the deploy.

---

## Redaction Notice

Sensitive values are redacted before committing screenshots.

Redacted or excluded items include:

- Public IPv4 address
- Public IPv6 address
- Tailscale IP
- Admin workstation hostname
- ACME / account email
- ACME order URLs (contain the account ID)
- Let's Encrypt validation remote addresses (redacted by default)
- SSH host fingerprint
- Provider account data

---

## Related Documentation

| Document | Link |
|---|---|
| Phase 3 Overview | [overview.md](../../docs/phase-3-reverse-proxy-https/overview.md) |
| Phase 3 Step-by-Step Guide | [step-by-step.md](../../docs/phase-3-reverse-proxy-https/step-by-step.md) |
| Phase 3 Validation Evidence | [validation.md](../../docs/phase-3-reverse-proxy-https/validation.md) |
