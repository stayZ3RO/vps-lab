# CrowdSec on the public edge: owner-run steps

Status: draft, prepared 2026-11-15. Not executed. Every command runs on the
VPS over Tailscale SSH unless a step says otherwise. Placeholders in angle
brackets are filled in at the terminal and never committed.

Secrets in this design and where they live:

| Secret | Lives in | Never in |
|---|---|---|
| Caddy bouncer key | `configs/crowdsec/.env` as `CROWDSEC_CADDY_BOUNCER_KEY`, and the same value in `configs/caddy/.env` as `CROWDSEC_API_KEY`, both mode 600 on the host | this repo, shell history, chat |
| Firewall bouncer key (Stage 2b only) | `configs/crowdsec/.env` as `CROWDSEC_FW_BOUNCER_KEY`, and `/etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml.local` mode 600 | same |
| Console enrollment key (optional) | `configs/crowdsec/.env` as `CROWDSEC_ENROLL_KEY` | same |
| Owner addresses | `/opt/stayz3ro/crowdsec-local/edge-allowlist.yaml` (host only) and the LAPI allowlist | this repo |

Keys are generated with `openssl rand` straight into those files and are
never printed.

Deploy paths follow the earlier phases: the repo checkout is
`/opt/stayz3ro/proxy`, so Caddy lives in `/opt/stayz3ro/proxy/configs/caddy`
and this design in `/opt/stayz3ro/proxy/configs/crowdsec`.

## Stage 0: read-only preflight

Nothing changes in this stage. Record each output in
[validation.md](validation.md).

    docker exec caddy caddy version
    ls -l /var/log/auth.log && systemctl is-active rsyslog
    sudo ss -ltnp | grep -E ':8080\b' || echo "8080 free"
    free -h
    df -h /var/lib/docker
    sudo iptables -S DOCKER-USER > ~/docker-user-before-crowdsec.txt
    wc -l ~/docker-user-before-crowdsec.txt

From a device that is not on the tailnet, for example a phone hotspot,
check whether SSH answers on the public address:

    nc -vz -w 5 <PUBLIC_ADDRESS> 22

Pass lines:

- `caddy version` reports v2.7.3 or later (the Caddy bouncer module and
  the `client_ip` log field need it).
- `/var/log/auth.log` exists and rsyslog is `active`. If not, use the
  journald variant in `configs/crowdsec/acquis.d/sshd-journald.yaml.example`
  with the `-debian` image.
- The `nc` result is recorded. A timeout matches the repo record (SSH
  tailnet only), so Stage 2b is dropped. A connection means SSH is public,
  and decision 1 in [overview.md](overview.md) section 6 applies.

## Stage 1: detect only, one week

Goal: the engine reads the Caddy and sshd logs and raises alerts. Nothing
is blocked: no bouncer is registered, and global simulation is on.

