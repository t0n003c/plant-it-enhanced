# Catalog reliability

Plant-it Enhanced validates the reviewed catalog as a whole so search, photos, and care do not rely
on a growing list of one-off fixes. The release policy lives in
`backend/src/main/resources/catalog-quality-manifest.json`; plant identities and aliases remain in
`trusted-common-names.json`, reviewed care values remain in `plant-care-catalog.json`, and
reviewed household-safety profiles remain in `plant-safety-catalog.json`.

## Support tiers

| Tier | Entries in 0.17.1 | Search contract | Care contract | Image contract |
| --- | ---: | --- | --- | --- |
| Curated cultivated | 87 | Accepted name, reviewed aliases, and synonyms must resolve to one taxon | Reviewed light and soil-moisture fields are required | A provider image is expected and missing results are tracked |
| North American trail | 90 | Same identity and alias validation, plus trail metadata | Household care is intentionally not required | A provider image is expected and missing results are tracked |

An image requirement is not a promise that a photo is bundled or permanently available. Images
come from attributed external providers and can be removed or temporarily unavailable. Release
canaries check representative live records, while the self-hosted application records a local gap
whenever a real search lacks a top-result image.

## What a release validates

- Every reviewed entry belongs to exactly one support tier.
- Every accepted scientific name, reviewed synonym, and everyday alias returns its intended taxon.
- Exact names cannot be assigned to different taxa.
- Every cultivated entry has the care fields required by the manifest.
- Recorded iNaturalist, GBIF, Trefle, Perenual, and Pl@ntNet responses still deserialize through the
  production code.
- Representative live iNaturalist images and GBIF taxonomy matches remain available after retries;
  the scheduled audit expands the same checks across all 177 reviewed entries.
- Every household-safety status maps by exact scientific identity or a deliberately reviewed
  taxonomic scope; unreviewed taxa remain explicitly unknown.
- Optional Trefle and Pl@ntNet repository credentials remain valid when their GitHub secrets are
  configured.

The live checks are deliberately rate-limited and quota-safe. They detect provider outages,
response drift, and reviewed entries whose expected image or accepted taxonomy disappeared. They
do not claim that a photo-identification service can identify every photo or that every provider
contains every plant outside the reviewed catalog.

## Self-hosted gap tracking

Authenticated use can reveal gaps that a fixed test corpus cannot predict. Plant-it stores these
three signals in the local MySQL database:

- `NO_RESULTS`: a normalized search returned no plants;
- `MISSING_IMAGE`: the top search result had no usable image; and
- `MISSING_CARE`: a requested scientific identity produced no structured care fields.

The record contains a sanitized query or scientific name, timestamps, an occurrence count, and the
owning account ID. It does not contain API keys, passwords, photos, precise coordinates, notes, or
provider response bodies. Records are separated by account, never sent to this repository, and
deleted with the owning account. A successful request for the same subject marks its prior gap
resolved.

Open **More → Catalog health** to review current tier coverage and the latest active gaps. The copy
button produces a sanitized JSON report suitable for a GitHub issue; review it before sharing just
as you would any diagnostic output.

## Maintainer workflow

Run the deterministic catalog and provider-contract checks:

```bash
cd backend
mvn -B -ntp \
  -Dtest=CatalogQualityManifestUnitTests,TrustedCommonNameIndexUnitTests,\
CatalogHealthServiceUnitTests,INaturalistRequestMakerUnitTests,\
GbifTaxonomyVerifierUnitTests,TrefleCareProviderUnitTests,\
PerenualCareProviderUnitTests,PlantIdentificationServiceUnitTests test
```

Run the live canary from the repository root (requires `curl` and `jq`):

```bash
./scripts/catalog-canary.sh
```

Run the rate-limited whole-catalog audit used by the scheduled workflow:

```bash
CATALOG_CANARY_SCOPE=full \
CATALOG_CANARY_DELAY_SECONDS=1 \
./scripts/catalog-canary.sh
```

`TREFLE_TOKEN` and `PLANTNET_API_KEY` are optional. Without them, their checks are reported as
skipped while iNaturalist and GBIF still run. The generated `catalog-canary-report.json` is ignored
by Git and contains no credentials. GitHub audits all 177 reviewed entries every Monday and opens
one deduplicated issue if any expected taxonomy or image remains unavailable after retries.

When adding or changing a plant:

1. Add one accepted scientific identity and its reviewed synonyms/aliases to the trusted index.
2. Assign trail and safety tags only when the reviewed evidence supports them.
3. Add the required cultivated-care fields with an attributable source, or intentionally classify
   the entry in a tier that does not require household care.
4. Add a provider contract fixture only when a response shape changes; never include credentials or
   personal data in a fixture.
5. Add a live canary only for a stable, representative failure mode. Do not add every user query to
   the quota-bearing canary list.
6. Run backend verification, Flutter analysis/tests, the production web build, and the live canary.

Provider behavior is documented by the official
[iNaturalist API reference](https://www.inaturalist.org/pages/api%2Breference),
[GBIF Species API](https://techdocs.gbif.org/en/openapi/v1/species),
[Trefle guide](https://docs.trefle.io/docs/guides/getting-started/), and
[Pl@ntNet API documentation](https://my.plantnet.org/doc/api/identify).
