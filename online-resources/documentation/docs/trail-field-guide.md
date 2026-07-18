# Trail field guide

Plant-it's field guide is a small, reviewed safety layer for hiking observations. It does not try
to generate ecological ranges or lookalike advice for every identification. A profile is attached
only when the candidate's accepted scientific name, or an explicitly listed scientific synonym,
matches exactly.

## What appears in the app

The first field-guide set contains six ecological profiles and 12 lookalike comparisons:

| Candidate | Reviewed context | Reviewed comparisons |
| --- | --- | --- |
| Eastern poison ivy | Forest edges, paths, and disturbed areas | Virginia creeper, Jack-in-the-pulpit, boxelder |
| Poison hemlock | Sunny railways, rivers, ditches, field edges, farms, and bike paths | Queen Anne's lace, cow parsnip, water hemlock, giant hogweed |
| Giant hogweed | Moist sunny streams, rivers, fields, forests, yards, roadsides, and riparian areas | Cow parsnip, angelica, wild parsnip, Queen Anne's lace |
| Pacific poison oak | Disturbed sites, streams, canyons, foothill oak woodland, chaparral, and slopes below 1,829 m | No comparison published yet |
| Stinging nettle | Stream banks, wet-meadow edges, and shaded moist or riparian places below 3,048 m | No comparison published yet |
| Poodle-dog bush | Post-fire southern California chaparral from 305–2,134 m | Yerba santa |

A candidate card retains the Pl@ntNet visual confidence separately. A matching reviewed habitat
adds at most `0.03`, and a matching reviewed elevation adds at most `0.02`, to the context rank.
Context outside a reviewed range does not subtract points, hide a candidate, or claim that the
candidate is absent. Field notes can be incomplete, and public sources can describe only part of a
taxon's range.

## Review and safety rules

- Use accepted scientific identity and explicit scientific synonyms; never attach advice from a
  common-name or partial-name match.
- Accept a lookalike relationship only when the linked source explicitly describes the confusion
  or comparison.
- Require an HTTPS source from a public land or conservation agency, Extension program, herbarium,
  or similarly accountable botanical authority.
- Keep comparison text short and observable. Do not infer edibility, medicinal use, or safe
  handling.
- Flag another contact hazard independently; a benign-looking comparison must not weaken a safety
  warning.
- Add only positive contextual evidence and keep it smaller than the visual-identification signal.
- Validate every profile and source link at startup and cover exact-name, synonym, context, and
  mobile rendering behavior with tests.

The reviewed data lives in
[`trail-field-guide.json`](https://github.com/t0n003c/plant-it-enhanced/blob/main/backend/src/main/resources/trail-field-guide.json).
This keeps source review separate from the larger everyday-name search index and makes each future
addition auditable in code review.

## Current references

- [NPS: Poison Ivy, Mississippi National River and Recreation Area](https://www.nps.gov/miss/learn/nature/poison_ivy.htm)
- [NPS: Boxelder, Arches National Park](https://home.nps.gov/arch/learn/nature/aceraceae_acer_negundo.htm)
- [University of Minnesota Extension: Poison hemlock](https://extension.umn.edu/identify-invasive-species/poison-hemlock)
- [University of Minnesota Extension: Giant hogweed](https://extension.umn.edu/identify-invasive-species/giant-hogweed)
- [New York State DEC: Giant hogweed and lookalikes](https://dec.ny.gov/nature/animals-fish-plants/plants/harmful-plants/giant-hogweed)
- [USDA Forest Service: Poisonous Plants in Sequoia National Forest](https://www.fs.usda.gov/media/232503)
- [Kew Plants of the World Online: `Turricula parryi` synonymy](https://powo.science.kew.org/taxon/urn%3Alsid%3Aipni.org%3Anames%3A259173-2)

!!! warning "Identification is not a safety decision"

    Never eat, touch, burn, or use a wild plant medicinally because of an app result. Avoid an
    uncertain plant and follow local ranger, Extension, poison-control, or public-health guidance.
