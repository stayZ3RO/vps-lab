# Self-hosted ntfy execution packet

Date prepared: 2026-09-28 (America/New_York). Executed 2026-09-28.
Preflight results below are a historical snapshot from before ntfy went live;
the current outcome is recorded in `CURRENT-STATUS.md`.
Estimated hands-on time: 60 to 75 minutes, plus a few minutes for DNS and the
first certificate.

## 1. Purpose and scope

Run one private ntfy server on `edge-vps`, published at
`https://ntfy.chrisalorenzo.com` through the existing Caddy container, and
move Uptime Kuma's `public-edge-ntfy` provider from the interim `ntfy.sh`
topic to it.

Design decisions:

- **Private instance.** `auth-default-access: deny-all`, no sign-up, no web
  app. Every sender and every phone has its own user. Senders are write-only
  on their topic, and the phone user is read-only.
- **Kuma publishes container to container** (`http://ntfy` on the `web`
  Docker network), not through the public URL. The publish then does not
  depend on public DNS, Cloudflare, or Caddy. If the edge is broken, Kuma still
  hands the alert to ntfy, which caches it (24 hours) and delivers it when
  phones reconnect. Access control is the same on both paths: the internal
  path still needs Kuma's token.
- **Cloudflare record is DNS-only (grey cloud).** Subscribers hold long-lived
  HTTP streams and WebSocket connections. The Cloudflare proxy can buffer
  streamed responses and would terminate TLS, so it would see message content.
  ntfy's own proxy guidance (v2.28.0 config docs) covers nginx, Apache and
  Caddy with buffering off, and has no Cloudflare-specific setup. Caddy
  already terminates TLS with its own certificate, and `status.stayz3ro.dev`
  is DNS-only the same way.
- **Later senders go out, never in.** The home lab's workflow automation and
  Alertmanager will publish over HTTPS to this server. Nothing on the VPS
  connects into the home LAN.

Out of scope: changing firewall rules (80/443 are already open for Caddy, and
ntfy publishes no port), email or SMS notifications, and any home-lab change
(section 9 describes the follow-up only).

## 2. What this changes vs what it does not

| This packet changes | This packet does not change |
|---|---|
| Adds a DNS-only `A` record `ntfy.chrisalorenzo.com` in Cloudflare | Any other DNS record or the Cloudflare proxy setting of other records |
| Adds an `ntfy` container (pinned image, two volumes, no published port) on the `web` network | UFW, published ports, SSH, or the `uptime-kuma` container |
| Adds one site block to the live Caddyfile and restarts Caddy once | Other Caddy site blocks, TLS settings, or the Caddy image |
| Creates ntfy users, access rules, and tokens (stored only in the ntfy volume) | Any secret in this repo |
| Switches Kuma's `public-edge-ntfy` provider to the new server | Kuma monitors, the Discord provider, or retry settings |

## 3. Prerequisites you provide

- SSH to `edge-vps` over Tailscale as the existing admin user (in the
  `docker` group; no `sudo` is needed for any step).
- Cloudflare dashboard access for `chrisalorenzo.com`.
- A password manager entry for: the ntfy admin password, the `phone` user
  password, and one token each for `kuma`, `automation` and `alertmanager`.
  Tokens are shown once, at creation.
- The ntfy app on the phone (Android: F-Droid or Play Store; iOS: App Store).
- The Kuma admin login, and the interim `ntfy.sh` topic kept in the password
  manager for rollback.
- A local clone of this repo at the merged commit.

## 4. Preflight results (read-only, 2026-09-28)

Run from a workstation with `ssh -o BatchMode=yes edge-vps`. No change
was made. No config file was printed, only container labels, mount paths, site
block names, and sizes.

