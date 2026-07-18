#!/bin/sh
set -eu

if [ "$#" -ne 2 ] || [ "$1" != "--confirm-replace-all-data" ]; then
    echo "Usage: $0 --confirm-replace-all-data /absolute/path/to/plant-it-backup.tar.gz" >&2
    exit 1
fi

ARCHIVE=$2
case "$ARCHIVE" in
    /*) ;;
    *)
        echo "Use an absolute backup archive path." >&2
        exit 1
        ;;
esac
if [ ! -f "$ARCHIVE" ]; then
    echo "Backup archive does not exist: $ARCHIVE" >&2
    exit 1
fi

SCRIPT_DIRECTORY=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
COMPOSE_FILE=${COMPOSE_FILE:-$SCRIPT_DIRECTORY/compose.example.yaml}
ENV_FILE=${ENV_FILE:-$SCRIPT_DIRECTORY/.env}
DATA_DIRECTORY=${DATA_DIRECTORY:-$SCRIPT_DIRECTORY/data}
RESTORE_DIRECTORY=$(mktemp -d "${TMPDIR:-/tmp}/plantit-restore.XXXXXX")
trap 'rm -rf "$RESTORE_DIRECTORY"' EXIT HUP INT TERM

compose() {
    docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

tar -C "$RESTORE_DIRECTORY" -xzf "$ARCHIVE"
(cd "$RESTORE_DIRECTORY" && sha256sum -c SHA256SUMS)

compose stop server
compose exec -T db sh -c \
    'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot -e "DROP DATABASE IF EXISTS \`$MYSQL_DATABASE\`; CREATE DATABASE \`$MYSQL_DATABASE\`;"'
compose exec -T db sh -c \
    'MYSQL_PWD="$MYSQL_PASSWORD" exec mysql -u"$MYSQL_USER" "$MYSQL_DATABASE"' \
    < "$RESTORE_DIRECTORY/database.sql"

if [ -f "$RESTORE_DIRECTORY/uploads.tar.gz" ]; then
    mkdir -p "$DATA_DIRECTORY"
    if [ -d "$DATA_DIRECTORY/upload" ]; then
        mv "$DATA_DIRECTORY/upload" "$DATA_DIRECTORY/upload.before-restore-$(date +%Y%m%d-%H%M%S)"
    fi
    tar -C "$DATA_DIRECTORY" -xzf "$RESTORE_DIRECTORY/uploads.tar.gz"
fi

compose up -d server
compose exec -T db sh -c \
    'MYSQL_PWD="$MYSQL_PASSWORD" mysql -u"$MYSQL_USER" "$MYSQL_DATABASE" -e "SELECT 1"'
echo "Restore completed and database connectivity verified."
