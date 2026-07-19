# Plant-it Enhanced roadmap

This roadmap records the product direction for the maintained fork. Each milestone must remain
self-hosting friendly: optional cloud providers may enrich the experience, but core search, care,
and backup workflows must continue to work without API keys.

The v0.14 onboarding milestone, v0.15 Trail Mode foundation, and v0.16 catalog-reliability
foundation are implemented. The next product work adds a privacy-aware trail map and life list,
then makes care schedules adapt to observed conditions and history. Trail Mode deliberately
separates a wild observation from an owned plant so a trail find never receives care reminders
unless the user explicitly adds a cultivated plant to their collection.

## v0.14 — Trustworthy plant onboarding

- [x] Rank everyday common names ahead of misleading partial matches.
- [x] Explain why each search result matched and show a confidence level.
- [x] Maintain an offline trusted-name index and an 800+ query regression corpus.
- [x] Add a tagged 90-species North American hiking starter set with contact-hazard warnings.
- [x] Merge care data field by field instead of stopping at the first provider.
- [x] Retain source, source reference, confidence, and verification date for every care field.
- [x] Guide users through whole-plant, leaf, and flower photos and send up to five images to
      Pl@ntNet in one identification request.
- [x] Make the top three identification candidates easy to compare before adding a plant.
- [x] Capture the plant's growing environment and create a suggested care schedule.

## v0.15 — Field journal and Trail Mode

### Phase 1 — Observation foundation

- [x] Store wild observations independently from owned plants and care reminders.
- [x] Add authenticated create, list, edit, and delete APIs scoped to the current user.
- [x] Save one or more field photos, the observed time, trail, habitat, notes, and an optional
      confirmed taxon.
- [x] Add a mobile-first capture flow and a chronological hiking journal.
- [x] Treat precise coordinates as private by default and record an explicit sharing preference.

### Phase 2 — Offline field capture

- [x] Save photo-first drafts without connectivity and synchronize them with visible retry state.
- [x] Preserve optional GPS, accuracy, and elevation in offline drafts and synchronize them only
      after the user chooses to save the observation.
- [x] Group observations into named hike sessions with start and end times.
- [x] Keep original photos and exact coordinates on the self-hosted server unless the user exports
      or publishes them.

### Phase 3 — Contextual identification and field safety

- [x] Use an opt-in, server-coarsened field location to choose a nearby Pl@ntNet flora, show which
      flora was used, and keep exact observation coordinates on the self-hosted server.
- [x] Rerank candidates with bounded regional-flora and nearby seasonal-occurrence evidence while
      retaining the provider's visual confidence as a separate value.
- [x] Show captured habitat and elevation for comparison, and add only small positive adjustments
      when an exact taxon has a source-backed ecological profile.
- [x] Show comparable candidates, contact hazards, evidence, and confidence before confirmation.
- [x] Label common lookalikes only where a reviewed, attributable source supports the relationship.
- [x] Show native, introduced, or endemic status only when iNaturalist returns it for the configured
      place; add invasive status only after an attributable regional source is selected.
- [x] Keep wild-plant safety language prominent and never infer edibility or medicinal safety.

### Phase 4 — Life list and portable observations

- [x] Add Trail dashboard counts, text/date/hike/status filters, and an unidentified-observation
      inbox that can rerun identification from already saved photos.
- [ ] Add a privacy-aware observation map and distinct-species life-list counts.
- [ ] Export observations and photos as JSON, CSV, and GeoJSON with private or obscured locations.
- [ ] Add optional, review-before-publish iNaturalist integration; never publish automatically.

## v0.16 — Catalog reliability and care foundation

- [x] Define one support manifest for cultivated and trail catalog tiers.
- [x] Validate every accepted scientific name, synonym, and reviewed alias as a release corpus.
- [x] Require reviewed light and soil-moisture fields for all 82 cultivated entries.
- [x] Replay recorded production deserializers for iNaturalist, GBIF, Trefle, Perenual, and Pl@ntNet.
- [x] Run quota-safe scheduled provider canaries and deduplicate failure alerts.
- [x] Track sanitized, account-scoped no-result, missing-image, and missing-care gaps locally.
- [x] Expose tier coverage and recent gaps in a high-contrast mobile Catalog Health screen.
- [x] Preserve the query-matched everyday name and keep search responsive during provider work.

## Next — Care that adapts

- [ ] Expand the reviewed offline care catalog toward 150–200 common plants, with Extension or
      similarly authoritative references for each profile.
- [ ] Adjust suggested schedules using indoor/outdoor placement, light, pot, drainage, soil, and
      completed-care history.
- [ ] Optionally use local forecast data for outdoor watering advice without making weather a hard
      dependency.
- [x] Add clear confidence and safety language anywhere care data is approximate or inferred.

## Next — Self-hosting operations and portability

- [x] Add an authenticated diagnostics screen for database, cache, provider configuration,
      provider status, version, and recent upstream failures.
- [x] Identify the exact frontend and backend revisions, warn when a browser has a stale interface,
      and verify the public proxy/cache path with one deployment command.
- [ ] Add portable user-data and image export/import.
- [x] Add scheduled backup retention with an explicit destination and restore verification.
- [ ] Complete keyboard, screen-reader, contrast, large-text, and intermittent-network testing.

## Engineering rules

- Database migrations are additive and preserve existing user data.
- Scientific identity is verified independently of display names.
- A lower-priority provider fills missing care fields; it never silently overwrites a stronger
  field.
- Every displayed care value must say where it came from and when it was checked.
- Provider photos fill only missing images and retain their source, license, and attribution.
- Provider credentials stay on the server. Photos are uploaded only after an explicit user action.
- Forwarded client addresses are trusted only from configured reverse-proxy CIDRs, and remote
  provider images pass an explicit host, address, redirect, type, and size policy.
- Releases require backend tests, frontend analysis/tests, and a production web build.