| Item | Result |
|---|---|
| Compose project | `caddy`, working dir `/opt/stayz3ro/proxy/configs/caddy`, file `docker-compose.yml` there (services `caddy`, `uptime-kuma`) |
| Docker network | `caddy` and `uptime-kuma` on the `web` bridge network |
| Caddy | v2.11.4, image `caddy:2-alpine`, ports 80/443 (TCP) and 443/UDP; Caddyfile bind-mounted read-only from `/opt/stayz3ro/proxy/configs/caddy/Caddyfile`; certificates in volume `caddy_caddy_data` |
| Live site blocks | `status.{$SITE_DOMAIN}` only (analytics and others are commented) |
| Caddy admin API | `admin off` in the live Caddyfile, so `caddy reload` cannot work; this packet restarts the container instead |
| Uptime Kuma | 1.23.17, no published port |
| ntfy | not present |
| Disk / memory | 232 GB free on `/`; 7.1 GB memory available |
| UFW | enabled (`ENABLED=yes`); rule list needs `sudo` and was not read |
| Deploy directory | `/opt/stayz3ro/proxy` is an older checkout of this repo from before its history was rewritten, so `git pull` there is not safe. This packet copies the two new files and edits the Caddyfile in place, with a backup. |
| DNS | `chrisalorenzo.com` NS are Cloudflare; `ntfy.chrisalorenzo.com` has no A, AAAA or CNAME record yet; `status.stayz3ro.dev` has an A record and no AAAA |

Checked offline on 2026-09-28: `configs/ntfy/server.yml` and every ntfy
command in this packet ran against the ntfy v2.28.0 release binary, and the
ntfy site block passed `caddy validate` on Caddy v2.11.4.

## 5. Set these once

Paste at the start of every workstation shell used below.

```sh
NTFY_HOST=ntfy.chrisalorenzo.com
VPS=edge-vps
DEPLOY_DIR=/opt/stayz3ro/proxy/configs          # from the compose labels in section 4
REPO="$HOME/github/vps-lab"                      # local clone of this repo at the merged commit
test -f "$REPO/configs/ntfy/server.yml" || echo "set REPO to the local clone first"
```

## 6. Stages

### Stage 1: DNS record (5 min)

```sh
VPS_IPV4=$(dig +short status.stayz3ro.dev A)     # same VPS, already published
echo "$VPS_IPV4"
```

In Cloudflare, open `chrisalorenzo.com` > DNS > Records > Add record:
type `A`, name `ntfy`, IPv4 = the value printed above, proxy status **DNS
only**, TTL Auto. Save.

Gate:

```sh
dig +short "$NTFY_HOST" A @1.1.1.1              # must equal $VPS_IPV4
```

Rollback: delete the `ntfy` record in Cloudflare.

### Stage 2: deploy ntfy (10 min)

```sh
ssh -o BatchMode=yes "$VPS" "install -d -m 0755 $DEPLOY_DIR/ntfy"
scp "$REPO/configs/ntfy/docker-compose.yml" "$REPO/configs/ntfy/server.yml" "$REPO/configs/ntfy/README.md" "$VPS:$DEPLOY_DIR/ntfy/"
ssh -o BatchMode=yes "$VPS" "cd $DEPLOY_DIR/ntfy && docker compose config --quiet && docker compose up -d && sleep 15 && docker compose ps"
ssh -o BatchMode=yes "$VPS" "docker exec ntfy wget -q -O- http://localhost:80/v1/health; echo; docker inspect ntfy --format '{{.Config.Image}} {{.State.Health.Status}}'"
```

Gate: `{"healthy":true}`, the image is `binwiederhier/ntfy:v2.28.0` pinned to
digest `sha256:6ef4b819f722fccdc036af611c4774cfdc2de821ab74fdd48bbf4c9d6f8973da`,
and the health status is `healthy` (after about a minute).
`docker network inspect web --format '{{range .Containers}}{{.Name}} {{end}}'`
lists `ntfy` next to `caddy` and `uptime-kuma`.

Rollback: `ssh -o BatchMode=yes "$VPS" "cd $DEPLOY_DIR/ntfy && docker compose down"`
(keeps the volumes). Only when abandoning the server for good:
`docker compose down -v`, which deletes the auth database and cache.

### Stage 3: users, access rules and tokens (15 min)

These prompt for passwords, so run them in an interactive session. Passwords
are typed at the prompts. Each token is printed once: copy it straight into
the password manager, and do not paste it into any file.

```sh
ssh -tt "$VPS"
```

On the VPS:

```sh
docker exec -it ntfy ntfy user add --role=admin admin      # prompts for the admin password
docker exec -it ntfy ntfy user add kuma                   # prompts; password is not used after the token exists
docker exec -it ntfy ntfy user add automation
docker exec -it ntfy ntfy user add alertmanager
docker exec -it ntfy ntfy user add phone                  # the phone signs in with this user and password

docker exec ntfy ntfy access kuma edge-alerts write-only
docker exec ntfy ntfy access automation lab-alerts write-only
docker exec ntfy ntfy access alertmanager lab-alerts write-only
docker exec ntfy ntfy access phone edge-alerts read-only
docker exec ntfy ntfy access phone lab-alerts read-only

docker exec ntfy ntfy token add --label=kuma kuma                   # copy the tk_ value to the password manager
docker exec ntfy ntfy token add --label=automation automation
docker exec ntfy ntfy token add --label=alertmanager alertmanager
clear
docker exec ntfy ntfy access                                          # review: no token values are shown
exit
```

