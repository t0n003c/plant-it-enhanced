package com.github.mdeluise.plantit.plantinfo.care;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfo;
import com.github.mdeluise.plantit.exception.InfoExtractionException;
import com.github.mdeluise.plantit.plantinfo.config.PerenualCareProperties;
import com.github.mdeluise.plantit.plantinfo.config.PlantSearchProperties;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class PerenualCareProvider {
    private static final int HTTP_SUCCESS_MIN = 200;
    private static final int HTTP_SUCCESS_MAX = 300;
    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(10);
    private static final int WATER_NONE = 0;
    private static final int WATER_MINIMUM = 3;
    private static final int WATER_AVERAGE = 6;
    private static final int WATER_FREQUENT = 9;
    private static final int LIGHT_LOW = 2;
    private static final int LIGHT_MODERATE = 6;
    private static final int LIGHT_HIGH = 9;
    private final HttpClient httpClient;
    private final PerenualCareProperties properties;
    private final PlantSearchProperties searchProperties;


    @Autowired
    public PerenualCareProvider(HttpClient httpClient, PerenualCareProperties properties,
                                PlantSearchProperties searchProperties) {
        this.httpClient = httpClient;
        this.properties = properties;
        this.searchProperties = searchProperties;
    }


    public boolean isConfigured() {
        return properties.isConfigured();
    }


    public Optional<PlantCareInfo> fetch(String scientificName) {
        Optional<PlantCareInfo> result = Optional.empty();
        if (properties.isConfigured()) {
            final JsonObject match = findExactMatch(scientificName);
            final Long id = match == null ? null : readLong(match, "id");
            final JsonObject details = id == null ? null : getJson("/v2/species/details/" + id);
            if (details != null) {
                result = buildCareInfo(details, id);
            }
        }
        return result;
    }


    private JsonObject findExactMatch(String scientificName) {
        final JsonObject root = getJson("/v2/species-list?q=" + encode(scientificName));
        final JsonArray data = root.has("data") && root.get("data").isJsonArray()
                                   ? root.getAsJsonArray("data") : new JsonArray();
        for (JsonElement candidateElement : data) {
            final JsonObject candidate = candidateElement.getAsJsonObject();
            if (hasExactScientificName(candidate, scientificName)) {
                return candidate;
            }
        }
        return null;
    }


    private boolean hasExactScientificName(JsonObject candidate, String scientificName) {
        boolean result = false;
        if (candidate.has("scientific_name") && !candidate.get("scientific_name").isJsonNull()) {
            final JsonElement names = candidate.get("scientific_name");
            result = names.isJsonArray()
                         ? containsScientificName(names.getAsJsonArray(), scientificName)
                         : scientificName.equalsIgnoreCase(names.getAsString());
        }
        return result;
    }


    private boolean containsScientificName(JsonArray names, String scientificName) {
        boolean result = false;
        for (JsonElement name : names) {
            if (!name.isJsonNull() && scientificName.equalsIgnoreCase(name.getAsString())) {
                result = true;
                break;
            }
        }
        return result;
    }


    private Optional<PlantCareInfo> buildCareInfo(JsonObject details, Long id) {
        final PlantCareInfo result = new PlantCareInfo();
        result.setLight(mapSunlight(details));
        result.setSoilHumidity(mapWatering(readString(details, "watering")));
        result.setSource("PERENUAL");
        result.setSourceReference(String.valueOf(id));
        result.setLastVerifiedAt(Instant.now());
        return result.isAllNull() ? Optional.empty() : Optional.of(result);
    }


    private Integer mapSunlight(JsonObject details) {
        if (!details.has("sunlight") || !details.get("sunlight").isJsonArray()) {
            return null;
        }
        final List<Integer> values = new ArrayList<>();
        for (JsonElement sunlight : details.getAsJsonArray("sunlight")) {
            if (!sunlight.isJsonNull()) {
                final Integer value = mapSunlightValue(sunlight.getAsString());
                if (value != null) {
                    values.add(value);
                }
            }
        }
        if (values.isEmpty()) {
            return null;
        }
        return (int) Math.round(values.stream().mapToInt(Integer::intValue).average().orElse(0));
    }


    private Integer mapSunlightValue(String value) {
        final String normalized = normalizeCategory(value);
        Integer result = null;
        if (normalized.contains("full sun") || normalized.contains("direct sun")) {
            result = LIGHT_HIGH;
        } else if (normalized.contains("part shade") || normalized.contains("part sun") ||
                normalized.contains("filtered") || normalized.contains("indirect")) {
            result = LIGHT_MODERATE;
        } else if (normalized.contains("full shade") || normalized.contains("deep shade") ||
                normalized.contains("low light")) {
            result = LIGHT_LOW;
        }
        return result;
    }


    private Integer mapWatering(String value) {
        if (value == null) {
            return null;
        }
        return switch (normalizeCategory(value)) {
            case "none" -> WATER_NONE;
            case "minimum" -> WATER_MINIMUM;
            case "average" -> WATER_AVERAGE;
            case "frequent" -> WATER_FREQUENT;
            default -> null;
        };
    }


    private String normalizeCategory(String value) {
        return value.trim().toLowerCase(Locale.ROOT).replace('_', ' ').replace('-', ' ');
    }


    private JsonObject getJson(String pathAndQuery) {
        final String separator = pathAndQuery.contains("?") ? "&" : "?";
        final String baseUrl = properties.getUrl().endsWith("/")
                                   ? properties.getUrl().substring(0, properties.getUrl().length() - 1)
                                   : properties.getUrl();
        final URI uri = URI.create(baseUrl + pathAndQuery + separator + "key=" + encode(properties.getApiKey()));
        final HttpRequest request = HttpRequest.newBuilder()
                                               .uri(uri)
                                               .header("Accept", "application/json")
                                               .header("User-Agent", searchProperties.getUserAgent())
                                               .timeout(REQUEST_TIMEOUT)
                                               .GET()
                                               .build();
        try {
            final HttpResponse<String> response = httpClient.send(
                request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (response.statusCode() < HTTP_SUCCESS_MIN || response.statusCode() >= HTTP_SUCCESS_MAX) {
                throw new InfoExtractionException(
                    "Perenual care lookup returned HTTP " + response.statusCode());
            }
            return JsonParser.parseString(response.body()).getAsJsonObject();
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new InfoExtractionException(exception);
        } catch (IOException exception) {
            throw new InfoExtractionException(exception);
        }
    }


    private Long readLong(JsonObject object, String field) {
        return object.has(field) && !object.get(field).isJsonNull() ? object.get(field).getAsLong() : null;
    }


    private String readString(JsonObject object, String field) {
        return object.has(field) && !object.get(field).isJsonNull() ? object.get(field).getAsString() : null;
    }


    private String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }
}
