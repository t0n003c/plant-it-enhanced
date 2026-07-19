<p align="center">
  <img width="150px" src="images/plant-it-logo.png" title="Plant-it">
</p>

<h1 align="center">Plant-it Enhanced</h1>

> This is a maintained fork of [MDeLuise/plant-it](https://github.com/MDeLuise/plant-it),
> focused on accurate everyday-name search, practical care workflows, and reliable self-hosting.
> It remains available under the original GPLv3 license.

<p align="center"><i><b>Maintained self-hosted release line; database changes are applied through additive migrations.</b></i></p>
<p align="center">Plant-it is a <b>self-hosted gardening companion app.</b><br>Useful for keeping track of plant care, receiving notifications about when to water plants, uploading plant images, and more.</p>

<p align="center"><a href="online-resources/documentation/docs/index.md">Explore the maintained documentation</a></p>

<p align="center"><a href="#why">Why?</a> • <a href="#features-highlight">Features highlights</a> • <a href="#quickstart">Quickstart</a> • <a href="BACKUP_AND_RESTORE.md">Backups</a> • <a href="ROADMAP.md">Roadmap</a> • <a href="#support-the-project">Support</a> • <a href="#contribute">Contribute</a></p>

<p align="center">
  <img src="/images/banner.png" width="100%" />
</p>

## Why?
Plant-it is a gardening companion app that helps you take care of your plants.

Plant-it keeps you in control of care decisions. Its sun and water guidance is reference
information—not a substitute for checking the soil, the plant, and the conditions in your home.

Plant-it helps you remember the last time you did a treatment of your plants, which plants you have, collects photos of your plants, and notifies you about the time passed since the last action on them.


## Features highlight
* Add existing plants or user created plants to your collection
* Search a reviewed offline index by everyday common names, aliases, reordered words, and minor typos
* Inspect catalog coverage and locally observed search, image, and care gaps from the app
* Recognize an offline starter set of 90 North American trail plants, including wildflowers,
  prairie plants, ferns, shrubs, trees, and several contact hazards
* Keep a private, chronological hiking journal with multi-photo observations, optional GPS, trail
  and habitat notes, and explicitly confirmed identifications
* Save finds offline, group them into named hikes, and retry interrupted synchronization without
  duplicating observations or photos
* See why a search result matched and its match confidence
* Keep the searched everyday name visible for multi-purpose species, such as Thai chili versus
  bell pepper, while preserving the shared scientific identity
* See attributable iNaturalist photos for image-less search results without replacing your own photos
* Take guided whole-plant, leaf, and flower photos, compare the top matches, and add the plant
* Optionally use a coarsened field location to select a closer Pl@ntNet regional flora while exact
  observation coordinates remain on the self-hosted server
* Compare visual confidence with bounded, attributable regional and nearby seasonal evidence
* Compare source-reviewed lookalikes and use positive habitat/elevation evidence where a reviewed
  ecological profile exists
* Review unidentified finds from saved photos and filter the Trail dashboard by status, hike, date,
  names, habitats, trails, or notes
* Verify accepted scientific taxonomy through GBIF, with iNaturalist discovery and FloraCodex fallback
* View field-level sources and confidence for light, moisture, temperature, and pH guidance
* Create a personalized care reminder from placement, light, pot, drainage, and soil details
* Work through due, overdue, snoozed, and upcoming care in a Today list
* Log events like watering, fertilizing, biostimulating, etc. for your plants
* View all the logged events, filtering by plant and event type
* Upload photos of your plants
* Set reminders for some actions on your plants (e.g. notify if not watered every 4 days)

## Trusted plant catalog

Plant-it Enhanced treats the accepted GBIF taxon key as a stable identity. Results from
iNaturalist, FloraCodex, and future providers are combined into one catalog entry instead
of creating a new copy for each provider. Scientific synonyms, localized common names,
provider references, and missing care values are merged while existing values are
preserved. Personal `USER` entries remain private copies and are never auto-merged.

Search results that do not already have a photo are enriched from iNaturalist when one is
available. Plant-it retains the provider's source page, license code, and attribution and uses a
smaller square thumbnail if the preferred medium image cannot be loaded. Existing local and
user-selected images always take precedence.

The reviewed offline index contains 172 taxa and more than 800 accepted scientific-name, synonym,
and everyday-name test queries and works without an API key. The cultivated tier contains 82 plants
with reviewed light and soil-moisture guidance; the trail tier contains 90 North American plants
whose household-care fields are intentionally not required. The web app sends its current language
and region with each search. Exact everyday-name matches stay visible on the result card even when
several cultivated forms share one scientific species. Search starts after a short 400 ms pause,
can be submitted immediately from the keyboard, and keeps compact progress feedback visible without
replacing the result layout.
`PLANT_SEARCH_LOCALE` and `PLANT_SEARCH_REGION` are fallbacks for older clients. Outbound
iNaturalist traffic is also throttled with a small interactive burst; repeated searches continue
to use Redis.

### Catalog reliability

One versioned manifest defines the support policy for every reviewed entry. Release tests search
the complete local name corpus, enforce unique exact identities and complete cultivated-care
requirements, and replay recorded response contracts for each external provider. A weekly,
rate-limited GitHub audit checks all 172 reviewed plants against live iNaturalist image and GBIF
taxonomy endpoints; 10 stable manifest canaries provide a faster representative set. Repository
secrets can also verify Trefle and Pl@ntNet.

When an authenticated search still returns nothing, lacks a top-result image, or produces no care
guide, Plant-it records only the sanitized query or scientific name in that account's self-hosted
database. A later successful request resolves the gap automatically. Open **More → Catalog health**
to inspect tier coverage and recent gaps or copy a credential-free report for an issue. These local
observations are never uploaded automatically. See [Catalog reliability](CATALOG_RELIABILITY.md)
for the support contract and maintenance commands.

### Trail plant coverage

The index includes a 90-species North American hiking starter set spanning eastern and Midwest
woodlands and prairies, western forests and wildflowers, and northern boreal plants. Trail results
carry a visible **North American trail plant** tag. Poison ivy, poison sumac, western poison oak,
stinging nettle, poison hemlock, giant hogweed, cow parsnip, water hemlock, wild parsnip,
purple-stemmed angelica, and poodle-dog bush also carry a high-contrast **Avoid contact · verify
independently** warning. The same metadata is applied when Pl@ntNet returns an exact
scientific-name match.

The starter set was cross-checked against public land-agency resources including the
[Cuyahoga Valley woodland wildflower list](https://www.nps.gov/cuva/learn/nature/wildflowers.htm),
[Craters of the Moon common wildflowers](https://www.nps.gov/crmo/learn/nature/wildflowers.htm),
[Great Lakes forest and wildflower communities](https://www.fs.usda.gov/wildflowers/regions/eastern/RoundIsland/index.shtml),
and [Denali's abundant boreal plants](https://www.nps.gov/dena/learn/nature/abundant-plant-species.htm).
It is a broad starter set, not a claim that every species occurs on every North American trail.
Range, season, elevation, and local look-alikes still matter.

The initial reviewed field guide adds six exact-taxonomy ecological profiles and 12 attributable
lookalike comparisons. Candidate cards show the comparison clue, scientific name, additional
contact warning where applicable, and a link to its public-agency or Extension source. Habitat can
add at most three percentage points and elevation at most two, and only when the recorded context
matches a reviewed profile. A mismatch never subtracts confidence or rules out a candidate. See
the [Trail field guide](online-resources/documentation/docs/trail-field-guide.md) for the current
coverage and data-review rules.

Plant-it does not use a photo or common-name match to decide whether a wild plant is edible, safe
to touch, or suitable for medicine. Do not eat or handle a trail plant based on an app result; for
contact hazards, follow local ranger guidance such as the
[NPS poison-ivy precautions](https://www.nps.gov/sacn/learn/nature/poisonivy.htm). Leave wild
plants where they grow and observe local trail rules.

### Trail journal

Trail observations are separate from cultivated plants. Saving a wild find never creates a
watering reminder or adds it to **My Green Friends**. Open the dedicated **Trail** tab from the
bottom navigation, start an optional named hike, take a whole-plant photo, optionally add leaf and
flower views, and either confirm one of the identification candidates or save it as unidentified
for later. Photo-first drafts are written to durable device storage before sync, and the journal
shows pending or failed uploads with explicit edit, retry, and discard actions.

The Trail dashboard summarizes all finds, pending uploads, and observations that still need an
identification. Search and filters work across names, trails, habitats, notes, dates, and named
hikes. An unidentified saved observation can be reopened from the **Identification inbox** and run
through identification again using the original self-hosted photos. A partially synchronized find
is represented once while its retry draft is pending.

Location is always opt-in. Exact coordinates and photo metadata remain in the authenticated,
self-hosted account, and the initial sharing preference is **Private**. Obscured and open settings
are recorded for future exports, but Plant-it does not publish observations. Browser location access
requires an HTTPS deployment (or localhost); photos, notes, and identification continue to work
when location is unavailable or denied. Offline drafts are isolated by server and username. If a
browser or device refuses durable storage, Plant-it says so and does not claim that an in-memory
draft is safely stored.

## Photo identification and care guides

These integrations are optional. Normal common-name search and the bundled care catalog continue
to work when every key is blank. API credentials remain in the server environment and are never
shipped to the browser or mobile app.

1. Create a free [Pl@ntNet API key](https://my.plantnet.org/) for photo identification.
2. Create a [Trefle access token](https://trefle.io/) for structured care data.
3. Optionally create a [Perenual API key](https://www.perenual.com/docs/api) for additional
   watering and sunlight fallback data. Its free plan provides detail records only for a limited
   species-ID range, so broader coverage can require a paid plan.
4. Add the values to the same `.env` file used by Docker Compose:

```dotenv
PLANTNET_API_KEY=replace-with-your-plantnet-key
TREFLE_TOKEN=replace-with-your-trefle-token
PERENUAL_API_KEY=replace-with-your-perenual-key
```

Redeploy only the server after changing these values:

```bash
docker compose up -d --no-deps --force-recreate server
```

In Search, use the camera button and follow the prompts for a whole-plant view, a leaf close-up,
and—when present—a flower close-up. Plant-it sends the photos together, shows the top three ranked
suggestions, and lets you confirm before adding anything. Opening a search result loads a cached
care preview without saving the species. When the plant is added, Plant-it keeps the first photo in
your own upload directory and attaches the preview to the saved catalog entry.

For Trail Journal identification, an explicitly captured location can select a closer Pl@ntNet
regional flora before the photos are evaluated. The server rounds the coordinates to a half-degree
grid by default; exact coordinates remain in the self-hosted observation. The candidate card names
the regional flora when one was applied. Set `PLANTNET_LOCATION_PROJECT_ENABLED=false` to keep all
identification requests on the world flora, or adjust the privacy/accuracy tradeoff with
`PLANTNET_LOCATION_PRECISION_DEGREES`.

When contextual identification is enabled, the server also checks public, research-grade
iNaturalist observations around the same coarsened grid point for the observation month and its two
adjacent months. Nearby evidence can make only a bounded adjustment; the Pl@ntNet photo confidence
remains visible separately. Habitat and elevation remain visible as field context. An exact
scientific-name or reviewed-synonym match can add a small positive adjustment when the context
falls within the source-backed field-guide profile; unmatched context is not penalized. Native,
introduced, or endemic status appears only when iNaturalist supplies it for the configured place.
Configure the radius and response bound with
`IDENTIFICATION_OCCURRENCE_RADIUS_KM` and `IDENTIFICATION_OCCURRENCE_RESULT_LIMIT`, or disable this
lookup with `IDENTIFICATION_CONTEXT_ENABLED=false`. Keep `INATURALIST_PLACE_ID` aligned with
`PLANT_SEARCH_REGION`; the example place ID `1` is the United States.

Plant-it combines Trefle, its bundled Extension-sourced catalog, and optional Perenual field by
field. A lower-priority source fills only missing values. The bundled catalog covers 80 frequently
grown plant profiles, including common scientific synonyms, and requires no API key. Exact
scientific-name matching prevents care from being attached to the wrong species. Each stored care
field retains its source, reference, confidence, and verification time and can still be edited
manually.

Identification suggestions are provided by [Pl@ntNet](https://plantnet.org/). Structured care
data is provided by [Trefle](https://trefle.io/), the bundled catalog mapped from
[NC State Extension Plant Toolbox](https://plants.ces.ncsu.edu/), and optional
[Perenual](https://www.perenual.com/) under their published terms. In your Pl@ntNet account, keep
**Expose my API key** disabled for normal server-side requests; if you choose IP restrictions,
authorize the NAS's public outbound IP. Always treat automated identification and generalized care
guidance as suggestions.

## Quickstart

### Server

The maintained AMD64/ARM64 image is published from this repository to
`ghcr.io/t0n003c/plant-it-enhanced:latest` after the complete backend and frontend test suites pass
on `main`.

```bash
git clone https://github.com/t0n003c/plant-it-enhanced.git
cd plant-it-enhanced
cp .env.example .env
```

Replace every `replace-with-...` value in `.env`, then start the stack:

```bash
docker compose -f compose.example.yaml up -d
```

The web app is available at `http://localhost:3000`; the API is available at
`http://localhost:8080/api`. MySQL and Redis share an internal-only network, while
the server has a separate network for outbound plant-data requests.

### Dockge on UGREEN or another NAS

Keep `compose.yaml` and `.env` together in the Dockge stack directory. The NAS example joins only
the application server to your existing reverse-proxy network; MySQL and Redis stay on an
internal-only network and publish no host ports.

```bash
cp compose.nas.example.yaml compose.yaml
cp .env.example .env
```

In `.env`, use absolute paths appropriate for the NAS and set the existing Docker network shared
with Nginx Proxy Manager:

```dotenv
PLANTIT_UPLOAD_PATH=/volume1/docker/plantit/upload_dir
PLANTIT_DB_PATH=/volume1/docker/plantit/db
PLANTIT_PROXY_NETWORK=TinhnasNetwork
TRUSTED_PROXY_CIDRS=172.20.0.0/16
TRUSTED_CLIENT_IP_HEADERS=CF-Connecting-IP,X-Forwarded-For
ALLOWED_ORIGINS=https://plants.example.com
```

Replace `172.20.0.0/16` with the exact subnet reported for `TinhnasNetwork`. The hardened NAS
example publishes no host ports: Nginx Proxy Manager reaches the stable `plantit-server` network
alias on ports `3000` and `8080`. A single public hostname can route `/` to port `3000` and `/api/`
to port `8080`, which also avoids cross-origin browser configuration. Cloudflare Tunnel should
continue to target Nginx Proxy Manager, not MySQL, Redis, or the Plant-it container directly.

Do not add `container_name`; Compose-generated names avoid conflicts with abandoned containers from
older stacks. The server has `pull_policy: always`, so a Dockge redeploy checks GHCR for a newer
`latest` image. See the maintained [server installation guide](online-resources/documentation/docs/server-installation.md)
for the Cloudflare Tunnel, Nginx Proxy Manager, trusted-proxy, and `.env` configuration.

### Safe upgrades

Back up the application database before pulling a new image. `--no-tablespaces` allows
the regular application user to create the backup without MySQL's `PROCESS` privilege:

```bash
mkdir -p backups
docker compose exec -T db sh -c \
  'MYSQL_PWD="$MYSQL_PASSWORD" exec mysqldump --no-tablespaces -u"$MYSQL_USER" "$MYSQL_DATABASE"' \
  > "backups/plant-it-$(date +%Y%m%d-%H%M%S).sql"

docker compose pull server
docker compose up -d --no-deps --force-recreate server
docker compose ps
docker compose logs --since=5m server
```

Verify the public hostname after the server is healthy:

```bash
./scripts/verify-deployment.sh https://plants.example.com
```

Pass a full or abbreviated Git commit as the second argument to prove that the expected image is
serving both the interface and API. The check fails if the hostname reaches the Nginx Proxy Manager
default site, `/api/` is routed incorrectly, the running revision is different, or Cloudflare/Nginx
allows the mutable Flutter bundle to become stale:

```bash
./scripts/verify-deployment.sh https://plants.example.com "$(git rev-parse HEAD)"
```

Every published image bakes the same source revision into the Flutter interface and Spring backend.
**Settings → Interface build** shows the browser bundle revision, **System diagnostics → Server
build** shows the backend revision, and `/api/info/build` provides the same server identity without
requiring an account. Do not set `APP_BUILD_REVISION` in `.env`; the release image supplies it.

The image sends no-store/revalidation headers for Flutter's mutable web bundle so Cloudflare does
not keep an older interface after a deployment. Installations upgraded from an earlier image may
need one final custom purge of `main.dart.js`, `flutter.js`, and `flutter_service_worker.js`, followed
by visiting `/update.html` and choosing **Refresh the app safely**. The recovery page removes only
Flutter's service worker and app-shell caches; it preserves application and offline journal data.

The Catalog v1 and Care Intelligence v1 migrations add catalog identity, care provenance,
soil-moisture, snooze, and skip-state columns. They do not delete plants, diaries, reminders,
images, users, or custom species.

The Trustworthy Onboarding migration adds field-level provenance and optional growing-environment,
light, pot, drainage, soil, recent-care, and approximate-location fields. It is additive and does
not change existing account or plant data. The authenticated **More → System diagnostics** screen
checks MySQL, Redis, provider configuration and recent provider responses. See
[Backup and restore](BACKUP_AND_RESTORE.md) for the verified archive scripts and NAS schedule.

The Field Journal migrations add owner-scoped observations, named hike sessions, durable retry
references, and observation-image links. They do not convert or modify existing plants, care
reminders, diaries, or photos.

The search-result photography migration adds optional image fallback and attribution columns. It
does not replace or delete any existing image.

See [Server installation](online-resources/documentation/docs/server-installation.md) for the full
configuration reference.

## App
You can access the Plant-it service using the web app at `http://<server_ip>:3000`.

For Android users, the app is also available as an APK, which can be downloaded either from the GitHub releases assets or from F-Droid.

### Download
- **GitHub Releases**: You can download the latest enhanced APK from the [GitHub releases page](https://github.com/t0n003c/plant-it-enhanced/releases/latest).
  <p align="center">
    <a href="https://github.com/t0n003c/plant-it-enhanced/releases/latest"><img src="https://raw.githubusercontent.com/Kunzisoft/Github-badge/main/get-it-on-github.png" alt="Get it on GitHub" height="60" style="max-width: 200px"></a>
  </p>

- **F-Droid (upstream client)**: The [F-Droid package](https://f-droid.org/packages/com.github.mdeluise.plantit/)
  follows upstream Plant-it and may not include enhanced search, care, or Trail Journal features.
  <p align="center">
    <a href="https://f-droid.org/packages/com.github.mdeluise.plantit" rel="nofollow"><img src="https://upload.wikimedia.org/wikipedia/commons/thumb/a/a3/Get_it_on_F-Droid_%28material_design%29.svg/2880px-Get_it_on_F-Droid_%28material_design%29.svg.png" alt="Get it on F-Droid" height=40 ></a>
  </p>

### Installation
For detailed instructions, including HTTPS requirements for location capture and durable offline
drafts, see [App installation](online-resources/documentation/docs/app-installation.md).


## Support the project
If you find this project helpful and would like to support it, consider [buying me a coffee](https://www.buymeacoffee.com/mdeluise). Your generosity helps keep this project alive and ensures its continued development and improvement.
<p align="center">
  <a href="https://www.buymeacoffee.com/mdeluise" target="_blank"><img width="150px" src="images/bmc-button.png"></a>
</p>

## Contribute
Feel free to contribute and help improve the repo.

### Contributing Translations to the Project
If you're interested in contributing translations, start with the
[upstream translation guide](https://github.com/MDeLuise/plant-it/discussions/148); this fork keeps
the same localization structure.
| Language | Filename | Translation |
|----------|----------|-------------|
| English | app_en.arb | 100% |
| Italian | app_it.arb | 100% |
| German | app_de.arb | 100% |
| Russian | app_ru.arb | 91% |
| Dutch Flemish | app_nl.arb | 91% |
| French | app_fr.arb | 90% |
| Danish | app_da.arb | 90% |
| Portuguese | app_pt.arb | 89% |
| Ukrainian | app_uk.arb | 87% |
| Spanish Castilian | app_es.arb | 87% |

### Bug Report, Feature Request and Question
You can submit any of this in the [issues](https://github.com/t0n003c/plant-it-enhanced/issues/new/choose) section of the repository. Choose the right template and then fill in the required info.

### Feature development
Let's discuss possible solutions before starting development; open a [feature request issue](https://github.com/t0n003c/plant-it-enhanced/issues/new/choose).

### How to contribute
If you want to make changes and test them locally, see the
[contribution guide](online-resources/documentation/docs/support.md#contribute).
