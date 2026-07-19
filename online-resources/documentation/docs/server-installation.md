# Server installation

Plant-it Enhanced publishes one container containing the Java API and Flutter web app. MySQL stores
accounts, plants, care history, reminders, catalog data, hikes, and synchronized observations.
Redis is a disposable cache. Uploaded plant and trail photos are stored in `/upload-dir`.

## Requirements

- Docker Engine with the Compose v2 plugin (`docker compose`)
- an AMD64 or ARM64 Linux host
- persistent storage for MySQL and uploads
- an existing external Docker network only when using a reverse proxy

The maintained image is `ghcr.io/t0n003c/plant-it-enhanced:latest`. It is published from `main`
only after backend tests, frontend analysis/tests, a production web build, and a multi-architecture
container build succeed.

## Standard Docker Compose deployment

Clone the repository and create a private environment file:

```bash
git clone https://github.com/t0n003c/plant-it-enhanced.git
cd plant-it-enhanced
cp .env.example .env
```

Replace the three `replace-with-...` secrets in `.env`. Use different long random values for the
application database password, MySQL root password, and JWT secret. Then validate and start:

```bash
docker compose -f compose.example.yaml config --quiet
docker compose -f compose.example.yaml pull
docker compose -f compose.example.yaml up -d
docker compose -f compose.example.yaml ps
```

The defaults expose the web app at `http://<host>:3000` and the API at
`http://<host>:8080/api`. MySQL and Redis publish no host ports.

## Dockge on UGREEN or another NAS

Dockge expects the active `compose.yaml` and `.env` in the stack directory. A clean layout is:

```text
/volume1/docker/Dockge/stacks/plantit/
├── .env
├── compose.yaml
└── source/
```

Clone or update the source, then copy the maintained examples into the stack root:

```bash
cd /volume1/docker/Dockge/stacks/plantit
git clone https://github.com/t0n003c/plant-it-enhanced.git source
cp source/compose.nas.example.yaml compose.yaml
cp source/.env.example .env
```

If `source` already exists, use `git -C source pull --ff-only` instead of cloning. Edit `.env` and
set at least:

```dotenv
PLANTIT_IMAGE=ghcr.io/t0n003c/plant-it-enhanced:latest
PLANTIT_UPLOAD_PATH=/volume1/docker/plantit/upload_dir
PLANTIT_DB_PATH=/volume1/docker/plantit/db
PLANTIT_PROXY_NETWORK=TinhnasNetwork

MYSQL_DATABASE=bootdb
MYSQL_USER=plantit
MYSQL_PASSWORD=replace-with-a-long-database-password
MYSQL_ROOT_PASSWORD=replace-with-a-different-root-password
JWT_SECRET=replace-with-a-long-random-jwt-secret
TZ=America/Chicago
```

The proxy network must already exist:

```bash
docker network inspect TinhnasNetwork >/dev/null
```

Validate and deploy from the stack directory or use the matching Dockge actions:

```bash
docker compose config --quiet
docker compose pull
docker compose up -d
docker compose ps
docker compose logs --since=10m server
```

Then verify the same hostname users open in their browser. If this repository is kept in the
stack's `source` directory, the expected revision can be checked at the same time:

```bash
EXPECTED_REVISION=$(git -C source rev-parse HEAD)
./source/scripts/verify-deployment.sh \
  https://plants.example.com "$EXPECTED_REVISION"
```

After signing in, open **More → Catalog health**. Release 0.17.1 should report 176 reviewed plants,
86 curated care profiles, 14 live canaries, and no release-policy issue. A search that returns no
result, lacks a top-result image, or has no structured care will appear there only for the signed-in
account and will resolve after a later successful request.

The verifier checks that `/` is Plant-it rather than the Nginx Proxy Manager default site, `/api/`
reaches Spring Boot, the expected image revision is running, Flutter's mutable JavaScript is not
cached stale, and `/update.html` is available. Omit the second argument when the stack contains only
the published image and no source checkout.

The NAS example intentionally does not set `container_name`. Compose-generated names prevent stale
containers from a previous project from blocking deployment. It also uses `pull_policy: always`, so
a redeploy checks GHCR for the current `latest` image. Ports `3000` and `8080` are exposed only on
the shared Docker network and are not published on the NAS host.

## Network design

The database and cache belong only on the Compose `backend` network, which is marked `internal`.
They do not need internet access, an external reverse-proxy network, or published ports.

The server joins both networks:

```text
browser / reverse proxy
          |
       server  ---- outbound HTTPS to optional plant providers
          |
   internal backend
      /        \
   MySQL      Redis
```

