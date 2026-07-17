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
import java.util.Optional;

import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfo;
import com.github.mdeluise.plantit.exception.InfoExtractionException;
import com.github.mdeluise.plantit.plantinfo.config.PlantSearchProperties;
import com.github.mdeluise.plantit.plantinfo.config.TrefleCareProperties;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class TrefleCareProvider {
    private static final int HTTP_SUCCESS_MIN = 200;
    private static final int HTTP_SUCCESS_MAX = 300;
    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(10);
    private final HttpClient httpClient;
    private final TrefleCareProperties properties;
    private final PlantSearchProperties searchProperties;


    @Autowired
    public TrefleCareProvider(HttpClient httpClient, TrefleCareProperties properties,
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
            final String slug = match == null ? null : readString(match, "slug");
            final JsonObject root = slug == null ? null : getJson("/api/v1/plants/" + encode(slug));
            final JsonObject data = getObject(root, "data");
            final JsonObject mainSpecies = getObject(data, "main_species");
            final JsonObject careOwner = mainSpecies == null ? data : mainSpecies;
            final JsonObject growth = getObject(careOwner, "growth");
            if (growth != null) {
                result = buildCareInfo(growth, slug);
            }
        }
        return result;
    }


    private Optional<PlantCareInfo> buildCareInfo(JsonObject growth, String slug) {
        final PlantCareInfo result = new PlantCareInfo();
        result.setLight(readInteger(growth, "light"));
        result.setHumidity(readInteger(growth, "atmospheric_humidity"));
        result.setSoilHumidity(readFirstInteger(growth, "soil_humidity", "ground_humidity"));
        result.setPhMin(readDouble(growth, "ph_minimum"));
        result.setPhMax(readDouble(growth, "ph_maximum"));
        result.setMinTemp(readTemperature(growth, "minimum_temperature"));
        result.setMaxTemp(readTemperature(growth, "maximum_temperature"));
        result.setSource("TREFLE");
        result.setSourceReference(slug);
        result.setLastVerifiedAt(Instant.now());
        return result.isAllNull() ? Optional.empty() : Optional.of(result);
    }


    private JsonObject findExactMatch(String scientificName) {
        final JsonObject root = getJson("/api/v1/plants/search?q=" + encode(scientificName));
        final JsonArray data = root.has("data") && root.get("data").isJsonArray()
                                   ? root.getAsJsonArray("data") : new JsonArray();
        for (JsonElement candidateElement : data) {
            final JsonObject candidate = candidateElement.getAsJsonObject();
            if (scientificName.equalsIgnoreCase(readString(candidate, "scientific_name"))) {
                return candidate;
            }
        }
        return null;
    }


    private JsonObject getJson(String pathAndQuery) {
        final String separator = pathAndQuery.contains("?") ? "&" : "?";
        final String baseUrl = properties.getUrl().endsWith("/")
                                   ? properties.getUrl().substring(0, properties.getUrl().length() - 1)
                                   : properties.getUrl();
        final URI uri = URI.create(baseUrl + pathAndQuery + separator + "token=" + encode(properties.getToken()));
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
                throw new InfoExtractionException("Trefle care lookup returned HTTP " + response.statusCode());
            }
            return JsonParser.parseString(response.body()).getAsJsonObject();
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new InfoExtractionException(exception);
        } catch (IOException exception) {
            throw new InfoExtractionException(exception);
        }
    }


    private JsonObject getObject(JsonObject parent, String field) {
        return parent != null && parent.has(field) && parent.get(field).isJsonObject()
                   ? parent.getAsJsonObject(field) : null;
    }


    private String readString(JsonObject object, String field) {
        return object.has(field) && !object.get(field).isJsonNull() ? object.get(field).getAsString() : null;
    }


    private Integer readInteger(JsonObject object, String field) {
        return object.has(field) && !object.get(field).isJsonNull() ? object.get(field).getAsInt() : null;
    }


    private Integer readFirstInteger(JsonObject object, String firstField, String secondField) {
        final Integer first = readInteger(object, firstField);
        return first == null ? readInteger(object, secondField) : first;
    }


    private Double readDouble(JsonObject object, String field) {
        return object.has(field) && !object.get(field).isJsonNull() ? object.get(field).getAsDouble() : null;
    }


    private Double readTemperature(JsonObject growth, String field) {
        Double result = null;
        if (growth.has(field) && !growth.get(field).isJsonNull()) {
            if (growth.get(field).isJsonPrimitive()) {
                result = growth.get(field).getAsDouble();
            } else {
                result = readTemperatureMeasurement(growth.get(field));
            }
        }
        return result;
    }


    private Double readTemperatureMeasurement(JsonElement element) {
        Double result = null;
        if (element.isJsonObject()) {
            final JsonObject measurement = element.getAsJsonObject();
            for (String unit : new String[] {"deg_c", "celsius", "value"}) {
                result = result == null ? readDouble(measurement, unit) : result;
            }
        }
        return result;
    }


    private String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }
}
