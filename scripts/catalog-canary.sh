#!/bin/sh

set -u

manifest_path="${CATALOG_MANIFEST_PATH:-backend/src/main/resources/catalog-quality-manifest.json}"
trusted_catalog_path="${TRUSTED_CATALOG_PATH:-backend/src/main/resources/trusted-common-names.json}"
report_path="${CATALOG_CANARY_REPORT:-catalog-canary-report.json}"
audit_scope="${CATALOG_CANARY_SCOPE:-representative}"
audit_delay_seconds="${CATALOG_CANARY_DELAY_SECONDS:-0}"
user_agent="${CATALOG_CANARY_USER_AGENT:-Plant-it catalog reliability canary}"
inaturalist_url="${INATURALIST_URL:-https://api.inaturalist.org}"
gbif_url="${GBIF_URL:-https://api.gbif.org}"

if [ ! -f "$manifest_path" ]; then
    echo "Catalog manifest not found: $manifest_path" >&2
    exit 2
fi

for command_name in curl jq mktemp; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Required command is unavailable: $command_name" >&2
        exit 2
    fi
done

canary_tmp_dir=$(mktemp -d)
trap 'rm -rf "$canary_tmp_dir"' EXIT HUP INT TERM
rows_file="$canary_tmp_dir/canaries.jsonl"
results_file="$canary_tmp_dir/results.jsonl"
touch "$results_file"
failures=0

append_result() {
    provider="$1"
    query="$2"
    passed="$3"
    detail="$4"
    jq -cn \
        --arg provider "$provider" \
        --arg query "$query" \
        --argjson passed "$passed" \
        --arg detail "$detail" \
        '{provider: $provider, query: $query, passed: $passed, detail: $detail}' \
        >> "$results_file"
    if [ "$passed" != "true" ]; then
        failures=$((failures + 1))
    fi
}

encode() {
    jq -rn --arg value "$1" '$value | @uri'
}