For a local deployment, `compose.example.yaml` uses a normal bridge network named `app`. For a NAS
behind a reverse proxy, `compose.nas.example.yaml` replaces that side with the existing external
network named by `PLANTIT_PROXY_NETWORK`. Only the server is attached to it, with the stable network
alias `plantit-server`.

## How `.env` is used

Docker Compose automatically reads a file named `.env` beside the active Compose file for `${...}`
interpolation. That alone does not pass every value into a container. These examples also declare:

```yaml
env_file:
  - ./.env
```

on the server service, so application settings enter the server container. A file named
`server.env` is ignored unless the Compose file explicitly references it.

The Compose `environment` block deliberately maps `MYSQL_USER` and `MYSQL_PASSWORD` to the
application's `MYSQL_USERNAME` and `MYSQL_PSW` names. This keeps the application and MySQL service
on the same non-root credential and prevents password drift.

!!! warning "Existing MySQL data"

    `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, and `MYSQL_ROOT_PASSWORD` initialize a new,
    empty MySQL directory only. Editing `.env` later does not change accounts already stored in an
    existing database. Keep the working values, or deliberately change the MySQL account inside the
    database before recreating the server container.

## Configuration reference

The checked-in `.env.example` is the canonical list for Docker Compose. Important groups are:

### Required secrets

- `MYSQL_PASSWORD`: password used by the `plantit` application account
- `MYSQL_ROOT_PASSWORD`: separate administrative password, not used by the app
- `JWT_SECRET`: long random signing secret; changing it signs users out

Do not commit `.env`, paste it into an issue, or expose it through a reverse proxy.

### Plant search and care

Common-name search and the bundled catalog work with every provider key blank.

- `PLANTNET_API_KEY`: optional guided photo identification
- `PLANTNET_LOCATION_PROJECT_ENABLED`: use an opt-in Trail Journal location to choose a closer
  Pl@ntNet flora; defaults to `true`
- `PLANTNET_LOCATION_PRECISION_DEGREES`: coordinate grid used for that lookup; defaults to `0.5`,
  while exact observation coordinates remain self-hosted
- `IDENTIFICATION_CONTEXT_ENABLED`: add bounded, source-linked iNaturalist occurrence evidence to
  photo candidate ranking; defaults to `true`
- `IDENTIFICATION_OCCURRENCE_RADIUS_KM`: search radius around the coarsened point; defaults to
  `100` km and is bounded by the server
- `IDENTIFICATION_OCCURRENCE_RESULT_LIMIT`: maximum species-count rows requested per cached context;
  defaults to `200` and is bounded by the server
- `TREFLE_TOKEN`: optional structured plant data
- `PERENUAL_API_KEY`: optional care fallback; free-plan coverage is limited
- `FLORACODEX_KEY`: optional final plant-data fallback
- `INATURALIST_ENABLED`: common-name discovery; defaults to `true`
- `INATURALIST_PLACE_ID`: preferred place for localized names and establishment status; `1` is the
  United States, so update it together with `PLANT_SEARCH_REGION`
- `PLANT_SEARCH_LOCALE` and `PLANT_SEARCH_REGION`: fallback language and region for older clients
- `GBIF_MIN_CONFIDENCE`: threshold for accepted-taxonomy verification

Provider keys remain on the server and are never sent to the web app. After changing them, recreate
only the server:

```bash
docker compose up -d --no-deps --force-recreate server
```

Open **More → System diagnostics** after signing in to verify configuration and recent provider
responses. **Settings → Interface build** identifies the Flutter bundle loaded by this browser,
while **System diagnostics → Server build** identifies the backend container. They should match.
The public, read-only `/api/info/build` endpoint exposes only the application version and source
revision, never credentials. `APP_BUILD_REVISION` is supplied by the published image and should not
be overridden in `.env`. For Pl@ntNet, keep **Expose my API key** disabled for normal server-side use. If its
account uses IP restrictions, authorize the NAS's public outbound IP.

### Upload and request limits

- `PLANTIT_UPLOAD_PATH`: host directory mounted at `/upload-dir`
- `MAX_ORIGIN_IMG_SIZE`: maximum original image size in bytes
- `MAX_UPLOAD_IMG_SIZE`: maximum individual multipart file size
- `MAX_UPLOAD_REQUEST_SIZE`: combined size for a multi-photo request

### Accounts, logging, and email

- `USERS_LIMIT=-1`: no account limit
- `LOG_LEVEL=INFO`: application logging
- `CONTACT_MAIL`: administrator contact shown in email templates
- `SMTP_*`: optional password-reset and notification email delivery
- `NTFY_ENABLED` and `GOTIFY_ENABLED`: optional notification dispatchers

## Cloudflare Tunnel and Nginx Proxy Manager

The recommended public request path is:

```text
browser -> Cloudflare -> Cloudflare Tunnel -> Nginx Proxy Manager -> plantit-server
                                                               `-> :3000
                                                                   |-> Flutter files
                                                                   `-> /api/ -> :8080
