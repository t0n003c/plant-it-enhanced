package com.github.mdeluise.plantit.plantinfo.identification;

import java.io.ByteArrayOutputStream;
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
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalCommonName;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoCreator;
import com.github.mdeluise.plantit.exception.InfoExtractionException;
import com.github.mdeluise.plantit.plantinfo.config.PlantNetProperties;
import com.github.mdeluise.plantit.plantinfo.config.PlantSearchProperties;
import com.github.mdeluise.plantit.systeminfo.ProviderStatusRegistry;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
@SuppressWarnings("ClassDataAbstractionCoupling")
public class PlantIdentificationService {
    private static final int HTTP_SUCCESS_MIN = 200;
    private static final int HTTP_SUCCESS_MAX = 300;
    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(40);
    private static final int MAXIMUM_RESULTS = 5;
    private static final int MAXIMUM_IMAGES = 5;
    private static final String JPEG_CONTENT_TYPE = "image/jpeg";
    private static final String PNG_CONTENT_TYPE = "image/png";
    private final HttpClient httpClient;
    private final PlantNetProperties properties;
    private final PlantSearchProperties searchProperties;
    private final ProviderStatusRegistry providerStatusRegistry;
    private final PlantNetProjectResolver projectResolver;
    private final PlantIdentificationContextScorer contextScorer;


    public PlantIdentificationService(HttpClient httpClient, PlantNetProperties properties,
                                      PlantSearchProperties searchProperties) {
        this(httpClient, properties, searchProperties, new ProviderStatusRegistry(),
            new PlantNetProjectResolver(httpClient, properties, searchProperties),
            PlantIdentificationContextScorer.noOp());
    }


    @Autowired
    @SuppressWarnings("ParameterNumber")
    public PlantIdentificationService(HttpClient httpClient, PlantNetProperties properties,
                                      PlantSearchProperties searchProperties,
                                      ProviderStatusRegistry providerStatusRegistry,
                                      PlantNetProjectResolver projectResolver,
                                      PlantIdentificationContextScorer contextScorer) {
        this.httpClient = httpClient;
        this.properties = properties;
        this.searchProperties = searchProperties;
        this.providerStatusRegistry = providerStatusRegistry;
        this.projectResolver = projectResolver;
        this.contextScorer = contextScorer;
    }


    public List<PlantIdentificationCandidate> identify(MultipartFile image, String language) {
        return identify(List.of(new PlantIdentificationPhoto(image, "auto")), language);
    }


    public List<PlantIdentificationCandidate> identify(List<PlantIdentificationPhoto> photos, String language) {
        return identify(photos, language, PlantIdentificationContext.empty());
    }


