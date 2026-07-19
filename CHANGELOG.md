# Changelog

## 0.16.1 - 2026-07-18 - Query-aware, responsive search

- Preserve the exact common name that matched each result, so searches for `Thai chili` or
  `Thai pepper` display that everyday name while retaining `Capsicum annuum` as the scientific
  identity instead of relabeling the result as bell pepper.
- Reduce the search debounce from 1.1 seconds to 400 milliseconds, support immediate keyboard
  submission, and reset short or cleared queries without an unnecessary network request.
- Replace the disruptive full-result spinner with compact progress feedback while keeping existing
  result layout stable, and render plant labels while remote photos are still loading.
- Remove the arbitrary provider request when opening Search, add useful initial and empty-result
  states, lazily build result cards with stable identities, and tighten mobile padding.
- Cache successful GBIF verification responses for 24 hours in a bounded 512-entry server cache,
  avoiding duplicate taxonomy calls for the same scientific name without storing user data.
- Invalidate earlier search-response caches, add narrow-screen interaction regressions, and release
  the backend, web app, and Helm metadata as 0.16.1.

## 0.16.0 - 2026-07-18 - Catalog reliability

- Define one versioned catalog-quality manifest with separate support requirements for 82
  cultivated plants and 90 North American trail plants.
- Validate every accepted scientific name, synonym, and reviewed everyday alias as one corpus,
  preventing one-off search fixes and cross-taxon exact-name collisions.
- Prefer match confidence before provider-specific score when merging candidates, fixing accepted
  scientific names that could lose to a weaker synonym prefix.
- Expand attributed image discovery to active subspecies and varieties, and reconcile provider
  hybrid notation plus current GBIF accepted identities across the complete catalog.
- Require the full cultivated tier to have reviewed light and soil-moisture guidance, and add the
  missing Extension-sourced ginger profile for complete 82-of-82 coverage.
- Record sanitized, account-scoped no-result, missing-image, and missing-care gaps in the local
  database, automatically resolving a gap when a later request succeeds.
- Add **More → Catalog health** with tier coverage, corpus totals, recent local gaps, and a
  copyable report that contains no credentials or private observation coordinates.
- Replace hand-written provider samples with recorded contract fixtures for iNaturalist, GBIF,
  Trefle, Perenual, and Pl@ntNet response decoding.
- Add a weekly, rate-limited external audit for all 172 reviewed plants plus 10 fast representative
  canaries; optional repository secrets also verify Trefle and Pl@ntNet credentials.
- Add an additive catalog-gap migration, invalidate pre-release search caches, and document the
  quality policy, privacy boundary, maintenance workflow, and NAS upgrade checks.

## 0.15.7 - 2026-07-18 - Single-destination reverse proxy

- Proxy `/api/` from the bundled frontend on port `3000` to the backend on port `8080`, allowing
  Cloudflare Tunnel and Nginx Proxy Manager to use one reliable upstream destination.
- Preserve forwarded HTTPS and securely retain the immediate upstream for trusted client-address
  resolution across the loopback hop, and allow the documented 50 MB guided-photo request limit.
- Remove the custom `/api/` location as a required Nginx Proxy Manager setup step while retaining
  compatibility with deployments that route it directly to port `8080`.

## 0.15.6 - 2026-07-18 - Cross-provider common-name ranking

- Add reviewed kale, Thai pepper, Thai chili, and Thai chile aliases, resolving them to
  `Brassica oleracea` and `Capsicum annuum` for taxonomy and licensed-photo enrichment.
- Rank merged provider results by match confidence before applying the result limit, preventing a
  full page of fuzzy catalog matches from hiding an exact downstream provider match.
- Suppress unrelated common-name typo coincidences when the merged results contain a strong match,
  while preserving typo tolerance when the user actually misspells a plant name.
- Continue to external discovery when a complete local result page contains no strong match, even
  when every weak result already has an image.
- Add an Extension-sourced sunlight and soil-moisture profile for kale and invalidate stale search
  results created before the new mappings and ranking behavior.
- Document the diagnostic signature of a misrouted `/api/` custom location: HTTP 200 with Flutter
  HTML is a proxy failure; the ping response must be exactly `pong`.

## 0.15.5 - 2026-07-18 - Trusted alias photo enrichment

- Resolve exact reviewed everyday names to their accepted scientific identity before taxonomy and
  photo-provider lookup, while preserving ranking and match explanations for the user's wording.
- Add culinary ginger with `ginger root` aliases and enrich both ginger and cilantro through
  `Zingiber officinale` and `Coriandrum sativum`, respectively.
- Invalidate cached herb searches that were created before canonical alias enrichment.