ntfy tokens carry the full rights of their user, which is why every sender
gets its own user with rights on one topic only.

Gate: `ntfy access` lists `admin` (all topics), `kuma` write-only on
`edge-alerts`, `automation` and `alertmanager` write-only on `lab-alerts`,
`phone` read-only on both, and anonymous with no access.

Rollback (on the VPS). Remove a user together with its tokens and rules:

```sh
NTFY_USER=kuma                  # the user to remove: kuma, automation, alertmanager or phone
docker exec ntfy ntfy user del "$NTFY_USER"
```

Revoke a user's tokens without printing them (`token list` shows full
values, so the output goes into a variable):

```sh
NTFY_USER=kuma
for t in $(docker exec ntfy ntfy token list "$NTFY_USER" | grep -oE 'tk_[a-z0-9]+'); do
  docker exec ntfy ntfy token remove "$NTFY_USER" "$t"
done
docker exec ntfy ntfy token list "$NTFY_USER" | grep -c 'tk_'          # 0
```

### Stage 4: Caddy site block (10 min)

The block is staged (commented) in `configs/caddy/Caddyfile` in this repo. On
the VPS it is appended to the live file, so the bind mount keeps the same
file. Back up first.

```sh
ssh -tt "$VPS"
```

On the VPS:

```sh
cd /opt/stayz3ro/proxy/configs/caddy
STAMP=$(date +%Y%m%d-%H%M%S)
cp -p Caddyfile "Caddyfile.bak-$STAMP"
cat >> Caddyfile <<'EOF'

# ntfy.chrisalorenzo.com -> self-hosted ntfy (Phase 5, enabled per packet Stage 4)
ntfy.chrisalorenzo.com {
	import security_headers
	# ntfy's metrics listener is off; refuse the path at the edge anyway.
	respond /metrics 404
	reverse_proxy ntfy:80 {
		# Send subscriber streams (JSON stream, SSE) without buffering.
		flush_interval -1
	}
}
EOF
docker exec caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
docker restart caddy
sleep 10
docker logs --since 2m caddy 2>&1 | grep -E 'certificate obtained|ntfy.chrisalorenzo.com' | tail -5
exit
```

`admin off` means Caddy cannot reload in place, so the restart briefly drops
the public sites (`status.stayz3ro.dev` included) for a few seconds.
The first request for the new name gets its certificate from Let's Encrypt.

Gate (from the workstation):

```sh
curl -sS "https://$NTFY_HOST/v1/health"; echo                       # {"healthy":true}
curl -sS -o /dev/null -w '%{http_version} %{http_code}\n' "https://$NTFY_HOST/v1/health"   # 2 200 (HTTP/2)
curl -sS -o /dev/null -w '%{http_code}\n' "https://status.stayz3ro.dev/"                   # existing site still up
```

Rollback (on the VPS, in the same directory):

```sh
cp -p "$(ls -t Caddyfile.bak-* | head -1)" Caddyfile
docker exec caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
docker restart caddy
```

### Stage 5: validation (10 min)

From the workstation. The token is read at a hidden prompt and cleared after.

```sh
curl -sS -o /dev/null -w 'root %{http_code}\n'          "https://$NTFY_HOST/"                       # 404: no web app
curl -sS -o /dev/null -w 'metrics %{http_code}\n'       "https://$NTFY_HOST/metrics"                # 404
curl -sS -o /dev/null -w 'anon publish %{http_code}\n'  -d test "https://$NTFY_HOST/edge-alerts"     # 403
curl -sS -o /dev/null -w 'anon read %{http_code}\n'     "https://$NTFY_HOST/edge-alerts/json?poll=1" # 403
read -rsp 'kuma token: ' NTFY_TOKEN; echo
curl -sS -o /dev/null -w 'kuma publish %{http_code}\n'  -H "Authorization: Bearer $NTFY_TOKEN" -d 'ntfy packet test' "https://$NTFY_HOST/edge-alerts"   # 200
curl -sS -o /dev/null -w 'kuma wrong topic %{http_code}\n' -H "Authorization: Bearer $NTFY_TOKEN" -d x "https://$NTFY_HOST/lab-alerts"             # 403
curl -sS -o /dev/null -w 'kuma read %{http_code}\n'     -H "Authorization: Bearer $NTFY_TOKEN" "https://$NTFY_HOST/edge-alerts/json?poll=1"         # 403
unset NTFY_TOKEN
```

