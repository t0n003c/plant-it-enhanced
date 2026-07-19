package com.github.mdeluise.plantit.unit.component;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.http.HttpClient;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.plantinfo.config.GbifProperties;
import com.github.mdeluise.plantit.plantinfo.config.INaturalistProperties;
import com.github.mdeluise.plantit.plantinfo.config.PlantSearchProperties;
import com.github.mdeluise.plantit.plantinfo.gbif.GbifTaxonomyVerifier;
import com.github.mdeluise.plantit.plantinfo.inaturalist.INaturalistRequestMaker;
import com.github.mdeluise.plantit.plantinfo.inaturalist.INaturalistRequestThrottle;
import com.github.mdeluise.plantit.plantinfo.search.TrustedCommonNameIndex;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

@DisplayName("Unit tests for iNaturalist common-name search")
class INaturalistRequestMakerUnitTests {
    private static final String AUTOCOMPLETE_RESPONSE =
        ProviderContractFixtures.load("inaturalist-taxa-autocomplete.json");
    private static final String GBIF_RESPONSE =
        ProviderContractFixtures.load("gbif-species-match.json");
    private static final String VARIETY_RESPONSE =
        ProviderContractFixtures.load("inaturalist-variety-autocomplete.json");
    private static final String GBIF_VARIETY_RESPONSE =
        ProviderContractFixtures.load("gbif-variety-match.json");
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
    @DisplayName("Should rank regional common names and merge accepted-name duplicates")
    void shouldRankAndMergeAcceptedTaxa() {
        final AtomicReference<String> naturalistQuery = new AtomicReference<>();
        server.createContext("/v1/taxa/autocomplete", exchange -> {
            naturalistQuery.set(exchange.getRequestURI().getRawQuery());
            respond(exchange, AUTOCOMPLETE_RESPONSE);
        });
        server.createContext("/v2/species/match", exchange -> respond(exchange, GBIF_RESPONSE));
        server.start();

        final INaturalistRequestMaker requestMaker = createRequestMaker();
        final List<BotanicalInfo> results = requestMaker.search("snake plant", 5);

        Assertions.assertTrue(naturalistQuery.get().contains("q=snake+plant"));
        Assertions.assertTrue(naturalistQuery.get().contains("rank=species,hybrid,subspecies,variety"));
        Assertions.assertTrue(naturalistQuery.get().contains("locale=en"));
        Assertions.assertTrue(naturalistQuery.get().contains("preferred_place_id=1"));
        Assertions.assertEquals(1, results.size());
        final BotanicalInfo result = results.get(0);
        Assertions.assertEquals("Dracaena trifasciata", result.getSpecies());
        Assertions.assertEquals("Snake Plant", result.getPreferredCommonName());
        Assertions.assertEquals("67710", result.getExternalId());
        Assertions.assertEquals("67710", result.getExternalReferences().get("INATURALIST"));
        Assertions.assertEquals("11041822", result.getExternalReferences().get("GBIF"));
        Assertions.assertTrue(result.getSynonyms().contains("Sansevieria trifasciata"));
        Assertions.assertTrue(result.getCommonNames().stream()
                                    .anyMatch(name -> "Mother-in-Law's Tongue".equals(name.getName())));
        Assertions.assertNotNull(result.getImage());
        Assertions.assertNull(result.getImage().getId());
        Assertions.assertEquals("https://static.inaturalist.org/photos/12345/medium.jpeg",
                                result.getImage().getUrl());
        Assertions.assertEquals("https://static.inaturalist.org/photos/12345/square.jpeg",
                                result.getImage().getFallbackUrl());
        Assertions.assertEquals("INATURALIST", result.getImage().getSource());
        Assertions.assertEquals("https://www.inaturalist.org/photos/12345", result.getImage().getSourceUrl());
        Assertions.assertEquals("cc-by", result.getImage().getLicenseCode());
        Assertions.assertEquals("(c) Example Photographer, CC BY", result.getImage().getAttribution());
    }


