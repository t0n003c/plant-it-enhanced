#!/usr/bin/env bash

set -euo pipefail

target_count="${1:-2000}"
catalog_path="${2:-backend/src/main/resources/trusted-common-names.json}"
page_count="${CATALOG_EXPANSION_PAGES:-12}"
per_page="${CATALOG_EXPANSION_PAGE_SIZE:-200}"
api_base="${INATURALIST_TAXA_API:-https://api.inaturalist.org/v1/taxa}"
user_agent="${CATALOG_EXPANSION_USER_AGENT:-Plant-it catalog expansion (https://github.com/t0n003c/plant-it-enhanced)}"

if ! [[ "$target_count" =~ ^[0-9]+$ ]] || [ "$target_count" -lt 1 ]; then
    echo "Target catalog size must be a positive integer" >&2
    exit 1
fi

for command_name in curl jq mktemp; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Required command is not installed: $command_name" >&2
        exit 1
    fi
done

if [ ! -f "$catalog_path" ]; then
    echo "Trusted catalog not found: $catalog_path" >&2
    exit 1
fi

working_dir="$(mktemp -d)"
trap 'rm -rf "$working_dir"' EXIT

for page in $(seq 1 "$page_count"); do
    curl --fail --silent --show-error --location --retry 3 --max-time 30 \
        --user-agent "$user_agent" \
        "$api_base?taxon_id=47126&rank=species&is_active=true&order_by=observations_count&order=desc&per_page=$per_page&page=$page" \
        > "$working_dir/page-$page.json"
done

jq -s '[.[] | .results[]
    | select(.rank == "species" and .is_active == true)
    | select(.name != null and .preferred_common_name != null)
    | select((.name | length) > 0 and (.preferred_common_name | length) > 0)
    | {scientificName: .name, commonName: .preferred_common_name}]' \
    "$working_dir"/page-*.json > "$working_dir/candidates.json"

jq -n \
    --argjson target_count "$target_count" \
    --slurpfile existing "$catalog_path" \
    --slurpfile candidates "$working_dir/candidates.json" '
    def norm:
        ascii_downcase
        | gsub("[^a-z0-9]+"; " ")
        | gsub("^ +| +$"; "")
        | gsub(" +"; " ");

    ($existing[0].entries) as $existing_entries
    | ([$existing_entries[]
        | .scientificName, (.scientificSynonyms[]?), (.commonNames[]?)]
        | map(select(. != null) | norm)
        | unique) as $existing_names
    | reduce $candidates[0][] as $candidate
        ({entries: $existing_entries, names: $existing_names};
         ($candidate.scientificName | norm) as $scientific
         | ($candidate.commonName | norm) as $common
         | if ($scientific == "" or $common == "" or
              (.names | index($scientific)) != null or
              (.names | index($common)) != null)
           then .
           elif (.entries | length) >= $target_count
           then .
           else .entries += [{
                    scientificName: $candidate.scientificName,
                    scientificSynonyms: [],
                    commonNames: [$candidate.commonName],
                    catalogTags: ["SEARCH_DISCOVERY"]
                }]
                | .names += [$scientific, $common]
           end)
    | if (.entries | length) < $target_count
      then error("Only " + ((.entries | length) | tostring) +
                 " unique plant names were available; increase CATALOG_EXPANSION_PAGES")
      else {entries: (.entries[:$target_count])}
      end
    ' > "$working_dir/catalog.json"

mv "$working_dir/catalog.json" "$catalog_path"
jq '{entries: (.entries | length), discoveryEntries: ([.entries[] | select((.catalogTags // []) | index("SEARCH_DISCOVERY"))] | length)}' \
    "$catalog_path"
