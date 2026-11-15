# CrowdSec on the public edge

Status: design draft, 2026-11-15. Not deployed and not scheduled.

CrowdSec reads the Caddy access log and the sshd log on the edge VPS:

- **Stage 1** is detect only for one week.
- **Stage 2** adds blocking. Web traffic is blocked in Caddy, using the
  real client address from `CF-Connecting-IP`. The host firewall bouncer
  is added only if SSH turns out to be reachable on the public address.

| File | Purpose |
|---|---|
| [overview.md](overview.md) | Current layout from this repo, upstream facts with sources, the CDN reasoning, estimates, open decisions |
| [step-by-step.md](step-by-step.md) | Owner-run Stage 0, 1, 2a and 2b with commands, pass lines and rollback |
| [validation.md](validation.md) | Empty result tables for each stage |
| [configs/crowdsec/](../../configs/crowdsec/) | Draft compose files, acquisition files, allowlist template and Caddy examples |
