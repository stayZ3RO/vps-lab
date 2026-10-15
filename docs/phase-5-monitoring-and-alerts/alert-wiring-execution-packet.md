# Uptime Kuma alert wiring execution packet

Date prepared: 2026-09-28 (America/New_York). Executed 2026-09-28.
Preflight statements below describe the state before execution; the final
result is recorded in Stage 6 and `CURRENT-STATUS.md`.
Estimated hands-on time: 60 to 90 minutes, including the DOWN/UP test.
Scope: public-edge availability and certificate alerts only.

This packet is the execution form of the public-edge alert plan. It turns the
plan into a sequence you can run in one sitting with your own credentials. The
provider credentials (an ntfy token and topic, a Discord webhook) are entered
only in the Uptime Kuma UI and never written to this repo.

## 1. Purpose and scope

At preparation time, Uptime Kuma was deployed and reachable at
`https://status.stayz3ro.dev`, but it had no monitors or notification
providers. This packet wired:

- two notification providers: ntfy (push) and Discord (history)
- public-edge monitors only: public sites, the HTTPS edge, public DNS, and TLS
  certificate expiry
- a real, reversible DOWN/UP test so the wiring is proven, not assumed

Out of scope and explicitly not done here:

- no private, admin, or LAN endpoint monitor. Proxmox, Pi-hole, Grafana,
  Portainer, network-management interfaces, Docker admin ports, and every Kuma
  admin/API route stay unmonitored from this VPS.
- no inbound path from this VPS into the home LAN.
- no heartbeat (Push) monitor. The Caddy access-log exclusion that a Push
  token would require is a separate prerequisite and does not apply to this
  packet.
- no change to the internal LAN monitoring and alerting stack. It keeps its
  own receivers.
- no secret in Git. The ntfy token and topic, and the Discord webhook, live
  only in the Kuma UI (and the ntfy subscription on your phone).

## 2. What this changes vs what it does not

| This packet changes | This packet does not change |
|---|---|
| Adds two notification providers in Kuma | Changes Caddy, the compose stack, or firewall rules |
| Adds public-edge HTTP, TCP, and DNS monitors | Adds or exposes any port |
| Sets retry and resend values on those monitors | Touches the LAN monitoring stack or its receivers |
| Proves a real DOWN/UP notification path | Touches DNS records or certificates |
| Records the final wiring (no secrets) in this repo | Creates a public status page |

The VPS-side commands below are read-only. The only write actions are inside
the Kuma admin UI, plus the optional Discord channel creation in your own
Discord server.

## 3. Prerequisites you provide

- SSH access to `edge-vps` over Tailscale as the existing admin user,
  and the Kuma admin credentials.
- A Discord server where you can create a channel for public-edge alerts. The
  channel must be different from the one the LAN infrastructure stack posts
  to. This packet uses the name `#status-public` as the example.
- A Discord channel webhook URL. Create it in the channel settings. It is a
  secret; it is pasted only into Kuma.
- The self-hosted ntfy on the VPS, published at `https://ntfy.chrisalorenzo.com`
  with authentication on (deny-all default, per-client tokens). Kuma uses a
  dedicated write-only client token for its topic, and the phone subscribes
  read-only with its own token. The server is deployed by a separate packet.
  Until it is live, an `ntfy.sh` topic with a long random name is the interim
  fallback.
- About 60 to 90 minutes. The DOWN/UP test waits on retry timing, so keep the
  session open.

Generate an ntfy topic on the workstation (do not paste the result into any
file in this repo). The per-client ntfy token is created on the ntfy server
and is never recorded here.

```sh
openssl rand -hex 12
```

## 4. Preflight results (read-only, 2026-09-28 10:56 to 10:58 EDT)

These checks were run from a workstation against the live VPS. No change was
made. Commands that need `sudo` or the Kuma credentials were not run.

Commands (read-only):

