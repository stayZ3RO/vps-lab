#!/bin/sh
set -eu

backup_dir=/opt/stayz3ro/backups/umami
dump_file="$backup_dir/umami-$(date -u +%F).dump"
tmp_file="$dump_file.tmp"
checksum_file="$dump_file.sha256"
checksum_tmp="$checksum_file.tmp"

umask 077
mkdir -p "$backup_dir"
trap 'rm -f "$tmp_file" "$checksum_tmp"' EXIT
docker exec umami-db pg_dump -U umami -d umami -Fc > "$tmp_file"
docker exec -i umami-db pg_restore --list < "$tmp_file" >/dev/null
checksum=$(sha256sum "$tmp_file")
printf '%s  %s\n' "${checksum%% *}" "$(basename "$dump_file")" > "$checksum_tmp"
rm -f "$checksum_file"
mv -f "$tmp_file" "$dump_file"
mv -f "$checksum_tmp" "$checksum_file"
find "$backup_dir" -type f \( -name 'umami-*.dump' -o -name 'umami-*.dump.sha256' \) -mtime +13 -delete
