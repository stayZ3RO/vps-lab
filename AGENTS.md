# Agent Instructions

Read these first:

1. `CURRENT-STATUS.md`: canonical current state
2. `ROADMAP.md`
3. `LESSONS-LEARNED.md`
4. `CHANGELOG.md`

## Scope

Netcup VPS provisioning and hardening: connected to `stayz3ro.dev`, public DNS routing validated, Docker-based services, Tailscale-only private access, SSH hardened. Active/in-progress repo (unlike the two home-network-* repos, which are closed out).

## Directories

`configs/`, `diagrams/`, `docs/`, `screenshots/`, `scripts/`

## Git and CI

Forgejo is primary at https://git.chrisalorenzo.com/; GitHub is the push
mirror, and CI runs only on GitHub mirror pushes. SSH uses
`gitssh.chrisalorenzo.com` on port 2222.

## Rules

- Do not commit unless explicitly instructed.
- Do not modify the live VPS from this repo. It's documentation/portfolio, not a control surface.
- Public-safe repo: never introduce secrets, tokens, private keys, or non-public-safe IPs/hostnames.