    @Test
    @DisplayName("Should keep an exact cultivated-hybrid match ahead of crowded related names")
    void shouldIncludeCultivatedHybrids() {
        final AtomicReference<String> naturalistQuery = new AtomicReference<>();
        server.createContext("/v1/taxa/autocomplete", exchange -> {
            naturalistQuery.set(exchange.getRequestURI().getRawQuery());
            respond(exchange, crowdedStrawberryResponse());
        });
        server.createContext("/v2/species/match", exchange -> {
            if (exchange.getRequestURI().getRawQuery().contains("Fragaria")) {
                respond(exchange, """
                    {
                      "usage": {
                        "key": "3029912",
                        "canonicalName": "Fragaria ananassa",
                        "rank": "SPECIES"
                      },
                      "classification": [
                        {"rank": "FAMILY", "name": "Rosaceae"},
                        {"rank": "GENUS", "name": "Fragaria"}
                      ],
                      "diagnostics": {"confidence": 99}
                    }
                    """);
                return;
            }
            respond(exchange, "{\"diagnostics\":{\"confidence\":0}}");
        });
        server.start();

        final List<BotanicalInfo> results = createRequestMaker().search("strawberry", 5);

        Assertions.assertTrue(naturalistQuery.get().contains("rank=species,hybrid,subspecies,variety"));
        Assertions.assertEquals(5, results.size());
        final BotanicalInfo result = results.get(0);
        Assertions.assertEquals("Fragaria ananassa", result.getSpecies());
        Assertions.assertEquals("garden strawberry", result.getPreferredCommonName());
        Assertions.assertEquals("3029912", result.getCanonicalTaxonKey());
        Assertions.assertEquals(
            "https://inaturalist-open-data.s3.amazonaws.com/photos/74966564/medium.jpg",
            result.getImage().getUrl());
        Assertions.assertEquals("cc-by-nc", result.getImage().getLicenseCode());
        Assertions.assertEquals(
            "https://www.inaturalist.org/photos/74966564", result.getImage().getSourceUrl());
    }


    @Test
    @DisplayName("Should enrich a trusted everyday alias through its accepted scientific name")
    void shouldEnrichTrustedEverydayAlias() {
        final AtomicReference<String> naturalistQuery = new AtomicReference<>();
        server.createContext("/v1/taxa/autocomplete", exchange -> {
            naturalistQuery.set(exchange.getRequestURI().getRawQuery());
            respond(exchange, """
                {
                  "results": [{
                    "id": 122971,
                    "name": "Zingiber officinale",
                    "rank": "species",
                    "iconic_taxon_name": "Plantae",
                    "preferred_common_name": "Ginger",
                    "matched_term": "Zingiber officinale",
                    "observations_count": 2225,
                    "default_photo": {
                      "id": 247973845,
                      "medium_url": "https://static.inaturalist.org/photos/247973845/medium.jpeg",
                      "square_url": "https://static.inaturalist.org/photos/247973845/square.jpeg"
                    }
                  }]
                }
                """);
        });
        server.createContext("/v2/species/match", exchange -> respond(exchange, """
            {
              "usage": {
                "key": "2757280",
                "canonicalName": "Zingiber officinale",
                "rank": "SPECIES"
              },
              "classification": [
                {"rank": "FAMILY", "name": "Zingiberaceae"},
                {"rank": "GENUS", "name": "Zingiber"}
              ],
              "diagnostics": {"confidence": 100}
            }
            """));
        server.start();
        final TrustedCommonNameIndex trustedCommonNameIndex = Mockito.mock(TrustedCommonNameIndex.class);
        Mockito.when(trustedCommonNameIndex.resolveProviderSearchTerm("ginger root"))
               .thenReturn("Zingiber officinale");

        final List<BotanicalInfo> results = createRequestMaker(trustedCommonNameIndex).search("ginger root", 5);

        Assertions.assertTrue(naturalistQuery.get().contains("q=Zingiber+officinale"));
        Assertions.assertEquals(1, results.size());
        Assertions.assertEquals("Zingiber officinale", results.get(0).getSpecies());
        Assertions.assertTrue(results.get(0).getSynonyms().contains("ginger root"));
        Assertions.assertEquals("https://static.inaturalist.org/photos/247973845/medium.jpeg",
                                results.get(0).getImage().getUrl());
    }


    @Test
    @DisplayName("Should include an attributed infraspecific plant image")
    void shouldIncludeVarietyImages() {
        server.createContext("/v1/taxa/autocomplete", exchange -> respond(exchange, VARIETY_RESPONSE));
        server.createContext("/v2/species/match", exchange -> respond(exchange, GBIF_VARIETY_RESPONSE));
        server.start();
        final TrustedCommonNameIndex trustedCommonNameIndex = Mockito.mock(TrustedCommonNameIndex.class);
        Mockito.when(trustedCommonNameIndex.resolveProviderSearchTerm("Madagascar dragon tree"))
               .thenReturn("Dracaena reflexa angustifolia");

        final List<BotanicalInfo> results = createRequestMaker(trustedCommonNameIndex).search(
            "Madagascar dragon tree", 5);

        Assertions.assertEquals(1, results.size());
        Assertions.assertEquals("Dracaena reflexa angustifolia", results.get(0).getSpecies());
        Assertions.assertEquals(
            "https://inaturalist-open-data.s3.amazonaws.com/photos/85543245/medium.jpg",
            results.get(0).getImage().getUrl()
        );
    }


