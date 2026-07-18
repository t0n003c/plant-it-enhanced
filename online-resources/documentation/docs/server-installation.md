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
PLANTIT_API_HOST_PORT=8346
PLANTIT_WEB_HOST_PORT=3372
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

The NAS example intentionally does not set `container_name`. Compose-generated names prevent stale
containers from a previous project from blocking deployment. It also uses `pull_policy: always`, so
a redeploy checks GHCR for the current `latest` image.

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
network named by `PLANTIT_PROXY_NETWORK`. Only the server is attached to it.

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
- `TREFLE_TOKEN`: optional structured plant data
- `PERENUAL_API_KEY`: optional care fallback; free-plan coverage is limited
- `FLORACODEX_KEY`: optional final plant-data fallback
- `INATURALIST_ENABLED`: common-name discovery; defaults to `true`
- `PLANT_SEARCH_LOCALE` and `PLANT_SEARCH_REGION`: fallback language and region for older clients
- `GBIF_MIN_CONFIDENCE`: threshold for accepted-taxonomy verification

Provider keys remain on the server and are never sent to the web app. After changing them, recreate
only the server:

```bash
docker compose up -d --no-deps --force-recreate server
```

Open **More → System diagnostics** after signing in to verify configuration and recent provider
responses. For Pl@ntNet, keep **Expose my API key** disabled for normal server-side use. If its
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

## Reverse proxy

Route the application hostname to server container port `3000` and the API hostname or path to
server container port `8080`. The NAS Compose service is reachable as `server` on the external
proxy network. Never route `db:3306` or `cache:6379`.

Use HTTPS for mobile geolocation. When the frontend and API use different origins, set
`ALLOWED_ORIGINS` to the frontend origin or leave `*` while validating the deployment. Enter the API
base URL without `/api` when the app asks for a server address.

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

Database migrations are additive. The v0.14 and v0.15 migrations add catalog provenance, care
context, field observations, named hikes, and idempotent synchronization references without
deleting existing users, plants, care history, reminders, diaries, or photos.

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
