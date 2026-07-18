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
import java.util.Comparator;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

import com.github.mdeluise.plantit.plantinfo.config.PlantNetProperties;
import com.github.mdeluise.plantit.plantinfo.config.PlantSearchProperties;
import com.google.gson.JsonElement;
import com.google.gson.JsonParser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Selects a Pl@ntNet geographic flora from a deliberately coarsened location.
 */
@Component
public class PlantNetProjectResolver {
    private static final Logger LOGGER = LoggerFactory.getLogger(PlantNetProjectResolver.class);
    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(10);
    private static final Duration CACHE_TTL = Duration.ofHours(24);
    private static final int MAXIMUM_CACHE_ENTRIES = 512;
    private static final int HTTP_SUCCESS_MIN = 200;
    private static final int HTTP_SUCCESS_MAX = 300;
    private final HttpClient httpClient;
    private final PlantNetProperties properties;
    private final PlantSearchProperties searchProperties;
    private final Map<String, CachedProject> cache = new ConcurrentHashMap<>();


    public PlantNetProjectResolver(HttpClient httpClient, PlantNetProperties properties,
                                   PlantSearchProperties searchProperties) {
        this.httpClient = httpClient;
        this.properties = properties;
        this.searchProperties = searchProperties;
    }


    public PlantNetProject resolve(PlantIdentificationContext context, String language) {
        if (context == null || !context.hasCoordinates() || !properties.isLocationProjectEnabled()) {
            return PlantNetProject.world();
        }
        final IdentificationLocationPrivacy.CoarsenedLocation location = IdentificationLocationPrivacy.coarsen(
            context, properties.getLocationPrecisionDegrees());
        final double latitude = location.latitude();
        final double longitude = location.longitude();
        final String normalizedLanguage = language == null || language.isBlank()
                                              ? searchProperties.getLocale()
                                              : language.trim().toLowerCase(Locale.ROOT);
        final String cacheKey = latitude + ":" + longitude + ":" + normalizedLanguage;
        final CachedProject existing = cache.get(cacheKey);
        if (existing != null && !existing.expired()) {
            return existing.project();
        }
        final PlantNetProject resolved = requestProject(latitude, longitude, normalizedLanguage)
            .orElse(PlantNetProject.world());
        put(cacheKey, resolved);
        return resolved;
    }


    @SuppressWarnings("ReturnCount")
    private Optional<PlantNetProject> requestProject(double latitude, double longitude, String language) {
        final HttpRequest request = HttpRequest.newBuilder()
                                               .uri(projectsUri(latitude, longitude, language))
                                               .header("Accept", "application/json")
                                               .header("User-Agent", searchProperties.getUserAgent())
                                               .timeout(REQUEST_TIMEOUT)
                                               .GET()
                                               .build();
        try {
            final HttpResponse<String> response = httpClient.send(
                request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (response.statusCode() < HTTP_SUCCESS_MIN || response.statusCode() >= HTTP_SUCCESS_MAX) {
                LOGGER.warn("Pl@ntNet project lookup returned HTTP {}; using the world flora",
                    response.statusCode());
                return Optional.empty();
            }
            return parseProject(response.body());
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
            return Optional.empty();
        } catch (IOException | RuntimeException unavailable) {
            LOGGER.warn("Pl@ntNet project lookup unavailable; using the world flora: {}", unavailable.getMessage());
            return Optional.empty();
        }
    }


    private URI projectsUri(double latitude, double longitude, String language) {
        final String baseUrl = properties.getUrl().endsWith("/")
                                   ? properties.getUrl().substring(0, properties.getUrl().length() - 1)
                                   : properties.getUrl();
        final String query = "lat=" + latitude
            + "&lon=" + longitude
            + "&lang=" + encode(language)
            + "&api-key=" + encode(properties.getApiKey());
        return URI.create(baseUrl + "/v2/projects?" + query);
    }


    private Optional<PlantNetProject> parseProject(String responseBody) {
        final JsonElement root = JsonParser.parseString(responseBody);
        if (!root.isJsonArray()) {
            return Optional.empty();
        }
        PlantNetProject first = null;
        for (JsonElement item : root.getAsJsonArray()) {
            if (!item.isJsonObject() || !item.getAsJsonObject().has("id")) {
                continue;
            }
            final String id = item.getAsJsonObject().get("id").getAsString();
            if (!id.matches("[A-Za-z0-9_-]+")) {
                continue;
            }
            final String title = item.getAsJsonObject().has("title")
                && !item.getAsJsonObject().get("title").isJsonNull()
                                     ? item.getAsJsonObject().get("title").getAsString() : id;
            final PlantNetProject candidate = new PlantNetProject(id, title, true);
            if (first == null) {
                first = candidate;
            }
            if (id.startsWith("k-")) {
                return Optional.of(candidate);
            }
        }
        return Optional.ofNullable(first);
    }


    private void put(String cacheKey, PlantNetProject project) {
        if (cache.size() >= MAXIMUM_CACHE_ENTRIES) {
            cache.entrySet().stream()
                 .min(Comparator.comparing(entry -> entry.getValue().cachedAt()))
                 .map(Map.Entry::getKey)
                 .ifPresent(cache::remove);
        }
        cache.put(cacheKey, new CachedProject(project, Instant.now()));
    }


    private String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }


    private record CachedProject(PlantNetProject project, Instant cachedAt) {
        private boolean expired() {
            final Duration ttl = project.contextual() ? CACHE_TTL : Duration.ofMinutes(5);
            return cachedAt.plus(ttl).isBefore(Instant.now());
        }
    }
}