Gate: every line prints the code in its comment. These results matched a run
of the same commands against the v2.28.0 binary on 2026-09-28.

### Stage 6: phone subscription (10 min)

In the ntfy app: Settings > Manage users > add server
`https://ntfy.chrisalorenzo.com`, user `phone`, and the `phone` password.
Then subscribe to `edge-alerts` and `lab-alerts` on that server (Use another
server: `https://ntfy.chrisalorenzo.com`).

- Android: instant delivery works directly (the app keeps a connection open).
- iOS: instant push for a self-hosted server needs an upstream relay. ntfy.sh
  then receives only a poll request with the message ID, and the message
  content stays on the VPS. Skip this if no iPhone subscribes. On the VPS:

  ```sh
  cd /opt/stayz3ro/proxy/configs/ntfy
  sed -i 's|^# upstream-base-url: "https://ntfy.sh"|upstream-base-url: "https://ntfy.sh"|' server.yml
  grep -n '^upstream-base-url' server.yml
  docker compose up -d --force-recreate
  ```

  `sed -i` writes a new file, and the container's single-file bind mount would
  keep the old one, so the container is recreated rather than restarted.

Gate: re-run the `kuma publish` line from Stage 5; the message arrives on the
phone within a few seconds.

Rollback: remove the subscriptions and the server entry in the app.

### Stage 7: add the ntfy provider in Kuma (5 min)

In Kuma (`https://status.stayz3ro.dev`): Settings > Notifications > Setup
Notification:

1. Notification Type: ntfy. Friendly Name: `public-edge-ntfy`.
2. Server URL: `http://ntfy` (plain HTTP to the container on the `web`
   network; `https://ntfy` fails with ECONNREFUSED on 443).
3. Topic: `edge-alerts`. Priority: 5.
4. Authentication: Access Token with the `kuma` token, or Username and
   Password with the `kuma` user. Both carry the same rights. The live setup
   uses username and password.
5. Default enabled and Apply on all existing monitors: on.
6. Test. The test message must arrive on the phone. Then Save.

Gate: the Test notification arrives, and the next real DOWN/UP (or a forced
one, as in the alert wiring packet) arrives through the new server.

Rollback: delete `public-edge-ntfy` in Kuma. Discord stays attached to every
monitor.

## 7. Monitoring the new server

Add one Kuma HTTP monitor for `https://ntfy.chrisalorenzo.com/v1/health`
(keyword `healthy`), attached to the Discord provider only. That way a broken
ntfy still alerts through a channel that does not depend on it.

## 8. Failure domain

ntfy runs on the same VPS as Kuma. If the whole VPS is down, neither alerts.
That case needs an outside check (for example the planned second vantage). It
is not solved by this packet. The Discord provider stays configured as the
second path for edge alerts.

## 9. Follow-up for the home lab (describe only, not part of this packet)

- If workflow automation still has an old ntfy sender configuration, point its
  ntfy base URL at
  `https://ntfy.chrisalorenzo.com`, set its token to the `automation` token
  (from the password manager, in that deployment's secret store), publish to
  `lab-alerts`, and remove the bundled ntfy service. Phones then use one
  server for everything.
- Alertmanager: add a webhook receiver with URL
  `https://ntfy.chrisalorenzo.com/lab-alerts?template=alertmanager` (ntfy's
  built-in Alertmanager template, confirmed on v2.28.0) and
  `http_config.authorization` of type `Bearer`, with `credentials_file`
  pointing at a root-only file that holds the `alertmanager` token.
- Both are outbound HTTPS from the lab to the VPS. No inbound port, tunnel or
  route into the LAN is added.

## 10. Record after running

Add to `CURRENT-STATUS.md` in a separate change: the date, the ntfy version and
digest, the DNS record (name only), the users created (names only, no tokens),
the Kuma provider switch time, and the Stage 5 results. Remove the Caddyfile
backup after a week of normal operation.
