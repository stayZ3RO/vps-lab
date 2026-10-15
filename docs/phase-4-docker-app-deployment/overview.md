# Phase 4 - Docker App Deployment 🐳

## Quick Navigation

| Page | Link |
|---|---|
| Phase 4 Home | [README](README.md) |
| Step-by-Step Guide | [step-by-step.md](step-by-step.md) |
| Validation Evidence | [validation.md](validation.md) |
| Current Status | [CURRENT-STATUS.md](../../CURRENT-STATUS.md) |

## Implemented Design

Umami 3.4.0 and PostgreSQL 16 were deployed on 2026-10-14. The public host
`a.chrisalorenzo.com` exposes only `/script.js` and `/api/send` through Caddy;
other public paths return 404. Administration uses loopback port 3000 through
Tailscale Serve on port 8444. PostgreSQL has no published port and uses its
own internal-only network. Umami also joins `web` so Caddy can reach it.

The public record must be proxied through Cloudflare. Since 2026-10-05,
origin HTTP/HTTPS accepts Cloudflare ranges only, including Docker-published
proxy ports through `DOCKER-USER`. The earlier DNS-only proposal prevented
the ACME challenge and visitors from reaching the origin. The proxied record
and `CLIENT_IP_HEADER: CF-Connecting-IP` correction are recorded in
[CHANGELOG.md](../../CHANGELOG.md#2026-10-14-umami-deployed-public-record-proxied).

The [deployment guide](step-by-step.md) owns setup and rollback instructions.
[Validation](validation.md) separates the deployment record from remaining
monitoring, site-integration, backup-execution and screenshot checks. The
[archived draft](../archive/umami-rescope-DRAFT-2026-10-12.md) preserves the
re-scope proposal, not current DNS or operational instructions.

## Historical Scoping Record

The candidate comparison below preserves the original selection reasoning.
Its proposed hosts, port layouts, resource estimates and future-work language
are historical. Use the implemented design above and the current guide for
Umami deployment.

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

## Considered for Phase 4

| Option | Why not now |
|---|---|
| Grafana / Prometheus | Public-edge monitoring is already live with Kuma; this phase does not add an internal metrics stack. |
| Forgejo | Separate Git hosting, outside this VPS app phase. Forgejo is now the primary remote; GitHub is the push mirror. |
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

## Deployment and Validation

Follow [step-by-step.md](step-by-step.md) for compose startup, private account
setup, backup installation, proxied DNS, restricted Caddy paths, monitoring
and site embeds. Follow [validation.md](validation.md) for the expected
results and evidence still required. These instructions replace the original
shared candidate deployment pattern.

## Related Documentation

| Document | Purpose |
|---|---|
| [Phase 3 validation](../phase-3-reverse-proxy-https/validation.md) | Completed proxy deployment and captured evidence |
| [Caddy Config](../../configs/caddy/) | Proxy example, staged routes and current exposure inventory |
| [Umami Config](../../configs/umami/) | Implemented service contract and backup tooling |
| [Lessons Learned](../../LESSONS-LEARNED.md) | DNS authority, first-run administration and Cloudflare ingress |
| [Roadmap](../../ROADMAP.md) | Follow-up phases and remaining work pointers |
