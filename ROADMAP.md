# Plant-it Enhanced roadmap

This roadmap records the product direction for the maintained fork. Each milestone must remain
self-hosting friendly: optional cloud providers may enrich the experience, but core search, care,
and backup workflows must continue to work without API keys.

The v0.14 onboarding milestone and the first two v0.15 Trail Mode phases are implemented. The next
phase adds contextual identification and field-safety signals. Trail Mode deliberately separates a
wild observation from an owned plant so a trail find never receives care reminders unless the user
explicitly adds a cultivated plant to their collection.

## v0.14 — Trustworthy plant onboarding

- [x] Rank everyday common names ahead of misleading partial matches.
- [x] Explain why each search result matched and show a confidence level.
- [x] Maintain an offline trusted-name index and a 200+ query regression corpus.
- [x] Add a tagged 80-species North American hiking starter set with contact-hazard warnings.
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

- [ ] Rerank identification candidates using region, season, elevation, habitat, and nearby
      occurrence evidence without presenting those signals as certainty.
- [ ] Show comparable candidates, common lookalikes, contact hazards, and confidence before the
      user confirms an identification.
- [ ] Add native, introduced, and invasive status only where an attributable regional source is
      available.
- [ ] Keep wild-plant safety language prominent and never infer edibility or medicinal safety.

### Phase 4 — Life list and portable observations

- [ ] Add a map, timeline filters, species counts, and an unidentified-observation inbox.
- [ ] Export observations and photos as JSON, CSV, and GeoJSON with private or obscured locations.
- [ ] Add optional, review-before-publish iNaturalist integration; never publish automatically.

## v0.16 — Care that adapts

- [ ] Expand the reviewed offline care catalog toward 150–200 common plants, with Extension or
      similarly authoritative references for each profile.
- [ ] Adjust suggested schedules using indoor/outdoor placement, light, pot, drainage, soil, and
      completed-care history.
- [ ] Optionally use local forecast data for outdoor watering advice without making weather a hard
      dependency.
- [x] Add clear confidence and safety language anywhere care data is approximate or inferred.

## v0.17 — Self-hosting operations

- [x] Add an authenticated diagnostics screen for database, cache, provider configuration,
      provider status, version, and recent upstream failures.
- [ ] Add portable user-data and image export/import.
- [x] Add scheduled backup retention with an explicit destination and restore verification.
- [ ] Complete keyboard, screen-reader, contrast, large-text, and intermittent-network testing.

## Engineering rules

- Database migrations are additive and preserve existing user data.
- Scientific identity is verified independently of display names.
- A lower-priority provider fills missing care fields; it never silently overwrites a stronger
  field.
- Every displayed care value must say where it came from and when it was checked.
- Provider credentials stay on the server. Photos are uploaded only after an explicit user action.
- Releases require backend tests, frontend analysis/tests, and a production web build.
