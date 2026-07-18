package com.github.mdeluise.plantit.unit.component;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.http.HttpClient;
import java.time.Instant;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

import com.github.mdeluise.plantit.plantinfo.config.ContextualIdentificationProperties;
import com.github.mdeluise.plantit.plantinfo.config.INaturalistProperties;
import com.github.mdeluise.plantit.plantinfo.config.PlantNetProperties;
import com.github.mdeluise.plantit.plantinfo.config.PlantSearchProperties;
import com.github.mdeluise.plantit.plantinfo.identification.INaturalistOccurrenceEvidenceProvider;
import com.github.mdeluise.plantit.plantinfo.identification.PlantIdentificationContext;
import com.github.mdeluise.plantit.plantinfo.identification.PlantOccurrenceEvidence;
import com.github.mdeluise.plantit.plantinfo.identification.PlantOccurrenceSnapshot;
import com.github.mdeluise.plantit.plantinfo.inaturalist.INaturalistRequestThrottle;
import com.github.mdeluise.plantit.systeminfo.ProviderStatusRegistry;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

@DisplayName("Unit tests for nearby iNaturalist occurrence evidence")
class INaturalistOccurrenceEvidenceProviderUnitTests {
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
    @DisplayName("Should coarsen location, include adjacent months, parse status, and cache the result")
    void shouldReadCoarsenedSeasonalEvidence() {
        final AtomicReference<String> query = new AtomicReference<>();
        final AtomicInteger requests = new AtomicInteger();
        server.createContext("/v1/observations/species_counts", exchange -> {
            query.set(exchange.getRequestURI().getRawQuery());
            requests.incrementAndGet();
            respond(exchange, """
                {
                  "results": [{
                    "count": 42,
                    "taxon": {
                      "name": "Monarda fistulosa",
                      "establishment_means": {
                        "establishment_means": "native",
                        "place": {"display_name": "United States"}
                      }
                    }
                  }]
                }
                """);
        });
        server.start();
        final INaturalistOccurrenceEvidenceProvider provider = createProvider();
        final PlantIdentificationContext context = new PlantIdentificationContext(
            41.8781, -87.6298, 181.0, "prairie edge", Instant.parse("2026-07-18T12:00:00Z"), "US");

        final PlantOccurrenceSnapshot first = provider.findNearbySeasonalEvidence(context, "en");
        final PlantOccurrenceSnapshot second = provider.findNearbySeasonalEvidence(context, "en");

        final PlantOccurrenceEvidence evidence = first.find("Monarda fistulosa");
        Assertions.assertNotNull(evidence);
        Assertions.assertEquals(42, evidence.observationCount());
        Assertions.assertEquals("native", evidence.establishmentMeans());
        Assertions.assertEquals("United States", evidence.establishmentPlace());
        Assertions.assertTrue(query.get().contains("lat=42.0"));
        Assertions.assertTrue(query.get().contains("lng=-87.5"));
        Assertions.assertTrue(query.get().contains("radius=75"));
        Assertions.assertTrue(query.get().contains("month=6,7,8"));
        Assertions.assertTrue(query.get().contains("preferred_place_id=1"));
        Assertions.assertSame(first, second);
        Assertions.assertEquals(1, requests.get());
    }


    private INaturalistOccurrenceEvidenceProvider createProvider() {
        final INaturalistProperties naturalist = Mockito.mock(INaturalistProperties.class);
        final ContextualIdentificationProperties contextual =
            Mockito.mock(ContextualIdentificationProperties.class);
        final PlantNetProperties plantNet = Mockito.mock(PlantNetProperties.class);
        final PlantSearchProperties search = Mockito.mock(PlantSearchProperties.class);
        final INaturalistRequestThrottle throttle = Mockito.mock(INaturalistRequestThrottle.class);
        Mockito.when(naturalist.isEnabled()).thenReturn(true);
        Mockito.when(naturalist.getUrl()).thenReturn(serverUrl);
        Mockito.when(naturalist.getPreferredPlaceId()).thenReturn(1);
        Mockito.when(contextual.isEnabled()).thenReturn(true);
        Mockito.when(contextual.getOccurrenceRadiusKm()).thenReturn(75);
        Mockito.when(contextual.getOccurrenceResultLimit()).thenReturn(100);
        Mockito.when(plantNet.getLocationPrecisionDegrees()).thenReturn(0.5);
        Mockito.when(search.getLocale()).thenReturn("en");
        Mockito.when(search.getRegion()).thenReturn("US");
        Mockito.when(search.getUserAgent()).thenReturn("Plant-it unit test");
        Mockito.when(throttle.tryAcquire()).thenReturn(true);
        return new INaturalistOccurrenceEvidenceProvider(
            HttpClient.newHttpClient(), naturalist, contextual, plantNet, search, throttle,
            new ProviderStatusRegistry());
    }


    private void respond(HttpExchange exchange, String body) throws IOException {
        final byte[] response = body.getBytes(java.nio.charset.StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.sendResponseHeaders(200, response.length);
        exchange.getResponseBody().write(response);
        exchange.close();
    }
}
