package com.github.mdeluise.plantit.plantinfo.identification;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import com.github.mdeluise.plantit.plantinfo.config.ContextualIdentificationProperties;
import com.github.mdeluise.plantit.plantinfo.config.INaturalistProperties;
import com.github.mdeluise.plantit.plantinfo.config.PlantNetProperties;
import com.github.mdeluise.plantit.plantinfo.config.PlantSearchProperties;
import com.github.mdeluise.plantit.plantinfo.inaturalist.INaturalistRequestThrottle;
import com.github.mdeluise.plantit.plantinfo.search.PlantNameNormalizer;
import com.github.mdeluise.plantit.systeminfo.ProviderStatusRegistry;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Reads public, research-grade iNaturalist occurrence counts near a deliberately coarsened location.
 */
@Component
@SuppressWarnings({"ClassDataAbstractionCoupling", "ParameterNumber", "ReturnCount"})
public class INaturalistOccurrenceEvidenceProvider implements PlantOccurrenceEvidenceProvider {
    private static final Logger LOGGER = LoggerFactory.getLogger(INaturalistOccurrenceEvidenceProvider.class);
    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(8);
    private static final Duration CACHE_TTL = Duration.ofHours(12);
    private static final int MAXIMUM_CACHE_ENTRIES = 256;
    private static final int HTTP_SUCCESS_MIN = 200;
    private static final int HTTP_SUCCESS_MAX = 300;
    private static final int MONTHS_PER_YEAR = 12;
    private final HttpClient httpClient;
    private final INaturalistProperties naturalistProperties;
    private final ContextualIdentificationProperties contextualProperties;
    private final PlantNetProperties plantNetProperties;
    private final PlantSearchProperties searchProperties;
    private final INaturalistRequestThrottle requestThrottle;
    private final ProviderStatusRegistry providerStatusRegistry;
    private final Map<String, CachedSnapshot> cache = new ConcurrentHashMap<>();


    public INaturalistOccurrenceEvidenceProvider(HttpClient httpClient,
                                                  INaturalistProperties naturalistProperties,
                                                  ContextualIdentificationProperties contextualProperties,
                                                  PlantNetProperties plantNetProperties,
                                                  PlantSearchProperties searchProperties,
                                                  INaturalistRequestThrottle requestThrottle,
                                                  ProviderStatusRegistry providerStatusRegistry) {
        this.httpClient = httpClient;
        this.naturalistProperties = naturalistProperties;
        this.contextualProperties = contextualProperties;
        this.plantNetProperties = plantNetProperties;
        this.searchProperties = searchProperties;
        this.requestThrottle = requestThrottle;
        this.providerStatusRegistry = providerStatusRegistry;
    }


