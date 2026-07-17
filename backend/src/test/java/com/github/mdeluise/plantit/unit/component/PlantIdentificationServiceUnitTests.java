package com.github.mdeluise.plantit.unit.component;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.http.HttpClient;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.plantinfo.config.PlantNetProperties;
import com.github.mdeluise.plantit.plantinfo.config.PlantSearchProperties;
import com.github.mdeluise.plantit.plantinfo.identification.PlantIdentificationCandidate;
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
        final BotanicalInfo botanicalInfo = result.get(0).botanicalInfo();
        Assertions.assertEquals("Monstera deliciosa", botanicalInfo.getSpecies());
        Assertions.assertEquals("Swiss cheese plant", botanicalInfo.getPreferredCommonName());
        Assertions.assertEquals("2877284", botanicalInfo.getCanonicalTaxonKey());
        Assertions.assertEquals("87469-1", botanicalInfo.getExternalReferences().get("POWO"));
        Assertions.assertEquals(0.94, result.get(0).confidence());
    }


    private PlantIdentificationService createService() {
        final PlantNetProperties plantNetProperties = Mockito.mock(PlantNetProperties.class);
        final PlantSearchProperties searchProperties = Mockito.mock(PlantSearchProperties.class);
        Mockito.when(plantNetProperties.isConfigured()).thenReturn(true);
        Mockito.when(plantNetProperties.getUrl()).thenReturn(serverUrl);
        Mockito.when(plantNetProperties.getApiKey()).thenReturn("secret");
        Mockito.when(plantNetProperties.getMaximumResults()).thenReturn(5);
        Mockito.when(plantNetProperties.getMinimumConfidence()).thenReturn(0.05);
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
}