```

Cloudflare Tunnel remains the only public ingress. It should send the Plant-it hostname to Nginx
Proxy Manager. Do not point the tunnel at MySQL, Redis, or Plant-it directly, and do not forward NAS
router ports for this stack.

In Nginx Proxy Manager, create one Proxy Host for `plants.example.com`:

- forward the main host to `plantit-server` on port `3000` using `http`;
- enable the normal exploit protections;
- add `client_max_body_size 50m;` in the advanced configuration so guided multi-photo requests fit
  the application request limit.

Plant-it 0.15.7 and later proxy `/api/` to the backend inside the application container. A separate
Nginx Proxy Manager custom location is therefore unnecessary. An existing `/api/` location pointed
directly at `plantit-server:8080` remains compatible, but using only the main port `3000` destination
is simpler and also works when a Cloudflare Tunnel bypasses location-specific proxy rules.

Nginx Proxy Manager and the Plant-it server must both join `TinhnasNetwork` (or the network named by
`PLANTIT_PROXY_NETWORK`). The same-origin layout means the server address entered in Plant-it is
simply `https://plants.example.com`, without `/api`.

After saving the Proxy Host, verify the API route itself rather than relying on an HTTP 200 status
alone:

```bash
curl -fsS https://plants.example.com/api/info/ping
```

The complete response must be `pong`. If it is Flutter HTML (usually beginning with
`<!DOCTYPE html>`), confirm that `/version.json` reports 0.15.7 or later and force-recreate the server
from the current `latest` image. As a legacy fallback, add an Nginx Proxy Manager custom location
for `/api/` using `http`, `plantit-server`, and port `8080`. A misrouted API path also prevents
catalog images from loading because authenticated `/api/proxy` requests receive HTML instead of an
image. Run `./scripts/verify-deployment.sh https://plants.example.com` after correcting the route.

Set an exact CORS origin even though same-origin requests do not require CORS:

```dotenv
ALLOWED_ORIGINS=https://plants.example.com
```

### Trusted client addresses

