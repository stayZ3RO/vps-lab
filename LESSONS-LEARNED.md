# Lessons Learned 🧠

![Status](https://img.shields.io/badge/status-active-brightgreen)
![Phase 1](https://img.shields.io/badge/phase_1-complete-success)
![Phase 2](https://img.shields.io/badge/phase_2-complete-success)
![Phase 3](https://img.shields.io/badge/phase_3-complete-success)
![Next](https://img.shields.io/badge/next-Docker%20App%20Deployment-blue)

This file documents operational lessons, troubleshooting notes, and infrastructure design decisions from the VPS Cloud Infrastructure Lab.

---

## Current Project Takeaway

The first two phases established the foundation for a production-style public VPS environment:

| Phase | Outcome |
|---|---|
| Phase 1 - VPS Baseline & Security Hardening | Built a secure Linux server baseline |
| Phase 2 - Domain DNS & Public Routing | Connected `stayz3ro.dev` and restricted SSH to Tailscale |
| Phase 3 - Reverse Proxy & HTTPS | Deployed Caddy + Uptime Kuma, found and fixed a DNS zone mismatch, closed a race-condition risk before going public |

The project is now ready for:

**Phase 4 - Docker App Deployment**

---

# Phase 1 - VPS Baseline & Security Hardening

## Secure the Server Before Hosting Anything

The first priority with a public VPS is not application deployment.

The first priority is:

- Access control
- Patch management
- SSH hardening
- Firewall rules
- Brute-force protection
- Listening port validation
- Documentation

Before adding Docker apps, domains, reverse proxy rules, or dashboards, the server needs a secure baseline.

This phase established that foundation.

---

## SSH Hardening Requires a Safe Workflow

SSH changes can lock you out if applied incorrectly.

The safe workflow is:

1. Keep the existing SSH session open
2. Validate the SSH config
3. Reload SSH instead of blindly restarting
4. Open a second terminal
5. Test login from the second terminal
6. Only then close the original session

Useful validation command:

    sudo sshd -t

If there is no output, the SSH configuration syntax is valid.

---

## Disable Risky Access After Validating Safe Access

Disabling root login and password login is good practice, but only after confirming key-based access works.

The final SSH posture for Phase 1:

| Setting | Value |
|---|---|
| Root SSH login | Disabled |
| Password SSH login | Disabled |
| Public key authentication | Enabled |
| Non-root sudo user | Enabled |

This reduced the risk of brute-force access and removed direct root login from the public internet.

---

## Hostname Resolution Matters

After changing the hostname, the server should also have a matching local hosts entry.

Without that, sudo can show a warning like:

    sudo: unable to resolve host edge-vps

The fix was to ensure the hostname was reflected in `/etc/hosts`.

This was a useful reminder that clean Linux administration includes both visible hostname configuration and local name resolution.

---

## Public Exposure Should Start Small

A new VPS should not expose application ports directly.

For the baseline phase, only these public services were expected:

| Port | Purpose |
|---|---|
| SSH | Administrative access |
| HTTP | Web traffic and certificate validation |
| HTTPS | Secure public services |

Ports for applications, databases, Portainer, monitoring dashboards, and internal tools should not be directly exposed.

Those services should eventually sit behind a reverse proxy, Tailscale, or private network access.

---

## UFW Provides a Simple Baseline Firewall

UFW gives a straightforward host-level firewall baseline.

The initial policy was:

| Direction | Policy |
|---|---|
| Incoming | Deny by default |
| Outgoing | Allow by default |

Allowed public traffic during Phase 1:

- SSH
- HTTP
- HTTPS

This created a small and understandable exposure model before the VPS hosted public workloads.

---

## Fail2Ban Adds Useful SSH Protection

Fail2Ban does not replace SSH key authentication or firewalling, but it adds another useful layer.

For Phase 1, Fail2Ban was configured to monitor SSH authentication attempts and temporarily ban repeated failures.

This is especially useful on a public VPS where automated SSH scanning is expected.

---

## Tailscale Is Useful for Private Administration

Tailscale gives the VPS a private administrative access path.

This is useful for future services that should not be public, such as:

- Portainer
- Internal dashboards
- Monitoring tools
- Admin-only apps
- Private service checks

The main design decision:

**Public services should use HTTPS through a reverse proxy. Admin services should stay private whenever possible.**

---

# Phase 2 - Domain DNS & Public Routing

## DNS Should Be Treated as Infrastructure

Phase 2 showed that DNS is not just a domain setup step. It is part of the infrastructure design.

The domain records define how users, services, and future applications will reach the VPS.

Configured records:

| Record | Purpose |
|---|---|
| `stayz3ro.dev` | Root domain |
| `www.stayz3ro.dev` | Web alias |
| `apps.stayz3ro.dev` | Future public apps |
| `status.stayz3ro.dev` | Future status page |
| `api.stayz3ro.dev` | Future API services |

The lesson:

**DNS should be planned before deploying the reverse proxy.**

---

## Remove Default Parking Records First

Porkbun default parking records needed to be removed before the domain could point cleanly to the Netcup VPS.

Removed records:

    ALIAS   stayz3ro.dev       pixie.porkbun.com
    CNAME   *.stayz3ro.dev     pixie.porkbun.com

Keeping wildcard or parking records would make future validation confusing.

The lesson:

**Clean DNS records reduce troubleshooting noise.**

---

## Validate DNS Locally and Publicly

DNS was validated from the local workstation and from public resolvers.

Useful validation commands:

    dig +short stayz3ro.dev
    dig +short www.stayz3ro.dev
    dig +short apps.stayz3ro.dev
    dig +short status.stayz3ro.dev
    dig +short api.stayz3ro.dev

Public resolver checks:

    dig @1.1.1.1 +short stayz3ro.dev
    dig @8.8.8.8 +short stayz3ro.dev

The lesson:

**A DNS record is not complete until resolution is verified from more than one perspective.**

---

## Public DNS Does Not Mean Public Administration

Connecting a domain to a public VPS does not mean administrative services should be public.

During Phase 2, SSH was moved from public exposure to Tailscale-only access.

Final access model:

| Access Type | Result |
|---|---|
| SSH to public VPS IP | Blocked |
| SSH to Tailscale IP | Allowed |
| HTTP | Public for future reverse proxy |
| HTTPS | Public for future reverse proxy |
| Direct app ports | Blocked |
| Admin dashboards | Not publicly exposed |

The lesson:

**Public service traffic and administrative access should be separate paths.**

---

## Tailscale-Only SSH Better Matches Enterprise Access Patterns

Restricting SSH to Tailscale created a more enterprise-style management plane.

The model is similar to:

    Admin workstation
      ↓
    VPN / private access layer
      ↓
    Server management interface

In this lab:

    Admin workstation
      ↓
    Tailscale
      ↓
    Netcup VPS
      ↓
    SSH

The lesson:

**Administrative access should go through a private management path whenever possible.**

---

## Firewall Rules Should Match Actual Listening Services

During Phase 2, SSH was confirmed to be listening on port `22`.

That made unused `2222` firewall rules unnecessary.

The final firewall posture should be simple and intentional:

| Rule | Purpose |
|---|---|
| `22/tcp on tailscale0` | Private SSH administration |
| `80/tcp` | Public HTTP for future reverse proxy |
| `443/tcp` | Public HTTPS for future reverse proxy |

The lesson:

**Firewall rules should be reviewed after each change so stale rules do not remain.**

---

## Confirm What a Domain Serves Before Building For It

Phase 3 was originally built to serve the `stayz3ro.dev` apex directly, a
static landing page with TLS terminated on this VPS. Between building that
and deploying it, the apex was claimed by a separate project (a blog, on
Cloudflare Pages) that had been decided independently, in a different
repo, around the same time.

The rework wasn't large (retarget the Caddyfile, compose, and docs from
apex/`www` to a subdomain), but it was avoidable. The two decisions, "the
VPS serves the apex" and "the blog serves the apex", were made in
different places without either one checking the other first.

**The lesson: before building infrastructure for a specific domain or
hostname, confirm nothing else already owns it or is about to.** A
one-line check (grep the other repos, or just ask) is cheaper than a
rebuild.

---

# Phase 3 - Reverse Proxy & HTTPS

## A DNS Panel Is Not Authoritative Just Because You Can Edit Records In It

Deploying Caddy failed with a real ACME error: Let's Encrypt got `NXDOMAIN`
looking up `status.stayz3ro.dev`, even though the record had just been
added in Porkbun's DNS panel and Porkbun's own nameservers
(`*.ns.porkbun.com`) returned the correct value when queried directly.

The first theory was DNS negative caching, since the SOA's negative-cache
TTL was 1800s and the record had genuinely been missing minutes earlier.
Plausible, and partially right, but wrong as the root cause. After far
longer than any TTL could explain, a check against real, independent
resolvers (DNS-over-HTTPS, which bypasses any local resolver or VPN DNS
override entirely) kept returning a real, authoritative `NXDOMAIN`, with
the `aa` (authoritative answer) flag set. That flag matters. It means the
answer came from a server that considers itself the source of truth for
the zone, not a cache.

Querying the domain's actual registry-delegated nameservers (found via
`dig NS stayz3ro.dev` through DoH, bypassing every local resolver) showed
`stayz3ro.dev`'s real nameservers are Cloudflare's
(`felipe.ns.cloudflare.com` / `melissa.ns.cloudflare.com`), not Porkbun's.
The domain's nameservers had been switched to Cloudflare when the blog
moved to Cloudflare Pages (a separate decision, in a separate repo, around
the same time. See "Confirm What a Domain Serves Before Building For It"
below, the same root pattern twice). Porkbun's own DNS hosting still
accepted edits through its panel, but was never consulted by the live
internet again after that switch. Every edit made there all night was
going to a zone nobody was reading.

The actual fix: add the record in Cloudflare's dashboard, where the zone
that's actually delegated lives.

The lesson:

**Before troubleshooting DNS propagation, confirm you're editing the zone
that's actually delegated at the registry, not just a panel that lets you
edit records.** `dig NS <domain>` against a resolver that bypasses local
overrides (DoH, or a resolver you don't control) tells you the truth in one
query. An `aa` (authoritative answer) flag on an unexpected result is the
signal to stop trusting your first theory and check the delegation itself.

---

## Don't Trust Local DNS Checks Without Ruling Out Your Own Resolver

A second, compounding trap during the same investigation: the workstation
used to run every `dig` command had Tailscale's MagicDNS enabled, which
overrides the system resolver (`/etc/resolv.conf` pointed at
`100.100.100.100`). Tailscale can transparently intercept port-53 traffic
system-wide, including explicit `dig @8.8.8.8` queries. Even "checking
against a different public resolver" can silently still be answered by the
same local proxy.

DNS-over-HTTPS (plain HTTPS to `https://dns.google/resolve` or
`https://1.1.1.1/dns-query`) sidesteps this entirely, since it never uses
port 53 and can't be intercepted the same way.

The lesson:

**When a machine runs a VPN or MagicDNS-style tool, "specifying a different
DNS server" in a CLI tool is not enough to guarantee an independent
answer. Verify the resolution path itself (`resolv.conf`, `tailscale dns
status`), or use DoH to bypass it entirely.**

---

## A Fresh Public Service Needs Its Admin Account Secured Before It's Discoverable

Uptime Kuma's first-run setup (create the admin account) is unauthenticated
by design. Whoever loads the page first gets to claim it. The moment
Let's Encrypt issues a real certificate for a hostname, that hostname
becomes public in Certificate Transparency logs (crt.sh and similar),
which are continuously scanned by bots. That creates a real window between
"certificate issued" and "admin account claimed" where a stranger could
win the race.

The fix didn't require exposing anything early or rushing the deploy:
Docker's bridge networking means the VPS host can always reach a
container's internal IP directly, even when no port is published to the
host or the internet. An SSH local-port-forward (`ssh -L
3001:<container_ip>:3001`) tunneled straight to Uptime Kuma's internal
Docker network address, completely bypassing the public hostname, Caddy,
and the certificate. Setup was completed over that private tunnel before
DNS had even finished propagating, closing the race window before it could
open.

The lesson:

**For any self-hosted service with unauthenticated first-run setup, claim
the admin account over a private path (SSH tunnel, VPN, `docker exec`)
before the service is reachable by its public hostname. Don't rely on
being fast enough to win a race against Certificate Transparency log
scanners.**

---

## A Runbook's Assumptions Can Go Stale Against the Actual Config

The Phase 3 runbook's Step 6 (confirm certificate issuance) called for
`docker compose logs caddy`. That returned nothing, not an error, just
silence, because this Caddyfile explicitly redirects the default logger
from stderr to a file (`/var/log/caddy/access.log`, bind-mounted to
`configs/caddy/logs/access.log`), a deliberate choice for structured JSON
logging. `docker compose logs` only captures a container's stdout/stderr,
so it will never see anything the app has redirected away from those
streams.

The lesson:

**A runbook step that assumes a default (stdout logging) needs to be
checked against what the actual config does, not re-run harder when it
returns nothing.** The fix here was checking the log file directly
(`sudo grep -i certificate logs/access.log`), which is also where Step 9's
access-log evidence lives. Both steps' real evidence sits in the same
file, not in `docker compose logs`.

## UFW Does Not See Docker's Published Ports

A public-exposure review flagged two of this VPS's public DNS records
(`status`, `ntfy`) as resolving directly to the VPS's own IP instead of
through the Cloudflare proxy, and flagged that the origin IP's reverse DNS
revealed the hosting provider by name. The fix looked simple: proxy both
records in Cloudflare, then restrict the host firewall (UFW) to allow
80/443 only from Cloudflare's published IP ranges, so a client that knew
the real IP couldn't reach the service directly.

UFW's own rule table updated correctly and showed only the Cloudflare
ranges. Direct-IP access still worked anyway, completely unaffected.

The cause: Caddy publishes 80/443 through Docker (`-p 80:80 -p 443:443`
style publishing, bound to `0.0.0.0`). Docker manages its own `iptables`
rules for published container ports, in a `DOCKER-USER` chain that the
kernel evaluates before UFW's own `INPUT` chain gets a say for forwarded
container traffic. UFW's rules were never wrong; they were simply never
in the path. This is a known interaction, not a bug in either tool: UFW
filters host-destined traffic, Docker's own forwarding rules handle
traffic destined for a published container port, and the two don't talk
to each other unless something explicitly bridges them.

The real fix lives in the `DOCKER-USER` chain itself, which Docker
reserves specifically for operator-added rules that run ahead of its own:
an `ESTABLISHED,RELATED` accept, an explicit accept for each Cloudflare
IP range on 80/443 (tcp) and 443 (udp, for HTTP/3), and a final deny for
everything else on those ports. `iptables-persistent` was not installed,
so without it this rule set would have silently reverted on the next
reboot; it was installed and the rules saved before calling this done.
Verification that actually proves the fix: not reading the rule table,
but a live request forced at the raw IP from outside, confirming it times
out while the normal domain keeps working.

---

## The Watcher Shares the VPS Failure Domain

Kuma checks public sites, DNS, and HTTPS, but it runs on the same VPS as Caddy
and ntfy. A full VPS outage stops the watcher and its local push path, so none
of those seven monitors can originate an alert. The synthetic DOWN/UP test
proved the Discord path while Kuma was running; it did not prove alerting for
a failed VPS. An independent offsite check remains planned for that case.

---

## Main Takeaway

Phase 1 made the VPS safe to manage.

Phase 2 made the VPS reachable through a real domain while keeping administration private.

Phase 3 made a real service publicly reachable over HTTPS. It also
surfaced that "public" and "publicly discoverable" arrive on different
timelines (DNS/cert issuance vs. Certificate Transparency logs), and that
troubleshooting DNS requires confirming *which* DNS is actually live before
trusting any answer from it.

Phase 5 made the public edge observable and added two alert paths, while
leaving full-VPS failure detection to an independent offsite check.

The important lesson:

**Public infrastructure should expose services intentionally, but management access should stay private. And before you trust an authoritative-looking DNS answer, confirm it actually came from the zone the registry delegates to.**
