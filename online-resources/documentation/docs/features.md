# Features

## Everyday-name plant search

Search uses familiar names first while preserving accepted scientific identity underneath. The
bundled reviewed index handles aliases, reordered words, minor spelling mistakes, and an 80-species
North American trail starter set. Results explain why they matched and show confidence instead of
presenting a weak match as fact.

When configured, iNaturalist expands common-name discovery, GBIF verifies accepted taxonomy, and
FloraCodex provides a final fallback. Provider records that resolve to the same accepted taxon are
merged instead of creating duplicate species.

## Photo identification

The search camera guides you through a whole-plant view and optional leaf and flower close-ups.
Plant-it sends up to five compressed photos to Pl@ntNet, displays several ranked candidates, and
waits for your confirmation before adding anything. **Take a plant photo** and **Choose from
gallery** use high-contrast mobile actions.

In the Trail Journal, capturing location is optional. When it is enabled, the server rounds the
coordinates to a configurable grid and asks Pl@ntNet for a nearby regional flora before identifying
the photos. Candidate cards name that flora. The same coarsened point can be used to find public,
research-grade iNaturalist observations from the observation month and adjacent months. Regional
flora and nearby seasonal occurrences can make only a small, bounded ranking adjustment; the photo
confidence remains visible as a separate score. Exact observation coordinates remain in the
self-hosted account and are not sent to either provider for contextual ranking.

Candidate cards show the evidence behind an adjustment and link to the occurrence query when one
was used. Habitat and elevation are visible comparison notes but are not scored until an
attributable ecological range is available. Native, introduced, or endemic status is shown only
when iNaturalist supplies it for the configured place.

Pl@ntNet is optional. A missing, exhausted, or rejected API key does not disable ordinary search.
The authenticated **More → System diagnostics** page reports whether the integration is configured
and records recent provider responses.

## Source-aware care guides

Plant-it merges care fields rather than stopping at the first provider. The built-in catalog can
fill common light, moisture, temperature, pH, and care values without an API key. Optional Trefle
and Perenual records enrich missing fields. Each structured value retains its source, source link,
confidence, and verification date, and users can still edit their own plant details.

Generalized guidance is a starting point. Check the plant, soil, pot, season, and local conditions
before watering or changing placement.

## My Green Friends and Today

Owned plants remain separate from catalog species. Add placement, light, pot, drainage, soil,
recent-care, and approximate-location context to create an initial schedule. The Today view groups
due, overdue, snoozed, and upcoming work. Completing a task creates a care event so the plant's
history remains visible.

## Care history and reminders

Log watering, fertilizing, biostimulating, pruning, repotting, and other events for one or more
plants. Filter the chronological diary by plant or event type. Reminders can be enabled, disabled,
edited, snoozed, skipped, or completed, with optional notification dispatchers configured by the
self-hosting administrator.

## Trail Journal

Wild observations do not become owned plants and never receive watering reminders automatically.
Open **Trail** in the five-item bottom navigation to view the journal or record a find. The journal
is no longer duplicated on Home, and its photo action stays inside the Trail tab so it remains easy
to reach without obscuring the primary navigation.

An observation can include:

- one or more original photos;
- observed date and time;
- trail and habitat notes;
- optional coordinates, accuracy, and elevation;
- an unconfirmed or explicitly confirmed identification;
- a private, obscured, or open sharing preference; and
- an optional named hike session with start and end times.

The Trail dashboard counts all finds, pending synchronization, and finds needing identification.
Its identification inbox can reopen a saved observation, reuse its authenticated self-hosted
photos, and run identification again. Text, status, hike, and inclusive date filters make longer
journals manageable. If observation creation succeeded but an image upload needs retrying, the
server record and retry draft are presented as one find rather than double-counted.

### Offline capture and synchronization

Photo-first drafts are written to durable browser or device storage before synchronization. The
journal shows pending, syncing, and failed states with edit, retry, and discard actions. Stable
client references make repeated requests idempotent, so an interrupted retry does not create a
second hike, taxon, observation, or image.

Offline drafts are isolated by server and username. If durable storage is unavailable, the offline
save action is disabled and Plant-it says why. Pending device drafts are not included in a server
backup until synchronization succeeds.

### Location and safety

Location is always opt-in. Browser geolocation normally requires HTTPS or localhost; photos, notes,
and identification still work when location is denied. Exact coordinates and original photos stay
inside the authenticated self-hosted account. Sharing preferences are recorded for future export,
but v0.15 does not publish observations.

Trail tags, contextual ranking, and contact-hazard warnings are informational. Visual and
contextual scores are shown separately; no candidate is presented as certain. Region, season,
elevation, habitat, and lookalikes still matter, and the application never infers edibility,
medicinal safety, or whether a wild plant is safe to touch.

## Self-hosting and reverse proxies

The hardened NAS layout supports Cloudflare Tunnel in front of Nginx Proxy Manager. Only the
application server joins the proxy network; MySQL and Redis stay on an internal Docker network and
publish no host ports. Plant-it accepts `CF-Connecting-IP` or `X-Forwarded-For` only from explicitly
trusted proxy CIDRs, so a direct caller cannot select a different rate-limit identity.

Catalog images are downloaded through a provider-host allowlist. Redirect destinations are checked
again, private and link-local addresses are blocked, and response type and size are bounded for both
previews and saved species images.

## Backups and diagnostics

The repository includes verified scripts for database and upload backups, checksum validation,
retention, and restore checks. Diagnostics report the application version, MySQL and Redis status,
provider configuration, and recent provider failures without exposing credentials.

See [Server installation](server-installation.md) and the repository's
[backup guide](https://github.com/t0n003c/plant-it-enhanced/blob/main/BACKUP_AND_RESTORE.md).
