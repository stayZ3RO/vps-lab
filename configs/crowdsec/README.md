# CrowdSec draft configs

DRAFT, not deployed. Design and owner-run steps:
[docs/crowdsec-edge-design/](../../docs/crowdsec-edge-design/).

| File | Stage | Purpose |
|---|---|---|
| `docker-compose.yml` | 1 | Security Engine, detect only, on the `web` network, no host port |
| `.env.example` | 1 | Host paths and the signal sharing switch; keys are added on the host only |
| `acquis.d/caddy.yaml` | 1 | Caddy JSON access log |
| `acquis.d/sshd.yaml` | 1 | sshd through `/var/log/auth.log` |
| `acquis.d/sshd-journald.yaml.example` | 1 | journald alternative (needs the `-debian` image) |
| `edge-allowlist.yaml.example` | 1 | Parser whitelist template for the tailnet and owner addresses; the filled copy stays on the host |
| `caddy/trusted-proxies.snippet.example` | 1 | Caddy `trusted_proxies` and `client_ip_headers` for the Cloudflare ranges |
| `docker-compose.stage2.yml` | 2a | Registers the Caddy bouncer from a host-only key |
| `caddy/Dockerfile.crowdsec.example` | 2a | Custom Caddy build with the bouncer module |
| `caddy/docker-compose.caddy-bouncer.yml` | 2a | Override for the Caddy stack to use that build |
| `caddy/crowdsec-bouncer.snippet.example` | 2a | Caddyfile additions for the bouncer |
| `docker-compose.lapi-loopback.yml` | 2b | LAPI on host loopback for the firewall bouncer, only if SSH is public |
