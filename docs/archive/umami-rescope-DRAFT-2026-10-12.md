> Archived proposal. Umami was deployed on 2026-10-14. Follow the
> [current implementation guide](../phase-4-docker-app-deployment/step-by-step.md);
> its proxied DNS record supersedes the DNS-only assumptions below.

# Umami analytics re-scope (DRAFT)

Date: 2026-10-12
Status: draft for review. Hostname decided 2026-10-12: a neutral single-letter host (proposed `a.chrisalorenzo.com`) instead of `analytics.`, to reduce silent loss from ad-block filter lists; examples below still show `analytics.` and change at Stage 0. Nothing is deployed, no files outside this draft were changed, no commits. Based on read-only inspection of `~/github/vps-lab`, the private ops notes, `~/github/blog`, `~/github/portfolio`, the Umami 3.4.0 docs and release notes, and one read-only capacity check on edge-vps (`free -h`, `df -h /`, `docker ps`).

## 1. Why this draft exists

The Umami deployment in `configs/umami/` and `docs/phase-4-docker-app-deployment/step-by-step.md` was staged on 2026-08-30 and still targets `analytics.stayz3ro.dev`. The domain consolidation of 2026-09-28 moved every public web property to `chrisalorenzo.com` and reduced `stayz3ro.dev` to 301 redirects:

| Host | Role after consolidation |
|---|---|
| `chrisalorenzo.com` | Portfolio (Cloudflare Pages) |
| `blog.chrisalorenzo.com` | Blog (Cloudflare Pages) |
| `status.chrisalorenzo.com` | Uptime Kuma public status page (edge-vps, Caddy) |
| `stayz3ro.dev`, `www.stayz3ro.dev` | 301 to `https://blog.chrisalorenzo.com` |
| `status.stayz3ro.dev` | 301 to `https://status.chrisalorenzo.com` |

The `stayz3ro.dev` registration is kept on purpose, and it is now redirect-only. Deploying a brand new tracker host under a redirect-only domain would fork the analytics story across two domains and leave the blog embed pointing at a hostname that only redirects. This draft re-scopes the deployment to the consolidated domain and folds in the things the original plan could not know: the current Umami major version, the Postgres-only requirement, and a public/admin split that keeps the dashboard off the internet.

What stays the same: Umami plus PostgreSQL on edge-vps behind Caddy, no published application ports, the external `web` network, and the internal-only database network. What changes: hostname, image pin, DB minimum and timezone, the public surface (tracker only), the admin access path, the Kuma monitor target, and the backup and privacy sections.

## 2. Hostname proposal

Primary proposal: **`analytics.chrisalorenzo.com`**, Caddy fronted, Cloudflare DNS record DNS-only (grey cloud), matching the `status.chrisalorenzo.com` pattern.

Reasons to keep the name as proposed:

- It matches the existing naming style (`status.`, `ntfy.`) and the consolidation decision that service subdomains live under `chrisalorenzo.com`.
- The blog embed snippet already reads `https://<host>/script.js`, so only the host changes, not the shape.
- One zone holds every public host, so the "live zone versus parked zone" confusion from the Phase 3 DNS lesson cannot repeat.

One caveat worth a decision before Stage 3: many ad-blocker and privacy filter lists block hostnames that begin with `analytics.` or `stats.`. That does not break the site, it silently drops your own traffic data. Three options, in order of effort:

1. Keep `analytics.chrisalorenzo.com` and accept partial data loss from filtered browsers.
2. Use a neutral host such as `a.chrisalorenzo.com` or `t.chrisalorenzo.com`, which some lists do not match.
3. Serve the tracker same-origin from the Pages sites through a Pages Function or Worker proxy (`/u/script.js` and `/u/api/send` forwarded to edge-vps). This defeats most filter lists and needs no new CSP origin, at the cost of a proxy to maintain and one more moving part on the Pages side.

Recommendation: option 1 or 2 for the first deployment, because both keep the origin count at one and the validation simple. Note the choice in the commit message either way, since it changes the embed snippet and the CSP entries.

## 3. Public tracker, tailnet-only admin

The tracker endpoint has to be public: visitors' browsers load `/script.js` and post pageviews to the collection endpoint, so an allowlist or a VPN requirement in front of those two paths would end analytics. The dashboard is the opposite: it is a login form plus a broad management API, useful to exactly one person, and the Phase 3 lesson (and Umami's own default `admin` / `umami` credential) is that every public login page is attacked. Split the two.

### 3.1 Public surface: one Caddy site block, tracker paths only

```
analytics.chrisalorenzo.com {
	import security_headers
	# Public surface: the tracker script and the collection endpoint only.
	@tracker path /script.js /api/send
	handle @tracker {
		reverse_proxy umami:3000
	}
	handle {
		respond 404
	}
}
```

