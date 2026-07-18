#!/bin/sh
set -eu

SCRIPT_DIRECTORY=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
COMPOSE_FILE=${COMPOSE_FILE:-$SCRIPT_DIRECTORY/compose.example.yaml}
ENV_FILE=${ENV_FILE:-$SCRIPT_DIRECTORY/.env}
DATA_DIRECTORY=${DATA_DIRECTORY:-$SCRIPT_DIRECTORY/data}
BACKUP_DIRECTORY=${BACKUP_DIRECTORY:-$SCRIPT_DIRECTORY/backups}
BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}

case "$BACKUP_DIRECTORY" in
    ""|"/"|"$HOME")
        echo "Refusing unsafe BACKUP_DIRECTORY: $BACKUP_DIRECTORY" >&2
        exit 1
        ;;
esac

mkdir -p "$BACKUP_DIRECTORY"
WORK_DIRECTORY=$(mktemp -d "$BACKUP_DIRECTORY/.plantit-backup.XXXXXX")
trap 'rm -rf "$WORK_DIRECTORY"' EXIT HUP INT TERM
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
ARCHIVE="$BACKUP_DIRECTORY/plant-it-$TIMESTAMP.tar.gz"

compose() {
    docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

compose exec -T db sh -c \
    'MYSQL_PWD="$MYSQL_PASSWORD" exec mysqldump --no-tablespaces --single-transaction --routines --triggers -u"$MYSQL_USER" "$MYSQL_DATABASE"' \
    > "$WORK_DIRECTORY/database.sql"

if [ -d "$DATA_DIRECTORY/upload" ]; then
    tar -C "$DATA_DIRECTORY" -czf "$WORK_DIRECTORY/uploads.tar.gz" upload
fi

{
    echo "created_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "compose_file=$COMPOSE_FILE"
    compose images --format json 2>/dev/null || true
} > "$WORK_DIRECTORY/manifest.txt"

if [ -f "$WORK_DIRECTORY/uploads.tar.gz" ]; then
    (cd "$WORK_DIRECTORY" && sha256sum database.sql uploads.tar.gz) > "$WORK_DIRECTORY/SHA256SUMS"
else
    (cd "$WORK_DIRECTORY" && sha256sum database.sql) > "$WORK_DIRECTORY/SHA256SUMS"
fi
tar -C "$WORK_DIRECTORY" -czf "$ARCHIVE" .

find "$BACKUP_DIRECTORY" -maxdepth 1 -type f -name 'plant-it-*.tar.gz' \
    -mtime "+$BACKUP_RETENTION_DAYS" -delete

echo "Backup created: $ARCHIVE"