## 0.15.4 - 2026-07-18 - Exact photo-match ranking

- Preserve iNaturalist's exact provider match through the bounded GBIF verification stage, so a
  requested plant is not crowded out by related names that merely begin with the same word.
- Add a regression with nine higher-scoring `strawberry ...` results around cultivated strawberry,
  proving its licensed photo still reaches the final result.
- Invalidate image-less search results cached before the exact-match ranking correction.

## 0.15.3 - 2026-07-18 - Cultivated strawberry enrichment

- Include iNaturalist's species-level hybrid rank when enriching common-name search results, so
  cultivated hybrids such as garden strawberry can provide their licensed photo and attribution.
- Recognize GBIF's accepted `Fragaria ananassa` canonical form alongside the `x` and `×` hybrid
  spellings, restoring the reviewed sunlight and watering guide for cultivated strawberry.
- Invalidate earlier image-less common-name search caches after the provider query change.

## 0.15.2 - 2026-07-18 - Context-aware identification and hardened self-hosting

- Add a separately reviewed trail field guide with six ecological profiles and 12 attributable
  lookalike comparisons from NPS, USDA Forest Service, University Extension, and state
  conservation guidance.
- Show common and scientific lookalike names, comparison clues, source links, and additional
  contact warnings in a high-contrast mobile candidate panel.
- Add only small positive habitat and elevation adjustments for exact scientific identities or
  reviewed synonyms; never penalize a mismatch or infer a range for an unreviewed taxon.
- Expand the offline North American trail set from 80 to 90 plants, including poison hemlock,
  giant hogweed, cow parsnip, water hemlock, wild parsnip, and poodle-dog bush.
- Bake one Git revision into the frontend, backend, OCI image metadata, Settings, and authenticated
  diagnostics so a self-hoster can identify the code actually running.
- Add a public no-store `/api/info/build` identity endpoint and an in-app stale-interface detector
  with a high-contrast, mobile-safe refresh action.
- Filter the packaged Spring properties so the application version is reported as its real release
  number rather than the unresolved Maven placeholder.
- Add `scripts/verify-deployment.sh` to validate the public Flutter root, `/api/` proxy route,
  expected revision, mutable-asset cache headers, and safe-refresh page after a NAS upgrade.
- Prevent Cloudflare and browser caches from combining a newly deployed Flutter shell with an
  older `main.dart.js`; mutable web assets now revalidate and critical entry files use `no-store`.
- Serve Flutter JavaScript and JSON with their correct MIME types and validate the bundled Nginx
  configuration while building the release image.
- Add a high-contrast, mobile-friendly `/update.html` recovery page that unregisters only the
  Flutter service worker and app-shell caches without deleting application or offline journal data.
- Enrich image-less trusted and saved search results with iNaturalist's default species photos
  without replacing an existing local or user-selected image.
- Preserve provider, source page, license, attribution, and a square-image fallback when a species
  photo is saved.
- Correct image selection for saved species, safely encode nested provider URLs, and retry a
  fallback thumbnail when the preferred remote image is unavailable.
- Display provider photo credit in species details and invalidate earlier image-less search caches.
- Add additive image-provenance columns plus backend and frontend regression coverage.
- Use an explicitly captured Trail Journal location to choose a nearby Pl@ntNet regional flora,
  after coarsening the coordinates on the server, and name the flora on each candidate.
- Rerank photo candidates with small, explainable regional-flora and nearby seasonal iNaturalist
  occurrence adjustments while preserving Pl@ntNet's visual confidence as a separate score.
- Show attributable evidence and regional establishment status on mobile candidate cards, display
  habitat/elevation without unsourced scoring, and keep contact-hazard guidance prominent.
- Add a Trail dashboard, status/hike/date/text filters, and an identification inbox that can rerun
  saved observations through identification without uploading their existing photos twice.
- Deduplicate partially synchronized observations in the journal while retaining their visible
  retry draft.
- Move search and identification response decoding behind a typed frontend repository and replace
  raw deserialization failures with an actionable server/web-version message.
- Trust Cloudflare and forwarded client addresses only when the immediate connection is from a
  configured Nginx Proxy Manager network, bound the per-client rate-limit cache, and return a
  standards-compatible `429` response with retry information.
- Apply one allowlisted, redirect-aware, public-address-only, size-limited image downloader to both
  catalog previews and saved remote images.
- Harden the NAS Compose example for Cloudflare Tunnel and Nginx Proxy Manager: only the server
  joins the proxy network, no application ports are published, and MySQL/Redis remain internal.
