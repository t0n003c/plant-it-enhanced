# Care tools and UI audit

Release 0.17.0 adds two privacy-first helpers and completes a focused audit of the app's core
mobile and web interactions. Open **Care tools** from Home, More, an owned plant, or catalog
details. No new environment variable, provider key, database migration, or reverse-proxy route is
required.

Release 0.17.1 extends that audit across the full application shell: shared page and section
hierarchy, bounded readable content, consistent authentication and settings cards, useful
empty/error/retry states, a responsive collection grid, and a labeled desktop navigation rail.
Phones retain the five clear bottom destinations.

## Guided plant-health check

The health check asks for:

- an optional owned plant and optional whole-plant and affected-area reference photos;
- every visible symptom that applies;
- current soil moisture and light; and
- wet leaves or poor airflow, plus any recent move or care change.

It returns at most three ranked patterns with a **Possible pattern** or **Strong pattern** label,
an intentionally conservative next check, and a source link. Guidance is based on public
University Extension diagnosis, indoor-disease, lighting, and integrated-pest-management
resources. **Not sure** inputs remain valid and weak evidence produces a closer-inspection result.

The tool does not inspect pixels. Reference photos remain local to the current interface and are
not uploaded or stored in the plant record. Results are not a diagnosis and never select a
pesticide, dose, edibility status, human treatment, or pet treatment. A selected owned plant can
open a normal journal event so the gardener decides what to record.

The current checks link directly to the University of Maryland Extension guides for
[diagnosing indoor plant problems](https://extension.umd.edu/resource/diagnose-indoor-plant-problems),
[indoor plant diseases](https://www.extension.umd.edu/resources/yard-garden/indoor-plants/indoor-plant-diseases),
and [integrated pest management](https://extension.umd.edu/resource/ipm-prevent-identify-and-manage-plant-problems).

## Light-placement check

The manual light check combines direct-light duration, distance from the nearest window, and
whether the view is open, filtered, or blocked. It intentionally reports only **Low**,
**Moderate**, or **High**. A browser camera is not a calibrated light meter, so the app does not
claim a lux or PAR reading.

The estimate and its limitations link to the University of Minnesota Extension guide to
[lighting for indoor plants](https://extension.umn.edu/planting-and-growing-guides/lighting-indoor-plants).

When a selected species has reviewed light guidance, the result states whether the estimated
placement is broadly lower than, similar to, or higher than that requirement. An owned plant can
save the estimate into its personalized care profile. The complete profile can now also be viewed
and edited from plant details.

## Completed UI audit

The release verifies and improves the following core functions:

- collection search always starts from the complete plant list, covers personal and scientific
  names, debounces typing, resets cleanly, and explains empty and no-match states;
- detail and calendar sections keep one controlled selection and wrap at large text sizes instead
  of hiding labels in a horizontal scroller;
- catalog add, settings links, event cards, reminders, filters, and collection cards use real
  Material actions with keyboard and assistive-technology semantics;
- event, photo, language, and settings listeners are removed when their page closes;
- the calendar can safely update its visible month without a late-final runtime failure;
- buttons, inputs, chips, cards, feedback, dialogs, and date pickers share a high-contrast Material
  3 palette and at least a 48-pixel primary target height; and
- the PWA has a real name, description, theme colors, responsive orientation, and current Flutter
  bootstrap, improving home-screen installs and landscape/web use.

Focused narrow-screen widget tests cover the new care tools, full care-profile editor, controlled
section navigation, and collection filtering. The release gate also runs the full frontend test
suite, static analysis, a production web build, backend tests, documentation validation, and the
container build.

## Product inspiration and boundaries

The public PictureThis feature set was reviewed for useful interaction patterns: photo-first
identification, health triage, care plans, household-toxicity warnings, light guidance, reminders,
collections, wishlists, smart discovery, and weed information. Plant-it already had identification,
source-aware care, separate human/cat/dog safety, reminders, owned collections, and a private Trail
Journal. Release 0.17.0 adds the high-value health and light workflows while keeping them honest and
self-hosting friendly.

The maintained roadmap records the next suitable ideas: a private wishlist, preference-based plant
finder, region-specific sourced weed/invasive guidance, calibrated native-device light support,
and opt-in photo health analysis with a complete manual fallback. Expert consultation is not
copied as an implied automated authority; Plant-it should expose evidence and let users decide when
to contact a local Extension office, veterinarian, poison service, or plant professional.
