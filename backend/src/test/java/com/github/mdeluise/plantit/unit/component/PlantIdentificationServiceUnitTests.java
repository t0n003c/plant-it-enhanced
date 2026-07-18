package com.github.mdeluise.plantit.unit.component;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.http.HttpClient;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.plantinfo.config.PlantNetProperties;
import com.github.mdeluise.plantit.plantinfo.config.PlantSearchProperties;
import com.github.mdeluise.plantit.plantinfo.identification.PlantIdentificationCandidate;
import com.github.mdeluise.plantit.plantinfo.identification.PlantIdentificationContext;
import com.github.mdeluise.plantit.plantinfo.identification.PlantIdentificationPhoto;
import com.github.mdeluise.plantit.plantinfo.identification.PlantIdentificationService;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.mock.web.MockMultipartFile;

@DisplayName("Unit tests for Pl@ntNet photo identification")
class PlantIdentificationServiceUnitTests {
    private static final String IDENTIFICATION_RESPONSE = """
        {
          "version": "2026-01-01 (8.0)",
          "results": [
            {
              "score": 0.94,
              "species": {
                "scientificNameWithoutAuthor": "Monstera deliciosa",
                "genus": {"scientificNameWithoutAuthor": "Monstera"},
                "family": {"scientificNameWithoutAuthor": "Araceae"},
                "commonNames": ["Swiss cheese plant"]
              },
              "gbif": {"id": "2877284"},
              "powo": {"id": "87469-1"}
            }
          ]
        }
        """;
    private HttpServer server;
    private String serverUrl;


    @BeforeEach
    void setUp() throws IOException {
        server = HttpServer.create(new InetSocketAddress(0), 0);
        serverUrl = "http://127.0.0.1:" + server.getAddress().getPort();
    }


    @AfterEach
    void tearDown() {
        server.stop(0);
    }


    @Test
    @DisplayName("Should return ranked botanical candidates with stable taxonomy identifiers")
    void shouldReturnRankedBotanicalCandidates() {
        final AtomicReference<String> query = new AtomicReference<>();
        final AtomicReference<String> requestBody = new AtomicReference<>();
        server.createContext("/v2/identify/all", exchange -> {
            query.set(exchange.getRequestURI().getRawQuery());
            requestBody.set(new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));
            respond(exchange, IDENTIFICATION_RESPONSE);
        });
        server.start();
        final MockMultipartFile image = new MockMultipartFile(
            "image", "monstera.jpg", "image/jpeg", "fake-jpeg".getBytes(StandardCharsets.UTF_8));

        final List<PlantIdentificationCandidate> result = createService().identify(image, "en");