    private String crowdedStrawberryResponse() {
        final StringBuilder relatedResults = new StringBuilder();
        for (int index = 0; index < 9; index++) {
            if (!relatedResults.isEmpty()) {
                relatedResults.append(',');
            }
            relatedResults.append("""
                {
                  "id": %d,
                  "name": "Echinocereus example%d",
                  "rank": "species",
                  "iconic_taxon_name": "Plantae",
                  "preferred_common_name": "Strawberry Cactus %d",
                  "matched_term": "Strawberry Cactus %d",
                  "observations_count": %d
                }
                """.formatted(80000 + index, index, index, index, 50000 - index));
        }
        return """
            {
              "results": [
                %s,
                {
                  "id": 55366,
                  "name": "Fragaria × ananassa",
                  "rank": "hybrid",
                  "iconic_taxon_name": "Plantae",
                  "preferred_common_name": "garden strawberry",
                  "matched_term": "strawberry",
                  "observations_count": 9184,
                  "default_photo": {
                    "id": 74966564,
                    "license_code": "cc-by-nc",
                    "attribution": "(c) cinema, some rights reserved (CC BY-NC)",
                    "square_url": "https://inaturalist-open-data.s3.amazonaws.com/photos/74966564/square.jpg",
                    "medium_url": "https://inaturalist-open-data.s3.amazonaws.com/photos/74966564/medium.jpg"
                  }
                }
              ]
            }
            """.formatted(relatedResults);
    }


    @Test
    @DisplayName("Should use the requesting user's locale without applying a different regional place")
    void shouldUseRequestedLocaleAndRegion() {
        final AtomicReference<String> naturalistQuery = new AtomicReference<>();
        server.createContext("/v1/taxa/autocomplete", exchange -> {
            naturalistQuery.set(exchange.getRequestURI().getRawQuery());
            respond(exchange, AUTOCOMPLETE_RESPONSE);
        });
        server.createContext("/v2/species/match", exchange -> respond(exchange, GBIF_RESPONSE));
        server.start();

        final List<BotanicalInfo> results = createRequestMaker().search("snake plant", 5, "de", "DE");

        Assertions.assertTrue(naturalistQuery.get().contains("locale=de"));
        Assertions.assertFalse(naturalistQuery.get().contains("preferred_place_id"));
        Assertions.assertTrue(results.get(0).getCommonNames().stream()
                                     .allMatch(name -> "de".equals(name.getLanguage()) &&
                                                           "DE".equals(name.getRegion())));
    }


    private INaturalistRequestMaker createRequestMaker() {
        final TrustedCommonNameIndex trustedCommonNameIndex = Mockito.mock(TrustedCommonNameIndex.class);
        Mockito.when(trustedCommonNameIndex.resolveProviderSearchTerm(Mockito.anyString()))
               .thenAnswer(invocation -> invocation.getArgument(0));
        return createRequestMaker(trustedCommonNameIndex);
    }


    private INaturalistRequestMaker createRequestMaker(TrustedCommonNameIndex trustedCommonNameIndex) {
        final INaturalistProperties naturalistProperties = Mockito.mock(INaturalistProperties.class);
        final GbifProperties gbifProperties = Mockito.mock(GbifProperties.class);
        final PlantSearchProperties searchProperties = Mockito.mock(PlantSearchProperties.class);
        Mockito.when(naturalistProperties.getUrl()).thenReturn(serverUrl);
        Mockito.when(naturalistProperties.getPreferredPlaceId()).thenReturn(1);
        Mockito.when(naturalistProperties.getRequestsPerSecond()).thenReturn(1);
        Mockito.when(naturalistProperties.getRequestBurst()).thenReturn(2);
        Mockito.when(gbifProperties.getUrl()).thenReturn(serverUrl);
        Mockito.when(gbifProperties.getMinimumConfidence()).thenReturn(90);
        Mockito.when(searchProperties.getLocale()).thenReturn("en");
        Mockito.when(searchProperties.getRegion()).thenReturn("US");
        Mockito.when(searchProperties.getUserAgent()).thenReturn("Plant-it unit test");
        final HttpClient client = HttpClient.newHttpClient();
        final GbifTaxonomyVerifier verifier = new GbifTaxonomyVerifier(client, gbifProperties, searchProperties);
        final INaturalistRequestThrottle throttle = new INaturalistRequestThrottle(naturalistProperties);
        final INaturalistRequestMaker result = new INaturalistRequestMaker(
            client, verifier, throttle, naturalistProperties, searchProperties);
        result.setTrustedCommonNameIndex(trustedCommonNameIndex);
        return result;
    }


    private void respond(HttpExchange exchange, String body) throws IOException {
        final byte[] response = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.sendResponseHeaders(200, response.length);
        exchange.getResponseBody().write(response);
        exchange.close();
    }
}
