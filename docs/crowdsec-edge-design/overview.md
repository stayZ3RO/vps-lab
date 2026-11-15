# CrowdSec on the public edge: design

Status: design draft, prepared 2026-11-15. Nothing here is deployed. Every
step that touches the VPS is owner-run and listed in
[step-by-step.md](step-by-step.md).

## 1. What the edge looks like today, from this repo

| Area | What the repo records | Where |
|---|---|---|
| Web server | One Caddy container (`caddy:2-alpine`, rolling tag) publishes 80/tcp, 443/tcp and 443/udp | `configs/caddy/docker-compose.yml:20` to `:27` |
| Sites | `status` (Kuma public status page, path allowlist), `ntfy`, and the `a` tracker for Umami; admin names `kuma` and `umami` answer only to tailnet sources | `configs/caddy/Caddyfile:57` to `:68`, `:114` to `:126`, `:135` to `:147`; `phase-state.md:19` to `:22` |
| Repo drift | The `a` tracker block is commented out in the checked-in Caddyfile, while `phase-state.md` records it live since 2026-10-14 | `configs/caddy/Caddyfile:82` to `:91`; `phase-state.md:19` |
| Access log | Global JSON access log at `/var/log/caddy/access.log` inside the container, rolled at 10 MiB, 10 files kept, 336 h | `configs/caddy/Caddyfile:21` to `:29` |
| Log on the host | `./logs` next to the Caddy compose file is bind-mounted to `/var/log/caddy`; the deploy directory is `/opt/stayz3ro/proxy/configs/caddy` | `configs/caddy/docker-compose.yml:29`; `docs/phase-4-docker-app-deployment/step-by-step.md:53` |
| Admin API | `admin off`, so a config change is validate then `docker restart caddy` | `configs/caddy/Caddyfile:18`; `configs/caddy/README.md:120` to `:128` |
| CDN in front | `status`, `ntfy` and `a` are proxied by Cloudflare | `phase-state.md:26` |
| Origin firewall | 80/tcp, 443/tcp and 443/udp accept Cloudflare ranges only, enforced in Docker's `DOCKER-USER` chain because UFW never sees published container ports; saved with `iptables-persistent` | `CHANGELOG.md` 2026-10-05 section; `phase-state.md:27` |
| Real client IP | Caddy has no `trusted_proxies` setting, so its logs carry the Cloudflare address. Umami reads `CF-Connecting-IP` itself; ntfy runs with `behind-proxy: true` | `configs/caddy/Caddyfile` (no `servers` block); `configs/umami/docker-compose.yml:16` to `:18`; `configs/ntfy/server.yml:11` |
| SSH | Recorded as blocked on the public address and reachable through Tailscale only; key-only, no root login; Fail2Ban runs an `sshd` jail | `phase-state.md:85`, `:123` to `:124`, `:72`; `configs/ssh/sshd_config.example`; `configs/fail2ban/jail.local.example` |
| Host firewall | UFW, default deny inbound | `configs/ufw/ufw-rules.example` |
| Provider firewall | Not recorded in this repo | unverified |
| sshd log location | Not recorded in this repo. Ubuntu normally writes `/var/log/auth.log` through rsyslog | unverified, checked in Stage 0 |
| Host size | Not recorded in this repo; a 2 GB swap file was added | `docs/phase-1-vps-baseline-security/step-by-step.md:276` to `:293` |

Two points differ from the brief this design started from:

- **SSH:** the brief says SSH is public with key-only login, but the repo
  records it as tailnet only. Stage 0 checks which is true from outside.
  The answer decides whether the firewall bouncer has any job (section 3).
- **Provider firewall:** this repo does not record one.

## 2. Upstream facts used

Checked 2026-11-15. Anything a source did not state is marked unverified.

