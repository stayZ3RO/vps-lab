# Phase 4: Umami Deployment

## Purpose

Deploy Umami with a public tracker at `a.chrisalorenzo.com` and tailnet-only
admin access. Caddy passes `/script.js` and `/api/send` to Umami. Every other
public path returns 404. Docker publishes the admin listener on loopback, and
Tailscale Serve exposes it to tailnet devices on port 8444.

Deployment was recorded on 2026-10-14 in [CHANGELOG.md](../../CHANGELOG.md#2026-10-14-umami-deployed-public-record-proxied).
This is the current implementation guide. The [archived re-scope draft](../archive/umami-rescope-DRAFT-2026-10-12.md)
preserves the earlier proposal, including DNS assumptions superseded below.
The public DNS record belongs in the `chrisalorenzo.com` zone and must be
proxied: origin HTTP/HTTPS accepts Cloudflare ranges only.

## Deployment order

| Step | Task |
|---|---|
| 1 | Check prerequisites and stage the Umami files |
| 2 | Create the private `.env` file |
| 3 | Validate and start the stack |
| 4 | Enable tailnet admin access and change the default password |
| 5 | Install and run the daily database backup timer |
| 6 | Add the public DNS record |
| 7 | Enable the Caddy tracker route |
| 8 | Validate public paths and add a monitor |
| 9 | Add the tracker script to the intended websites |

Run host commands over the existing tailnet SSH connection. Do not pull or
switch branches in the live checkout.

## Step 1: Check prerequisites and stage files

The proxy stack must be running and the external Docker network `web` must
exist. Check both and confirm there is enough memory for Umami and PostgreSQL.

From a clean workstation checkout, set the existing SSH alias and copy the
Umami files:

```sh
DEPLOY_ALIAS=your-existing-tailnet-ssh-alias
ssh "$DEPLOY_ALIAS" 'mkdir -p /opt/stayz3ro/proxy/configs/umami'
scp configs/umami/docker-compose.yml configs/umami/.env.example \
  configs/umami/backup-umami.sh configs/umami/umami-backup.service \
  configs/umami/umami-backup.timer \
  "$DEPLOY_ALIAS:/opt/stayz3ro/proxy/configs/umami/"
```

On the host, confirm the proxy and network are present:

```sh
cd /opt/stayz3ro/proxy/configs/caddy
docker compose ps
docker network ls --filter name=web
free -h
```

## Step 2: Create the private environment file

```sh
cd /opt/stayz3ro/proxy/configs/umami
cp .env.example .env
chmod 600 .env
nano .env
```

Set `POSTGRES_PASSWORD` to a long random hex value, for example from
`openssl rand -hex 32`. Set `APP_SECRET` from `openssl rand -base64 32`.
Keep `.env` on the host and out of git.

## Step 3: Validate and start the stack

```sh
docker compose config --quiet
docker compose up -d
docker compose ps
docker compose logs --tail=40 umami
docker port umami
```

Expected: `umami` is running, `umami-db` is healthy, the logs show successful
startup, and `docker port umami` reports `127.0.0.1:3000`. There must be no
published database port. The database health check gates Umami startup.

## Step 4: Enable tailnet admin access

The dashboard must be claimed before creating the public DNS record or
enabling the public Caddy route.

On the host:

```sh
tailscale serve --bg 8444 http://127.0.0.1:3000
tailscale serve status
```

From a tailnet device, open the HTTPS URL shown by `tailscale serve status`
with port 8444. Sign in with the initial `admin` / `umami` credentials and
change the password immediately. Confirm the login works again after an
Umami container restart.

## Step 5: Install and run the daily database backup

The script writes a custom-format `pg_dump` to
`/opt/stayz3ro/backups/umami` each day at 03:30 UTC. It keeps 14 days of local
dumps and matching SHA-256 sidecars. It checks the dump with `pg_restore --list`
before promotion and removes partial files if a command fails.

On the host:

```sh
cd /opt/stayz3ro/proxy/configs/umami
sudo install -o root -g root -m 0750 backup-umami.sh /usr/local/sbin/umami-backup.sh
sudo install -o root -g root -m 0644 umami-backup.service /etc/systemd/system/umami-backup.service
sudo install -o root -g root -m 0644 umami-backup.timer /etc/systemd/system/umami-backup.timer
sudo systemctl daemon-reload
sudo systemctl enable --now umami-backup.timer
sudo systemctl start umami-backup.service
sudo systemctl status --no-pager umami-backup.service
sudo ls -l /opt/stayz3ro/backups/umami
```

Confirm a dump exists and `systemctl list-timers umami-backup.timer` shows the
next run. Verify the newest checksum from the backup directory with
`sha256sum -c umami-<UTC-date>.dump.sha256`. Add the dump directory to the
offsite backup source list when that backup is available.

## Step 6: Add the public DNS record

In the Cloudflare `chrisalorenzo.com` zone, add an `A` record named `a` with
the VPS public IPv4 address and **proxied** status (orange cloud). Do not add
a record to the redirect-only zone.

```sh
dig +short a.chrisalorenzo.com
```

Confirm the record in Cloudflare contains the configured origin address and
proxying is enabled. Public DNS should return Cloudflare edge addresses, not
the origin. A DNS-only record cannot pass the origin firewall and prevents
visitors and the ACME challenge from reaching Caddy. Verify HTTPS in Step 8.

## Step 7: Enable the public tracker route

Edit the Caddyfile in place so the existing bind mount keeps its inode. Remove
the comment markers from the `a.chrisalorenzo.com` block only. Leave the path
matcher and fallback 404 handler intact.

Validate before restarting Caddy:

```sh
cd /opt/stayz3ro/proxy/configs/caddy
docker run --rm -v "$PWD/Caddyfile:/etc/caddy/Caddyfile:ro" \
  --env-file .env caddy:2-alpine \
  caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
```

The Caddy admin API is disabled in this stack, so apply the validated file
with a container restart:

```sh
docker restart caddy
```

The restart briefly interrupts the public proxy routes. Caddy obtains the
certificate for `a.chrisalorenzo.com` on the first HTTPS request.

## Step 8: Validate public paths and add a monitor

From a workstation:

```sh
curl -sS -o /dev/null -w '%{http_code} %{content_type}\n' https://a.chrisalorenzo.com/script.js
curl -sS -o /dev/null -w '%{http_code}\n' https://a.chrisalorenzo.com/
curl -sS -o /dev/null -w '%{http_code}\n' https://a.chrisalorenzo.com/login
curl -sS -o /dev/null -w '%{http_code}\n' https://a.chrisalorenzo.com/api/websites
```

Expected: `/script.js` returns 200 with a JavaScript content type. The root,
login, and website-management paths return 404. Confirm in browser developer
tools that page collection uses `/api/send`. If a future tracker feature adds
a public path, add only that required path to the Caddy matcher.

In Uptime Kuma, add an HTTPS monitor for
`https://a.chrisalorenzo.com/script.js`. The root path deliberately returns
404 and is not a valid monitor target.

## Step 9: Add the tracker to the intended websites

Add the Umami script tag to each site's page head, using its website ID and
the public tracker host:

```html
<script defer src="https://a.chrisalorenzo.com/script.js"
        data-website-id="..."
        data-domains="example.com,www.example.com"></script>
```

Allow `https://a.chrisalorenzo.com` in each site's Content Security Policy.
Check that a normal page view appears in Umami and that a page preview with an
unlisted hostname sends no event. Set the intended analytics retention period
and decide how to exclude your own visits before evaluating totals.

## Rollback

Comment out the public Caddy block, validate the Caddyfile, and restart Caddy.
Confirm the other public sites recover. The tracker host stops serving Umami;
clients may get a TLS error before receiving an HTTP response because the
Caddy site block is gone. The DNS record can be removed separately.

To stop scheduled backups, run `sudo systemctl disable --now umami-backup.timer`.
Keep the database volume and existing dumps unless the data is deliberately
being discarded. Do not use `docker compose down -v` as a routine rollback.

## Phase result

The public host serves the tracker script and collection endpoint only. The
Umami dashboard is available through Tailscale Serve on the loopback-backed
listener. PostgreSQL has no published port, startup waits for database health,
and the provided backup tooling writes custom-format dumps under
`/opt/stayz3ro/backups/umami` once installed. The deployment record confirms
the stack and certificate; [validation.md](validation.md) separates that
record from checks still needing execution evidence.
