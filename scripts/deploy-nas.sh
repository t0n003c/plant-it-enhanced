#!/bin/sh
set -eu

STACK_DIRECTORY=${1:-${PLANTIT_STACK_DIRECTORY:-$(pwd)}}
PUBLIC_URL=${2:-${PLANTIT_PUBLIC_URL:-}}
EXPECTED_REVISION=${3:-${PLANTIT_EXPECTED_REVISION:-}}
SCRIPT_DIRECTORY=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

[ -d "$STACK_DIRECTORY" ] || fail "stack directory does not exist: $STACK_DIRECTORY"
command -v docker >/dev/null 2>&1 || fail "docker is required"

cd "$STACK_DIRECTORY"
[ -f compose.yaml ] || fail "compose.yaml was not found in $STACK_DIRECTORY"

docker compose config --quiet || fail "compose.yaml is invalid or its .env is incomplete"
docker compose up -d --pull always --no-deps --force-recreate --wait server

CONTAINER_ID=$(docker compose ps -q server)
[ -n "$CONTAINER_ID" ] || fail "the server container was not created"

IMAGE_ID=$(docker inspect "$CONTAINER_ID" --format '{{.Image}}')
RUNNING_REVISION=$(docker image inspect "$IMAGE_ID" \
    --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')
[ -n "$RUNNING_REVISION" ] || fail "the running image has no source revision label"

case "$RUNNING_REVISION:$EXPECTED_REVISION" in
    *:) ;;
    "$EXPECTED_REVISION"*:*) ;;
    *:"$RUNNING_REVISION"*) ;;
    *) fail "the pulled image revision $RUNNING_REVISION does not match $EXPECTED_REVISION" ;;
esac

echo "PASS: NAS server is running image revision $RUNNING_REVISION"

if [ -n "$PUBLIC_URL" ]; then
    [ -x "$SCRIPT_DIRECTORY/verify-deployment.sh" ] ||
        fail "verify-deployment.sh is missing or not executable"
    "$SCRIPT_DIRECTORY/verify-deployment.sh" "$PUBLIC_URL" "$RUNNING_REVISION"
else
    echo "INFO: set PUBLIC_URL or pass a second argument to verify the public hostname"
fi
