#!/bin/sh
set -eu

wait_for_database() {
    database_host="${MYSQL_HOST:?MYSQL_HOST is required}"
    database_port="${MYSQL_PORT:-3306}"
    wait_seconds="${DB_WAIT_SECONDS:-120}"
    attempt=1

    echo "Waiting up to ${wait_seconds} seconds for ${database_host}:${database_port}"

    while ! nc -z -w 1 "${database_host}" "${database_port}" >/dev/null 2>&1; do
        if [ "${attempt}" -ge "${wait_seconds}" ]; then
            echo "Database ${database_host}:${database_port} is unavailable" >&2
            exit 1
        fi

        attempt=$((attempt + 1))
        sleep 1
    done

    echo "Database ${database_host}:${database_port} is available"
}

if [ "${DEV:-false}" = "true" ]; then
    export SPRING_PROFILES_ACTIVE=dev
else
    wait_for_database
fi

# nginx daemonizes after validating its configuration. Keeping Java in the
# foreground gives Docker correct exit codes and signal handling.
nginx
exec java -jar /opt/app/backend/app.jar
