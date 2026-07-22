# Support and contributing

## Get help

Search or open an issue in the
[Plant-it Enhanced issue tracker](https://github.com/t0n003c/plant-it-enhanced/issues). Include the
application version from **More → System diagnostics**, the relevant service logs, the deployment
method, and the steps that reproduce the problem. Remove passwords, API keys, JWTs, private
coordinates, and personal photos before posting.

For deployment problems, these commands usually provide the most useful starting point:

```bash
docker compose config --quiet
docker compose ps
docker compose logs --since=10m server db cache
```

## Report a provider problem

State whether the issue affects ordinary name search, Pl@ntNet photo identification, Trefle,
Perenual, iNaturalist, GBIF, or FloraCodex. Copy the HTTP status from diagnostics, but never the API
key. A provider being unconfigured should not break the bundled catalog or ordinary app use.

For a missing search result, photo, or care guide, open **More → Catalog health** and use the copy
button. The report contains catalog totals and sanitized account-local gaps, not API credentials,
photos, notes, or coordinates. Review it before posting and include the everyday query plus the
result you expected. A weekly GitHub workflow also checks all 180 reviewed identities for the
expected iNaturalist image and GBIF taxonomy, so link any open automated provider-canary issue when
the symptoms match.

The bundled catalog is validated as a whole. A fix should add or correct the reviewed identity,
alias, care source, provider contract, or support policy and then run the complete corpus tests;
avoid a UI-only special case for one plant.

## Contribute

1. Fork or clone the repository.
2. Create a focused branch.
3. Add tests and documentation with the change.
4. Run backend verification and frontend analysis/tests.
5. Open a pull request against `t0n003c/plant-it-enhanced`.

Plant-it Enhanced is derived from
[`MDeLuise/plant-it`](https://github.com/MDeLuise/plant-it) and remains GPLv3 licensed. Changes
intended for the upstream project can also be proposed there when they do not depend on fork-only
features.
