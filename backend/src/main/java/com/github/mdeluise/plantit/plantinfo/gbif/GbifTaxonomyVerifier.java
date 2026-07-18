package com.github.mdeluise.plantit.plantinfo.gbif;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoCreator;
import com.github.mdeluise.plantit.plantinfo.config.GbifProperties;
import com.github.mdeluise.plantit.plantinfo.config.PlantSearchProperties;
import com.github.mdeluise.plantit.systeminfo.ProviderStatusRegistry;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParseException;
import com.google.gson.JsonParser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class GbifTaxonomyVerifier {
    private static final int HTTP_SUCCESS_MIN = 200;
    private static final int HTTP_SUCCESS_MAX = 300;
    private static final int HTTP_TOO_MANY_REQUESTS = 429;
    private static final int HTTP_SERVER_ERROR_MIN = 500;
    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(4);
    private static final Duration RETRY_DELAY = Duration.ofMinutes(1);
    private final HttpClient client;
    private final String baseEndpoint;
    private final String userAgent;
    private final int minimumConfidence;
    private volatile Instant unavailableUntil = Instant.EPOCH;
    private final ProviderStatusRegistry providerStatusRegistry;
    private final Logger logger = LoggerFactory.getLogger(GbifTaxonomyVerifier.class);


    public GbifTaxonomyVerifier(HttpClient client, GbifProperties gbifProperties,
                                PlantSearchProperties searchProperties) {
        this(client, gbifProperties, searchProperties, new ProviderStatusRegistry());
    }


    @Autowired
    public GbifTaxonomyVerifier(HttpClient client, GbifProperties gbifProperties,
                                PlantSearchProperties searchProperties,
                                ProviderStatusRegistry providerStatusRegistry) {
        this.client = client;
        this.baseEndpoint = removeTrailingSlash(gbifProperties.getUrl());
        this.userAgent = searchProperties.getUserAgent();
        this.minimumConfidence = gbifProperties.getMinimumConfidence();
        this.providerStatusRegistry = providerStatusRegistry;
    }


    public BotanicalInfo verify(BotanicalInfo candidate) {
        if (Instant.now().isBefore(unavailableUntil)) {
            return candidate;
        }
        final String encodedName = URLEncoder.encode(candidate.getSpecies(), StandardCharsets.UTF_8);
        final String url = String.format("%s/v2/species/match?scientificName=%s&kingdom=Plantae",
                                         baseEndpoint, encodedName);
        final HttpRequest request = HttpRequest.newBuilder()
                                               .uri(URI.create(url))
                                               .header("Accept", "application/json")
                                               .header("User-Agent", userAgent)
                                               .timeout(REQUEST_TIMEOUT)
                                               .GET()
                                               .build();
        try {
            final HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() < HTTP_SUCCESS_MIN || response.statusCode() >= HTTP_SUCCESS_MAX) {
                providerStatusRegistry.recordFailure(
                    "GBIF", response.statusCode(), "GBIF verification returned HTTP " + response.statusCode(),
                    quotaRemaining(response));
                logger.warn("GBIF verification returned HTTP {}", response.statusCode());
                if (response.statusCode() == HTTP_TOO_MANY_REQUESTS ||
                        response.statusCode() >= HTTP_SERVER_ERROR_MIN) {
                    markUnavailable();
                }
                return candidate;
            }
            providerStatusRegistry.recordSuccess("GBIF", response.statusCode(), quotaRemaining(response));
            unavailableUntil = Instant.EPOCH;
            applyVerification(candidate, JsonParser.parseString(response.body()).getAsJsonObject());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            markUnavailable();
            logger.warn("GBIF verification interrupted for {}", candidate.getSpecies());
        } catch (IOException | JsonParseException | IllegalStateException | UnsupportedOperationException |
                 NullPointerException | NumberFormatException e) {
            providerStatusRegistry.recordFailure("GBIF", 0, e.getMessage(), null);
            markUnavailable();
            logger.warn("Unable to verify {} with GBIF: {}", candidate.getSpecies(), e.getMessage());
        }
        return candidate;
    }


    private void markUnavailable() {
        unavailableUntil = Instant.now().plus(RETRY_DELAY);
    }


    private void applyVerification(BotanicalInfo candidate, JsonObject response) {
        final JsonObject diagnostics = getObject(response, "diagnostics");
        if (diagnostics == null || readInt(diagnostics, "confidence") < minimumConfidence) {
            return;
        }
        final JsonObject acceptedUsage = getObject(response, "acceptedUsage");
        final JsonObject usage = acceptedUsage != null ? acceptedUsage : getObject(response, "usage");
        if (usage == null || !"SPECIES".equalsIgnoreCase(readString(usage, "rank"))) {
            return;
        }

        final String originalScientificName = candidate.getSpecies();
        final String acceptedScientificName = readString(usage, "canonicalName");
        if (acceptedScientificName != null && !acceptedScientificName.equalsIgnoreCase(originalScientificName)) {
            candidate.getSynonyms().add(originalScientificName);
            candidate.setSpecies(acceptedScientificName);
        }
        final String gbifKey = readString(usage, "key");
        if (gbifKey != null) {
            candidate.getExternalReferences().put(BotanicalInfoCreator.GBIF.name(), gbifKey);
            candidate.setCanonicalTaxonKey(gbifKey);
        }
        applyClassification(candidate, response.get("classification"));
        candidate.setLastVerifiedAt(Instant.now());
    }


    private void applyClassification(BotanicalInfo candidate, JsonElement classificationElement) {
        if (classificationElement == null || !classificationElement.isJsonArray()) {
            return;
        }
        classificationElement.getAsJsonArray().forEach(element -> {
            final JsonObject classification = element.getAsJsonObject();
            final String rank = readString(classification, "rank");
            if ("FAMILY".equalsIgnoreCase(rank)) {
                candidate.setFamily(readString(classification, "name"));
            } else if ("GENUS".equalsIgnoreCase(rank)) {
                candidate.setGenus(readString(classification, "name"));
            }
        });
    }


    private JsonObject getObject(JsonObject parent, String key) {
        return parent.has(key) && parent.get(key).isJsonObject() ? parent.getAsJsonObject(key) : null;
    }


    private String readString(JsonObject object, String key) {
        return object.has(key) && !object.get(key).isJsonNull() ? object.get(key).getAsString() : null;
    }


    private int readInt(JsonObject object, String key) {
        return object.has(key) && !object.get(key).isJsonNull() ? object.get(key).getAsInt() : 0;
    }


    private static String removeTrailingSlash(String value) {
        return value.endsWith("/") ? value.substring(0, value.length() - 1) : value;
    }


    private String quotaRemaining(HttpResponse<?> response) {
        return response.headers().firstValue("x-ratelimit-remaining").orElse(null);
    }
}
