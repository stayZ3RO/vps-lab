# Agent Instructions

Read these first:

1. `CURRENT-STATUS.md`: canonical current state
2. `ROADMAP.md`
3. `LESSONS-LEARNED.md`
4. `CHANGELOG.md`

## Scope

Netcup VPS provisioning and hardening: public services under `chrisalorenzo.com` since the 2026-10-04 domain move (`stayz3ro.dev` now only redirects), public DNS routing validated, Docker-based services, Tailscale-only private access, SSH hardened. Active/in-progress repo (unlike the two home-network-* repos, which are closed out).

## Directories

`configs/`, `diagrams/`, `docs/`, `screenshots/`, `scripts/`

## Git and CI

The repository is public (Forgejo primary, public GitHub mirror).

Forgejo is primary; GitHub is the push mirror. CI runs on Forgejo on push
(`.forgejo/workflows/validate.yml`).

## Rules

- Do not commit unless explicitly instructed.
- Do not modify the live VPS from this repo. It's documentation/portfolio, not a control surface.
- Public-safe repo: never introduce secrets, tokens, private keys, or non-public-safe IPs/hostnames.