- `/script.js` and `/api/send` are the two paths the tracker uses in v2 and v3 per the Umami docs. Confirm both from the browser Network tab during Stage 4 before enforcing anything, and add the pixel path only if the Pixel feature is enabled later.
- Everything else, including `/`, `/login`, `/api/auth`, `/api/websites` and the dashboard assets, answers 404 at the edge. Those paths never reach the container from the internet.
- Same `import security_headers` as the other hosts, same JSON access log, same HSTS. The security header set does not include a CSP for Umami itself; if the dashboard ever gets a CSP it should only apply to the tailnet listener.
- The `web` network stays external and shared with the Caddy and Kuma stacks, and the database stays on `umami_internal` with no route out.

### 3.2 Admin surface: loopback publish plus `tailscale serve`

Publish Umami on host loopback and expose that only over the tailnet, which is exactly how the Kuma admin is handled today (Kuma admin on tailnet port 8443 backed by `127.0.0.1:3001`):

```
# docker-compose.yml, umami service
    ports:
      - "127.0.0.1:3000:3000"
```

```
# on edge-vps, after the stack is up (Kuma already holds 8443)
tailscale serve --bg 8444 http://127.0.0.1:3000
tailscale serve status
```

Result: `https://edge-vps.<tailnet>.ts.net:8444` reaches the Umami login from tailnet devices only, with the node's Tailscale certificate, and nothing about the admin surface is public. `127.0.0.1` binds are not reachable from the internet, and UFW still only allows 22 (tailnet), 80 and 443.

The alternative, if one hostname for both surfaces is preferred, is a Caddy matcher keyed on source address rather than a separate listener:

```
	@admin remote_ip 100.64.0.0/10 ::1
	handle @admin {
		reverse_proxy umami:3000
	}
```

Tradeoffs worth writing down before choosing: the `remote_ip` form keeps one hostname and no extra port, but it relies on seeing the real client address, which is one more reason to keep the DNS record DNS-only rather than proxied through Cloudflare, and it makes the admin reachable from anything on the tailnet rather than only from the loopback listener that `tailscale serve` fronts. The default recommendation is 3.1 plus 3.2, and the matcher as a fallback if the extra port is unwanted.

## 4. Version pin and database requirement

- Current release: **v3.4.0**, published 2026-09-17 (GitHub releases API). The staged plan predates the v3 line entirely.
- **PostgreSQL only.** The docs state: "Umami supports PostgreSQL (minimum v12.14)". MySQL from the v2 line is gone in v3, which the staged compose already reflects with `postgres:16-alpine`.
- The staged image tag `umamisoftware/umami:postgresql-latest` is a rolling tag and must not be deployed. Checked against Docker Hub today: `umamisoftware/umami` publishes `latest`, `postgresql-latest` (legacy rolling), and plain version tags including `3.4.0`; the old `postgresql-vX.Y.Z` naming does not exist for v3 (a `postgresql-v3.4.0` tag does not resolve). Pin **`umamisoftware/umami:3.4.0`**, the same repo the staged compose already uses, with an exact tag. The Umami docs now also publish `docker.umami.is/umami-software/umami:<tag>`; either registry works, pick one and pin it.
- Postgres: keep `postgres:16-alpine` (satisfies the 12.14 minimum) or move to `17-alpine`. Either is fine. Pin by digest and record the digest in a comment, and do not use `postgres:latest`.
- Timezone: the docs recommend running the database in UTC, and the v3.4.0 notes list PostgreSQL timezone fixes. Add `TZ=UTC` to both services so the container clock and the Postgres `timezone` setting agree. Leave the host timezone alone.
- Migrations run automatically at container start (Prisma, during build/start). So the first `up -d` creates the schema, and a future image bump can migrate the schema forward on boot. That is why the database dump in section 8 matters before version bumps, not only at install: rolling an image back after a migration is not guaranteed to work.
- Default credentials are `admin` / `umami`, created when the database is first initialised. Change the password on first login in Stage 2, before any public route exists, even though the 3.1 design keeps that page private anyway.
- Env stays as staged: `DATABASE_URL`, `APP_SECRET`, `POSTGRES_PASSWORD`, plus the database/user/db names in the `db` service. Do not add `CLOUD_MODE`. Leave `MCP_ENABLED` unset: MCP is self-hosted-off by default in 3.4.0, and if it is wanted later it must sit behind the tailnet listener, never the public tracker route.

## 5. Resource fit on edge-vps

Measured 2026-10-12, read-only on edge-vps (`free -h`, `df -h /`, `docker ps`):

