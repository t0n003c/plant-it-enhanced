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
* Recognize an offline starter set of 80 North American trail plants, including wildflowers,
  prairie plants, ferns, shrubs, trees, and several contact hazards
* Keep a private, chronological hiking journal with multi-photo observations, optional GPS, trail
  and habitat notes, and explicitly confirmed identifications
* Save finds offline, group them into named hikes, and retry interrupted synchronization without
  duplicating observations or photos
* See why a search result matched and its match confidence
* See attributable iNaturalist photos for image-less search results without replacing your own photos
* Take guided whole-plant, leaf, and flower photos, compare the top matches, and add the plant
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

The reviewed offline index contains 160 taxa and nearly 600 everyday-name and synonym examples and
works without an API key. The web app sends its current language and region with each search.
`PLANT_SEARCH_LOCALE` and `PLANT_SEARCH_REGION` are fallbacks for older clients. Outbound
iNaturalist traffic is also throttled with a small interactive burst; repeated searches continue
to use Redis.

### Trail plant coverage

The index includes an 80-species North American hiking starter set spanning eastern and Midwest
woodlands and prairies, western forests and wildflowers, and northern boreal plants. Trail results
carry a visible **North American trail plant** tag. Poison ivy, poison sumac, western poison oak,
and stinging nettle also carry a high-contrast **Avoid contact · verify independently** warning.
The same metadata is applied when Pl@ntNet returns an exact scientific-name match.

The starter set was cross-checked against public land-agency resources including the
[Cuyahoga Valley woodland wildflower list](https://www.nps.gov/cuva/learn/nature/wildflowers.htm),
[Craters of the Moon common wildflowers](https://www.nps.gov/crmo/learn/nature/wildflowers.htm),
[Great Lakes forest and wildflower communities](https://www.fs.usda.gov/wildflowers/regions/eastern/RoundIsland/index.shtml),
and [Denali's abundant boreal plants](https://www.nps.gov/dena/learn/nature/abundant-plant-species.htm).
It is a broad starter set, not a claim that every species occurs on every North American trail.
Range, season, elevation, and local look-alikes still matter.

Plant-it does not use a photo or common-name match to decide whether a wild plant is edible, safe
to touch, or suitable for medicine. Do not eat or handle a trail plant based on an app result; for
contact hazards, follow local ranger guidance such as the
[NPS poison-ivy precautions](https://www.nps.gov/sacn/learn/nature/poisonivy.htm). Leave wild
plants where they grow and observe local trail rules.

### Trail journal

Trail observations are separate from cultivated plants. Saving a wild find never creates a
watering reminder or adds it to **My Green Friends**. Start from the Trail Journal card on the home
screen or the central add button, start an optional named hike, take a whole-plant photo, optionally
add leaf and flower views, and either confirm one of the identification candidates or save it as
unidentified for later. Photo-first drafts are written to durable device storage before sync, and
the journal shows pending or failed uploads with explicit edit, retry, and discard actions.

Location is always opt-in. Exact coordinates and photo metadata remain in the authenticated,
self-hosted account, and the initial sharing preference is **Private**. Obscured and open settings
are recorded for future exports, but v0.15 does not publish observations. Browser location access
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

In `.env`, use absolute paths appropriate for the NAS, set the existing Docker network name, and
choose the host ports you want Dockge to expose:

```dotenv
PLANTIT_UPLOAD_PATH=/volume1/docker/plantit/upload_dir
PLANTIT_DB_PATH=/volume1/docker/plantit/db
PLANTIT_PROXY_NETWORK=TinhnasNetwork
PLANTIT_API_HOST_PORT=8346
PLANTIT_WEB_HOST_PORT=3372
```

Do not add `container_name`; Compose-generated names avoid conflicts with abandoned containers from
older stacks. The server has `pull_policy: always`, so a Dockge redeploy checks GHCR for a newer
`latest` image. See the maintained [server installation guide](online-resources/documentation/docs/server-installation.md)
for first deployment, reverse-proxy, and `.env` details.

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
