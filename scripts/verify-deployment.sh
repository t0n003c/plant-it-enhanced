#!/bin/sh
set -eu

PUBLIC_URL=${1:-}
EXPECTED_REVISION=${2:-}

if [ -z "$PUBLIC_URL" ]; then
    echo "Usage: $0 https://plant.example.com [expected-revision]" >&2
    exit 2
fi

case "$PUBLIC_URL" in
    http://*|https://*) ;;
    *)
        echo "The public URL must start with http:// or https://" >&2
        exit 2
        ;;
esac

if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required" >&2
    exit 2
fi

BASE_URL=${PUBLIC_URL%/}
WORK_DIRECTORY=$(mktemp -d "${TMPDIR:-/tmp}/plantit-verify.XXXXXX")
trap 'rm -rf "$WORK_DIRECTORY"' EXIT HUP INT TERM

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

pass() {
    echo "PASS: $*"
}

curl -fsS --max-time 20 "$BASE_URL/" > "$WORK_DIRECTORY/index.html" ||
    fail "the public app root is unavailable"
if grep -Eiq 'nginx proxy manager|congratulations.*proxy host' "$WORK_DIRECTORY/index.html"; then
    fail "the hostname is serving the Nginx Proxy Manager default site"
fi
grep -Eiq 'flutter(?:_bootstrap)?\.js|main\.dart\.js|_flutter\.loader' \
    "$WORK_DIRECTORY/index.html" ||
    fail "the public root does not look like the Plant-it Flutter app"
pass "the public root serves Plant-it"

PING=$(curl -fsS --max-time 20 "$BASE_URL/api/info/ping") ||
    fail "/api/info/ping is unavailable; check the Nginx Proxy Manager /api/ location"
[ "$PING" = "pong" ] || fail "/api/info/ping returned '$PING' instead of 'pong'"
pass "the public API route reaches the backend"

curl -fsS --max-time 20 -D "$WORK_DIRECTORY/build.headers" \
    "$BASE_URL/api/info/build" > "$WORK_DIRECTORY/build.json" ||
    fail "/api/info/build is unavailable"
REVISION=$(sed -n \
    's/.*"revision"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    "$WORK_DIRECTORY/build.json")
[ -n "$REVISION" ] || fail "/api/info/build did not return a revision"
grep -Eiq '^cache-control:.*no-store' "$WORK_DIRECTORY/build.headers" ||
    fail "/api/info/build is cacheable; check reverse-proxy header overrides"
pass "the backend reports running revision $REVISION"

if [ -n "$EXPECTED_REVISION" ]; then
    case "$REVISION:$EXPECTED_REVISION" in
        "$EXPECTED_REVISION"*:*) ;;
        *:"$REVISION"*) ;;
        *) fail "running revision $REVISION does not match $EXPECTED_REVISION" ;;
    esac
    pass "the running revision matches the expected revision"
fi

curl -fsSI --max-time 20 "$BASE_URL/main.dart.js" \
    > "$WORK_DIRECTORY/frontend.headers" ||
    fail "main.dart.js is unavailable"
grep -Eiq '^cache-control:.*(no-store|no-cache)' "$WORK_DIRECTORY/frontend.headers" ||
    fail "main.dart.js can be cached stale; preserve the image's Cache-Control header"
pass "the mutable Flutter bundle requires revalidation"

curl -fsS --max-time 20 "$BASE_URL/update.html" \
    > "$WORK_DIRECTORY/update.html" || fail "/update.html is unavailable"
grep -Fq 'Refresh Plant-it Enhanced' "$WORK_DIRECTORY/update.html" ||
    fail "/update.html is not the Plant-it safe-refresh page"
pass "the safe-refresh page is available"

echo "Deployment verified: $BASE_URL ($REVISION)"
