#!/bin/sh
# Compose config parses the published examples without starting services.
set -eu
cd "$(dirname "$0")/.."

python3 scripts/check-relative-links.py --self-test
python3 scripts/check-relative-links.py
python3 scripts/check-state-claims.py --self-test
python3 scripts/check-state-claims.py

sensitive=$(find . -path './.git' -prune -o \
    \( -name '.env' -o \( -name '.env.*' ! -name '.env.example' \) \
       -o -name '*.pem' -o -name '*.key' -o -name '*.p12' -o -name '*.pfx' \
       -o -name id_rsa -o -name id_ed25519 \) -print)
if [ -n "$sensitive" ]; then
    printf '%s\n' "$sensitive" 'Potential sensitive files found'
    exit 1
fi
echo 'No obvious sensitive files found.'

empty=$(find . -name '*.md' -type f -empty -print)
if [ -n "$empty" ]; then
    printf 'Empty Markdown files found:\n%s\n' "$empty"
    exit 1
fi
echo 'No empty Markdown files found.'

if command -v docker-compose >/dev/null 2>&1; then
    set -- docker-compose
elif docker compose version >/dev/null 2>&1; then
    set -- docker compose
else
    echo 'Skipping Compose validation: Compose is not installed.'
    exit 0
fi
export POSTGRES_PASSWORD=ci-placeholder-not-a-secret APP_SECRET=ci-placeholder-not-a-secret
for file in configs/*/docker-compose.yml; do
    example=$(dirname "$file")/.env.example
    if [ -f "$example" ]; then
        "$@" --env-file "$example" -f "$file" config --quiet
    else
        "$@" -f "$file" config --quiet
    fi
    echo "Validated $file"
done
