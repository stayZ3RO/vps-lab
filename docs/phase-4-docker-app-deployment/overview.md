# Phase 4 - Docker App Deployment 🐳

---

## Quick Navigation

| Page | Link |
|---|---|
| Phase 4 Home | [README](README.md) |
| Overview | [overview.md](overview.md) |
| Step-by-Step Guide | To be written after app selection |
| Validation Evidence | To be written after app selection |

---

![Status](https://img.shields.io/badge/status-app%20chosen-yellow)
![Phase](https://img.shields.io/badge/phase-4-blue)
![App](https://img.shields.io/badge/app-Umami-success)
![Domain](https://img.shields.io/badge/domain-stayz3ro.dev-purple)

## Overview

Phase 3 left the VPS with a working pattern: Caddy terminates TLS on 80/443,
Uptime Kuma runs on the internal `web` network, backend ports are never
published, and `apps` / `api` subdomain routes sit staged in the `Caddyfile`.
Phase 4 uses that pattern for its intended purpose: deploying the first real
application container.

> **Decision (2026-08-30): Umami (Candidate A) selected**, at
> `analytics.stayz3ro.dev`. This page is the scoping record - candidates,
> tradeoffs, and the reasoning behind the choice - plus the deployment
> pattern the chosen app now follows in
> [step-by-step.md](step-by-step.md).

---

## Objective

Deploy one public Dockerized app that:

- Runs as a multi-container Compose service (application + database)
- Is reached only via Caddy on a subdomain, over HTTPS
- Stores its state in named volumes on internal Docker networks
- Has its configuration documented publicly (`.env.example`) with real
  secrets kept on the VPS only
- Produces a repeatable onboarding runbook. The second app should be faster
  than the first

---

## Why This Phase Matters

Phases 1-3 built a door with nothing behind it except a status page. Phase 4
answers the question the whole lab exists to answer:

> Can this VPS run a real, stateful, publicly reachable service, and recover,
> document, and monitor it like production?

The first stateful service also creates the first real backup target
(Phase 6) and the first real monitored workload (Phase 5), so what gets
deployed here shapes the next two phases.

---

## Selection Criteria

| # | Criterion | Why it matters |
|---|---|---|
| 1 | Real personal value in active use now | An app that gets used generates real operations stories; a demo generates nothing |
| 2 | Portfolio/blog relevance | This lab's stated goals are portfolio and content; the app should feed those tracks |
| 3 | Stateful (database + volumes) | Forces the skills this phase exists to teach: env secrets, data persistence, backup thinking |
| 4 | Fits the VPS | Netcup VPS 1000 G12 class (small, 2 vCore / ~4 GB RAM) alongside Caddy + Uptime Kuma |
| 5 | Public-safe behind auth | No open signup, no public write API without keys, no unauthenticated first-run window |
| 6 | Light operational surprise surface | First stateful deploy should not also be a security-hardening project |

---

## Candidate A - Umami (Privacy-First Web Analytics) 📊

### What It Is

Self-hosted, cookieless, GDPR-friendly web analytics. The self-hosted
answer to Google Analytics. Node.js app with a PostgreSQL backend, official
Docker images, single-tenant by default.

### Deployment Shape

| Item | Value |
|---|---|
| Containers | `umami` + `postgres` (both internal, `web` network) |
| Published ports | None |
| Subdomain | `analytics.stayz3ro.dev` (new record in the **Cloudflare** zone) |
| State | Named volumes for Postgres data |
| Client integration | One `<script>` tag in the Astro blog (separate repo) |
| Resource estimate | ~250-500 MB RAM for app + DB combined |

### Case For

- **Directly serves the two most active goals**: real visitor analytics for
  the blog (apex, Cloudflare Pages) and the portfolio, the exact projects
  being promoted on LinkedIn right now
- First stateful service: a real database to back up (Phase 6 target) and a
  reason to care about uptime beyond a status page (Phase 5)
- "I self-host my own privacy-first analytics" is a strong portfolio and
  blog-post story, and it spans the full stack: Cloudflare Pages front end +
  VPS-hosted data plane
- Cookieless analytics has no consent-banner baggage, a legitimate talking
  point for enterprise-style discussions

### Tradeoffs / Risks

- Requires a new DNS record, in Cloudflare, not Porkbun (the Phase 3 lesson;
  verify with `dig NS` first)
- Same unauthenticated-first-run race as Uptime Kuma → same fix: claim the
  admin account over an SSH tunnel **before** the certificate exists
- The embed script touches the blog repo, a cross-repo change, so coordinate
  it explicitly (the Phase 3 lesson about parallel repos making conflicting
  decisions applies in reverse here: this time the VPS side initiates it)

---

## Candidate B - Shlink (Self-Hosted URL Shortener) 🔗

### What It Is

A mature self-hosted URL shortener with a REST API, visit statistics, and
optional web client. PHP with a PostgreSQL or MySQL backend; official Docker
image.

### Deployment Shape

| Item | Value |
|---|---|
| Containers | `shlink` + `postgres` (both internal, `web` network) |
| Published ports | None |
| Subdomain | Uses both staged routes: `apps.stayz3ro.dev` (web client) + `api.stayz3ro.dev` (REST API) |
| State | Named volumes for Postgres data |
| Client integration | None, standalone |
| Resource estimate | ~200-400 MB RAM |

### Case For

- The only candidate that lights up **both** staged `Caddyfile` routes
  exactly as Phase 3 designed them
- A real **public REST API**, the only candidate that demonstrates
  deliberately exposing an authenticated API surface to the internet
- Branded short links are genuinely useful for blog/LinkedIn promotion, and
  Shlink's click stats are themselves content
- Key-authenticated API + rate-limiting options make it a well-bounded
  first public write surface

### Tradeoffs / Risks

- Honest limitation: `apps.stayz3ro.dev/abc123` is not a *short* link. The
  domain is 11 characters and the staged subdomains are long. A dedicated
  short host (e.g. `s.stayz3ro.dev`) would work but needs a new record
- A public write API is a real abuse surface (spam short-links), needs
  API-key discipline and monitoring from day one
- Two hostnames to route and validate doubles the DNS/Caddy steps of the
  first app deploy

---

## Candidate C - Vikunja (Task / Project Tracker) ✅

### What It Is

Open-source, self-hosted to-do and project management (list, Kanban, Gantt,
labels, teams). Go binary with a PostgreSQL backend. Recommended 2026-08-30
in the private cross-repo coordination notes as the tracker
for the parallel infra/certs/content tracks.

### Deployment Shape

| Item | Value |
|---|---|
| Containers | `vikunja` + `postgres` (both internal, `web` network) |
| Published ports | None |
| Subdomain | `tasks.stayz3ro.dev` public-with-auth (registration disabled), or Tailscale-only |
| State | Named volumes for Postgres data |
| Client integration | None, standalone |
| Resource estimate | ~200-400 MB RAM |

### Case For

- Already recommended on the merits elsewhere, deploying it here closes a
  real, recorded open decision instead of inventing a new one
- Real daily operational value across every active track, which keeps it
  maintained rather than abandoned
- Forces an explicit decision this lab has not yet made: **public-with-auth
  vs Tailscale-only** for a personal tool, a legitimate exercise either way

### Tradeoffs / Risks

- Primarily an internal tool: the weakest "public service" story for the
  portfolio, which is what Phase 4 is nominally about
- Placement conflict: the existing recommendation was "small container now,
  later pushed to a lab node or admin workstation." Putting it on the
  **public** VPS is a different placement decision and should be confirmed
  with you first
- It would front-run a decision owned by the private operations track; if it deploys
  here, that track should ratify the placement

---

## Considered and Deferred

| Option | Why not now |
|---|---|
| Grafana / Prometheus | That is Phase 5's scope; deploying it now empties the next phase |
| Gitea / Forgejo | Git is already anchored on GitHub; self-hosted git adds merge overhead, not value |
| Nextcloud | Too heavy for this VPS class alongside Caddy + Kuma |
| Memos / linkding / FreshRSS | Light and viable, but weak ties to the portfolio/blog goals, the criteria they'd win on don't rank |
| Another static site | Static content belongs on Cloudflare Pages, not on a stateful VPS |

---

## Recommendation

**Deploy Umami (Candidate A). Confirmed 2026-08-30.**

- It is the only candidate that makes the VPS part of the **active portfolio
  and blog pipeline** rather than adjacent to it, analytics for the exact
  properties being promoted right now
- It is stateful (Postgres), which is the skill this phase exists to teach,
  and it creates the concrete backup target Phase 6 needs
- Its abuse surface is minimal: single authenticated user, no signup, no
  public write API, the right size for a first stateful public deploy
- It fits the VPS budget comfortably

**Shlink is the strong second** if the goal shifts to demonstrating public API
management, and it remains a natural Phase 5-era addition, since its click
stats pair well with monitoring. **Vikunja is viable but mis-sequenced here**:
its placement decision belongs to the private operations track, and it can be
deployed behind Caddy later without losing anything.

---

## Deployment Pattern (Common to All Candidates)

Whichever app wins, Phase 4 follows the same shape. This section is the plan;
the concrete runbook (`step-by-step.md`) gets written after selection.

### 1. Compose Layout

    configs/<app>/
      docker-compose.yml    # app + postgres, joins `web` network, no published ports
      .env.example          # committed, public-safe
      .env                  # gitignored, VPS-only
      README.md             # what it is, how it runs

The app's compose file joins the existing `web` network so Caddy can reach
it by container name; nothing else changes in the proxy stack except the
Caddyfile.

### 2. DNS (Cloudflare, not Porkbun)

Add the chosen subdomain's record in **Cloudflare's dashboard**, the zone
the registry actually delegates to. Verify the delegation first:

    dig NS stayz3ro.dev          # must show Cloudflare nameservers
    # add record in Cloudflare, then:
    dig +short analytics.stayz3ro.dev   # (or the chosen host)

### 3. Caddy Route

Add or uncomment the site block, importing `security_headers`:

    analytics.{$SITE_DOMAIN} {
        import security_headers
        reverse_proxy umami:3000
    }

Validate and reload without downtime:

    # validate, same throwaway-container pattern as Phase 3
    docker run --rm -v "$PWD/Caddyfile:/etc/caddy/Caddyfile:ro" \
      -e SITE_DOMAIN -e ACME_EMAIL \
      caddy:2-alpine caddy validate --config /etc/caddy/Caddyfile
    # then reload the live proxy (Caddyfile is bind-mounted read-only)
    docker exec caddy caddy reload --config /etc/caddy/Caddyfile

### 4. Secure Before Public

If the app has an unauthenticated first-run setup, claim the admin account
over an SSH tunnel to the container's internal Docker network IP, the same
pattern that closed Uptime Kuma's race window. Do this **before** enabling
the route or the DNS record, so Certificate Transparency never advertises
an unclaimed hostname.

### 5. Validate

- `curl -I` on the new host: 308 from HTTP, 200 from HTTPS, security headers
- Certificate issuance confirmed in the access log (not `docker compose
  logs`, Caddy logs to the file)
- Backend and Postgres ports confirmed not reachable on the public IP
- Browser padlock and the app UI loaded
- New hostname added as an Uptime Kuma monitor, then confirmed reporting

### 6. Evidence

Redacted screenshots into `screenshots/phase-4-docker-app-deployment/`,
following the standing redaction rules (public IPs, Tailscale IPs, emails).

---

## Exposure Model After Phase 4

| Surface | Exposure |
|---|---|
| HTTP / HTTPS | Public (unchanged) |
| `status.stayz3ro.dev` (Uptime Kuma) | Public (unchanged) |
| New app subdomain | Public behind Caddy + auth |
| App + database containers | Internal `web` network only, no published ports |
| App state (volumes) | On-host named volumes; backup story is Phase 6 |
| SSH | Tailscale only (unchanged) |
| UFW | No new rules needed, 80/443 already open |

---

## Validation Approach

Phase 4 will be validated with:

- External `curl` checks: redirect, 200, valid chain, security headers
- Backend/DB port probes from outside confirming nothing but 80/443 answers
- Caddy access log entries for the new host (JSON)
- The app performing its purpose end-to-end (e.g. for Umami: the blog's embed
  script producing real visit data)
- An Uptime Kuma monitor on the new hostname going green

Details land in `validation.md` after app selection.

---

## Decision Points

| # | Decision | Status |
|---|---|---|
| 1 | Which app | ✅ Decided: A (Umami) |
| 2 | Subdomain naming | ✅ Decided: new `analytics.stayz3ro.dev` record in the Cloudflare zone |
| 3 | Vikunja placement (only if C won) | Moot (A won) - stays with the private operations track |
| 4 | Second app in this phase? | Scope stays **one app**; a second app would reuse this runbook in a later pass |

---

## Prerequisite (Before Any Deployment)

Capture the 9 outstanding Phase 3 evidence screenshots
(`screenshots/phase-3-reverse-proxy-https/README.md`) while the current
stack is still the only thing running. Phase 4 changes the live deployment;
that evidence window closes when it does.

---

## Related Documentation

| Document | Purpose |
|---|---|
| [Phase 3 docs](../phase-3-reverse-proxy-https/) | The proxy pattern this phase builds on |
| [Caddy Config](../../configs/caddy/) | Caddyfile, compose stack, staged routes |
| [Lessons Learned](../../LESSONS-LEARNED.md) | DNS-zone truth, tunnel-claim pattern, runbook staleness |
| [Roadmap](../../ROADMAP.md) | Phase 4 planned tasks; Phases 5-6 context |

---

## Key Takeaway

The proxy pattern is proven; the app choice decides what the VPS is *for*.
Umami turns the VPS into the data plane for the public sites the lab is
supposed to showcase, and gives the backup and monitoring phases their
first real workload.

> The first stateful service should be one you actually use. Everything
> after it is repetition.
