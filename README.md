<p align="center">
  <img width="150px" src="images/plant-it-logo.png" title="Plant-it">
</p>

<h1 align="center">Plant-it Enhanced</h1>

> This is a maintained fork of [MDeLuise/plant-it](https://github.com/MDeLuise/plant-it),
> focused on accurate everyday-name search, practical care workflows, and reliable self-hosting.
> It remains available under the original GPLv3 license.

<p align="center"><i><b>Maintained self-hosted release line; database changes are applied through additive migrations.</b></i></p>
<p align="center">Plant-it is a <b>self-hosted gardening companion app.</b><br>Useful for keeping track of plant care, receiving notifications about when to water plants, uploading plant images, and more.</p>

<p align="center"><a href="https://docs.plant-it.org/latest/">Explore the documentation</a></p>

<p align="center"><a href="#why">Why?</a> • <a href="#features-highlight">Features highlights</a> • <a href="#quickstart">Quickstart</a> • <a href="#support-the-project">Support</a> • <a href="#contribute">Contribute</a></p>

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
* Search by everyday common names, aliases, reordered words, and minor typos
* Take or select a photo to identify a plant and add it with that photo
* Verify accepted scientific taxonomy through GBIF, with iNaturalist discovery and FloraCodex fallback
* View source-backed light, moisture, temperature, and pH guidance
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

The web app sends its current language and region with each search. `PLANT_SEARCH_LOCALE`
and `PLANT_SEARCH_REGION` are fallbacks for older clients. Outbound iNaturalist traffic is
also throttled with a small interactive burst; repeated searches continue to use Redis.

## Photo identification and care guides

These integrations are optional. Normal common-name search continues to work when either key
is blank. API credentials remain in the server environment and are never shipped to the browser
or mobile app.

1. Create a free [Pl@ntNet API key](https://my.plantnet.org/) for photo identification.
2. Create a [Trefle access token](https://trefle.io/) for structured care data.
3. Add both values to the same `.env` file used by Docker Compose:

```dotenv
PLANTNET_API_KEY=replace-with-your-plantnet-key
TREFLE_TOKEN=replace-with-your-trefle-token
```

Redeploy only the server after changing these values:

```bash
docker compose up -d --no-deps --force-recreate server
```

In Search, use the camera button, photograph one plant in clear light, compare the ranked
suggestions, and select the best match. When the plant is added, Plant-it keeps the photo in your
own upload directory and attempts to attach a care guide automatically. Care values are stored in
your MySQL catalog with their source and verification time and can still be edited manually.

Identification suggestions are provided by [Pl@ntNet](https://plantnet.org/). Structured care
data is provided by [Trefle](https://trefle.io/) under its published terms. Always treat automated
identification and generalized care guidance as suggestions.

## Quickstart
### Server
The maintained AMD64/ARM64 image is published from this repository to
`ghcr.io/t0n003c/plant-it-enhanced` after the complete backend and frontend test suites pass.

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

### Safe upgrades

Back up the application database before pulling a new image. `--no-tablespaces` allows
the regular application user to create the backup without MySQL's `PROCESS` privilege:

```bash
mkdir -p backups
docker compose exec -T db sh -c \
  'MYSQL_PWD="$MYSQL_PASSWORD" exec mysqldump --no-tablespaces -u"$MYSQL_USER" "$MYSQL_DATABASE"' \
  > "backups/plant-it-$(date +%Y%m%d-%H%M%S).sql"

docker compose pull server
docker compose up -d --no-deps server
docker compose logs --since=5m server
```

The Catalog v1 and Care Intelligence v1 migrations add catalog identity, care provenance,
soil-moisture, snooze, and skip-state columns. They do not delete plants, diaries, reminders,
images, users, or custom species.

<a href="https://docs.plant-it.org/latest/server-installation/#configuration">Take a look at the documentation</a> in order to understand the available configurations.

## App
You can access the Plant-it service using the web app at `http://<server_ip>:3000`.

For Android users, the app is also available as an APK, which can be downloaded either from the GitHub releases assets or from F-Droid.

### Download
- **GitHub Releases**: You can download the latest enhanced APK from the [GitHub releases page](https://github.com/t0n003c/plant-it-enhanced/releases/latest).
  <p align="center">
    <a href="https://github.com/t0n003c/plant-it-enhanced/releases/latest"><img src="https://raw.githubusercontent.com/Kunzisoft/Github-badge/main/get-it-on-github.png" alt="Get it on GitHub" height="60" style="max-width: 200px"></a>
  </p>

- **F-Droid**: Alternatively, you can get the app from [F-Droid](https://f-droid.org/packages/com.github.mdeluise.plantit/).
  <p align="center">
    <a href="https://f-droid.org/packages/com.github.mdeluise.plantit" rel="nofollow"><img src="https://upload.wikimedia.org/wikipedia/commons/thumb/a/a3/Get_it_on_F-Droid_%28material_design%29.svg/2880px-Get_it_on_F-Droid_%28material_design%29.svg.png" alt="Get it on F-Droid" height=40 ></a>
  </p>

### Installation
For detailed instructions on how to install and configure the app, please refer to the [installation documentation](https://docs.plant-it.org/latest/app-installation/).


## Support the project
If you find this project helpful and would like to support it, consider [buying me a coffee](https://www.buymeacoffee.com/mdeluise). Your generosity helps keep this project alive and ensures its continued development and improvement.
<p align="center">
  <a href="https://www.buymeacoffee.com/mdeluise" target="_blank"><img width="150px" src="images/bmc-button.png"></a>
</p>

## Contribute
Feel free to contribute and help improve the repo.

### Contributing Translations to the Project
If you're interested in contributing transactions to enhance the app, you can get started by following the guide provided [here](https://github.com/MDeLuise/plant-it/discussions/148). Your support and contributions are greatly appreciated.
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
If you want to make some changes and test them locally <a href="https://docs.plant-it.org/latest/support/#contributing">take a look at the documentation</a>.
