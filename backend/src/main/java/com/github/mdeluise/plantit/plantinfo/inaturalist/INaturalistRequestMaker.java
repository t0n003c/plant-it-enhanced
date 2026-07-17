package com.github.mdeluise.plantit.plantinfo.inaturalist;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalCommonName;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoCreator;
import com.github.mdeluise.plantit.exception.InfoExtractionException;
import com.github.mdeluise.plantit.plantinfo.config.INaturalistProperties;
import com.github.mdeluise.plantit.plantinfo.config.PlantSearchProperties;
import com.github.mdeluise.plantit.plantinfo.gbif.GbifTaxonomyVerifier;
import com.github.mdeluise.plantit.plantinfo.search.PlantNameNormalizer;
import com.github.mdeluise.plantit.plantinfo.search.PlantSearchScorer;
import com.google.gson.JsonObject;
import com.google.gson.JsonParseException;
import com.google.gson.JsonParser;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class INaturalistRequestMaker {
    private static final int HTTP_SUCCESS_MIN = 200;
    private static final int HTTP_SUCCESS_MAX = 300;
    private static final int MINIMUM_CANDIDATES = 10;
    private static final int MAXIMUM_CANDIDATES = 30;
    private static final int CANDIDATE_MULTIPLIER = 3;
    private static final int MAXIMUM_GBIF_VERIFICATIONS = 7;
    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(8);
    private static final String PLANTAE_TAXON_ID = "47126";
    private final HttpClient client;
    private final GbifTaxonomyVerifier gbifTaxonomyVerifier;
    private final INaturalistRequestThrottle requestThrottle;
    private final String baseEndpoint;
    private final String locale;
    private final String region;
    private final int preferredPlaceId;
    private final String userAgent;


    @Autowired
    public INaturalistRequestMaker(HttpClient client,
                                   GbifTaxonomyVerifier gbifTaxonomyVerifier,
                                   INaturalistRequestThrottle requestThrottle,
                                   INaturalistProperties naturalistProperties,
                                   PlantSearchProperties searchProperties) {
        this.client = client;
        this.gbifTaxonomyVerifier = gbifTaxonomyVerifier;
        this.requestThrottle = requestThrottle;
        this.baseEndpoint = removeTrailingSlash(naturalistProperties.getUrl());
        this.locale = searchProperties.getLocale();
        this.region = searchProperties.getRegion();
        this.preferredPlaceId = naturalistProperties.getPreferredPlaceId();
        this.userAgent = searchProperties.getUserAgent();
    }


    public List<BotanicalInfo> search(String searchTerm, int size) {
        return search(searchTerm, size, null, null);
    }


    public List<BotanicalInfo> search(String searchTerm, int size, String requestedLocale, String requestedRegion) {
        if (!requestThrottle.tryAcquire()) {
            throw new InfoExtractionException("iNaturalist request limit reached; using cached or fallback data");
        }
        final String effectiveLocale = fallback(requestedLocale, locale);
        final String effectiveRegion = fallback(requestedRegion, region);
        final int candidateCount = Math.min(MAXIMUM_CANDIDATES,
                                            Math.max(MINIMUM_CANDIDATES, size * CANDIDATE_MULTIPLIER));
        final String encodedSearchTerm = URLEncoder.encode(searchTerm, StandardCharsets.UTF_8);
        String url = String.format(
            "%s/v1/taxa/autocomplete?q=%s&rank=species&taxon_id=%s&is_active=true&per_page=%s&locale=%s",
            baseEndpoint, encodedSearchTerm, PLANTAE_TAXON_ID, candidateCount,
            URLEncoder.encode(effectiveLocale, StandardCharsets.UTF_8)
        );
        if (shouldUseConfiguredPlace(requestedRegion)) {
            url += "&preferred_place_id=" + preferredPlaceId;
        }
        final HttpRequest request = HttpRequest.newBuilder()
                                               .uri(URI.create(url))
                                               .header("Accept", "application/json")
                                               .header("User-Agent", userAgent)
                                               .timeout(REQUEST_TIMEOUT)
                                               .GET()
                                               .build();
        final HttpResponse<String> response = send(request);
        if (response.statusCode() < HTTP_SUCCESS_MIN || response.statusCode() >= HTTP_SUCCESS_MAX) {
            throw new InfoExtractionException("iNaturalist returned HTTP " + response.statusCode());
        }
        try {
            return parseResponse(searchTerm, size, response.body(), effectiveLocale, effectiveRegion);
        } catch (JsonParseException | IllegalStateException | UnsupportedOperationException | NullPointerException |
                 NumberFormatException e) {
            throw new InfoExtractionException(e);
        }
    }


    private List<BotanicalInfo> parseResponse(String searchTerm, int size, String responseBody,
                                              String effectiveLocale, String effectiveRegion) {
        final JsonObject responseJson = JsonParser.parseString(responseBody).getAsJsonObject();
        final List<RankedCandidate> candidates = new ArrayList<>();
        responseJson.get("results").getAsJsonArray().forEach(result -> addCandidate(
            searchTerm, result.getAsJsonObject(), candidates, effectiveLocale, effectiveRegion
        ));
        candidates.sort(candidateComparator());

        final Map<String, BotanicalInfo> verifiedResults = new LinkedHashMap<>();
        candidates.stream()
                  .limit(Math.min(MAXIMUM_GBIF_VERIFICATIONS, size + 2L))
                  .map(RankedCandidate::botanicalInfo)
                  .map(gbifTaxonomyVerifier::verify)
                  .forEach(candidate -> mergeCandidate(verifiedResults, candidate));
        return verifiedResults.values().stream()
                  .sorted((left, right) -> Integer.compare(
                      PlantSearchScorer.score(searchTerm, right), PlantSearchScorer.score(searchTerm, left)
                  ))
                  .limit(size)
                  .toList();
    }


    private void addCandidate(String searchTerm, JsonObject result, List<RankedCandidate> candidates,
                              String effectiveLocale, String effectiveRegion) {
        if (!"species".equalsIgnoreCase(readString(result, "rank")) ||
                !"Plantae".equalsIgnoreCase(readString(result, "iconic_taxon_name"))) {
            return;
        }
        final String scientificName = readString(result, "name");
        final String externalId = readString(result, "id");
        if (scientificName == null || externalId == null) {
            return;
        }

        final BotanicalInfo botanicalInfo = new BotanicalInfo();
        botanicalInfo.setCreator(BotanicalInfoCreator.INATURALIST);
        botanicalInfo.setExternalId(externalId);
        botanicalInfo.setSpecies(scientificName);
        botanicalInfo.setGenus(scientificName.split(" ")[0]);
        botanicalInfo.getExternalReferences().put(BotanicalInfoCreator.INATURALIST.name(), externalId);
        final String commonName = readString(result, "preferred_common_name");
        if (commonName != null) {
            botanicalInfo.getCommonNames().add(new BotanicalCommonName(
                commonName, effectiveLocale, effectiveRegion, true, BotanicalInfoCreator.INATURALIST
            ));
            botanicalInfo.getSynonyms().add(commonName);
        }
        final String matchedTerm = readString(result, "matched_term");
        if (matchedTerm != null && !matchedTerm.equalsIgnoreCase(scientificName)) {
            botanicalInfo.getSynonyms().add(matchedTerm);
        }
        candidates.add(new RankedCandidate(
            botanicalInfo,
            PlantSearchScorer.score(searchTerm, botanicalInfo),
            readLong(result, "observations_count")
        ));
    }


    private void mergeCandidate(Map<String, BotanicalInfo> results, BotanicalInfo candidate) {
        final String normalizedSpecies = PlantNameNormalizer.normalize(candidate.getSpecies());
        final BotanicalInfo existing = results.get(normalizedSpecies);
        if (existing == null) {
            results.put(normalizedSpecies, candidate);
            return;
        }
        existing.getSynonyms().addAll(candidate.getSynonyms());
        existing.getCommonNames().addAll(candidate.getCommonNames());
        candidate.getExternalReferences().forEach(existing.getExternalReferences()::putIfAbsent);
    }


    private Comparator<RankedCandidate> candidateComparator() {
        return Comparator.comparingInt(RankedCandidate::score)
                         .reversed()
                         .thenComparing(Comparator.comparingLong(RankedCandidate::popularity).reversed());
    }


    private HttpResponse<String> send(HttpRequest request) {
        try {
            return client.send(request, HttpResponse.BodyHandlers.ofString());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new InfoExtractionException(e);
        } catch (IOException e) {
            throw new InfoExtractionException(e);
        }
    }


    private String readString(JsonObject object, String key) {
        return object.has(key) && !object.get(key).isJsonNull() ? object.get(key).getAsString() : null;
    }


    private long readLong(JsonObject object, String key) {
        return object.has(key) && !object.get(key).isJsonNull() ? object.get(key).getAsLong() : 0;
    }


    private boolean shouldUseConfiguredPlace(String requestedRegion) {
        return preferredPlaceId > 0 &&
                   (requestedRegion == null || requestedRegion.isBlank() || requestedRegion.equalsIgnoreCase(region));
    }


    private String fallback(String requested, String configured) {
        return requested == null || requested.isBlank() ? configured : requested.trim();
    }


    private static String removeTrailingSlash(String value) {
        return value.endsWith("/") ? value.substring(0, value.length() - 1) : value;
    }


    private record RankedCandidate(BotanicalInfo botanicalInfo, int score, long popularity) {
    }
}