| Topic | Fact | Source |
|---|---|---|
| Current release | Security Engine v1.8.2, published 2026-10-26; firewall bouncer v0.0.38, 2026-09-29; Caddy bouncer module v0.15.0, 2026-11-02 | https://github.com/crowdsecurity/crowdsec/releases, https://github.com/crowdsecurity/cs-firewall-bouncer/releases, https://github.com/hslatman/caddy-crowdsec-bouncer/releases |
| Image | `crowdsecurity/crowdsec:v1.8.2`, index digest `sha256:65b74942f7e7ed5c60fde4ac15fc4ba715904c398c8b16dd451f4907d90347d4`; compressed size 171.4 MB amd64. A `-slim` tag (128.5 MB) leaves out notifiers and the GeoIP database. A `-debian` tag (223.5 MB) carries systemd and journalctl | Docker Hub tag API (`hub.docker.com/v2/repositories/crowdsecurity/crowdsec/tags/v1.8.2`), https://hub.docker.com/r/crowdsecurity/crowdsec |
| Container persistence | `/etc/crowdsec` and `/var/lib/crowdsec/data` must be volumes; since 1.7.0 the container will not start without the data volume | https://docs.crowdsec.net/u/getting_started/installation/docker |
| Acquisition directory | Mount one YAML file per source at `/etc/crowdsec/acquis.d` | https://hub.docker.com/r/crowdsecurity/crowdsec |
| Detect only | The engine on its own "will not block anything"; a remediation component does the blocking | https://docs.crowdsec.net/u/getting_started/installation/docker |
| Health check | Use `cscli lapi status`, not `cscli capi status`, which can hit Central API rate limits if run often | same page |
| Caddy collection | `crowdsecurity/caddy` = parser `crowdsecurity/caddy-logs` plus `crowdsecurity/base-http-scenarios`; acquisition label `type: caddy` | https://app.crowdsec.net/hub/author/crowdsecurity/collections/caddy |
| Caddy parser source IP | The parser reads `request.client_ip` from the JSON log, not `remote_ip` | https://github.com/crowdsecurity/hub/blob/master/parsers/s01-parse/crowdsecurity/caddy-logs.yaml |
| Caddy client IP | With no `trusted_proxies`, nothing is trusted and the client IP falls back to the connecting address. `client_ip_headers` chooses the header; the default is `X-Forwarded-For`. The log has `request>remote_ip` (direct peer) and `request>client_ip` (real client when trusted proxies are set), both since v2.7 | https://caddyserver.com/docs/caddyfile/options, https://caddyserver.com/docs/caddyfile/directives/log |
| `remote_ip` matcher | Always the immediate peer; `client_ip` follows `trusted_proxies`. The tailnet admin gate on `kuma` and `umami` uses `remote_ip`, so trusting Cloudflare does not change that gate | https://caddyserver.com/docs/caddyfile/matchers |
| Cloudflare IP source in Caddy | Only the `static` source ships with standard Caddy; other sources are plugins | https://caddyserver.com/docs/caddyfile/options |
| sshd | `crowdsecurity/linux`, installed by default in the image, includes `crowdsecurity/sshd` and `crowdsecurity/whitelist-good-actors` | https://app.crowdsec.net/hub/author/crowdsecurity/collections/linux, https://hub.docker.com/r/crowdsecurity/crowdsec |
| journald source | `source: journalctl` with `journalctl_filter`, label `type: syslog`; it runs the `journalctl` binary. Without that binary the source is unavailable. Only the Debian image is described as having it | https://docs.crowdsec.net/docs/next/log_processor/data_sources/journald, https://discourse.crowdsec.net/t/exec-journalctl-executable-file-not-found-in-path/2642, https://hub.docker.com/r/crowdsecurity/crowdsec |
| File source | `source: file`, `filenames`, `labels.type`; uses inotify by default | https://docs.crowdsec.net/docs/next/log_processor/data_sources/file |
| CDN whitelist | Postoverflow `crowdsecurity/cdn-whitelist` drops alerts whose source is in Cloudflare's published IPv4 or IPv6 ranges | https://app.crowdsec.net/hub/author/crowdsecurity/postoverflows/cdn-whitelist |
| Parser whitelist | A YAML file in `parsers/s02-enrich/` with `whitelist.cidr` stops matching events before the scenario stage | https://docs.crowdsec.net/u/getting_started/post_installation/whitelists |
| LAPI allowlist | `cscli allowlists create <name> -d <description>`, then `cscli allowlists add <name> <ip or range>`; drops local alerts, removes the IP from blocklist pulls, and bypasses AppSec | https://docs.crowdsec.net/docs/local_api/centralized_allowlists |
| Simulation | Simulated decisions show in `cscli decisions list` but "won't be effective"; `cscli simulation enable --global` puts every scenario in simulation | https://docs.crowdsec.net/docs/log_processor/scenarios/simulation, https://docs.crowdsec.net/docs/cscli/cscli_simulation_enable |
| Firewall bouncer | Packages `crowdsec-firewall-bouncer-nftables` and `-iptables`; config `/etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml`, overrides in `.yaml.local`; keys `api_url`, `api_key`; managed nftables tables `crowdsec` and `crowdsec6`; `DOCKER-USER` can be added to `iptables_chains` | https://docs.crowdsec.net/u/bouncers/firewall |
| Package repo | `curl -s https://install.crowdsec.net \| sudo sh`, or the packagecloud key and source list by hand | https://docs.crowdsec.net/u/getting_started/installation/linux |
| Caddy bouncer | Needs a custom build with `xcaddy` (module `github.com/hslatman/caddy-crowdsec-bouncer/http`); needs Caddy v2.7.3+. Global `crowdsec { api_url ... api_key ... ticker_interval ... }`. Streams decisions by default; uses Caddy's client IP since v0.3.1, so it needs `trusted_proxies`. `enable_hard_fails` (default false) makes Caddy refuse to start when LAPI is down | https://github.com/hslatman/caddy-crowdsec-bouncer |
| Caddy images for the build | `caddy:2.11.9-builder` (84.0 MB compressed amd64) and `caddy:2.11.9-alpine` (24.8 MB) | Docker Hub tag API, read 2026-11-15 |
| Cloudflare Worker bouncer | The current Cloudflare remediation. A Worker plus Workers KV, ban page or Turnstile challenge. On the free plan, KV writes are about 1,000 a day (first sync truncated to about 1K IPs) and Worker requests about 100K a day; "when the request quota runs out, remediation stops". The docs advise routes set to Fail Open | https://docs.crowdsec.net/u/bouncers/cloudflare |
| Old Cloudflare bouncer | `crowdsecurity/cs-cloudflare-bouncer` was archived on 2026-09-02 | https://github.com/crowdsecurity/cs-cloudflare-bouncer |
| Cloudflare WAF on Free | 5 custom rules; 1 custom list, 10,000 items | https://developers.cloudflare.com/waf/custom-rules/, https://developers.cloudflare.com/waf/tools/lists/ |
| Community blocklist | Free and contributing: about 15 thousand IPs, tailored to the scenarios the engine reports. Not contributing: Lite, capped at 3 thousand. Only unmodified Hub scenarios count | https://docs.crowdsec.net/docs/next/central_api/community_blocklist |

