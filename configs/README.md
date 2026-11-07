# Config Examples ⚙️

This folder stores sanitized configuration examples used throughout the VPS Cloud Infrastructure Lab.

These files are documentation artifacts, not live production secrets.

---

## Config Index

| Area | File | Purpose |
|---|---|---|
| SSH | [sshd_config.example](ssh/sshd_config.example) | SSH hardening reference |
| UFW | [ufw-rules.example](ufw/ufw-rules.example) | Firewall baseline reference |
| Fail2Ban | [jail.local.example](fail2ban/jail.local.example) | SSH brute-force protection example |
| Reverse Proxy | [Caddy Config](caddy/) | Caddyfile + compose stack, automatic HTTPS (Phase 3) |
| Analytics | [Umami Config](umami/) | Umami + PostgreSQL compose stack, env template (Phase 4) |
| Notifications | [ntfy Config](ntfy/) | ntfy compose stack and server config |
| Docker | [Docker Config Notes](docker/) | Future Docker Compose examples |

---

## Security Rules

Do not commit:

- SSH private keys
- Real `.env` files
- API keys
- Database passwords
- Provider credentials
- Tailscale auth keys
- Live production secrets
- Unredacted configuration exports

Use `.example` files for documentation.

---

## Current Phase

Phase 1 includes sanitized examples for:

- SSH hardening
- UFW firewall baseline
- Fail2Ban SSH jail

Future phases will add examples for:

- Reverse proxy
- HTTPS routing
- Docker Compose services
- Monitoring
- Backups
