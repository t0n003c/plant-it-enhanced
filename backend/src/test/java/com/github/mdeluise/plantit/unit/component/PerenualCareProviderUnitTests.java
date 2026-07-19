package com.github.mdeluise.plantit.unit.component;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.http.HttpClient;
import java.nio.charset.StandardCharsets;

import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfo;
import com.github.mdeluise.plantit.plantinfo.care.PerenualCareProvider;
import com.github.mdeluise.plantit.plantinfo.config.PerenualCareProperties;
import com.github.mdeluise.plantit.plantinfo.config.PlantSearchProperties;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

@DisplayName("Unit tests for Perenual care enrichment")
class PerenualCareProviderUnitTests {
    private static final String SEARCH_RESPONSE =
        ProviderContractFixtures.load("perenual-species-search.json");
    private static final String DETAIL_RESPONSE =
        ProviderContractFixtures.load("perenual-species-detail.json");
    private HttpServer server;
    private String serverUrl;


    @BeforeEach
    void setUp() throws IOException {
        server = HttpServer.create(new InetSocketAddress(0), 0);
        serverUrl = "http://127.0.0.1:" + server.getAddress().getPort();
        server.createContext("/v2/species-list", exchange -> respond(exchange, SEARCH_RESPONSE));
        server.createContext("/v2/species/details/155", exchange -> respond(exchange, DETAIL_RESPONSE));
        server.start();
    }


    @AfterEach
    void tearDown() {
        server.stop(0);
    }


    @Test
    @DisplayName("Should map exact-match watering and sunlight data to the care scale")
    void shouldMapStructuredCareData() {
        final PerenualCareProvider provider = createProvider(true);

        final PlantCareInfo result = provider.fetch("Monstera deliciosa").orElseThrow();

        Assertions.assertEquals(6, result.getLight());
        Assertions.assertEquals(6, result.getSoilHumidity());
        Assertions.assertEquals("PERENUAL", result.getSource());
        Assertions.assertEquals("155", result.getSourceReference());
        Assertions.assertNotNull(result.getLastVerifiedAt());
    }


    @Test
    @DisplayName("Should not attach a similarly named species")
    void shouldRequireAnExactScientificName() {
        final PerenualCareProvider provider = createProvider(true);

        final var result = provider.fetch("Monstera");

        Assertions.assertTrue(result.isEmpty());
    }


    @Test
    @DisplayName("Should remain disabled when no API key is configured")
    void shouldRemainDisabledWithoutApiKey() {
        final PerenualCareProvider provider = createProvider(false);

        Assertions.assertFalse(provider.isConfigured());
        Assertions.assertTrue(provider.fetch("Monstera deliciosa").isEmpty());
    }


    private PerenualCareProvider createProvider(boolean configured) {
        final PerenualCareProperties perenualProperties = Mockito.mock(PerenualCareProperties.class);
        final PlantSearchProperties searchProperties = Mockito.mock(PlantSearchProperties.class);
        Mockito.when(perenualProperties.isConfigured()).thenReturn(configured);
        Mockito.when(perenualProperties.getUrl()).thenReturn(serverUrl);
        Mockito.when(perenualProperties.getApiKey()).thenReturn("secret");
        Mockito.when(searchProperties.getUserAgent()).thenReturn("Plant-it unit test");
        return new PerenualCareProvider(
            HttpClient.newHttpClient(), perenualProperties, searchProperties);
    }


    private void respond(HttpExchange exchange, String body) throws IOException {
        final byte[] response = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.sendResponseHeaders(200, response.length);
        exchange.getResponseBody().write(response);
        exchange.close();
    }
}
