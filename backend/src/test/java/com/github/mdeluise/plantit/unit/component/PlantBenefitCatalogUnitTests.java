package com.github.mdeluise.plantit.unit.component;

import com.github.mdeluise.plantit.botanicalinfo.benefits.PlantBenefitInfo;
import com.github.mdeluise.plantit.plantinfo.benefits.PlantBenefitCatalog;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;

@DisplayName("Unit tests for the reviewed plant-benefit catalog")
class PlantBenefitCatalogUnitTests {
    private PlantBenefitCatalog catalog;


    @BeforeEach
    void setUp() {
        catalog = new PlantBenefitCatalog(new ClassPathResource("plant-benefit-catalog.json"));
    }


    @Test
    @DisplayName("Should provide distinct people and pet notes for peppers")
    void shouldProvidePepperBenefits() {
        final PlantBenefitInfo result = catalog.find("Capsicum annuum");

        Assertions.assertTrue(result.reviewed());
        Assertions.assertEquals(4, result.entries().size());
        Assertions.assertTrue(result.entries().stream().anyMatch(entry ->
            entry.audience().equals("HUMAN") && entry.category().equals("FOOD")));
        Assertions.assertTrue(result.entries().stream().anyMatch(entry ->
            entry.audience().equals("PET") && entry.category().equals("MEDICINE")));
        Assertions.assertFalse(result.sources().isEmpty());
    }


    @Test
    @DisplayName("Should cover cat grass as oat grass enrichment")
    void shouldProvideCatGrassBenefits() {
        final PlantBenefitInfo result = catalog.find("Avena sativa");

        Assertions.assertTrue(result.reviewed());
        Assertions.assertTrue(result.entries().stream().anyMatch(entry ->
            entry.audience().equals("PET") && entry.category().equals("ENRICHMENT")));
        Assertions.assertTrue(result.entries().stream().anyMatch(entry ->
            entry.title().contains("No veterinary treatment")));
    }


    @Test
    @DisplayName("Should keep unreviewed taxa unknown")
    void shouldKeepUnknownTaxaUnknown() {
        final PlantBenefitInfo result = catalog.find("Avena example");

        Assertions.assertFalse(result.reviewed());
        Assertions.assertTrue(result.entries().isEmpty());
    }
}
