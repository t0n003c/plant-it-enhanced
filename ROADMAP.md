# Plant-it Enhanced roadmap

This roadmap records the product direction for the maintained fork. Each milestone must remain
self-hosting friendly: optional cloud providers may enrich the experience, but core search, care,
and backup workflows must continue to work without API keys.

The v0.14 milestone is implemented on the `feature/trustworthy-onboarding` release branch. Checked
items below are complete; unchecked items remain the next planned progression.

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

## v0.15 — Care that adapts

- [ ] Expand the reviewed offline care catalog toward 150–200 common plants, with Extension or
      similarly authoritative references for each profile.
- [ ] Adjust suggested schedules using indoor/outdoor placement, light, pot, drainage, soil, and
      completed-care history.
- [ ] Optionally use local forecast data for outdoor watering advice without making weather a hard
      dependency.
- [x] Add clear confidence and safety language anywhere care data is approximate or inferred.

## v0.16 — Self-hosting operations

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
