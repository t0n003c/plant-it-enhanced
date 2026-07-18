package com.github.mdeluise.plantit.unit.component;

import java.time.Instant;
import java.util.List;

import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfo;
import com.github.mdeluise.plantit.plantinfo.care.CuratedCareProvider;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;

@DisplayName("Unit tests for the curated plant-care catalog")
class CuratedCareProviderUnitTests {
    private CuratedCareProvider provider;


    @BeforeEach
    void setUp() {
        provider = new CuratedCareProvider(new ClassPathResource("plant-care-catalog.json"));
    }


    @Test
    @DisplayName("Should cover the plants reported missing by exact scientific name")
    void shouldCoverReportedPlants() {
        final List<String> reportedPlants = List.of(
            "Monstera deliciosa", "Zea mays", "Helianthus annuus", "Lavandula angustifolia", "Rosa",
            "Fragaria ananassa", "Brassica oleracea");

        for (String scientificName : reportedPlants) {
            Assertions.assertTrue(provider.fetch(scientificName).isPresent(), scientificName);
        }
        Assertions.assertTrue(provider.fetch("Rosa rubiginosa").isPresent());
    }


    @Test
    @DisplayName("Should recognize cultivated strawberry hybrid spellings and the GBIF canonical name")
    void shouldRecognizeCultivatedStrawberryNames() {
        final List<String> scientificNames = List.of(
            "Fragaria × ananassa", "Fragaria x ananassa", "Fragaria ananassa");

        for (String scientificName : scientificNames) {
            final PlantCareInfo result = provider.fetch(scientificName).orElseThrow();
            Assertions.assertEquals(8, result.getLight(), scientificName);
            Assertions.assertEquals(6, result.getSoilHumidity(), scientificName);
            Assertions.assertEquals(
                "https://plants.ces.ncsu.edu/plants/fragaria-x-ananassa/",
                result.getSourceReference(), scientificName);
        }
    }


    @Test
    @DisplayName("Should return attributable sunlight, humidity, and watering care")
    void shouldReturnAttributableCare() {
        final PlantCareInfo result = provider.fetch("  Monstera   deliciosa ").orElseThrow();

        Assertions.assertEquals(6, result.getLight());
        Assertions.assertEquals(8, result.getHumidity());
        Assertions.assertEquals(6, result.getSoilHumidity());
        Assertions.assertEquals("CURATED_CATALOG", result.getSource());
        Assertions.assertEquals(
            "https://plants.ces.ncsu.edu/plants/monstera-deliciosa/", result.getSourceReference());
        Assertions.assertEquals(Instant.parse("2026-07-17T00:00:00Z"), result.getLastVerifiedAt());
    }


    @Test
    @DisplayName("Should support accepted taxonomic synonyms without fuzzy matching")
    void shouldSupportSynonymsWithoutFuzzyMatching() {
        Assertions.assertTrue(provider.fetch("Sansevieria trifasciata").isPresent());
        Assertions.assertTrue(provider.fetch("Rosmarinus officinalis").isPresent());
        Assertions.assertTrue(provider.fetch("Monstera").isEmpty());
        Assertions.assertTrue(provider.fetch("sunflower").isEmpty());
    }
}