```sh
ssh -o BatchMode=yes edge-vps 'hostname; uptime; id'
ssh -o BatchMode=yes edge-vps 'docker ps --format "{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
curl -sS -o /dev/null -w '%{http_code}\n' https://status.stayz3ro.dev/
```

For a repeat of the monitor and provider counts, run three narrow read-only
counts inside the container. Do not copy the database off the host.

```sh
ssh -o BatchMode=yes edge-vps 'docker exec -i uptime-kuma sqlite3 "file:/app/data/kuma.db?mode=ro"' <<'SQL'
select count(*) from monitor;
select count(*) from notification;
select count(*) from status_page;
SQL
```

Findings:

| Item | Result |
|---|---|
| Host | `edge-vps`, up 35 days, admin user in the `docker` group |
| Running containers | `caddy` (`caddy:2-alpine`, ports 80 and 443) and `uptime-kuma` (`louislam/uptime-kuma:1`, healthy, no published port) |
| Kuma application version | 1.23.17 |
| Existing monitors | none (0) |
| Existing notification providers | none (0) |
| Existing status pages | none (0) |
| Public edge | `https://status.stayz3ro.dev/` returns 302 into the Kuma UI |

Two current-state notes, flagged and not changed by this packet:

- **No public status page exists.** The `status_page` table is empty, so
  `status.stayz3ro.dev` currently serves the Kuma UI, not a status page.
  Creating one is optional and out of scope here.
- **Admin access hardening is tracked privately.** No further detail is
  recorded here.

What could not be checked read-only: the `.env` file, the Caddy runtime
configuration, firewall state, and anything behind `sudo`. None of those are
needed to run this packet.

## 5. Monitor plan

All targets are public hostnames already documented in this repo. No monitor
points at an admin route or a private address.

| Monitor name | Type | Target | Providers | Retries | Resend |
|---|---|---|---|---|---|
| `public-blog` | HTTP(s) | `https://stayz3ro.dev` | ntfy + Discord | 2 | 30 |
| `public-portfolio` | HTTP(s) | `https://chrisalorenzo.com` | ntfy + Discord | 2 | 30 |
| `public-status-edge` | HTTP(s) | `https://status.stayz3ro.dev` | ntfy + Discord | 2 | 30 |
| `public-edge-https` | TCP port | `status.stayz3ro.dev` port 443 | ntfy + Discord | 2 | 30 |
| `dns-stayz3ro` | DNS | `stayz3ro.dev` A | ntfy + Discord | 2 | 30 |
| `dns-chrisalorenzo` | DNS | `chrisalorenzo.com` A | ntfy + Discord | 2 | 30 |

Notes:

- Every monitor uses a 60-second interval, a 60-second retry interval, and
  retries `2`, so the alert fires after two consecutive failed checks, not on
  a single blip.
- Resend `30` re-notifies every 30 failed heartbeats while still down, about
  30 minutes at a 60-second interval. Set `0` to disable re-notify entirely if
  you prefer state-change-only alerts.
- `public-status-edge` watches Kuma's own public entry point. It proves the
  edge is answering, but a total VPS outage takes Kuma down with it and
  nothing alerts. The real answer to that is an independent offsite dead-man
  monitor, which is out of scope here (see section 11).
- A local script, `~/kuma-add-monitors.sh`, inserts the monitors with a
  stopped-container backup. It is not reproduced here.
- `blog.chrisalorenzo.com` is added after the domain move.
- An analytics monitor is added only after that record exists.
- Excluded on purpose: everything in the section 1 out-of-scope list.

### Certificate expiry

Kuma reports certificate expiry on its HTTP(s) monitors. Enable the expiry
notification on `public-blog`, `public-portfolio`, and `public-status-edge`
and set the warning threshold to 14 days. There is one limitation to know
about: Kuma assigns providers to a monitor, not to an event type, so those
three monitors send both DOWN and expiry notices to ntfy and Discord. If you
want the expiry warning on Discord only, add a second HTTP(s) monitor for the
same host with only the Discord provider assigned and leave the expiry notice
off the primary monitor. This packet defaults to the simpler single-monitor
form.

