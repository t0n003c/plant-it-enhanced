# Changelog

## 0.13.1 - 2026-07-17 - Cache compatibility fix

- Scope Redis cache keys to the application version so serialized catalog and plant data from an older release
  cannot be read by an incompatible newer model.
- Fix common-name search failures reporting that cached values could not be deserialized after upgrading from
  0.12.0 to 0.13.0.

## 0.13.0 - 2026-07-17 - Care intelligence v1

- Add camera and gallery plant identification through a server-side Pl@ntNet integration.
- Reuse an existing taxon when a photo matches the trusted catalog and preserve the selected photo when adding it.
- Add attributable Trefle care enrichment with light, humidity, soil moisture, temperature, and pH data.
- Present plain-language sun and watering guidance while keeping raw care values editable.
- Add a Today workflow for completing, snoozing, and skipping due plant-care reminders.
- Record completed care tasks in the plant diary.
- Make daily, weekly, monthly, and yearly recurrence calendar-aware across DST and month boundaries.
- Add additive migrations for reminder workflow state and care-data provenance.
- Add focused provider, recurrence, and Today workflow tests.

## 0.12.0 - 2026-07-17 - Catalog v1

- Add a durable GBIF-backed canonical taxon identity.
- Merge iNaturalist and FloraCodex results into an existing catalog record on save.
- Preserve personal species copies and existing care values during provider enrichment.
- Merge accepted scientific names, aliases, localized common names, and provider IDs.
- Use the requesting app's language and region for common-name discovery and display.
- Add an outbound iNaturalist request throttle with configurable burst capacity.
- Add a 39-query household-plant search quality corpus.
- Update the locked shared-preferences packages to remove a reported Android advisory.
- Point update checks at `t0n003c/plant-it-enhanced` and normalize `v`-prefixed tags.
- Add an additive Liquibase migration and PROCESS-free MySQL backup instructions.
