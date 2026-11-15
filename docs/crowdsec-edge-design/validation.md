# CrowdSec on the public edge: validation record

Empty until the owner runs the stages in [step-by-step.md](step-by-step.md).
Record results only, never addresses, keys or raw log lines.

## Stage 0

| Check | Result | Date |
|---|---|---|
| Caddy version (v2.7.3 or later) | not run | |
| `/var/log/auth.log` present, rsyslog active | not run | |
| Loopback 8080 free | not run | |
| Host memory and Docker disk free | not run | |
| SSH from off the tailnet (timeout or connect) | not run | |
| `DOCKER-USER` rule count saved | not run | |

## Stage 1

| Check | Result | Date |
|---|---|---|
| Caddy validate and restart | not run | |
| `client_ip` is the visitor, `remote_ip` is Cloudflare | not run | |
| Admin names still 403 off the tailnet | not run | |
| `cscli lapi status` | not run | |
| Acquisition: both files read and parsed | not run | |
| `cdn-whitelist` enabled, global simulation enabled, no bouncers | not run | |
| Allowlists `edge-owner` and `edge-cdn` populated | not run | |
| Memory at start (MiB) | not run | |
| Memory peak over the week (MiB) | not run | |
| Disk used by the image and volumes | not run | |
| Alerts from Cloudflare, tailnet or owner sources (must be zero) | not run | |
| False positives noted by scenario | not run | |

## Stage 2a

| Check | Result | Date |
|---|---|---|
| `crowdsec` module present in the custom build | not run | |
| Bouncer `caddy` pulling | not run | |
| Test address 403, then 200 after delete | not run | |
| Monitors green, admin gate unchanged | not run | |

## Stage 2b (only if SSH is public)

| Check | Result | Date |
|---|---|---|
| Firewall bouncer active, registered | not run | |
| `DOCKER-USER` unchanged | not run | |
| Test address blocked on 22, then allowed | not run | |
