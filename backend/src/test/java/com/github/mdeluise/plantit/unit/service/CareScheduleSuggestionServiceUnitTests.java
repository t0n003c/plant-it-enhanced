package com.github.mdeluise.plantit.unit.service;

import java.time.Instant;
import java.util.Date;
import java.util.List;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfo;
import com.github.mdeluise.plantit.diary.entry.DiaryEntry;
import com.github.mdeluise.plantit.diary.entry.DiaryEntryRepository;
import com.github.mdeluise.plantit.diary.entry.DiaryEntryType;
import com.github.mdeluise.plantit.plant.Plant;
import com.github.mdeluise.plantit.plant.care.CareScheduleSuggestion;
import com.github.mdeluise.plantit.plant.care.CareScheduleSuggestionService;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

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


    @Test
    @DisplayName("Should blend recent watering history into the next suggestion")
    void shouldUseRecentWateringHistory() {
        final DiaryEntryRepository repository = Mockito.mock(DiaryEntryRepository.class);
        final CareScheduleSuggestionService historyService = new CareScheduleSuggestionService(repository);
        final Plant plant = plantWithSoilMoisture(3);
        plant.setId(42L);
        final DiaryEntry newer = wateringEntry("2026-07-08T12:00:00Z");
        final DiaryEntry older = wateringEntry("2026-07-04T12:00:00Z");
        Mockito.when(repository.findTop4ByDiaryTargetAndTypeOrderByDateDesc(plant, DiaryEntryType.WATERING))
               .thenReturn(List.of(newer, older));

        final CareScheduleSuggestion result = historyService.suggest(plant);

        Assertions.assertEquals(9, result.intervalDays());
        Assertions.assertTrue(result.factors().contains("RECENT_WATERING_HISTORY"));
    }


    private DiaryEntry wateringEntry(String instant) {
        final DiaryEntry entry = new DiaryEntry();
        entry.setType(DiaryEntryType.WATERING);
        entry.setDate(Date.from(Instant.parse(instant)));
        return entry;
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
