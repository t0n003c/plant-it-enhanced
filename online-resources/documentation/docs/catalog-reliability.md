# Catalog reliability

Plant-it Enhanced tests the reviewed catalog as a whole instead of adding UI exceptions for plants
that happen to expose a gap.

## Support contract

| Tier | Entries | Search | Care | Images |
| --- | ---: | --- | --- | --- |
| Cultivated | 87 | Accepted names, synonyms, and reviewed aliases | Reviewed light and soil moisture required | External availability monitored |
| North American trail | 90 | The same identity checks plus trail metadata | Household care intentionally not required | External availability monitored |

All 177 identities and 859 reviewed name queries run through the production search code during a
release. The cultivated tier must remain 87-of-87 for required care fields. Sanitized
recorded responses also exercise the production iNaturalist, GBIF, Trefle, Perenual, and Pl@ntNet
deserializers without calling the network.

A scheduled, retrying, rate-limited workflow checks all 177 reviewed plants against live
iNaturalist image and GBIF taxonomy services. Fourteen stable manifest entries form a faster
representative canary set. Trefle and Pl@ntNet credential checks run when those repository secrets
are configured. The audit does not upload photos or spend Pl@ntNet identification quota for every
catalog entry.

## Your self-hosted health view

Open **More → Catalog health** after signing in. It shows release coverage plus the latest active
quality gaps observed by your account:

- a normalized query returned no result;
- the top result had no usable image; or
- a scientific identity had no structured care data.

Only a sanitized query or scientific name, timestamps, and an occurrence count are stored. Photos,
notes, precise coordinates, credentials, and provider response bodies are not recorded. The data
stays in MySQL on your server, is separated by account, and is deleted with the account. A later
successful request resolves the corresponding gap automatically.

Provider photos are attributed external resources, so no release can guarantee that every image
will remain online forever. Catalog Health calls these runtime-monitored requirements rather than
claiming that the photos are bundled.

Maintainers can find the complete policy and commands in the repository's
[catalog reliability guide](https://github.com/t0n003c/plant-it-enhanced/blob/main/CATALOG_RELIABILITY.md).