        Assertions.assertEquals(1, result.size());
        Assertions.assertTrue(query.get().contains("api-key=secret"));
        Assertions.assertTrue(query.get().contains("lang=en"));
        Assertions.assertTrue(requestBody.get().contains("name=\"images\""));
        Assertions.assertTrue(requestBody.get().contains("name=\"organs\""));
        Assertions.assertTrue(requestBody.get().contains("auto"));
        final BotanicalInfo botanicalInfo = result.get(0).botanicalInfo();
        Assertions.assertEquals("Monstera deliciosa", botanicalInfo.getSpecies());
        Assertions.assertEquals("Swiss cheese plant", botanicalInfo.getPreferredCommonName());
        Assertions.assertEquals("2877284", botanicalInfo.getCanonicalTaxonKey());
        Assertions.assertEquals("87469-1", botanicalInfo.getExternalReferences().get("POWO"));
        Assertions.assertEquals(0.94, result.get(0).confidence());
    }


    @Test
    @DisplayName("Should submit several labeled views in one identification request")
    void shouldSubmitMultipleOrganPhotos() {
        final AtomicReference<String> requestBody = new AtomicReference<>();
        server.createContext("/v2/identify/all", exchange -> {
            requestBody.set(new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));
            respond(exchange, IDENTIFICATION_RESPONSE);
        });
        server.start();
        final MockMultipartFile wholePlant = new MockMultipartFile(
            "images", "whole.jpg", "image/jpeg", "whole".getBytes(StandardCharsets.UTF_8));
        final MockMultipartFile leaf = new MockMultipartFile(
            "images", "leaf.png", "image/png", "leaf".getBytes(StandardCharsets.UTF_8));

        final List<PlantIdentificationCandidate> result = createService().identify(List.of(
            new PlantIdentificationPhoto(wholePlant, "auto"),
            new PlantIdentificationPhoto(leaf, "leaf")
        ), "en");

        Assertions.assertEquals(1, result.size());
        Assertions.assertEquals(2, occurrences(requestBody.get(), "name=\"images\""));
        Assertions.assertEquals(2, occurrences(requestBody.get(), "name=\"organs\""));
        Assertions.assertTrue(requestBody.get().contains("leaf"));
    }


    @Test
    @DisplayName("Should choose a regional flora from a coarsened opt-in field location")
    void shouldChooseRegionalFlora() {
        final AtomicReference<String> projectsQuery = new AtomicReference<>();
        server.createContext("/v2/projects", exchange -> {
            projectsQuery.set(exchange.getRequestURI().getRawQuery());
            respond(exchange, """
                [
                  {"id":"useful","title":"Useful plants"},
                  {"id":"k-northern-america","title":"Northern America"}
                ]
                """);
        });
        server.createContext("/v2/identify/k-northern-america", exchange -> respond(
            exchange, IDENTIFICATION_RESPONSE));
        server.start();
        final MockMultipartFile image = new MockMultipartFile(
            "image", "trail-plant.jpg", "image/jpeg", "fake-jpeg".getBytes(StandardCharsets.UTF_8));
        final PlantIdentificationContext context = new PlantIdentificationContext(
            41.8781, -87.6298, 181.0, "woodland edge", Instant.parse("2026-07-18T12:00:00Z"), "US");

        final List<PlantIdentificationCandidate> result = createService(true).identify(
            List.of(new PlantIdentificationPhoto(image, "leaf")), "en", context);

        Assertions.assertEquals("k-northern-america", result.get(0).project().id());
        Assertions.assertEquals("Northern America", result.get(0).project().title());
        Assertions.assertTrue(result.get(0).project().contextual());
        Assertions.assertTrue(projectsQuery.get().contains("lat=42.0"));
        Assertions.assertTrue(projectsQuery.get().contains("lon=-87.5"));
    }


    private PlantIdentificationService createService() {
        return createService(false);
    }


    private PlantIdentificationService createService(boolean locationProjectEnabled) {
        final PlantNetProperties plantNetProperties = Mockito.mock(PlantNetProperties.class);
        final PlantSearchProperties searchProperties = Mockito.mock(PlantSearchProperties.class);
        Mockito.when(plantNetProperties.isConfigured()).thenReturn(true);
        Mockito.when(plantNetProperties.getUrl()).thenReturn(serverUrl);
        Mockito.when(plantNetProperties.getApiKey()).thenReturn("secret");
        Mockito.when(plantNetProperties.getMaximumResults()).thenReturn(5);
        Mockito.when(plantNetProperties.getMinimumConfidence()).thenReturn(0.05);
        Mockito.when(plantNetProperties.isLocationProjectEnabled()).thenReturn(locationProjectEnabled);
        Mockito.when(plantNetProperties.getLocationPrecisionDegrees()).thenReturn(0.5);
        Mockito.when(searchProperties.getLocale()).thenReturn("en");
        Mockito.when(searchProperties.getUserAgent()).thenReturn("Plant-it unit test");
        return new PlantIdentificationService(
            HttpClient.newHttpClient(), plantNetProperties, searchProperties);
    }


    private void respond(HttpExchange exchange, String body) throws IOException {
        final byte[] response = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.sendResponseHeaders(200, response.length);
        exchange.getResponseBody().write(response);
        exchange.close();
    }


    private int occurrences(String value, String token) {
        return value.split(java.util.regex.Pattern.quote(token), -1).length - 1;
    }
}