| Resource | Reading |
|---|---|
| RAM | 7.8 GiB total, 800 MiB used, 7.0 GiB available |
| Swap | 2.0 GiB, 0 used |
| Root disk | 251 G total, 9.2 G used, 232 G available (4%) |
| Containers | `caddy:2-alpine`, `louislam/uptime-kuma:1`, `binwiederhier/ntfy:v2.28.0` |

Umami is one Next.js process (300 to 600 MiB resident is typical at this scale) plus Postgres 16 with the default 128 MB `shared_buffers` (100 to 200 MiB idle, more under query load). Budget roughly 0.8 to 1.0 GiB added. That leaves several GiB of headroom and no need for swap, so this stack fits comfortably. Disk grows with analytics rows plus WAL: a low-traffic blog and portfolio will add megabytes per year, so capacity is not the issue, unbounded retention is. Decide a retention window rather than accepting the default "keep forever" (section 10).

For a public edge host, add ceilings so one container cannot starve Caddy and Kuma, and a healthcheck so Kuma and `docker compose ps` tell the truth:

```
    # umami service
    mem_limit: 768m
    # db service
    mem_limit: 512m
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U umami -d umami"]
      interval: 10s
      timeout: 5s
      retries: 6
```

Then gate startup order with `depends_on: { db: { condition: service_healthy } }` so Umami does not race the database on a cold boot, and re-check `free -h` on edge-vps during Stage 1 with both containers running.

## 6. Compose changes to `configs/umami/docker-compose.yml`

Change list against the staged file (same file, same networks, no secrets touched):

| # | Change | Reason |
|---|---|---|
| 1 | `image: umamisoftware/umami:3.4.0` (was `postgresql-latest`) | Exact version, no silent drift on restart or rebuild |
| 2 | `name: umami` at the top level | Stable Compose project name, so the Postgres volume path is deterministic for backups and restores regardless of the checkout directory |
| 3 | `TZ=UTC` on both services | Umami docs recommend UTC for the database; avoids the timezone class of bugs fixed in 3.4.0 |
| 4 | `ports: ["127.0.0.1:3000:3000"]` on umami | Tailnet admin path over `tailscale serve`; loopback only, never public |
| 5 | `healthcheck` on db (`pg_isready`) | `docker compose ps` and `depends_on` reflect real readiness |
| 6 | `depends_on: db: condition: service_healthy` | No cold-boot race between migrations and the database |
| 7 | `mem_limit: 768m` (umami), `512m` (db) | Bound the blast radius on a host that also runs the public edge |
| 8 | Comment the Postgres digest next to the image | Reproducible pulls, and the digest is what the backup notes reference |

Unchanged on purpose: external `web` network (shared with Caddy and Kuma), internal-only `umami_internal` for the database, `restart: unless-stopped`, the named volume, no published database port, and the `.env` with `POSTGRES_PASSWORD` plus `APP_SECRET`.

Proposed file (for review; nothing was applied):

```yaml
# Umami analytics stack on edge-vps. Public surface is the tracker only
# (see docs/umami-rescope-DRAFT-2026-10-12.md section 3). Admin is reached
# over the tailnet via the loopback publish on port 3000.
name: umami

services:
  umami:
    image: umamisoftware/umami:3.4.0
    container_name: umami
    restart: unless-stopped
    mem_limit: 768m
    environment:
      TZ: UTC
      DATABASE_URL: postgresql://umami:${POSTGRES_PASSWORD:?set POSTGRES_PASSWORD in .env}@db:5432/umami
      APP_SECRET: ${APP_SECRET:?set APP_SECRET in .env}
    ports:
      - "127.0.0.1:3000:3000"   # tailnet admin only, never public
    networks:
      - web
      - umami_internal
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    container_name: umami-db
    restart: unless-stopped
    mem_limit: 512m
    environment:
      TZ: UTC
      POSTGRES_USER: umami
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?set POSTGRES_PASSWORD in .env}
      POSTGRES_DB: umami
    volumes:
      - umami_db_data:/var/lib/postgresql/data
    networks:
      - umami_internal
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U umami -d umami"]
      interval: 10s
      timeout: 5s
      retries: 6

networks:
  web:
    external: true
  umami_internal:
    internal: true

volumes:
  umami_db_data:
```

The Caddy container reaches `umami:3000` over `web`, so no Caddyfile volume change is needed beyond the site block in 3.1.

## 7. Cloudflare DNS record