- Promote Trail Journal to a dedicated fifth bottom-navigation tab, keep visited tab state alive,
  move add-event and record-find actions into their relevant tabs, and improve mobile navigation
  labels, semantics, and contrast.

## 0.15.1 - 2026-07-18 - Offline trail capture

- Store photo-first trail drafts, notes, optional GPS accuracy/elevation, and hike sessions in
  durable on-device storage before attempting any network request.
- Add visible pending, syncing, failed, and retry states; interrupted uploads resume without
  discarding original photos or creating duplicate hike, observation, taxon, or image records.
- Group field finds into named hikes with start/end times and keep active-hike context across the
  journal, home card, and central quick-add action.
- Add owner-scoped hike APIs, observation/hike client references, photo retry references, and an
  additive Liquibase migration.
- Keep the offline action unavailable when the device cannot provide durable storage rather than
  implying that an in-memory draft is safe.
- Add a Dockge/UGREEN NAS Compose example using the maintained `latest` image, automatic pulls,
  health-gated startup, internal-only MySQL/Redis, and an external network only for the server.
- Refresh the environment reference, self-hosting documentation, and backup guidance; pending
  device drafts are explicitly excluded from server archives until they synchronize.
- Validate both Compose examples and build the maintained documentation on every pull request,
  including stacked feature pull requests.
- Add storage round-trip, interrupted-sync, partial-upload recovery, idempotency, ownership, and
  mobile action coverage.

## 0.15.0 - 2026-07-18 - Field journal foundation

- Separate wild observations from owned plants so trail finds never receive care reminders.
- Add authenticated, owner-scoped observation create, list, update, delete, and photo APIs backed
  by an additive Liquibase migration.
- Add a mobile-first Trail Journal entry point, guided multi-photo capture, chronological journal,
  optional trail, habitat, and field notes, and explicit identification confirmation.
- Allow observations to be retained when Pl@ntNet is unavailable or no candidate is trustworthy.
- Make GPS capture opt-in and location privacy `PRIVATE` by default, with obscured and open export
  preferences recorded for future portable-data work.
- Add Android and iOS foreground-location permissions, while keeping every non-location workflow
  functional when permission is denied or browser HTTPS is unavailable.

## 0.14.0 - 2026-07-17 - Trustworthy onboarding

- Add a reviewed offline everyday-name index with more than 300 search examples, relevance
  filtering, match reasons, and confidence so short fragments do not outrank real common names.
- Expand that index to 160 taxa and nearly 600 examples with 80 tagged North American trail
  plants, visible trail badges, and high-contrast contact-hazard warnings that also follow exact
  scientific-name photo matches.
- Merge Trefle, the 80-profile bundled catalog, and Perenual care field by field while retaining
  each value's source, reference, confidence, and verification time.
- Add guided whole-plant, leaf, and flower capture, multi-image Pl@ntNet identification, and a
  high-contrast top-three candidate flow that preserves the selected photo when adding a plant.
- Capture optional placement, light, window, pot, drainage, soil, and recent-care details and use
  them to suggest a conservative watering reminder.
- Add an authenticated diagnostics screen for MySQL, Redis, provider configuration, recent HTTP
  status, quota information, application version, and optional NAS public egress IP.
- Add checksum-verified database-and-upload backup and restore scripts with PROCESS-free MySQL
  dumps, retention controls, explicit destructive confirmation, and NAS scheduling guidance.
- Add additive Liquibase migrations, provider/search/care tests, mobile target-size coverage, and
  a documented release roadmap.

## 0.13.3 - 2026-07-17 - Reliable common-plant care

- Add a bundled, source-attributed care catalog covering 25 common houseplant, herb, vegetable,
  and flower profiles without requiring a paid API plan.
- Resolve care in the order Trefle, bundled curated catalog, then optional Perenual, using exact
  scientific names and synonyms to avoid attaching guidance to the wrong plant.
- Cover Monstera deliciosa, corn, sunflower, lavender, and roses with practical light and soil-
  moisture guidance mapped from Extension references.
- Display the curated source link and verification date with each matching care guide.
- Replace the photo picker choices with high-contrast, full-width actions and 64-pixel minimum
  touch targets for clearer camera and gallery selection on mobile.

## 0.13.2 - 2026-07-17 - Care coverage fallback

- Add optional Perenual enrichment when Trefle has no usable care values for a species.
- Map attributable Perenual watering and sunlight categories onto Plant-it's existing care scale.
- Require an exact scientific-name match before attaching fallback care data.
- Load cached care previews while viewing unsaved search and photo-identification results.
- Distinguish missing provider configuration and upstream provider failures during manual refresh.
- Correctly treat Trefle temperature objects containing only null measurements as missing data.

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