## 3. The CDN in front, and what can block what

Ports 80 and 443 accept Cloudflare addresses only, so every web connection
the VPS sees comes from Cloudflare. That gives three rules:

1. **A firewall bouncer must never act on web traffic.** On 80 and 443 it
   would only ever see Cloudflare addresses. A ban on one of them drops
   every visitor routed through that Cloudflare node, so it takes the
   sites down for everyone. The firewall bouncer stays off the
   `DOCKER-USER` chain, which is the chain that carries 80 and 443.
2. **Web remediation goes where the real client is known.** There are
   two such places:
   - **At Caddy.** With `trusted_proxies` set to the Cloudflare ranges and
     `client_ip_headers CF-Connecting-IP`, the access log's `client_ip`
     and the bouncer module both use the visitor's address. Header
     spoofing is not a concern, because only Cloudflare can reach 80 and
     443 (the `DOCKER-USER` rules). This option also keeps working if the
     CDN provider changes.
   - **At Cloudflare.** The Worker bouncer blocks at Cloudflare, but the
     free-plan quotas stop remediation once they are used up. The IP
     list route on Free (1 list, 10,000 items) has no maintained sync
     now that the old bouncer is archived.
3. **The firewall bouncer is for ports that are not behind the CDN.** On
   this host that is SSH, and only if SSH really is reachable on the
   public address. If Stage 0 confirms the repo's record (tailnet only),
   no public port is left for it to protect, and it is not installed.

Safety nets in every stage:

- The `crowdsecurity/cdn-whitelist` postoverflow drops any alert whose
  source is a Cloudflare address. It covers a missed `trusted_proxies`
  setting or a Cloudflare range change.
- An allowlist for the tailnet and the owner, in two layers:
  - a parser whitelist, so these addresses never reach scenarios;
  - a LAPI allowlist, so no decision or blocklist entry can name them.
- It covers:
  - the tailnet CGNAT range, the same range the Caddyfile admin matcher
    uses;
  - the owner's home connection (IPv4 and IPv6 prefix);
  - the owner's mobile carrier range, if one is wanted.
- Values are filled in on the host only and never committed here.