Cloudflare supplies the original visitor in
[`CF-Connecting-IP`](https://developers.cloudflare.com/fundamentals/reference/http-headers/#cf-connecting-ip),
but Plant-it accepts that header only when the immediate connection came from a configured trusted
proxy. Find the Nginx Proxy Manager network subnet:

```bash
docker network inspect TinhnasNetwork \
  --format '{{range .IPAM.Config}}{{println .Subnet}}{{end}}'
```

Then put the exact reported subnet in `.env`:

```dotenv
TRUSTED_PROXY_CIDRS=172.20.0.0/16
TRUSTED_CLIENT_IP_HEADERS=CF-Connecting-IP,X-Forwarded-For
```

The bundled port `3000` proxy securely carries Nginx Proxy Manager's immediate source address to
the backend, so keep `TRUSTED_PROXY_CIDRS` set to the actual shared proxy-network subnet; do not add
the container loopback range. Direct clients cannot use the internal marker to become trusted.

Do not copy the example subnet blindly and do not use all private address ranges. Leave
`TRUSTED_PROXY_CIDRS` empty if the API is accessed directly. Plant-it ignores forwarding headers
from every address outside this list, preventing a direct caller from choosing a different
rate-limit identity.

Cloudflare recommends `CF-Connecting-IP` for the original visitor because it contains one
consistent address. Do not enable Cloudflare's **Remove visitor IP headers** transform for this
hostname. If the NPM host is also reachable from an untrusted non-Cloudflare ingress, restrict that
ingress before trusting the Cloudflare header.

In Cloudflare, bypass caching for `/api/*`. Do not create a **Cache Everything** rule for the app
hostname. The maintained image marks Flutter's mutable entry files as `no-store` and requires the
remaining web assets to revalidate, preventing an old `main.dart.js` from being combined with a new
release. Use HTTPS at the public hostname because browser geolocation and camera behavior require a
secure context. Cloudflare Tunnel uses
[outbound-only connections](https://developers.cloudflare.com/tunnel/), so no inbound router port
is required.

### Image proxy restrictions

Remote catalog photos are fetched only from the public provider hosts in
`IMAGE_PROXY_ALLOWED_HOSTS`. Every redirect is checked again, private/link-local destinations are
blocked, and only common raster image types are returned. If a legitimate provider adopts a new
CDN, or a custom species uses a remote image host, add only that exact hostname after verifying it:

```dotenv
IMAGE_PROXY_ALLOWED_HOSTS=static.inaturalist.org,inaturalist-open-data.s3.amazonaws.com,bs.plantnet.org,new.example-cdn.test
IMAGE_PROXY_ALLOWED_PORTS=80,443
IMAGE_PROXY_ALLOW_PRIVATE_ADDRESSES=false
```

Never set `IMAGE_PROXY_ALLOW_PRIVATE_ADDRESSES=true` on the NAS. It would permit the application to
reach internal services through the image endpoint.

## Upgrade safely

`latest` changes only after a successful build on the default branch. Before an upgrade, synchronize
pending Trail Journal drafts and create a backup. Pending device drafts are not yet in MySQL or the
server upload directory.

```bash
cd /volume1/docker/Dockge/stacks/plantit

COMPOSE_FILE="$PWD/compose.yaml" \
ENV_FILE="$PWD/.env" \
DATA_DIRECTORY=/volume1/docker/plantit \
BACKUP_DIRECTORY=/volume1/docker/plantit-backups \
./source/scripts/backup.sh

docker compose pull server
docker compose up -d --no-deps --force-recreate server
docker compose ps
docker compose logs --since=10m server
```

Confirm the public route and running image before testing features:

```bash
EXPECTED_REVISION=$(git -C source rev-parse HEAD)
./source/scripts/verify-deployment.sh \
  https://plants.example.com "$EXPECTED_REVISION"
```

If the interface and server revisions differ, Plant-it shows a high-contrast update notice. Its
**Refresh app safely** action opens `/update.html`, which clears only the old Flutter app shell.

If Cloudflare cached JavaScript before the cache-policy fix was deployed, purge these exact URLs
once in **Cloudflare → Caching → Configuration → Custom Purge**:

```text
https://plants.example.com/main.dart.js
https://plants.example.com/flutter.js
https://plants.example.com/flutter_service_worker.js
```

Replace `plants.example.com` with the real hostname, close every open app tab or installed PWA
window, then visit `https://plants.example.com/update.html` and choose **Refresh the app safely**.
That page unregisters only Flutter's service worker and app-shell caches; it does not clear
cookies, local storage, IndexedDB, accounts, plants, photos, reminders, or unsynchronized Trail
Journal drafts. A private window is also a useful non-destructive check.

Database migrations are additive. The v0.14 through v0.16 migrations add catalog provenance, care
context, field observations, named hikes, idempotent synchronization references, and private
catalog-gap observations without deleting existing users, plants, care history, reminders,
diaries, or photos.

See [Backup and restore](https://github.com/t0n003c/plant-it-enhanced/blob/main/BACKUP_AND_RESTORE.md)
for retention and restore verification.

## Troubleshooting

### Dockge says inactive but containers exist

Run `docker compose ps` from the exact Dockge stack directory. If old manually created containers
used fixed names, remove or rename only those confirmed stale containers, then redeploy. The
maintained examples omit fixed names to prevent this problem.

### MySQL access denied

Confirm the running server sees the expected non-secret settings:

```bash
docker compose exec -T server sh -c 'printf "%s\n" "$MYSQL_HOST" "$MYSQL_USERNAME"'
docker compose exec -T db sh -c \
  'MYSQL_PWD="$MYSQL_PASSWORD" mysql -h127.0.0.1 -u"$MYSQL_USER" "$MYSQL_DATABASE" -e "SELECT 1"'
```

If the second command works but the server fails, recreate only `server`. If it fails, the existing
MySQL data directory was initialized with different credentials. Do not delete it merely to change
a password; either restore the known credential or update the MySQL account deliberately.

### Pl@ntNet returns HTTP 403

Check that the key belongs to the current Pl@ntNet API product, is not exposed client-side, has
remaining quota, and permits the NAS's public outbound IP. Diagnostics records the provider status.
Ordinary name search remains available while photo identification is unavailable.

### No structured care guide

Confirm the result resolved to an accepted scientific taxon and review diagnostics for each care
provider. The bundled catalog covers common plants but not every taxon; Trefle and Perenual may also
have sparse records. Plant-it does not attach a care profile from a merely similar name.

### Offline save is unavailable

The browser or embedded client denied durable storage. Use a normal browser profile, allow site
storage, leave private browsing, and reload. Plant-it disables offline save rather than pretending
an in-memory draft is safe.