case "$audit_scope" in
    representative)
        jq -c '.liveCanaries[]' "$manifest_path" > "$rows_file"
        ;;
    full)
        if [ ! -f "$trusted_catalog_path" ]; then
            echo "Trusted catalog not found: $trusted_catalog_path" >&2
            exit 2
        fi
        jq -c '.entries[] | {
            query: (.commonNames[0] // .scientificName),
            providerTerm: .scientificName,
            acceptedScientificNames: ([.scientificName] + (.scientificSynonyms // [])),
            requiresImage: true
        }' "$trusted_catalog_path" > "$rows_file"
        ;;
    *)
        echo "Unsupported CATALOG_CANARY_SCOPE: $audit_scope" >&2
        exit 2
        ;;
esac
audited_plants=$(wc -l < "$rows_file" | tr -d ' ')
while IFS= read -r canary; do
    query=$(printf '%s' "$canary" | jq -r '.query')
    provider_term=$(printf '%s' "$canary" | jq -r '.providerTerm')
    accepted=$(printf '%s' "$canary" | jq -c '.acceptedScientificNames')
    requires_image=$(printf '%s' "$canary" | jq -r '.requiresImage')
    encoded_term=$(encode "$provider_term")

    inaturalist_endpoint="$inaturalist_url/v1/taxa/autocomplete?q=$encoded_term&rank=species,hybrid,subspecies,variety&taxon_id=47126&is_active=true&per_page=10"
    if inaturalist_response=$(curl --retry 2 --retry-all-errors --connect-timeout 10 --max-time 30 \
        -fsS -A "$user_agent" "$inaturalist_endpoint"); then
        if printf '%s' "$inaturalist_response" | jq -e \
            --argjson accepted "$accepted" \
            --argjson requiresImage "$requires_image" '
                def normalized_name:
                    ascii_downcase |
                    gsub("×"; " x ") |
                    gsub(" (var|subsp|ssp)\\. "; " ") |
                    gsub(" x "; " ") |
                    gsub("[^a-z0-9]+"; " ") |
                    gsub("^ +| +$"; "") |
                    gsub(" +"; " ");
                any(.results[];
                    .iconic_taxon_name == "Plantae" and
                    ((.name | normalized_name) as $name |
                     any($accepted[]; (. | normalized_name) == $name)) and
                    (($requiresImage | not) or
                     ((.default_photo.medium_url // .default_photo.url //
                       .default_photo.square_url // "") | length > 0)))
            ' >/dev/null 2>&1; then
            append_result "INATURALIST" "$query" true "accepted taxon and required image are available"
        else
            append_result "INATURALIST" "$query" false "accepted taxon or required image is missing"
        fi
    else
        append_result "INATURALIST" "$query" false "provider request failed after retries"
    fi

    gbif_endpoint="$gbif_url/v2/species/match?scientificName=$encoded_term&kingdom=Plantae"
    if gbif_response=$(curl --retry 2 --retry-all-errors --connect-timeout 10 --max-time 30 \
        -fsS -A "$user_agent" "$gbif_endpoint"); then
        if printf '%s' "$gbif_response" | jq -e \
            --argjson accepted "$accepted" '
                def normalized_name:
                    ascii_downcase |
                    gsub("×"; " x ") |
                    gsub(" (var|subsp|ssp)\\. "; " ") |
                    gsub(" x "; " ") |
                    gsub("[^a-z0-9]+"; " ") |
                    gsub("^ +| +$"; "") |
                    gsub(" +"; " ");
                (.acceptedUsage.canonicalName // .usage.canonicalName // "") as $name |
                any($accepted[]; (. | normalized_name) == ($name | normalized_name)) and
                ((.diagnostics.confidence // 0) >= 90)
            ' >/dev/null 2>&1; then
            append_result "GBIF" "$query" true "accepted taxonomy match is available"
        else
            append_result "GBIF" "$query" false "accepted taxonomy match is missing or low confidence"
        fi
    else
        append_result "GBIF" "$query" false "provider request failed after retries"
    fi

    if [ "$audit_delay_seconds" != "0" ]; then
        sleep "$audit_delay_seconds"
    fi
done < "$rows_file"

if [ -n "${TREFLE_TOKEN:-}" ]; then
    trefle_endpoint="https://trefle.io/api/v1/plants/search?token=$(encode "$TREFLE_TOKEN")&q=Monstera%20deliciosa"
    if trefle_response=$(curl --retry 2 --retry-all-errors --connect-timeout 10 --max-time 30 \
        -fsS -A "$user_agent" "$trefle_endpoint") &&
            printf '%s' "$trefle_response" | jq -e \
                'any(.data[]; .scientific_name == "Monstera deliciosa")' >/dev/null 2>&1; then
        append_result "TREFLE" "Monstera deliciosa" true "configured search contract is healthy"
    else
        append_result "TREFLE" "Monstera deliciosa" false "configured search contract failed"
    fi
else
    append_result "TREFLE" "configuration" true "skipped because no CI token is configured"
fi

if [ -n "${PLANTNET_API_KEY:-}" ]; then
    plantnet_endpoint="https://my-api.plantnet.org/v2/quota?api-key=$(encode "$PLANTNET_API_KEY")"
    if plantnet_response=$(curl --retry 2 --retry-all-errors --connect-timeout 10 --max-time 30 \
        -fsS -A "$user_agent" "$plantnet_endpoint") &&
            printf '%s' "$plantnet_response" | jq -e 'type == "object" or type == "array"' >/dev/null 2>&1; then
        append_result "PLANTNET" "quota" true "configured API key reached the quota endpoint"
    else
        append_result "PLANTNET" "quota" false "configured API key could not reach the quota endpoint"
    fi
else
    append_result "PLANTNET" "configuration" true "skipped because no CI key is configured"
fi

jq -s \
    --arg checkedAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg scope "$audit_scope" \
    --argjson auditedPlants "$audited_plants" \
    --argjson failures "$failures" \
    '{checkedAt: $checkedAt, scope: $scope, auditedPlants: $auditedPlants,
      failures: $failures, results: .}' \
    "$results_file" > "$report_path"

jq -r '.results[] | "\(.provider) \(.query): \(if .passed then "PASS" else "FAIL" end) - \(.detail)"' \
    "$report_path"
echo "Catalog canary failures: $failures"

if [ "$failures" -gt 0 ]; then
    exit 1
fi