## 4. Layout

    Cloudflare --80/443 (Cloudflare ranges only, DOCKER-USER)--> caddy container
                                                                  | JSON access log
                                                                  v
                                       host dir /opt/stayz3ro/proxy/configs/caddy/logs
                                                                  | read-only bind
    host /var/log (auth.log) --read-only bind--------------------> crowdsec container
                                                                     engine + LAPI on the web network
                                                                     no host port in Stage 1
    Stage 2a: caddy (custom build with the bouncer module) --http://crowdsec:8080--> LAPI
    Stage 2b, only if SSH is public: host firewall bouncer --http://127.0.0.1:8080--> LAPI

The engine runs in a container, not on the host:

- It matches how every other service on this edge is run (compose files
  under `configs/`).
- It needs only read-only log mounts.
- It can be removed with one `docker compose down`.

What a container costs:

- The firewall bouncer, if used, still runs on the host and needs LAPI on
  host loopback.
- sshd logs are read from `/var/log/auth.log`, not journald, because the
  default image has no `journalctl`.
- The whole `/var/log` directory is mounted, not the single file. A single
  file bind mount keeps the old inode after logrotate replaces the file
  (unverified for this host's logrotate settings).

## 5. Memory and disk estimates

| Item | Estimate | Source |
|---|---|---|
| Engine memory | Under 100 MB in a small to medium setup, per the v1.5.0 FAQ; the older prerequisites page asks for 1 core and 100 MB of free RAM. Neither page renders on the current docs site, so both figures are unverified for v1.8.2. Planning figure (recommendation, not a measurement): under 256 MiB, with `mem_limit: 512m` as the ceiling | search index of https://doc.crowdsec.net/docs/v1.5.0/faq and https://doc.crowdsec.net/u/getting_started/pre_requisites, read 2026-11-15 |
| Engine image | 171.4 MB compressed (amd64); unpacked size unverified | Docker Hub tag API |
| Database | The older prerequisites page asks for 1 GB of free disk for the database | same as above, unverified for v1.8.2 |
| Firewall bouncer | Size not stated upstream | unverified |
| Custom Caddy build | Builder image 84.0 MB compressed plus the Go module download during the build; the final image size is unverified | Docker Hub tag API |
| Caddy logs | Unchanged: at most 10 x 10 MiB rolled files plus the current one | `configs/caddy/Caddyfile:22` to `:26` |

Stage 1 replaces the memory and disk estimates with measured values from
`docker stats` and `docker system df`.

## 6. Open decisions for the owner

1. **SSH exposure.** Stage 0 shows whether SSH answers on the public
   address. If it does not, Stage 2b is dropped. If it does, decide
   between closing it (the repo's recorded design) and protecting it
   with the firewall bouncer.
2. **Signal sharing.** Sharing with the Central API earns the roughly
   15 thousand IP community blocklist. Not contributing gives the Lite
   list of 3 thousand. Sharing sends the attacking addresses and scenario
   names from this edge to CrowdSec. Whether simulated alerts are shared
   is unverified (the docs only say they are kept out of the Console).
3. **Console enrollment.** Optional. The enrollment key would live in
   `configs/crowdsec/.env` on the host as `CROWDSEC_ENROLL_KEY`, never in
   this repo.
4. **Web remediation point.** At Caddy (the recommendation: works with
   any CDN, no quota) or at Cloudflare (blocks before the origin, but
   free-plan quotas and Cloudflare lock-in).
5. **Custom Caddy build.** Stage 2a replaces the official image with a
   locally built one. That image then has to be rebuilt by hand for every
   Caddy or module update, and the custom build would be the third
   image on this edge that is not an official tag.
6. **Fail2Ban.** Keep the `sshd` jail alongside CrowdSec, or retire it
   once the firewall bouncer covers SSH (only relevant if SSH is public).
7. **Owner addresses.** A home address that changes needs either a
   provider range or an update routine for both allowlist layers.
8. **Ban duration and scenarios.** Upstream defaults apply in Stage 2.
   Review them against the Stage 1 alert list before enabling.

## 7. Unverified, to check during the stages

- The live Caddy version (the compose file uses a rolling `caddy:2-alpine`
  tag) and whether it is at least v2.7.3.
- That `/var/log/auth.log` exists and rsyslog is active on the host.
- That host port 8080 on loopback is free (only needed for Stage 2b).
- The memory and disk figures in section 5.
- How the firewall bouncer cleans up its nftables tables when it stops.
- Whether `cscli simulation disable --global` is the exact inverse flag.
  Check with `cscli simulation disable --help`.
- How the Caddy bouncer behaves on a request while LAPI is down. The
  README does not say whether it fails open or closed.