- Zone: `chrisalorenzo.com` (the live zone for every public host). Do not add anything to `stayz3ro.dev`; that zone is redirect-only now.
- Record: type `A`, name `analytics`, content = the edge-vps public IPv4, **Proxy status: DNS only (grey cloud)**, TTL Auto. Add an `AAAA` only if edge-vps has a public IPv6 address to serve on.
- Why DNS-only: Caddy terminates TLS and obtains its own Let's Encrypt certificate. A proxied record puts Cloudflare in front of the ACME HTTP-01 challenge (the usual cause of the "cert never issues" failure), adds a second TLS layer, and hides real client addresses from Caddy, which would also break the optional `remote_ip` admin matcher in 3.3. The consolidation packet already settled on DNS-only for `status.chrisalorenzo.com`, so this matches the precedent.
- Order: bring the stack up and claim the admin account first (Stage 1 and 2), then add the record (Stage 3), then enable the Caddy block (Stage 4). Adding the record before the Caddy block is harmless, HTTPS for the new name simply fails the handshake until Caddy has a certificate for it.
- Validation, from two perspectives:

```
dig +short analytics.chrisalorenzo.com
dig +short analytics.chrisalorenzo.com @1.1.1.1
```

  Expect the edge-vps address from both. If a public resolver lags, re-check after the record TTL.
- Housekeeping: leave the apex, `www`, `blog`, `status` and `ntfy` records exactly as they are. The `stayz3ro.dev` redirect rules are unrelated to this record.
- Inventory note: the blog and portfolio `_headers` files deliberately omit `includeSubDomains` from HSTS "until a complete HTTPS subdomain inventory" exists. Adding `analytics.` extends that inventory to five HTTPS-only hosts (apex and blog on Pages, `status.`, `ntfy.`, `analytics.` on edge-vps). Worth recording, not worth changing in this deployment.

## 8. Blog and portfolio changes (separate repos, listed only)

Both sites are Cloudflare Pages builds and both ship a `_headers` file that carries a report-only CSP today. Nothing in that CSP allows a third-party script origin, so the tracker is blocked by the browser policy the moment it is added, and report-only mode means it loads but logs violations. Files to change:

Blog, Astro (`~/github/blog`):

| File | Change |
|---|---|
| `src/layouts/Base.astro` | Add the tracker `<script>` in `<head>`. The head already carries inline scripts covered by two `sha256-` hashes; an external script needs no new hash, only the origin allowlist |
| `public/_headers` | CSP delta, below |
| `README.md` | Update the stale mention of `analytics.stayz3ro.dev` |
| `src/content/blog/stayz3ro-dev-cloudflare.md` | Published post that says `analytics.stayz3ro.dev` is "coming next" (three places). Decide whether to edit the post or leave it as a dated record |
| `dist/*` | Do not hand-edit; regenerated by the Pages build |

Portfolio, Vite (`~/github/portfolio`):

| File | Change |
|---|---|
| `index.html` | Add the tracker `<script>` in `<head>`. The existing inline failsafe script keeps its hash; the external script only needs the origin allowlist |
| `public/_headers` | Same CSP delta |
| `dist/*` | Do not hand-edit; regenerated by the Pages build |

CSP delta in both `_headers` files (currently `Content-Security-Policy-Report-Only`): add the analytics origin to two directives.

```
script-src 'self' <existing sha256 hashes> https://analytics.chrisalorenzo.com;
connect-src 'self' https://fonts.googleapis.com https://fonts.gstatic.com https://analytics.chrisalorenzo.com;
```

- `img-src` stays as is unless the Pixel feature is enabled later; a pixel is an image request to the same origin and would need it there.
- Keep the header report-only through this change, exercise the index, a post and the 404 page with devtools open, confirm no violations, then flip to the enforcing header name as the existing comment already prescribes.
- If option 3 from section 2 (same-origin proxy) is chosen instead, no new origin is needed and `connect-src 'self'` keeps working.

Tracker tag. One website entry per site in Umami, so two website IDs:

```
<script defer src="https://analytics.chrisalorenzo.com/script.js"
        data-website-id="<blog-website-id>"
        data-domains="blog.chrisalorenzo.com"
        data-do-not-track="true"></script>
```

```
<script defer src="https://analytics.chrisalorenzo.com/script.js"
        data-website-id="<portfolio-website-id>"
        data-domains="chrisalorenzo.com"
        data-do-not-track="true"></script>
```

Notes on the attributes, all from the tracker configuration doc:

- `data-domains` matches `window.location.hostname` exactly, so it keeps Pages preview hostnames (`*.pages.dev`) and any `www` variant out of the data. Use the exact host each site is served on.
- `data-do-not-track="true"` respects the browser DNT setting (available since v2.17.0). This draft assumes it is wanted.
- `data-exclude-search="true"` is optional if query strings should not be captured on pageviews.
- Do not set `data-host-url`: the default, sending data to wherever the script came from, is exactly the split we want, because script and collection endpoint live on the same host.
- Deploy the blog first, verify one pageview lands with the right hostname, then do the portfolio. One site at a time keeps a bad tag attributable.

