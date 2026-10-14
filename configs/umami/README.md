# Umami analytics

The public host is `a.chrisalorenzo.com`. Caddy sends only `/script.js` and
`/api/send` to Umami and returns 404 for other public paths. The dashboard
uses a loopback publish on `127.0.0.1:3000`, exposed to tailnet devices by
Tailscale Serve on port 8444.

PostgreSQL 16 is on the internal `umami_internal` network. The Umami service
also joins the external `web` network so Caddy can reach it. The database has
no published port. Both images use immutable Docker Hub OCI index digests.

## Files

| File | Purpose |
|---|---|
| [docker-compose.yml](docker-compose.yml) | Umami 3.4.0 and PostgreSQL 16 stack |
| [.env.example](.env.example) | Variable names for the private host environment file |
| [backup-umami.sh](backup-umami.sh) | Daily custom-format PostgreSQL dump |
| [umami-backup.service](umami-backup.service) | systemd one-shot backup service |
| [umami-backup.timer](umami-backup.timer) | Daily timer at 03:30 UTC |

Create `.env` from `.env.example` on the host and fill in `POSTGRES_PASSWORD`
and `APP_SECRET`. Keep `.env` out of git. Follow the
[Phase 4 deployment guide](../../docs/phase-4-docker-app-deployment/step-by-step.md)
for startup, tailnet admin setup, backup installation, DNS, and Caddy order.

The initial Umami credentials are `admin` / `umami`. Change the password over
the tailnet before adding the public DNS record or enabling the Caddy route.
The public `a.<domain>` record must be **proxied** through Cloudflare (orange
cloud): the edge firewall accepts 80/443 from Cloudflare ranges only, so a
DNS-only record leaves both the ACME challenge and every visitor timing out.
With the proxy in front, the visitor address arrives in `CF-Connecting-IP`,
which `CLIENT_IP_HEADER` in the compose file tells Umami to use.
The backup timer writes verified dumps and SHA-256 sidecars to
`/opt/stayz3ro/backups/umami` and keeps 14 days of local files. Include that
directory in the offsite backup plan when available.
