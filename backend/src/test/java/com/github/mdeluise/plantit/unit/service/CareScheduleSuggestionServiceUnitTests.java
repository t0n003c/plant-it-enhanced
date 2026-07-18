package com.github.mdeluise.plantit.unit.service;

import java.time.Instant;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfo;
import com.github.mdeluise.plantit.plant.Plant;
import com.github.mdeluise.plantit.plant.care.CareScheduleSuggestion;
import com.github.mdeluise.plantit.plant.care.CareScheduleSuggestionService;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("Unit tests for personalized care schedule suggestions")
class CareScheduleSuggestionServiceUnitTests {
    private final CareScheduleSuggestionService service = new CareScheduleSuggestionService();


    @Test
    @DisplayName("Should shorten the soil-check interval for a small bright terracotta pot")
    void shouldApplyDryingEnvironmentFactors() {
        final Plant plant = plantWithSoilMoisture(6);
        plant.getInfo().setGrowingEnvironment("INDOOR");
        plant.getInfo().setLightExposure("HIGH");
        plant.getInfo().setPotDiameterCm(10.0);
        plant.getInfo().setPotMaterial("TERRACOTTA");
        plant.getInfo().setHasDrainage(true);

        final CareScheduleSuggestion result = service.suggest(plant);

        Assertions.assertEquals(4, result.intervalDays());
        Assertions.assertTrue(result.factors().contains("HIGH_LIGHT"));
        Assertions.assertTrue(result.factors().contains("SMALL_POT"));
        Assertions.assertTrue(result.factors().contains("TERRACOTTA"));
        Assertions.assertEquals(0.93, result.confidence(), 0.001);
    }


    @Test
    @DisplayName("Should remain conservative when no structured care profile exists")
    void shouldUseConservativeDefault() {
        final Plant plant = plantWithSoilMoisture(null);

        final CareScheduleSuggestion result = service.suggest(plant);

        Assertions.assertEquals(7, result.intervalDays());
        Assertions.assertEquals(0.45, result.confidence(), 0.001);
        Assertions.assertTrue(result.factors().contains("DEFAULT_BASELINE"));
    }


    private Plant plantWithSoilMoisture(Integer soilMoisture) {
        final PlantCareInfo care = new PlantCareInfo();
        care.setSoilHumidity(soilMoisture);
        if (soilMoisture != null) {
            care.attributePopulatedFields("CURATED_CATALOG", "reference", 0.88, Instant.now());
        }
        final BotanicalInfo botanicalInfo = new BotanicalInfo();
        botanicalInfo.setPlantCareInfo(care);
        final Plant plant = new Plant();
        plant.setBotanicalInfo(botanicalInfo);
        return plant;
    }
}
