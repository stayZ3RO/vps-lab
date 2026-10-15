# Phase 5 - Monitoring & Alerts 🔔

![Status](https://img.shields.io/badge/status-public%20edge%20live-brightgreen)
![Service](https://img.shields.io/badge/service-Uptime%20Kuma-orange)
![Scope](https://img.shields.io/badge/scope-public%20edge-purple)

## Phase Summary

Phase 5 makes the public edge observable. Since 2026-09-28, Kuma on
`edge-vps` has watched public sites, HTTPS, and public DNS, with
certificate-expiry notices and alerts through Discord and self-hosted ntfy
(`ntfy.chrisalorenzo.com`). The public page is now at
`https://status.chrisalorenzo.com/status/main`; Kuma administration is
tailnet-only through `tailscale serve` on port 8443. Public admin paths return
404.

The five display-name changes and retained `id` tags are recorded in
[Current Status](../../CURRENT-STATUS.md#monitoring-and-alerts). Verification
of the Blog, status-page and HTTPS Edge targets against the new hosts, plus a
`blog-redirect` monitor for the old blog host's 301, remain pending. Do not
count that redirect monitor as live yet.

The design rule for the phase is narrow: monitor only what is public, from
outside the LAN. Nothing in this phase monitors a private or admin endpoint,
and nothing opens a path from the VPS into the home LAN.

---

## What This Phase Demonstrates

| Area | Demonstrated Skill |
|---|---|
| External monitoring | Public endpoints checked by Kuma on the VPS; an offsite check is still planned |
| Alert design | Severity expressed through provider choice, retries, and resend intervals |
| Secret handling | Provider credentials entered only in the service UI, never in Git |
| Failure-domain reasoning | Separating external public-edge alerts from internal infrastructure alerts |
| Validation | A real, reversible DOWN/UP test instead of trusting a test button |

---

## Documentation

| Page | Description |
|---|---|
| [Alert Wiring Execution Packet](alert-wiring-execution-packet.md) | Executed 2026-09-28; records the monitor and Discord test |
| [Self-hosted ntfy Execution Packet](ntfy-self-hosted-execution-packet.md) | Executed 2026-09-28; records the live ntfy service and provider switch |

---

## Scope

In scope:

- ntfy and Discord notification providers in Uptime Kuma
- HTTP(s), TCP port, and DNS monitors for public hostnames
- TLS certificate expiry warning on the public HTTP monitors
- a reversible DOWN/UP notification test
- a written record of the final wiring, without secrets

Out of scope:

- any private, admin, or LAN endpoint monitor
- an inbound path from the VPS into the LAN
- heartbeat (Push) monitors and the Caddy access-log prerequisite
- changes to the LAN-side monitoring and alerting stack
- an independent offsite dead-man monitor

The public status page was added with the 2026-10-04 domain move, after the
initial 2026-09-28 alert-wiring work.

---

## Completion Criteria

| Requirement | Status |
|---|---:|
| Execution packet written and reviewed read-only | ✅ Complete |
| ntfy provider configured and test received | ✅ Complete |
| Discord provider configured and test received | ✅ Complete |
| Public-edge monitors created | ✅ Complete |
| Certificate expiry warning enabled | ✅ Complete |
| Real DOWN and UP notification proven | ✅ Complete |
| Final wiring recorded without secrets | ✅ Complete |
| Offsite dead-man monitor designed | ⏳ Separate packet |

The live wiring was done on 2026-09-28 and is recorded in the packet and
`CURRENT-STATUS.md`.