## 9. Umami database backup (ties to the planned offsite backup)

What has to survive: the Postgres database (authoritative analytics), the compose file plus `.env` (the file is gitignored, so its secrets belong in the password manager, not the repo), and the Caddyfile (already in git). A raw copy of a running Postgres data directory is not a backup, it can be torn mid-write. Use a logical dump as the portable artifact and treat the volume as a machine-level convenience only.

```sh
#!/bin/sh
# /opt/stayz3ro/proxy/configs/umami/backup-umami.sh   (root-owned, 0750)
set -eu
dir=/opt/stayz3ro/backups/umami
mkdir -p "$dir"
cd /opt/stayz3ro/proxy/configs/umami
docker compose exec -T db pg_dump -U umami -d umami -Fc > "$dir/umami-$(date -u +%F).dump"
find "$dir" -name 'umami-*.dump' -mtime +14 -delete
```

- Pair it with a systemd timer (daily 03:30 UTC is a fine slot, before the snapshot window) so it runs without a shell.
- Then have the planned offsite backup's Kopia snapshot `/opt/stayz3ro/backups/umami` together with the compose directory. That directory is the interface between this stack and the backup system: keep the dumps there, keep local retention short, and let B2 hold the long history.
- If the offsite backup (Kopia plus B2) is not live yet, run the timer anyway so dumps accumulate locally, and add the kopia source to the offsite backup checklist. Also settle whether edge-vps is a Kopia source at all today: the current papers describe Kopia and B2 for the lab and backup targets, so this may be a new source to inventory.
- Monthly restore drill, in the spirit of the W7a canary: `pg_restore --list` on the newest dump as the cheap check, plus a real restore into a throwaway database once a month to prove the artifact. A dump that has never been restored is a theory.
- Version note: `pg_dump` and `pg_restore` from the 16 image cover 16 and 17 servers. If the server is bumped later, take dumps from the newer image.
- Rollback: this section is additive. `systemctl disable --now umami-backup.timer`, remove the unit and the script, and the running stack is untouched. Dumps are plain files.

## 10. Privacy notes

Facts from the Umami FAQ and tracker configuration doc, which is where any published privacy statement should get its wording:

- **No cookies.** The FAQ is explicit: "Umami does not use any cookies in the tracking code", and a cookie notice is not required. That is also why the tracker works with no consent banner on the Pages sites.
- **No personally identifiable information.** The FAQ states Umami does not collect PII and anonymises what it does collect: pageviews, referrer URL, browser, operating system, device type and country of origin. Country is derived server-side from the request address.
- **Respect DNT.** Set `data-do-not-track="true"` on both tags (section 8). A browser sending DNT then produces no events. Note that this is opt-in per attribute, not a default.
- **Scope the tracker.** `data-domains` on each tag keeps preview and staging hostnames out of the data, so what lands in the dashboard maps to production pages only.
- **No cross-site tracking.** Umami never tracks a user across websites (FAQ), and each site is a separate website entry with its own ID.
- **Retention is your decision.** Self-hosted Umami keeps data indefinitely unless pruned (FAQ). Pick a window, for example 12 months of pageviews, prune on a schedule, and make the backup retention match so the dump does not quietly become the longer-lived copy.
- **Where the addresses do persist.** The tracker payload does not carry the IP, but the server necessarily sees it, and Caddy's JSON access log on edge-vps records client addresses for these requests as it already does for every other host (10 MiB rolling, 10 files kept). That is the local copy to reason about in any privacy note, and it is governed by the existing log policy, not by Umami.
- **Data location.** Rows live in Postgres on the Netcup VPS; the sites themselves are served from Cloudflare Pages. If a privacy line is ever published for the blog or portfolio, state both, plus the cookieless and DNT behaviour above.
- Optional but recommended: use the documented "exclude my own visits" route (a local storage or query-param convention on the tracker) so internal browsing does not pollute short-term numbers. Decide it before the first month of data, not after.

## 11. Staged rollout, validation and rollback

Every stage is independently reversible, and no stage exposes the dashboard. Run the edge-vps work over the Tailscale SSH alias. Do not `git pull` in the live checkout: the Phase 4 runbook records that it predates a history rewrite. Stage the changed files with `scp` as the existing runbook already describes.

### Stage 0, prepare (workstation only)

- [ ] Branch in `vps-lab`, apply the section 6 changes and the section 3.1 Caddy block (commented out, as today).
- [ ] Confirm the pinned tag actually exists before touching the VPS: `docker manifest inspect umamisoftware/umami:3.4.0 >/dev/null && echo tag-ok`.
- [ ] Syntax-check the compose without creating a real `.env`: `POSTGRES_PASSWORD=x APP_SECRET=y docker compose config --quiet`.
- [ ] Rollback: discard the branch. Nothing has touched edge-vps.

