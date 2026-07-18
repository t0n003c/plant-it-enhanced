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
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoCatalogMerger;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoCreator;
import com.github.mdeluise.plantit.exception.InfoExtractionException;
import com.github.mdeluise.plantit.image.BotanicalInfoImage;
import com.github.mdeluise.plantit.plantinfo.config.INaturalistProperties;
import com.github.mdeluise.plantit.plantinfo.config.PlantSearchProperties;
import com.github.mdeluise.plantit.plantinfo.gbif.GbifTaxonomyVerifier;
import com.github.mdeluise.plantit.plantinfo.search.PlantNameNormalizer;
import com.github.mdeluise.plantit.plantinfo.search.PlantSearchScorer;
import com.github.mdeluise.plantit.systeminfo.ProviderStatusRegistry;
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
    private static final String PHOTO_PAGE = "https://www.inaturalist.org/photos/";
    private final HttpClient client;
    private final GbifTaxonomyVerifier gbifTaxonomyVerifier;
    private final INaturalistRequestThrottle requestThrottle;
    private final String baseEndpoint;
    private final String locale;
    private final String region;
    private final int preferredPlaceId;
    private final String userAgent;
    private ProviderStatusRegistry providerStatusRegistry = new ProviderStatusRegistry();


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


    @Autowired
    void setProviderStatusRegistry(ProviderStatusRegistry providerStatusRegistry) {
        this.providerStatusRegistry = providerStatusRegistry;
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
            "%s/v1/taxa/autocomplete?q=%s&rank=species,hybrid&taxon_id=%s&is_active=true&per_page=%s&locale=%s",
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
            providerStatusRegistry.recordFailure(
                "INATURALIST", response.statusCode(), "iNaturalist returned HTTP " + response.statusCode(),
                quotaRemaining(response));
            throw new InfoExtractionException("iNaturalist returned HTTP " + response.statusCode());
        }
        providerStatusRegistry.recordSuccess("INATURALIST", response.statusCode(), quotaRemaining(response));
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

        final Map<String, RankedCandidate> verifiedResults = new LinkedHashMap<>();
        candidates.stream()
                  .limit(Math.min(MAXIMUM_GBIF_VERIFICATIONS, size + 2L))
                  .map(this::verifyCandidate)
                  .forEach(candidate -> mergeCandidate(verifiedResults, candidate));
        return verifiedResults.values().stream()
                  .filter(candidate -> PlantSearchScorer.evaluate(
                      searchTerm, candidate.botanicalInfo()).isRelevant())
                  .sorted(candidateComparator())
                  .limit(size)
                  .map(RankedCandidate::botanicalInfo)
                  .peek(candidate -> PlantSearchScorer.applyMatchMetadata(searchTerm, candidate))
                  .toList();
    }


    private void addCandidate(String searchTerm, JsonObject result, List<RankedCandidate> candidates,
                              String effectiveLocale, String effectiveRegion) {
        if (!isSupportedRank(readString(result, "rank")) ||
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
        applyDefaultPhoto(result, botanicalInfo);
        if (PlantSearchScorer.evaluate(searchTerm, botanicalInfo).isRelevant()) {
            candidates.add(new RankedCandidate(
                botanicalInfo,
                isExactMatch(searchTerm, matchedTerm),
                PlantSearchScorer.score(searchTerm, botanicalInfo),
                readLong(result, "observations_count")
            ));
        }
    }


    private boolean isSupportedRank(String rank) {
        return "species".equalsIgnoreCase(rank) || "hybrid".equalsIgnoreCase(rank);
    }


    private RankedCandidate verifyCandidate(RankedCandidate candidate) {
        final BotanicalInfo verified = gbifTaxonomyVerifier.verify(candidate.botanicalInfo());
        return new RankedCandidate(
            verified, candidate.exactProviderMatch(), candidate.score(), candidate.popularity());
    }


    private void mergeCandidate(Map<String, RankedCandidate> results, RankedCandidate candidate) {
        final String normalizedSpecies = PlantNameNormalizer.normalize(candidate.botanicalInfo().getSpecies());
        final RankedCandidate existing = results.get(normalizedSpecies);
        if (existing == null) {
            results.put(normalizedSpecies, candidate);
            return;
        }
        BotanicalInfoCatalogMerger.mergeInto(existing.botanicalInfo(), candidate.botanicalInfo());
        results.put(normalizedSpecies, new RankedCandidate(
            existing.botanicalInfo(),
            existing.exactProviderMatch() || candidate.exactProviderMatch(),
            Math.max(existing.score(), candidate.score()),
            Math.max(existing.popularity(), candidate.popularity())
        ));
    }


    private void applyDefaultPhoto(JsonObject result, BotanicalInfo botanicalInfo) {
        final JsonObject photo = readObject(result, "default_photo");
        if (photo == null) {
            return;
        }
        final String mediumUrl = firstPresent(readString(photo, "medium_url"), readString(photo, "url"),
                                              readString(photo, "square_url"));
        if (mediumUrl == null) {
            return;
        }
        final BotanicalInfoImage image = new BotanicalInfoImage();
        image.setId(null);
        image.setUrl(mediumUrl);
        image.setFallbackUrl(firstDifferent(mediumUrl, readString(photo, "square_url"),
                                            readString(photo, "url")));
        image.setSource(BotanicalInfoCreator.INATURALIST.name());
        image.setLicenseCode(readString(photo, "license_code"));
        image.setAttribution(readString(photo, "attribution"));
        final String photoId = readString(photo, "id");
        if (photoId != null) {
            image.setSourceUrl(PHOTO_PAGE + photoId);
        }
        botanicalInfo.setImage(image);
    }


    private Comparator<RankedCandidate> candidateComparator() {
        return Comparator.comparing(RankedCandidate::exactProviderMatch)
                         .reversed()
                         .thenComparing(Comparator.comparingInt(RankedCandidate::score).reversed())
                         .thenComparing(Comparator.comparingLong(RankedCandidate::popularity).reversed());
    }


    private boolean isExactMatch(String searchTerm, String matchedTerm) {
        return matchedTerm != null &&
                   PlantNameNormalizer.normalize(searchTerm).equals(PlantNameNormalizer.normalize(matchedTerm));
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


    private JsonObject readObject(JsonObject object, String key) {
        return object.has(key) && object.get(key).isJsonObject() ? object.getAsJsonObject(key) : null;
    }


    private long readLong(JsonObject object, String key) {
        return object.has(key) && !object.get(key).isJsonNull() ? object.get(key).getAsLong() : 0;
    }


    private String firstPresent(String... values) {
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                return value;
            }
        }
        return null;
    }


    private String firstDifferent(String primary, String... alternatives) {
        for (String alternative : alternatives) {
            if (alternative != null && !alternative.isBlank() && !alternative.equals(primary)) {
                return alternative;
            }
        }
        return null;
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


    private String quotaRemaining(HttpResponse<?> response) {
        return response.headers().firstValue("x-ratelimit-remaining").orElse(null);
    }


    private record RankedCandidate(BotanicalInfo botanicalInfo, boolean exactProviderMatch,
                                   int score, long popularity) {
    }
}
