package com.github.mdeluise.plantit.unit.component;

import java.util.Map;

import com.github.mdeluise.plantit.botanicalinfo.safety.PlantSafetyInfo;
import com.github.mdeluise.plantit.botanicalinfo.safety.PlantSafetyStatus;
import com.github.mdeluise.plantit.plantinfo.safety.PlantSafetyCatalog;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;

@DisplayName("Unit tests for the reviewed plant-safety catalog")
class PlantSafetyCatalogUnitTests {
    private PlantSafetyCatalog catalog;


    @BeforeEach
    void setUp() {
        catalog = new PlantSafetyCatalog(new ClassPathResource("plant-safety-catalog.json"));
    }


    @Test
    @DisplayName("Should apply a reviewed genus profile to true lily species")
    void shouldApplyTrueLilySafetyToSpecies() {
        final PlantSafetyInfo result = catalog.find("Lilium candidum");

        Assertions.assertTrue(result.reviewed());
        Assertions.assertEquals("Lilium", result.matchedTaxon());
        Assertions.assertEquals(PlantSafetyStatus.UNKNOWN, result.humanStatus());
        Assertions.assertEquals(PlantSafetyStatus.HIGHLY_TOXIC, result.catStatus());
        Assertions.assertEquals(PlantSafetyStatus.NON_TOXIC, result.dogStatus());
        Assertions.assertTrue(result.hazardousParts().contains("Pollen"));
        Assertions.assertEquals(2, result.sources().size());
        Assertions.assertNotNull(result.lastVerifiedAt());
    }


    @Test
    @DisplayName("Should distinguish peace lily safety from true lilies")
    void shouldDistinguishPeaceLily() {
        final PlantSafetyInfo result = catalog.find("Spathiphyllum wallisii");

        Assertions.assertEquals("Spathiphyllum", result.matchedTaxon());
        Assertions.assertEquals(PlantSafetyStatus.TOXIC, result.humanStatus());
        Assertions.assertEquals(PlantSafetyStatus.TOXIC, result.catStatus());
        Assertions.assertEquals(PlantSafetyStatus.TOXIC, result.dogStatus());
        Assertions.assertTrue(result.summary().contains("calcium oxalate"));
    }


    @Test
    @DisplayName("Should never infer safety from an unreviewed lookalike name")
    void shouldReturnExplicitUnknownForUnreviewedTaxa() {
        final PlantSafetyInfo result = catalog.find("Liliumsomething example");

        Assertions.assertFalse(result.reviewed());
        Assertions.assertEquals(PlantSafetyStatus.UNKNOWN, result.humanStatus());
        Assertions.assertEquals(PlantSafetyStatus.UNKNOWN, result.catStatus());
        Assertions.assertEquals(PlantSafetyStatus.UNKNOWN, result.dogStatus());
        Assertions.assertTrue(result.sources().isEmpty());
        Assertions.assertEquals(10, catalog.profileCount());
    }


    @Test
    @DisplayName("Should cover reviewed safety profiles for common indoor plants")
    void shouldCoverCommonIndoorPlants() {
        final Map<String, PlantSafetyStatus> expectedHumanStatus = Map.of(
            "Monstera deliciosa", PlantSafetyStatus.TOXIC,
            "Epipremnum aureum", PlantSafetyStatus.TOXIC,
            "Dracaena trifasciata", PlantSafetyStatus.CAUTION,
            "Aloe vera", PlantSafetyStatus.CAUTION
        );

        expectedHumanStatus.forEach((scientificName, humanStatus) -> {
            final PlantSafetyInfo result = catalog.find(scientificName);
            Assertions.assertTrue(result.reviewed(), scientificName);
            Assertions.assertEquals(humanStatus, result.humanStatus(), scientificName);
            Assertions.assertEquals(PlantSafetyStatus.TOXIC, result.catStatus(), scientificName);
            Assertions.assertEquals(PlantSafetyStatus.TOXIC, result.dogStatus(), scientificName);
            Assertions.assertFalse(result.sources().isEmpty(), scientificName);
        });
    }


    @Test
    @DisplayName("Should expose reviewed Ming aralia safety for people and pets")
    void shouldCoverMingAralia() {
        final PlantSafetyInfo result = catalog.find("Polyscias fruticosa");

        Assertions.assertTrue(result.reviewed());
        Assertions.assertEquals(PlantSafetyStatus.CAUTION, result.humanStatus());
        Assertions.assertEquals(PlantSafetyStatus.CAUTION, result.catStatus());
        Assertions.assertEquals(PlantSafetyStatus.CAUTION, result.dogStatus());
        Assertions.assertEquals("Polyscias fruticosa", result.matchedTaxon());
        Assertions.assertTrue(result.summary().contains("mouth irritation"));
    }
}
