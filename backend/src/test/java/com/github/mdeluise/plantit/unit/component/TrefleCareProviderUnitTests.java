package com.github.mdeluise.plantit.unit.component;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.http.HttpClient;
import java.nio.charset.StandardCharsets;

import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfo;
import com.github.mdeluise.plantit.plantinfo.care.TrefleCareProvider;
import com.github.mdeluise.plantit.plantinfo.config.PlantSearchProperties;
import com.github.mdeluise.plantit.plantinfo.config.TrefleCareProperties;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

@DisplayName("Unit tests for Trefle care enrichment")
class TrefleCareProviderUnitTests {
    private static final String SEARCH_RESPONSE = ProviderContractFixtures.load("trefle-plant-search.json");
    private static final String DETAIL_RESPONSE = ProviderContractFixtures.load("trefle-plant-detail.json");
    private static final String EMPTY_DETAIL_RESPONSE = ProviderContractFixtures.load("trefle-empty-detail.json");
    private HttpServer server;
    private String serverUrl;


    @BeforeEach
    void setUp() throws IOException {
        server = HttpServer.create(new InetSocketAddress(0), 0);
        serverUrl = "http://127.0.0.1:" + server.getAddress().getPort();
        server.createContext("/api/v1/plants/search", exchange -> respond(exchange, SEARCH_RESPONSE));
        server.createContext("/api/v1/plants/monstera-deliciosa",
                             exchange -> respond(exchange, DETAIL_RESPONSE));
        server.createContext("/api/v1/plants/zea-mays",
                             exchange -> respond(exchange, EMPTY_DETAIL_RESPONSE));
        server.start();
    }


    @AfterEach
    void tearDown() {
        server.stop(0);
    }


    @Test
    @DisplayName("Should map attributable light, moisture, temperature, and pH data")
    void shouldMapStructuredCareData() {
        final TrefleCareProperties trefleProperties = Mockito.mock(TrefleCareProperties.class);
        final PlantSearchProperties searchProperties = Mockito.mock(PlantSearchProperties.class);
        Mockito.when(trefleProperties.isConfigured()).thenReturn(true);
        Mockito.when(trefleProperties.getUrl()).thenReturn(serverUrl);
        Mockito.when(trefleProperties.getToken()).thenReturn("secret");
        Mockito.when(searchProperties.getUserAgent()).thenReturn("Plant-it unit test");
        final TrefleCareProvider provider = new TrefleCareProvider(
            HttpClient.newHttpClient(), trefleProperties, searchProperties);

        final PlantCareInfo result = provider.fetch("Monstera deliciosa").orElseThrow();

        Assertions.assertEquals(7, result.getLight());
        Assertions.assertEquals(5, result.getSoilHumidity());
        Assertions.assertEquals(10.0, result.getMinTemp());
        Assertions.assertEquals(30.0, result.getMaxTemp());
        Assertions.assertEquals("TREFLE", result.getSource());
        Assertions.assertEquals("monstera-deliciosa", result.getSourceReference());
        Assertions.assertNotNull(result.getLastVerifiedAt());
    }


    @Test
    @DisplayName("Should treat nested objects containing only null values as missing care data")
    void shouldTreatNestedNullValuesAsMissing() {
        final TrefleCareProperties trefleProperties = Mockito.mock(TrefleCareProperties.class);
        final PlantSearchProperties searchProperties = Mockito.mock(PlantSearchProperties.class);
        Mockito.when(trefleProperties.isConfigured()).thenReturn(true);
        Mockito.when(trefleProperties.getUrl()).thenReturn(serverUrl);
        Mockito.when(trefleProperties.getToken()).thenReturn("secret");
        Mockito.when(searchProperties.getUserAgent()).thenReturn("Plant-it unit test");
        final TrefleCareProvider provider = new TrefleCareProvider(
            HttpClient.newHttpClient(), trefleProperties, searchProperties);

        Assertions.assertTrue(provider.fetch("Zea mays").isEmpty());
    }


    private void respond(HttpExchange exchange, String body) throws IOException {
        final byte[] response = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.sendResponseHeaders(200, response.length);
        exchange.getResponseBody().write(response);
        exchange.close();
    }
}