    @Override
    public PlantOccurrenceSnapshot findNearbySeasonalEvidence(PlantIdentificationContext context, String language) {
        if (!contextualProperties.isEnabled() || !naturalistProperties.isEnabled()
                || context == null || !context.hasCoordinates()) {
            return PlantOccurrenceSnapshot.empty();
        }
        final IdentificationLocationPrivacy.CoarsenedLocation location = IdentificationLocationPrivacy.coarsen(
            context, plantNetProperties.getLocationPrecisionDegrees());
        final List<Integer> months = seasonalMonths(context.observedAt());
        final String locale = normalizeLanguage(language);
        final String cacheKey = location.latitude() + ":" + location.longitude() + ":" + months + ":" + locale
            + ":" + context.region();
        final CachedSnapshot cached = cache.get(cacheKey);
        if (cached != null && !cached.expired()) {
            return cached.snapshot();
        }
        if (!requestThrottle.tryAcquire()) {
            return PlantOccurrenceSnapshot.empty();
        }
        final URI requestUri = buildUri(location, months, locale, context.region());
        final HttpRequest request = HttpRequest.newBuilder()
                                               .uri(requestUri)
                                               .header("Accept", "application/json")
                                               .header("User-Agent", searchProperties.getUserAgent())
                                               .timeout(REQUEST_TIMEOUT)
                                               .GET()
                                               .build();
        try {
            final HttpResponse<String> response = httpClient.send(
                request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (response.statusCode() < HTTP_SUCCESS_MIN || response.statusCode() >= HTTP_SUCCESS_MAX) {
                providerStatusRegistry.recordFailure(
                    "INATURALIST_CONTEXT", response.statusCode(),
                    "iNaturalist context evidence returned HTTP " + response.statusCode(), quotaRemaining(response));
                return PlantOccurrenceSnapshot.empty();
            }
            final PlantOccurrenceSnapshot snapshot = parse(response.body(), requestUri.toString(), months);
            providerStatusRegistry.recordSuccess(
                "INATURALIST_CONTEXT", response.statusCode(), quotaRemaining(response));
            put(cacheKey, snapshot);
            return snapshot;
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
            return PlantOccurrenceSnapshot.empty();
        } catch (IOException | RuntimeException unavailable) {
            LOGGER.warn("iNaturalist context evidence unavailable: {}", unavailable.getMessage());
            providerStatusRegistry.recordFailure(
                "INATURALIST_CONTEXT", 0, unavailable.getMessage(), null);
            return PlantOccurrenceSnapshot.empty();
        }
    }


    private URI buildUri(IdentificationLocationPrivacy.CoarsenedLocation location, List<Integer> months,
                         String language, String requestedRegion) {
        final String baseUrl = removeTrailingSlash(naturalistProperties.getUrl());
        final int radius = Math.max(1, Math.min(500, contextualProperties.getOccurrenceRadiusKm()));
        final int resultLimit = Math.max(1, Math.min(500, contextualProperties.getOccurrenceResultLimit()));
        final StringBuilder query = new StringBuilder()
            .append("lat=").append(location.latitude())
            .append("&lng=").append(location.longitude())
            .append("&radius=").append(radius)
            .append("&month=").append(join(months))
            .append("&iconic_taxa=Plantae")
            .append("&quality_grade=research")
            .append("&per_page=").append(resultLimit)
            .append("&locale=").append(encode(language));
        if (shouldUseConfiguredPlace(requestedRegion)) {
            query.append("&preferred_place_id=").append(naturalistProperties.getPreferredPlaceId());
        }
        return URI.create(baseUrl + "/v1/observations/species_counts?" + query);
    }


    private PlantOccurrenceSnapshot parse(String responseBody, String sourceReference, List<Integer> months) {
        final JsonObject root = JsonParser.parseString(responseBody).getAsJsonObject();
        final Iterable<JsonElement> results = root.has("results") && root.get("results").isJsonArray()
                                                  ? root.getAsJsonArray("results") : List.of();
        final Map<String, PlantOccurrenceEvidence> evidence = new HashMap<>();
        for (JsonElement item : results) {
            if (!item.isJsonObject()) {
                continue;
            }
            final JsonObject result = item.getAsJsonObject();
            final JsonObject taxon = readObject(result, "taxon");
            final String scientificName = readString(taxon, "name");
            if (scientificName == null) {
                continue;
            }
            final JsonObject establishment = readObject(taxon, "establishment_means");
            final JsonObject place = readObject(establishment, "place");
            evidence.put(PlantNameNormalizer.normalize(scientificName), new PlantOccurrenceEvidence(
                result.has("count") ? result.get("count").getAsInt() : 0,
                readString(establishment, "establishment_means"),
                readString(place, "display_name")
            ));
        }
        return new PlantOccurrenceSnapshot(evidence, sourceReference, months);
    }


    private List<Integer> seasonalMonths(Instant observedAt) {
        final int month = (observedAt == null ? Instant.now() : observedAt).atZone(ZoneOffset.UTC).getMonthValue();
        final List<Integer> result = new ArrayList<>();
        result.add(month == 1 ? MONTHS_PER_YEAR : month - 1);
        result.add(month);
        result.add(month == MONTHS_PER_YEAR ? 1 : month + 1);
        return List.copyOf(result);
    }


    private boolean shouldUseConfiguredPlace(String requestedRegion) {
        return naturalistProperties.getPreferredPlaceId() > 0
            && (requestedRegion == null || requestedRegion.isBlank()
                || requestedRegion.equalsIgnoreCase(searchProperties.getRegion()));
    }


    private JsonObject readObject(JsonObject object, String key) {
        return object != null && object.has(key) && object.get(key).isJsonObject()
                   ? object.getAsJsonObject(key) : null;
    }


    private String readString(JsonObject object, String key) {
        return object != null && object.has(key) && !object.get(key).isJsonNull()
                   ? object.get(key).getAsString() : null;
    }


    private String join(List<Integer> values) {
        return values.stream().map(String::valueOf).reduce((left, right) -> left + "," + right).orElse("");
    }


    private String normalizeLanguage(String language) {
        return language == null || language.isBlank()
                   ? searchProperties.getLocale() : language.trim().toLowerCase(Locale.ROOT);
    }


    private String removeTrailingSlash(String value) {
        return value.endsWith("/") ? value.substring(0, value.length() - 1) : value;
    }


    private String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }


    private String quotaRemaining(HttpResponse<?> response) {
        return response.headers().firstValue("x-ratelimit-remaining").orElse(null);
    }


    private void put(String cacheKey, PlantOccurrenceSnapshot snapshot) {
        if (cache.size() >= MAXIMUM_CACHE_ENTRIES) {
            cache.entrySet().stream()
                 .min(Comparator.comparing(entry -> entry.getValue().cachedAt()))
                 .map(Map.Entry::getKey)
                 .ifPresent(cache::remove);
        }
        cache.put(cacheKey, new CachedSnapshot(snapshot, Instant.now()));
    }


    private record CachedSnapshot(PlantOccurrenceSnapshot snapshot, Instant cachedAt) {
        private boolean expired() {
            return cachedAt.plus(CACHE_TTL).isBefore(Instant.now());
        }
    }
}
