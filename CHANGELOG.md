# Changelog

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
