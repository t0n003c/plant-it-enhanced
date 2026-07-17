package com.github.mdeluise.plantit.plantinfo.floracodex;

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

import com.github.mdeluise.plantit.botanicalinfo.BotanicalCommonName;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoCreator;
import com.github.mdeluise.plantit.exception.InfoExtractionException;
import com.github.mdeluise.plantit.image.BotanicalInfoImage;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParseException;
import com.google.gson.JsonParser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Component;

@SuppressWarnings("ClassDataAbstractionCoupling")
@Component
public class FloraCodexRequestMaker {
    private static final int HTTP_SUCCESS_MIN = 200;
    private static final int HTTP_SUCCESS_MAX = 300;
    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(8);
    private static final String SPECIES_RANK_FILTER = "filter%5Brank%5D=species";
    private final String token;
    private final String baseEndpoint;
    private final String locale;
    private final String region;
    private final HttpClient client;
    private final Logger logger = LoggerFactory.getLogger(FloraCodexRequestMaker.class);


    @Autowired
    public FloraCodexRequestMaker(@Value("${floracodex.url}") String domain,
                                  @Value("${floracodex.key}") String token,
                                  @Value("${plant-search.locale}") String locale,
                                  @Value("${plant-search.region}") String region) {
        this.baseEndpoint = removeTrailingSlash(domain) + "/v2";
        this.token = token;
        this.locale = locale;
        this.region = region;
        this.client = HttpClient.newHttpClient();
    }


    public FloraCodexRequestMaker(String domain, String token) {
        this(domain, token, "en", "US");
    }


    public Page<BotanicalInfo> fetchInfoFromPartial(String searchTerm, Pageable pageable)
        throws InfoExtractionException {
        logger.debug("Fetching info for \"{}\" from FloraCodex", searchTerm);
        final String encodedSearchTerm = URLEncoder.encode(searchTerm, StandardCharsets.UTF_8);
        final String url = String.format("%s/species?q=%s&%s&page=%s", baseEndpoint, encodedSearchTerm,
                                         SPECIES_RANK_FILTER, pageable.getPageNumber() + 1);
        return fetchPage(url, pageable);
    }


    public Page<BotanicalInfo> fetchAll(Pageable pageable) {
        logger.debug("Fetching all info from FloraCodex");
        final String url = String.format("%s/species?%s&page=%s", baseEndpoint, SPECIES_RANK_FILTER,
                                         pageable.getPageNumber() + 1);
        return fetchPage(url, pageable);
    }


    private Page<BotanicalInfo> fetchPage(String url, Pageable pageable) {
        final HttpRequest request = HttpRequest.newBuilder()
                                               .uri(URI.create(url))
                                               .header("Authorization", "ApiKey " + token)
                                               .header("Accept", "application/json")
                                               .timeout(REQUEST_TIMEOUT)
                                               .GET()
                                               .build();
        final HttpResponse<String> response = send(request);
        if (response.statusCode() < HTTP_SUCCESS_MIN || response.statusCode() >= HTTP_SUCCESS_MAX) {
            throw new InfoExtractionException("FloraCodex returned HTTP " + response.statusCode());
        }

        try {
            final JsonObject responseJson = JsonParser.parseString(response.body()).getAsJsonObject();
            final List<BotanicalInfo> botanicalInfos = new ArrayList<>();
            responseJson.get("data").getAsJsonArray().forEach(plantResult -> addSpecies(
                plantResult, botanicalInfos
            ));
            final long total = readTotal(responseJson, botanicalInfos.size());
            return new PageImpl<>(botanicalInfos, pageable, total);
        } catch (JsonParseException | IllegalStateException | UnsupportedOperationException | NullPointerException |
                 NumberFormatException e) {
            throw new InfoExtractionException(e);
        }
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


    private void addSpecies(JsonElement plantResult, List<BotanicalInfo> botanicalInfos) {
        final JsonObject plantJson = plantResult.getAsJsonObject();
        if (!"species".equalsIgnoreCase(readString(plantJson, "rank"))) {
            return;
        }

        final BotanicalInfo botanicalInfo = new BotanicalInfo();
        botanicalInfo.setCreator(BotanicalInfoCreator.FLORA_CODEX);
        try {
            fillFloraCodexInfo(plantJson, botanicalInfo);
            botanicalInfos.add(botanicalInfo);
        } catch (UnsupportedOperationException e) {
            logger.error("Error while retrieving info about species", e);
        }
    }


    private void fillFloraCodexInfo(JsonObject plantJson, BotanicalInfo botanicalInfo) {
        final String externalId = readString(plantJson, "id");
        botanicalInfo.setExternalId(externalId);
        if (externalId != null) {
            botanicalInfo.getExternalReferences().put(BotanicalInfoCreator.FLORA_CODEX.name(), externalId);
        }
        botanicalInfo.setSpecies(readString(plantJson, "scientific_name"));
        botanicalInfo.setFamily(readString(plantJson, "family"));
        botanicalInfo.setGenus(readString(plantJson, "genus"));

        final String commonName = readString(plantJson, "common_name");
        if (commonName != null && !commonName.equalsIgnoreCase(botanicalInfo.getSpecies())) {
            botanicalInfo.getSynonyms().add(commonName);
            botanicalInfo.getCommonNames().add(new BotanicalCommonName(
                commonName, locale, region, true, BotanicalInfoCreator.FLORA_CODEX
            ));
        }
        final String imageUrl = readString(plantJson, "image_url");
        if (imageUrl != null) {
            fillImage(botanicalInfo, imageUrl);
        }
        botanicalInfo.setLastVerifiedAt(Instant.now());
    }


    private long readTotal(JsonObject responseJson, int fallback) {
        if (responseJson.has("meta") && responseJson.get("meta").isJsonObject()) {
            final JsonObject meta = responseJson.getAsJsonObject("meta");
            if (meta.has("total") && !meta.get("total").isJsonNull()) {
                return meta.get("total").getAsLong();
            }
        }
        return fallback;
    }


    private String readString(JsonObject jsonObject, String key) {
        if (!jsonObject.has(key) || jsonObject.get(key).isJsonNull()) {
            return null;
        }
        final String value = jsonObject.get(key).getAsString();
        return "null".equalsIgnoreCase(value) || value.isBlank() ? null : value;
    }


    private void fillImage(BotanicalInfo botanicalInfo, String imageUrl) throws InfoExtractionException {
        final BotanicalInfoImage abstractEntityImage = new BotanicalInfoImage();
        abstractEntityImage.setUrl(imageUrl);
        abstractEntityImage.setId(null);
        botanicalInfo.setImage(abstractEntityImage);
    }


    private static String removeTrailingSlash(String domain) {
        return domain.endsWith("/") ? domain.substring(0, domain.length() - 1) : domain;
    }
}
