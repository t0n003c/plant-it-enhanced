package com.github.mdeluise.plantit.unit.component;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.http.HttpClient;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicReference;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.plantinfo.config.GbifProperties;
import com.github.mdeluise.plantit.plantinfo.config.PlantSearchProperties;
import com.github.mdeluise.plantit.plantinfo.gbif.GbifTaxonomyVerifier;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

@DisplayName("Unit tests for GBIF taxonomy verification")
class GbifTaxonomyVerifierUnitTests {
    private static final String MATCH_RESPONSE = ProviderContractFixtures.load("gbif-species-match.json");
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
    @DisplayName("Should replace a synonym with the accepted scientific name")
    void shouldApplyAcceptedTaxonomy() {
        final AtomicReference<String> query = new AtomicReference<>();
        server.createContext("/v2/species/match", exchange -> {
            query.set(exchange.getRequestURI().getRawQuery());
            respond(exchange, MATCH_RESPONSE);
        });
        server.start();
        final GbifTaxonomyVerifier verifier = createVerifier();
        final BotanicalInfo candidate = new BotanicalInfo();
        candidate.setSpecies("Sansevieria trifasciata");

        final BotanicalInfo result = verifier.verify(candidate);

        Assertions.assertTrue(query.get().contains("scientificName=Sansevieria+trifasciata"));
        Assertions.assertTrue(query.get().contains("kingdom=Plantae"));
        Assertions.assertEquals("Dracaena trifasciata", result.getSpecies());
        Assertions.assertEquals("Dracaena", result.getGenus());
        Assertions.assertEquals("Asparagaceae", result.getFamily());
        Assertions.assertTrue(result.getSynonyms().contains("Sansevieria trifasciata"));
        Assertions.assertEquals("11041822", result.getExternalReferences().get("GBIF"));
        Assertions.assertEquals("11041822", result.getCanonicalTaxonKey());
        Assertions.assertNotNull(result.getLastVerifiedAt());
    }


    private GbifTaxonomyVerifier createVerifier() {
        final GbifProperties gbifProperties = Mockito.mock(GbifProperties.class);
        final PlantSearchProperties searchProperties = Mockito.mock(PlantSearchProperties.class);
        Mockito.when(gbifProperties.getUrl()).thenReturn(serverUrl);
        Mockito.when(gbifProperties.getMinimumConfidence()).thenReturn(90);
        Mockito.when(searchProperties.getUserAgent()).thenReturn("Plant-it unit test");
        return new GbifTaxonomyVerifier(HttpClient.newHttpClient(), gbifProperties, searchProperties);
    }


    private void respond(HttpExchange exchange, String body) throws IOException {
        final byte[] response = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.sendResponseHeaders(200, response.length);
        exchange.getResponseBody().write(response);
        exchange.close();
    }
}
