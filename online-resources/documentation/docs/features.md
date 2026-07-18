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
An observation can include:

- one or more original photos;
- observed date and time;
- trail and habitat notes;
- optional coordinates, accuracy, and elevation;
- an unconfirmed or explicitly confirmed identification;
- a private, obscured, or open sharing preference; and
- an optional named hike session with start and end times.

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

Trail tags and contact-hazard warnings are informational. Region, season, elevation, habitat, and
lookalikes still matter, and the application never infers edibility or medicinal safety.

## Backups and diagnostics

The repository includes verified scripts for database and upload backups, checksum validation,
retention, and restore checks. Diagnostics report the application version, MySQL and Redis status,
provider configuration, and recent provider failures without exposing credentials.

See [Server installation](server-installation.md) and the repository's
[backup guide](https://github.com/t0n003c/plant-it-enhanced/blob/main/BACKUP_AND_RESTORE.md).
