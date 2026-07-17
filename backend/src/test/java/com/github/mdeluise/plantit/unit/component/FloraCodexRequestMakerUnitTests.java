package com.github.mdeluise.plantit.unit.component;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicReference;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.exception.InfoExtractionException;
import com.github.mdeluise.plantit.plantinfo.floracodex.FloraCodexRequestMaker;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;

@DisplayName("Unit tests for FloraCodexRequestMaker")
class FloraCodexRequestMakerUnitTests {
    private static final String SPECIES_RESPONSE = """
        {
          "data": [
            {
              "id": "123",
              "scientific_name": "Epipremnum pinnatum",
              "common_name": "Pothos",
              "rank": "species",
              "family": "Araceae",
              "genus": "Epipremnum",
              "image_url": "https://example.test/pothos.jpg"
            },
            {
              "id": "456",
              "scientific_name": "Epipremnum",
              "common_name": "Pothos",
              "rank": "genus",
              "family": "Araceae",
              "genus": "Epipremnum",
              "image_url": null
            }
          ],
          "meta": {
            "total": 1,
            "per_page": 20,
            "current_page": 1,
            "last_page": 1
          }
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
    @DisplayName("Should search by common name using FloraCodex v2")
    void shouldSearchByCommonNameUsingVersionTwo() {
        final AtomicReference<String> query = new AtomicReference<>();
        final AtomicReference<String> authorization = new AtomicReference<>();
        server.createContext("/v2/species", exchange -> {
            query.set(exchange.getRequestURI().getRawQuery());
            authorization.set(exchange.getRequestHeaders().getFirst("Authorization"));
            respond(exchange, 200, SPECIES_RESPONSE);
        });
        server.start();
        final FloraCodexRequestMaker requestMaker = new FloraCodexRequestMaker(serverUrl + "/", "test-token");

        final Page<BotanicalInfo> result = requestMaker.fetchInfoFromPartial("pothos plant", PageRequest.of(0, 5));

        Assertions.assertEquals("ApiKey test-token", authorization.get());
        Assertions.assertTrue(query.get().contains("q=pothos+plant"));
        Assertions.assertTrue(query.get().contains("filter%5Brank%5D=species"));
        Assertions.assertTrue(query.get().contains("page=1"));
        Assertions.assertEquals(1, result.getContent().size());
        final BotanicalInfo pothos = result.getContent().get(0);
        Assertions.assertEquals("Epipremnum pinnatum", pothos.getScientificName());
        Assertions.assertEquals("Araceae", pothos.getFamily());
        Assertions.assertEquals("Epipremnum", pothos.getGenus());
        Assertions.assertEquals("123", pothos.getExternalId());
        Assertions.assertTrue(pothos.getSynonyms().contains("Pothos"));
        Assertions.assertEquals("Pothos", pothos.getPreferredCommonName());
        Assertions.assertEquals("123", pothos.getExternalReferences().get("FLORA_CODEX"));
        Assertions.assertNotNull(pothos.getLastVerifiedAt());
        Assertions.assertEquals("https://example.test/pothos.jpg", pothos.getImage().getUrl());
    }


    @Test
    @DisplayName("Should report a FloraCodex HTTP error without exposing the API key")
    void shouldReportHttpErrorWithoutExposingApiKey() {
        server.createContext("/v2/species", exchange -> respond(exchange, 401, "{}"));
        server.start();
        final FloraCodexRequestMaker requestMaker = new FloraCodexRequestMaker(serverUrl, "secret-token");

        final InfoExtractionException exception = Assertions.assertThrows(
            InfoExtractionException.class,
            () -> requestMaker.fetchInfoFromPartial("pothos", PageRequest.of(0, 5))
        );

        Assertions.assertTrue(exception.getMessage().contains("HTTP 401"));
        Assertions.assertFalse(exception.getMessage().contains("secret-token"));
    }


    private void respond(HttpExchange exchange, int status, String body) throws IOException {
        final byte[] response = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.sendResponseHeaders(status, response.length);
        exchange.getResponseBody().write(response);
        exchange.close();
    }
}