    public List<PlantIdentificationCandidate> identify(List<PlantIdentificationPhoto> photos, String language,
                                                       PlantIdentificationContext context) {
        validate(photos);
        final PlantNetProject project = projectResolver.resolve(context, language);
        final String boundary = "PlantIt-" + UUID.randomUUID();
        final HttpRequest request;
        try {
            request = HttpRequest.newBuilder()
                                 .uri(buildUri(language, project))
                                 .header("Accept", "application/json")
                                 .header("Content-Type", "multipart/form-data; boundary=" + boundary)
                                 .header("User-Agent", searchProperties.getUserAgent())
                                 .timeout(REQUEST_TIMEOUT)
                                 .POST(HttpRequest.BodyPublishers.ofByteArray(buildBody(photos, boundary)))
                                 .build();
        } catch (IOException exception) {
            throw new InfoExtractionException(exception);
        }
        try {
            final HttpResponse<String> response = httpClient.send(
                request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (response.statusCode() < HTTP_SUCCESS_MIN || response.statusCode() >= HTTP_SUCCESS_MAX) {
                providerStatusRegistry.recordFailure(
                    "PLANTNET", response.statusCode(),
                    "Pl@ntNet identification returned HTTP " + response.statusCode(), quotaRemaining(response));
                throw new InfoExtractionException(
                    "Pl@ntNet identification returned HTTP " + response.statusCode());
            }
            providerStatusRegistry.recordSuccess("PLANTNET", response.statusCode(), quotaRemaining(response));
            final List<PlantIdentificationCandidate> candidates = parse(
                response.body(), normalizeLanguage(language), project);
            return contextScorer.rerank(candidates, context, language);
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new InfoExtractionException(exception);
        } catch (IOException exception) {
            providerStatusRegistry.recordFailure("PLANTNET", 0, exception.getMessage(), null);
            throw new InfoExtractionException(exception);
        }
    }


    private void validate(List<PlantIdentificationPhoto> photos) {
        if (!properties.isConfigured()) {
            throw new InfoExtractionException(
                "Photo identification is not configured. Set PLANTNET_API_KEY on the server.");
        }
        if (photos == null || photos.isEmpty()) {
            throw new IllegalArgumentException("At least one plant photo is required");
        }
        if (photos.size() > MAXIMUM_IMAGES) {
            throw new IllegalArgumentException("At most five plant photos can be identified together");
        }
        for (PlantIdentificationPhoto photo : photos) {
            final MultipartFile image = photo == null ? null : photo.image();
            if (image == null || image.isEmpty()) {
                throw new IllegalArgumentException("Plant photos cannot be empty");
            }
            if (!JPEG_CONTENT_TYPE.equalsIgnoreCase(image.getContentType()) &&
                    !PNG_CONTENT_TYPE.equalsIgnoreCase(image.getContentType())) {
                throw new IllegalArgumentException("Plant photos must be JPEG or PNG images");
            }
        }
    }


    private URI buildUri(String language, PlantNetProject project) {
        final String baseUrl = properties.getUrl().endsWith("/")
                                   ? properties.getUrl().substring(0, properties.getUrl().length() - 1)
                                   : properties.getUrl();
        final String query = "api-key=" + encode(properties.getApiKey()) +
                                 "&lang=" + encode(normalizeLanguage(language)) +
                                 "&nb-results=" + Math.min(
                                     MAXIMUM_RESULTS, Math.max(1, properties.getMaximumResults())) +
                                 "&include-related-images=false";
        final String projectId = project.id().matches("[A-Za-z0-9_-]+") ? project.id() : "all";
        return URI.create(baseUrl + "/v2/identify/" + projectId + "?" + query);
    }


    private byte[] buildBody(List<PlantIdentificationPhoto> photos, String boundary) throws IOException {
        final ByteArrayOutputStream output = new ByteArrayOutputStream();
        for (PlantIdentificationPhoto photo : photos) {
            writeImagePart(output, photo.image(), boundary);
            writeTextPart(output, "organs", photo.normalizedOrgan(), boundary);
        }
        output.write(("--" + boundary + "--\r\n").getBytes(StandardCharsets.UTF_8));
        return output.toByteArray();
    }


    private void writeImagePart(ByteArrayOutputStream output, MultipartFile image,
                                String boundary) throws IOException {
        final String filename = image.getOriginalFilename() == null ? "plant.jpg" : image.getOriginalFilename();
        output.write(("--" + boundary + "\r\n").getBytes(StandardCharsets.UTF_8));
        output.write(("Content-Disposition: form-data; name=\"images\"; filename=\"" +
                          sanitizeFilename(filename) + "\"\r\n").getBytes(StandardCharsets.UTF_8));
        output.write(("Content-Type: " + image.getContentType() + "\r\n\r\n")
                         .getBytes(StandardCharsets.UTF_8));
        output.write(image.getBytes());
        output.write("\r\n".getBytes(StandardCharsets.UTF_8));
    }


    private void writeTextPart(ByteArrayOutputStream output, String name, String value,
                               String boundary) throws IOException {
        output.write(("--" + boundary + "\r\n").getBytes(StandardCharsets.UTF_8));
        output.write(("Content-Disposition: form-data; name=\"" + name + "\"\r\n\r\n")
                         .getBytes(StandardCharsets.UTF_8));
        output.write(value.getBytes(StandardCharsets.UTF_8));
        output.write("\r\n".getBytes(StandardCharsets.UTF_8));
    }


    private List<PlantIdentificationCandidate> parse(String responseBody, String language, PlantNetProject project) {
        final JsonObject root = JsonParser.parseString(responseBody).getAsJsonObject();
        final String modelVersion = readString(root, "version");
        final Iterable<JsonElement> results = root.has("results") && root.get("results").isJsonArray()
                                                  ? root.getAsJsonArray("results") : List.of();
        final List<PlantIdentificationCandidate> candidates = new ArrayList<>();
        for (JsonElement resultElement : results) {
            final JsonObject result = resultElement.getAsJsonObject();
            final double confidence = result.has("score") ? result.get("score").getAsDouble() : 0;
            final double minimumConfidence = Math.min(1, Math.max(0, properties.getMinimumConfidence()));
            if (confidence < minimumConfidence) {
                continue;
            }
            final BotanicalInfo botanicalInfo = toBotanicalInfo(result, language);
            if (botanicalInfo != null) {
                candidates.add(new PlantIdentificationCandidate(botanicalInfo, confidence, modelVersion, project));
            }
        }
        return candidates;
    }


    private BotanicalInfo toBotanicalInfo(JsonObject result, String language) {
        if (!result.has("species") || !result.get("species").isJsonObject()) {
            return null;
        }
        final JsonObject species = result.getAsJsonObject("species");
        final String scientificName = readString(species, "scientificNameWithoutAuthor");
        if (scientificName == null || scientificName.isBlank()) {
            return null;
        }
        final BotanicalInfo botanicalInfo = new BotanicalInfo();
        botanicalInfo.setSpecies(scientificName);
        botanicalInfo.setGenus(readNestedScientificName(species, "genus"));
        botanicalInfo.setFamily(readNestedScientificName(species, "family"));
        botanicalInfo.setCreator(BotanicalInfoCreator.PLANTNET);
        botanicalInfo.setSynonyms(new LinkedHashSet<>());
        botanicalInfo.setCommonNames(readCommonNames(species, language));
        botanicalInfo.setExternalReferences(new HashMap<>());
        final String gbifId = readNestedId(result, "gbif");
        final String powoId = readNestedId(result, "powo");
        botanicalInfo.getExternalReferences().put(BotanicalInfoCreator.PLANTNET.name(), scientificName);
        if (gbifId != null) {
            botanicalInfo.getExternalReferences().put(BotanicalInfoCreator.GBIF.name(), gbifId);
            botanicalInfo.setCanonicalTaxonKey(gbifId);
            botanicalInfo.setLastVerifiedAt(Instant.now());
        }
        if (powoId != null) {
            botanicalInfo.getExternalReferences().put("POWO", powoId);
        }
        botanicalInfo.setExternalId(gbifId == null ? scientificName : gbifId);
        return botanicalInfo;
    }


    private Set<BotanicalCommonName> readCommonNames(JsonObject species, String language) {
        final Set<BotanicalCommonName> result = new LinkedHashSet<>();
        if (!species.has("commonNames") || !species.get("commonNames").isJsonArray()) {
            return result;
        }
        boolean preferred = true;
        for (JsonElement name : species.getAsJsonArray("commonNames")) {
            if (!name.isJsonNull() && !name.getAsString().isBlank()) {
                result.add(new BotanicalCommonName(
                    name.getAsString(), language, null, preferred, BotanicalInfoCreator.PLANTNET));
                preferred = false;
            }
        }
        return result;
    }


    private String readNestedScientificName(JsonObject parent, String field) {
        if (!parent.has(field) || !parent.get(field).isJsonObject()) {
            return null;
        }
        return readString(parent.getAsJsonObject(field), "scientificNameWithoutAuthor");
    }


    private String readNestedId(JsonObject parent, String field) {
        if (!parent.has(field) || !parent.get(field).isJsonObject()) {
            return null;
        }
        return readString(parent.getAsJsonObject(field), "id");
    }


    private String readString(JsonObject object, String field) {
        return object.has(field) && !object.get(field).isJsonNull() ? object.get(field).getAsString() : null;
    }


    private String normalizeLanguage(String language) {
        if (language == null || language.isBlank()) {
            return searchProperties.getLocale();
        }
        return language.trim().toLowerCase(Locale.ROOT);
    }


    private String sanitizeFilename(String filename) {
        return filename.replace("\"", "").replace("\r", "").replace("\n", "");
    }


    private String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }


    private String quotaRemaining(HttpResponse<?> response) {
        return response.headers().firstValue("x-ratelimit-remaining").orElse(null);
    }
}