## 6. Notification provider plan

### ntfy (primary, actionable push)

- The ntfy server is self-hosted on the VPS at
  `https://ntfy.chrisalorenzo.com`, with authentication on: deny-all by
  default and a per-client token per sender.
- Kuma uses its own write-only client token for its topic. The phone
  subscribes read-only with a separate client token.
- Kuma reaches the server container to container over the internal Docker
  network, so an alert does not depend on public DNS, Cloudflare, or Caddy.
- Server URL and topic are separate fields in the Kuma ntfy form. The server
  URL must not contain the topic. Put the client token in the credential
  field, never in the URL.
- Interim fallback only: until the self-hosted server is live, an `ntfy.sh`
  topic with an unguessable name. The topic name is the only protection on a
  public `ntfy.sh` topic, so treat it as a secret.
- Set a high priority (5) for DOWN and a lower priority for recovery/expiry.
- Use Kuma's provider test button and confirm the push arrives on the phone.

### Discord (secondary, history)

- Create or select the public-edge channel (`#status-public` in this packet).
  It must be a different channel from the LAN infrastructure receiver so an
  external outage and an internal outage do not mix, and neither drowns the
  other.
- Paste the channel webhook URL only into the Kuma provider form.

### Email

Deferred. There is no SMTP relay on the VPS, and the plan treats email as a
third, critical-only channel that is not worth new infrastructure right now.

### Secret handling

- The ntfy topic and the Discord webhook are entered in the Kuma UI only.
  Kuma stores them in its own database on the VPS.
- Never put either value in this repo, a commit message, a shell command, a
  screenshot, a transcript, or shell history.
- This packet records that a provider exists and what it covers. It never
  records the value.

## 7. Relation to the LAN-side automation and alerting stack

The home LAN has its own alerting stack, with a Discord receiver today. The
self-hosted ntfy on the VPS is shared: Kuma uses it for public-edge alerts,
and the home automation stack uses it outbound for its own messages. Keep the
two paths distinct:

| | This packet (Kuma, external) | LAN automation stack |
|---|---|---|
| Vantage point | From the VPS, outside the LAN | From inside the LAN |
| Watches | Public sites, proxy, public DNS, certificates | Nodes, cluster, backups, HA DNS, containers |
| ntfy | The shared VPS server, its own topic and client token | The same VPS server, outbound, its own topic and client token |
| Discord | `#status-public` | Its existing channel |
| Direction | Outbound notifications only | Outbound to the VPS only, never reached from the VPS |

Rules that keep them from double-paging and from crossing the boundary:

- Use a dedicated ntfy topic and client token for Kuma, and a separate
  Discord channel, not the LAN stack's.
- The home automation stack reaches the VPS ntfy outbound. The VPS never
  opens a path into the LAN.
- Never monitor a LAN or admin endpoint from the VPS.
- The overlap is intentional only at the transport level. Separate topics,
  tokens, and channels keep the messages distinct.

## 8. Steps

Run the stages in order. Stop at a failed gate. Each stage lists its own
validation and rollback.

### Stage 0: open the private Kuma tunnel and record the baseline (5 minutes)

The private path is an SSH local port forward to the Kuma container, matching
the access method used at first-run. Get the container address, then tunnel.

```sh
KUMA_IP=$(ssh -o BatchMode=yes edge-vps \
  "docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' uptime-kuma")
echo "$KUMA_IP"
ssh -N -L "3001:${KUMA_IP}:3001" edge-vps
```

Leave the tunnel running and open `http://localhost:3001` in a browser. Run
the rest of the steps there, not on the public `status.stayz3ro.dev` hostname.
The container address can change if the container is recreated; re-run the
`docker inspect` line if the tunnel stops working.