### 1.1 Make Caddy log the real client

    cd /opt/stayz3ro/proxy/configs/caddy
    cp -p Caddyfile "Caddyfile.bak-crowdsec-$(date -u +%Y%m%dT%H%M%SZ)"
    ranges=$( { curl -fsS https://www.cloudflare.com/ips-v4/; echo; curl -fsS https://www.cloudflare.com/ips-v6/; echo; } | xargs )
    echo "$ranges" | wc -w

Edit `Caddyfile` and add this block inside the global options braces, right
after `admin off`. Paste the value of `$ranges` in place of the placeholder.
The example is also in `configs/crowdsec/caddy/trusted-proxies.snippet.example`.

    	servers {
    		trusted_proxies static <CLOUDFLARE_RANGES>
    		client_ip_headers CF-Connecting-IP
    	}

Validate, then restart (the admin API is off, so restart is the reload):

    docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile &&
      docker restart caddy

Load the status page once from outside the tailnet, then:

    tail -n 1 logs/access.log | python3 -c 'import sys,json; r=json.loads(sys.stdin.read())["request"]; print("remote", r.get("remote_ip"), "client", r.get("client_ip"))'

Pass lines:

- `validate` exits 0 and `docker ps` shows `caddy` up.
- In the last log line, `remote` is a Cloudflare address and `client` is
  the address of the device that loaded the page.
- From outside the tailnet, `https://kuma.chrisalorenzo.com` and
  `https://umami.chrisalorenzo.com` still answer 403. Over the tailnet they
  still load. Their gate uses `remote_ip`, which ignores `trusted_proxies`.
- Every Uptime Kuma monitor stays green, and `ntfy-health` stays up.

Side effect to watch: Caddy now passes on Cloudflare's `X-Forwarded-For`
instead of replacing it, so ntfy (`behind-proxy: true`) sees the visitor
and not the Cloudflare node. This is the intended direction for its visitor
rate limits. Confirm a test notification still reaches the phone.

### 1.2 Host-only allowlist and environment

    sudo install -d -m 700 /opt/stayz3ro/crowdsec-local
    sudo cp /opt/stayz3ro/proxy/configs/crowdsec/edge-allowlist.yaml.example /opt/stayz3ro/crowdsec-local/edge-allowlist.yaml
    sudoedit /opt/stayz3ro/crowdsec-local/edge-allowlist.yaml
    cd /opt/stayz3ro/proxy/configs/crowdsec
    install -m 600 .env.example .env

In `edge-allowlist.yaml`, replace each placeholder with the real value:

- the tailnet CGNAT range, the same range as the Caddyfile admin matcher;
- the owner's home IPv4 address;
- the owner's home IPv6 prefix;
- optionally, the owner's mobile carrier range.

Delete any line that is not used. `.env` keeps the paths from the example
unless the deploy directory differs.

### 1.3 Start the engine

    cd /opt/stayz3ro/proxy/configs/crowdsec
    docker compose config --quiet && docker compose up -d
    docker exec crowdsec cscli postoverflows install crowdsecurity/cdn-whitelist
    docker exec crowdsec cscli simulation enable --global
    docker restart crowdsec

Add the LAPI allowlists. Type each owner value at the prompt, not into a
saved script:

    docker exec crowdsec cscli allowlists create edge-owner -d "tailnet and owner addresses"
    docker exec crowdsec cscli allowlists add edge-owner <TAILNET_RANGE>
    docker exec crowdsec cscli allowlists add edge-owner <OWNER_ADDRESS>
    docker exec crowdsec cscli allowlists create edge-cdn -d "Cloudflare ranges, never ban"
    for r in $ranges; do docker exec crowdsec cscli allowlists add edge-cdn "$r"; done

Pass lines:

- `docker compose ps` shows `crowdsec` running and, after the first
  interval, `healthy`.
- `docker exec crowdsec cscli lapi status` reports that it can talk to the
  Local API.
- `docker exec crowdsec cscli metrics show acquisition` lists
  `/var/log/caddy/access.log` and `/var/log/host/auth.log`, each with lines
  read and lines parsed above zero.
- `docker exec crowdsec cscli postoverflows list` shows
  `crowdsecurity/cdn-whitelist` enabled.
- `docker exec crowdsec cscli simulation status` shows global simulation
  enabled.
- `docker exec crowdsec cscli bouncers list` is empty.
- `docker exec crowdsec cscli allowlists inspect edge-owner` and
  `... inspect edge-cdn` list the expected number of entries.
- `docker stats --no-stream crowdsec` memory is recorded in
  [validation.md](validation.md).

### 1.4 The week

Once a day, the owner runs:

    docker exec crowdsec cscli alerts list --limit 50
    docker stats --no-stream crowdsec

Gate to Stage 2, all must hold after seven days:

- No alert has a Cloudflare address, a tailnet address or an owner address
  as its source.
- Every alert that looks like a false positive is written down with its
  scenario name (an input to decision 8).
- Memory stayed under the `mem_limit`. Peak and typical values are
  recorded, along with `docker system df -v | grep -i crowdsec`.
- Sites and monitors stayed green all week.

### Rollback, Stage 1

    cd /opt/stayz3ro/proxy/configs/crowdsec
    docker compose down
    cd /opt/stayz3ro/proxy/configs/caddy
    cp -p Caddyfile.bak-crowdsec-<STAMP> Caddyfile
    docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile &&
      docker restart caddy

`docker compose down` keeps the `crowdsec_config` and `crowdsec_data`
volumes. Use `docker compose down -v` only to remove CrowdSec completely.
Pass: the status page answers, and the last access log line shows
`client_ip` equal to `remote_ip` again.

## Stage 2a: remediation at Caddy

Starts only after the Stage 1 gate passes and the owner has decided items 4
and 5 in [overview.md](overview.md) section 6.

### 2a.1 Key, without printing it

    cd /opt/stayz3ro/proxy/configs
    umask 077
    key=$(openssl rand -hex 32)
    printf 'CROWDSEC_CADDY_BOUNCER_KEY=%s\n' "$key" >> crowdsec/.env
    printf 'CROWDSEC_API_KEY=%s\n' "$key" >> caddy/.env
    unset key
    chmod 600 crowdsec/.env caddy/.env

### 2a.2 Register the bouncer and end simulation

    cd /opt/stayz3ro/proxy/configs/crowdsec
    docker compose -f docker-compose.yml -f docker-compose.stage2.yml config --quiet &&
      docker compose -f docker-compose.yml -f docker-compose.stage2.yml up -d
    docker exec crowdsec cscli simulation disable --global
    docker restart crowdsec
    docker exec crowdsec cscli bouncers list

`BOUNCER_KEY_<name>` cannot update an existing bouncer of that name. To
change the key, run `cscli bouncers delete caddy` first.

### 2a.3 Build Caddy with the bouncer module

    cd /opt/stayz3ro/proxy/configs/caddy
    cp -p Caddyfile "Caddyfile.bak-bouncer-$(date -u +%Y%m%dT%H%M%SZ)"
    docker compose -f docker-compose.yml -f ../crowdsec/caddy/docker-compose.caddy-bouncer.yml build caddy
    docker compose -f docker-compose.yml -f ../crowdsec/caddy/docker-compose.caddy-bouncer.yml run --rm --no-deps caddy caddy list-modules | grep -i crowdsec

Edit `Caddyfile` with the two parts in
`configs/crowdsec/caddy/crowdsec-bouncer.snippet.example`:

- the global `crowdsec` block;
- `route { crowdsec }` as the first line of the `status`, `ntfy` and `a`
  site blocks.

Leave the tailnet admin names alone. Then validate with the new image and
start it:

    docker compose -f docker-compose.yml -f ../crowdsec/caddy/docker-compose.caddy-bouncer.yml run --rm --no-deps caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile &&
      docker compose -f docker-compose.yml -f ../crowdsec/caddy/docker-compose.caddy-bouncer.yml up -d caddy

### 2a.4 Test with one address the owner controls

Use a device off the tailnet whose address is in no allowlist, for example
a phone on mobile data. Read its public address on the device itself.

    docker exec crowdsec cscli decisions add --ip <TEST_ADDRESS> --duration 10m --reason "stage 2a test"

On that device, within about 30 seconds (`ticker_interval 15s`):

    curl -s -o /dev/null -w '%{http_code}\n' https://status.chrisalorenzo.com/status/main

Then remove the decision and repeat the request:

    docker exec crowdsec cscli decisions delete --ip <TEST_ADDRESS>

Pass lines:

- `caddy list-modules` lists a `crowdsec` module.
- `cscli bouncers list` shows `caddy`, with a last pull time that keeps
  moving.
- The test device gets 403 while the decision exists and 200 after it is
  deleted. Other devices get 200 the whole time.
- Monitors stay green; admin names keep their tailnet gate.

### Rollback, Stage 2a

    cd /opt/stayz3ro/proxy/configs/caddy
    cp -p Caddyfile.bak-bouncer-<STAMP> Caddyfile
    docker compose up -d caddy
    docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile &&
      docker restart caddy
    docker exec crowdsec cscli bouncers delete caddy
    docker exec crowdsec cscli simulation enable --global
    docker restart crowdsec

`docker compose up -d caddy` with the base file alone returns to the
official image. Pass: `docker inspect caddy --format '{{.Config.Image}}'`
shows the official tag, the sites answer 200, and `cscli bouncers list` is
empty.

## Stage 2b: firewall bouncer for SSH, only if SSH is public

Skip this stage when Stage 0 showed SSH tailnet only. The firewall bouncer
never goes on the `DOCKER-USER` chain (see [overview.md](overview.md)
section 3).

    curl -s https://install.crowdsec.net | sudo sh
    sudo apt install crowdsec-firewall-bouncer-nftables
    cd /opt/stayz3ro/proxy/configs/crowdsec
    umask 077
    key=$(openssl rand -hex 32)
    printf 'CROWDSEC_FW_BOUNCER_KEY=%s\n' "$key" >> .env
    printf 'api_url: http://127.0.0.1:8080/\napi_key: %s\n' "$key" | sudo tee /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml.local > /dev/null
    unset key
    sudo chmod 600 /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml.local
    docker compose -f docker-compose.yml -f docker-compose.stage2.yml -f docker-compose.lapi-loopback.yml up -d
    sudo systemctl restart crowdsec-firewall-bouncer

The package's own setup normally creates its key with `cscli` on the host.
Here the engine runs in a container, so that step has nothing to call, and
the service may fail until the `.local` file exists. That behaviour is
unverified. The restart after writing the file is the step that counts.
Read the install script before running it. The packagecloud steps on the
upstream install page are the manual alternative.

Pass lines:

- `systemctl is-active crowdsec-firewall-bouncer` prints `active`.
- `docker exec crowdsec cscli bouncers list` shows `firewall`.
- `sudo nft list tables` shows the `crowdsec` and `crowdsec6` tables.
- `sudo iptables -S DOCKER-USER | diff ~/docker-user-before-crowdsec.txt -`
  prints nothing.
- With a test decision on `<TEST_ADDRESS>` (same commands as 2a.4),
  `nc -vz -w 5 <PUBLIC_ADDRESS> 22` from that device times out. After the
  decision is deleted, it connects. The sites answer 200 the whole time.

### Rollback, Stage 2b

    sudo systemctl disable --now crowdsec-firewall-bouncer
    sudo apt purge crowdsec-firewall-bouncer-nftables
    sudo nft list tables
    docker exec crowdsec cscli bouncers delete firewall
    cd /opt/stayz3ro/proxy/configs/crowdsec
    docker compose -f docker-compose.yml -f docker-compose.stage2.yml up -d

If `nft list tables` still shows the CrowdSec tables, remove them with
`sudo nft delete table <family> crowdsec` and `... crowdsec6`, using the
family the listing prints. Pass: no CrowdSec table remains, the
`DOCKER-USER` diff is empty, and SSH over the tailnet still works.