### Stage 1, stack up, no public route, no DNS record

- [ ] `scp` the compose and `.env.example` into the live umami directory (same shape as the runbook Step 1).
- [ ] On edge-vps: `cp .env.example .env`, fill `POSTGRES_PASSWORD` and `APP_SECRET` (`openssl rand -base64 32`), `chmod 600 .env`.
- [ ] `docker compose config --quiet` (the `--quiet` matters: the resolved config prints the password inside `DATABASE_URL`).
- [ ] `docker compose up -d && docker compose ps` and `docker compose logs --tail=40 umami`.

Validation:

- [ ] `docker compose ps` shows `umami` running and `umami-db` healthy (the new healthcheck).
- [ ] Logs show the database migrations completing, no restart loop.
- [ ] `ss -tlnp` on the host shows `127.0.0.1:3000` for the app and nothing for 5432; `docker port umami` prints `127.0.0.1:3000`.
- [ ] From the workstation, confirm neither port is reachable: `nc -vz <edge-public-ip> 3000` and `nc -vz <edge-public-ip> 5432` should both refuse or time out.
- [ ] `free -h` on edge-vps again with both containers up (expect roughly 1 GiB more used, still several GiB free).

Rollback: `docker compose down` (keep the volume; add `-v` only if the data is meant to be discarded).

### Stage 2, claim the admin account over the tailnet

- [ ] `tailscale serve --bg 8444 http://127.0.0.1:3000` then `tailscale serve status` (Kuma already holds 8443, so nothing clashes).
- [ ] From a tailnet device, open the admin URL, log in with `admin` / `umami`, and **change the password immediately**.
- [ ] Create two website entries: `blog.chrisalorenzo.com` and `chrisalorenzo.com`. Copy both website IDs into the section 8 tags. These IDs end up in public page HTML by design, so they are not secrets, but they are also not obviously memorable: keep them in the branch commit message rather than in a scratch file on the VPS.

Validation:

- [ ] Admin UI loads over the tailnet URL and the password change persists across a container restart.
- [ ] Two website entries exist with the expected domains.
- [ ] From the workstation, confirm there is no public path to the dashboard yet (`curl -sS -o /dev/null -w '%{http_code}\n' http://<edge-public-ip>:3000` should refuse).

Rollback: `tailscale serve --https=8444 off` (or `tailscale serve reset` to clear all serve config; confirm the exact flag with `tailscale serve --help` on the host). The stack keeps running and the data survives.

### Stage 3, Cloudflare DNS record

- [ ] Add the `analytics` A record per section 7: DNS only, TTL Auto.

Validation:

- [ ] `dig +short analytics.chrisalorenzo.com` and the same query against a public resolver both return the edge address.
- [ ] Public HTTPS will not validate yet, because Caddy has no certificate for the name until the site block exists. That is expected at this stage, not a fault.

Rollback: delete the record.

### Stage 4, enable the public tracker route

- [ ] Uncomment the 3.1 site block in the live Caddyfile.
- [ ] `docker exec caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile`.
- [ ] Prefer a reload over a restart so the status and ntfy hosts keep serving: `docker exec caddy caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile`. The existing runbook's `docker restart caddy` also works and is used in the rollback path.

Validation (from the workstation):

```
curl -sS -o /dev/null -w '%{http_code} %{content_type}\n' https://analytics.chrisalorenzo.com/script.js
curl -sS -o /dev/null -w '%{http_code}\n' https://analytics.chrisalorenzo.com/
curl -sS -o /dev/null -w '%{http_code}\n' https://analytics.chrisalorenzo.com/login
curl -sS -o /dev/null -w '%{http_code}\n' https://analytics.chrisalorenzo.com/api/websites
curl -sS -o /dev/null -w '%{http_code}\n' -X POST -H 'Content-Type: application/json' \
  --data '{"type":"event","payload":{"website":"<website-id>","hostname":"blog.chrisalorenzo.com","url":"/"}}' \
  https://analytics.chrisalorenzo.com/api/send
echo | openssl s_client -connect analytics.chrisalorenzo.com:443 -servername analytics.chrisalorenzo.com 2>/dev/null \
  | openssl x509 -noout -issuer -dates
```