Record the baseline in the admin UI: not a single monitor, provider, or status
page should be present.

- Gate: the UI opens over the tunnel and shows an empty monitor and
  notification list.
- Rollback: close the tunnel. Nothing changed.

### Stage 1: create the ntfy provider and test it (10 minutes)

1. In the private UI, open the notification settings and add a provider of
   type **ntfy**.
2. Label it `public-edge-ntfy`.
3. Enter `https://ntfy.chrisalorenzo.com` and the Kuma topic in their
   separate fields, and the Kuma client token in the credential field.
4. Set the DOWN priority to 5.
5. Save, then use the provider test action.
6. Subscribe the phone read-only to the same server and topic first, then run
   the test.

- Gate: the test push arrives on the phone and the UI reports success.
- Rollback: delete the `public-edge-ntfy` provider. It is not yet attached to
  any monitor, so nothing else changes.

### Stage 2: create the Discord provider and test it (10 minutes)

1. In Discord, create the `#status-public` channel (or select an existing
   dedicated public-edge channel that is not the LAN receiver).
2. Create a webhook for that channel.
3. In Kuma, add a provider of type **Discord**, label it
   `public-edge-discord`, and paste the webhook URL.
4. Save, then use the provider test action.

- Gate: the test message appears in the intended channel and the UI reports
  success.
- Rollback: delete the `public-edge-discord` provider. Leave the Discord
  channel in place or remove it if it was created only for this test and your
  Discord policy allows.

### Stage 3: create the monitors (20 minutes)

For each row in the section 5 table:

1. Add a new monitor.
2. Set the monitor type (HTTP(s), TCP port, or DNS) and the target.
3. Set the friendly name from the table.
4. Set the heartbeat interval to 60 seconds.
5. Set the retry interval to 60 seconds and retries to `2`.
6. Leave the monitor enabled.
7. For the three HTTP(s) monitors, enable the certificate expiry notification
   and set the threshold to 14 days.

Do not attach providers yet.

- Gate: every monitor shows UP, and no monitor targets a private address or
  an admin route. Re-open each monitor and confirm the saved interval, retry,
  and retry-interval values match section 5.
- Rollback: delete the monitors created in this stage. Because no provider is
  attached yet, no notification can have been sent.

### Stage 4: attach providers and set resend (10 minutes)

1. Edit each monitor and attach both `public-edge-ntfy` and
   `public-edge-discord`.
2. Set the resend value to `30` (or `0` for state-change-only alerts).
3. Save and reopen each monitor to confirm the assignments persisted.

- Gate: every public-edge monitor lists both providers, and the resend value
  is what you intended.
- Rollback: remove the provider assignments and confirm no monitor references
  either provider before deleting them.

### Stage 5: prove a real DOWN and UP notification (15 to 20 minutes)

Provider test buttons prove delivery. They do not prove monitor state
transitions. This stage uses a temporary monitor and a reserved, non-routable
public failure target. It does not stop any service.

1. Create a temporary monitor named `synthetic-alert-test`, type HTTP(s),
   target `https://example.com`, interval 60 seconds, retries `2`, resend `0`,
   with both providers attached.
2. Wait until it shows UP.
3. Change only its target to `https://example.invalid/`. Do not stop Caddy,
   Kuma, or any service.

- Gate: after the retry threshold, the monitor goes DOWN and both ntfy and
  Discord receive a DOWN notification. The first alert must not arrive before
  the configured two failed checks.
4. Restore the target to `https://example.com` and wait for UP.

- Gate: both destinations receive one recovery notification and no repeated
  "still up" messages.
- Rollback: restore the target, pause or delete `synthetic-alert-test`, and
  confirm the production monitors are unchanged.

### Stage 6: record the final state (done 2026-09-28)

Live state on 2026-09-28, recorded without secrets:

- Six monitors: `public-blog`, `public-portfolio`, and `public-status-edge`
  (HTTP(s), with certificate expiry notices), `public-edge-https` (TCP port
  443), `dns-stayz3ro`, and `dns-chrisalorenzo` (DNS A). Interval 60 seconds,
  retries 2, retry interval 60 seconds, resend 30.
- One notification provider live: Discord, `public-edge-discord`, attached to
  all six monitors.
- A synthetic DOWN/UP test passed on 2026-09-28: the monitor went DOWN after
  the retry threshold and one recovery message arrived. The synthetic monitor
  was removed afterwards.
- ntfy was pending at this stage; the separate ntfy packet was executed later
  on 2026-09-28.

Record only non-secret values. Never record the ntfy topic or token, the
Discord webhook, or any account identifier. Update `CURRENT-STATUS.md` and the
Phase 5 summary with the same non-secret set.

- Gate: another admin can reproduce the wiring from the record alone, and a
  search of the recorded text finds no secret.
- Rollback: none. This is documentation after the live change.

## 9. Rollback

- Provider wiring: remove provider assignments from every monitor first,
  confirm no monitor references a provider, then delete the provider.
- Monitors: delete the public-edge monitors created here. The instance started
  empty, so a full rollback returns it to empty.
- Synthetic test: restore its target, then pause or delete it.
- Discord channel: remove it only if it was created for this packet and your
  Discord policy allows. Otherwise leave it unused.
- Do not run `docker compose down` for an alert rollback. It is unnecessary and
  stops the whole edge.

## 10. What each test does and does not prove

- A provider test proves the credential and the destination path work.
- A real DOWN/UP transition proves the monitor state machine, the retry
  threshold, and both providers end to end.
- Neither proves that a full VPS outage can alert. Kuma and Caddy share the
  VPS failure domain, so an outage that takes the VPS down takes the watcher
  with it.

## 11. Failure domain and the offsite follow-up (out of scope)

The one real gap this packet leaves open: if the VPS itself goes down, Kuma
cannot report it. The fix is an independent offsite dead-man monitor that
expects a periodic check-in and alerts when the check-in stops. That is a
separate design and a separate packet. Note it against Phase 5 and do not
bolt it onto this one.

## 12. Open questions and decisions

1. **Discord target.** One shared server with a new `#status-public` channel,
   or a dedicated server for public-facing alerts. Confirm the channel.
2. **Email.** Deferred in this packet. Confirm it stays deferred.
3. **Expiry routing.** Kuma cannot route expiry notices to Discord only on the
   same monitor. Accept both providers for expiry, or add a duplicate
   warning-only monitor. Confirm which.
4. **Public status page.** None exists. Decide separately whether to create
   one, and whether it should list only these public-edge monitors.

## 13. Evidence and screenshots

Capture only after a result is verified. Redact before saving:

1. Provider list: labels and types only; blur the ntfy topic, any credential,
   and the Discord webhook.
2. ntfy provider form: server host, label, and non-secret priority. Blur the
   topic and any credential.
3. Discord provider form: type and label only. Blur the webhook, channel IDs,
   and account data.
4. Monitor list: names, types, and UP/DOWN state. Blur any URL parameter that
   could carry a secret.
5. Retry and resend settings: interval, retry interval, retries, resend.
6. DOWN event: the Kuma timeline and the received ntfy and Discord messages.
   Blur the topic, webhook, user names, and message IDs.
7. UP event: the matching recovery evidence with the same redactions.
8. The private tunnel must not appear in any screenshot. Do not capture login
   fields, browser-saved credentials, or the tunnel command.

Also apply the Phase 3 redaction rules: no public IP addresses, no Tailscale
addresses, no workstation hostname, no ACME account email, and no provider
account data.

## 14. Source

Derived from the internal public-edge alert plan and its read-only review.
This packet is the `vps-lab` execution form; the internal planning notes stay
in a private operations repository and are not reproduced here.
