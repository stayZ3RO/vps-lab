# Scripts 🧰

## Available Tooling

| File | Purpose | Where it runs |
|---|---|---|
| [check-relative-links.py](check-relative-links.py) | Check tracked Markdown links; `--self-test` checks the parser | Workstation and GitHub mirror docs CI |
| [backup-umami.sh](../configs/umami/backup-umami.sh) | Write and verify a PostgreSQL custom-format dump and SHA-256 sidecar; keep 14 days locally | VPS after explicit installation |
| [umami-backup.service](../configs/umami/umami-backup.service) | Run the backup script | Host systemd service |
| [umami-backup.timer](../configs/umami/umami-backup.timer) | Schedule the service daily at 03:30 UTC | Host systemd timer |

The [Umami deployment guide](../docs/phase-4-docker-app-deployment/step-by-step.md)
contains installation and verification steps. The tooling is committed;
[Current Status](../CURRENT-STATUS.md#next-workstream) tracks execution evidence
still needed. Do not run host backup or deployment commands as local docs checks.

## Local Documentation Checks

```sh
python3 scripts/check-relative-links.py --self-test
python3 scripts/check-relative-links.py
```

## Script Safety Rules

- Keep secrets out of scripts; use private host environment files.
- Use public-safe placeholders in examples.
- Prefer read-only checks for validation.
- Label mutating host commands and follow their deployment guide.
- Verify a database dump before replacing the previous artifact.

Health checks, general restore drills and additional deployment automation
remain future work. Add them to this inventory when actual scripts exist.