- [ ] Expect: `/script.js` 200 with a JavaScript content type; `/`, `/login` and `/api/websites` all 404; the POST is not 404; the certificate is a valid Let's Encrypt one covering the new name.
- [ ] Confirm the test event appears in the dashboard, then delete it if it pollutes the data.
- [ ] If the tracker in a browser hits a path that 404s, add that path to the `@tracker` matcher, revalidate, reload.
- [ ] Confirm the other hosts still serve: `curl -sS -o /dev/null -w '%{http_code}\n' https://status.chrisalorenzo.com/status/main` and the ntfy health path.

Rollback: comment the block out in place, `caddy validate`, then reload or restart. Leave the stack running so analytics data is preserved. The record can stay; the host simply 404s.

### Stage 5, monitor the new public surface

- [ ] In the tailnet-only Kuma admin, add an HTTP(s) monitor. Target **`https://analytics.chrisalorenzo.com/script.js`**, not the root: the root is a deliberate 404, so a monitor on it would show DOWN forever.
- [ ] Interval 60s, retries 2, retry interval 60s, TLS certificate expiry notice at 14 days, matching the other monitors.
- [ ] Attach the two existing notification providers (Discord and self-hosted ntfy) so the new host pages the same way the other hosts do.

Validation:

- [ ] Monitor goes Up and stays Up across a Caddy reload.
- [ ] Optional negative check: temporarily expect a 404 path and confirm the monitor flips to DOWN, then restore the correct URL. This proves the monitor is not a rubber stamp.

Rollback: delete or pause the monitor. It has no effect on the stack.

### Stage 6, add the tracker to the blog, then the portfolio

One site at a time, so a bad tag is attributable. Blog first.

- [ ] Edit `blog/src/layouts/Base.astro` (tag) and `blog/public/_headers` (CSP origins), deploy the Pages build.
- [ ] In a private window with DNT off, load a blog post. In devtools, Network: `/script.js` 200, a POST to `/api/send` with a 2xx, Console: no CSP report-only violations.
- [ ] Confirm the visit appears in Umami under the blog website entry, with `blog.chrisalorenzo.com` as the hostname.
- [ ] DNT check, in Firefox (Chrome dropped the UI): enable the DNT header, load another page, confirm no new event is recorded.
- [ ] Then repeat for `portfolio/index.html` plus `portfolio/public/_headers`, and confirm the portfolio shows up under its own website entry with `chrisalorenzo.com`.
- [ ] Confirm a Pages preview deployment does not send data (the `data-domains` guard). Load a preview URL and check the dashboard stays unchanged.

Rollback: remove the tag, or point `data-domains` at a hostname that never matches, and redeploy the Pages build. Leaving the CSP origins in place while the tag is gone is harmless (they are unused allowlist entries), and reverting them is a one-line change if wanted.

### Stage 7, enforce the CSP later

- [ ] After the report-only window is clean (the `_headers` comment already prescribes a week), rename the header from `Content-Security-Policy-Report-Only` to `Content-Security-Policy` in both repos, deploy, and re-verify the tracker still loads and sends.

Rollback: rename it back to report-only and redeploy. Enforcement failures here would be visible immediately as a blocked script in the console.

### Stage 8, backups and the first restore drill

- [ ] Install `backup-umami.sh` and its systemd timer per section 9, run the timer once by hand, confirm a dump file appears in `/opt/stayz3ro/backups/umami`.
- [ ] `pg_restore --list` on that dump (cheap structural check), then add the directory to the offsite backup source list once that system is live.
- [ ] Schedule the monthly full restore drill and write the date into the ops calendar, so it does not drift like the W7a canary discipline warns about.

Rollback: disable the timer, remove the unit and script. No effect on the running stack.

### Rollback summary

| Stage | Rollback action | Data impact | Public impact |
|---|---|---|---|
| 0 | Discard branch | None | None |
| 1 | `docker compose down` (keep volume) | Dumps and volume intact | None |
| 2 | `tailscale serve` off for the port | None | None |
| 3 | Delete the DNS record | None | None |
| 4 | Comment the Caddy block, validate, reload | None | Host returns 404 |
| 5 | Delete the Kuma monitor | None | None |
| 6 | Remove the tag (or break `data-domains`), redeploy | None | Tracking stops |
| 7 | Header back to report-only | None | None |
| 8 | Disable the timer | Old dumps stay until pruned | None |

The one irreversible step in the whole plan is `docker compose down -v`, which deletes `umami_db_data`. Do not use `-v` unless the analytics history is genuinely being thrown away, and take a dump first.

## 12. Repo files that still carry the old plan (listed, not edited here)

`vps-lab`:

| File | What is stale |
|---|---|
| `CURRENT-STATUS.md` | Phase 4 paragraph and the Next Workstream list both name `analytics.stayz3ro.dev`; the architecture diagram omits the analytics host |
| `ROADMAP.md` | Phase 4 says Umami at `analytics.stayz3ro.dev` |
| `configs/umami/README.md` | Embed snippet, the `analytics.{$SITE_DOMAIN}` Caddy route, and the "claim admin before public exposure" model, which this draft replaces with a tracker-only public surface |
| `configs/umami/docker-compose.yml` | Rolling image tag, no pin, no limits (section 6) |
| `configs/caddy/Caddyfile` | The staged analytics block is commented and uses `{$SITE_DOMAIN}`. Recommendation: hardcode `analytics.chrisalorenzo.com` in the new block, matching the hardcoded `status.chrisalorenzo.com` and `ntfy.chrisalorenzo.com` blocks; `SITE_DOMAIN` is now only the legacy-redirect variable |
| `docs/phase-4-docker-app-deployment/step-by-step.md` | Title, steps 5 to 7, step 10 (monitor URL), step 11 (embed host), the rollback section and the phase result all assume the old hostname and a public dashboard |
| `CHANGELOG.md`, `LESSONS-LEARNED.md`, `screenshots/` | Historical record. Leave the past entries as they are and add a new entry when this deployment lands |

Consumer repos (in scope for the change, still listed only): `blog/src/layouts/Base.astro`, `blog/public/_headers`, `blog/README.md`, `blog/src/content/blog/stayz3ro-dev-cloudflare.md`, `portfolio/index.html`, `portfolio/public/_headers`. Nothing in `blog/dist/**` or `portfolio/dist/**` is edited by hand; both are build output.

The domain-consolidation packet in the private ops repo records the naming decision. The current implementation guide linked above records the deployed public configuration.

## 13. Open decisions and uncertainty

Decisions to settle before Stage 0, each with a recommendation:

1. Hostname: `analytics.chrisalorenzo.com` (recommended), a neutral name, or a same-origin proxy. This changes the embed snippet and the CSP entries, so decide first.
2. Admin exposure: loopback plus `tailscale serve` on 8444 (recommended, matches Kuma) or a single hostname with the `remote_ip` matcher.
3. Postgres major: stay on 16 (recommended, already staged) or move to 17. Either way, pin by digest.
4. Backups: does edge-vps become an offsite backup (Kopia) source, and on what schedule? Recommended: yes, snapshot the dump directory daily.
5. Retention: pick a pageview retention window (for example 12 months) and match the backup retention to it.
6. Exclude-your-own-visits mechanism, decided before the first month of data.

Explicit uncertainty, so nothing here is read as measured fact:

- The tracker's exact collection paths: `/script.js` is confirmed from the docs, and `/api/send` is the v2/v3 collection path, but I did not verify the pixel route or any v3-specific route from the container. Confirm from the browser Network tab in Stage 4 before treating the matcher as final.
- The pinned tag: `umamisoftware/umami:3.4.0` is confirmed to exist on Docker Hub today (queried), and it matches the repo the staged compose already uses. The docs' alternative registry (`docker.umami.is/umami-software/umami`) is shown with `:latest` only, so verify the exact version tag with `docker manifest inspect` in Stage 0.
- Memory figures for Umami and Postgres are typical ranges, not measurements on this host. The Stage 1 `free -h` reading is the real number.
- The `tailscale serve` off syntax differs between client versions; check `tailscale serve --help` on edge-vps before relying on the rollback line.
- This is a fresh install, not a migration: no Umami instance has ever run, so there is no existing analytics database to preserve or upgrade. That is also why the version pin can be chosen freely now.
- No load, soak or multi-user testing has been done. The sizing assumes one admin and low public traffic.

## Sources

- Read-only repo inspection: `vps-lab` (`CURRENT-STATUS.md`, `ROADMAP.md`, `configs/umami/*`, `configs/caddy/Caddyfile`, `docs/phase-4-docker-app-deployment/step-by-step.md`), the private ops notes, `blog` (`astro.config.mjs`, `src/layouts/Base.astro`, `public/_headers`, `README.md`, content mentions), `portfolio` (`index.html`, `public/_headers`).
- edge-vps capacity, one read-only command on 2026-10-12: `free -h; df -h /; docker ps --format "{{.Names}} {{.Image}}"`.
- Umami: GitHub releases API (latest release v3.4.0, published 2026-09-17), `umami.is/docs/install` (PostgreSQL minimum 12.14, UTC recommendation), `umami.is/docs/faq` (no cookies, no PII, retention, supported databases), `umami.is/docs/tracker-configuration` (data-domains, data-do-not-track since v2.17.0, data-host-url), `umami.is/docs/collect-data` (tracker in the head), Docker Hub tags API for `umamisoftware/umami`.

Draft only. No deployment, no repo change outside this file, no commits.

DONE umami-rescope-DRAFT-2026-10-12.md
