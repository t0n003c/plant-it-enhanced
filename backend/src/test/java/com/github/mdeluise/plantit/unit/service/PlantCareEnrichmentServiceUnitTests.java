package com.github.mdeluise.plantit.unit.service;

import java.util.Optional;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoService;
import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfo;
import com.github.mdeluise.plantit.exception.CareProviderUnavailableException;
import com.github.mdeluise.plantit.exception.InfoExtractionException;
import com.github.mdeluise.plantit.plantinfo.care.CuratedCareProvider;
import com.github.mdeluise.plantit.plantinfo.care.PerenualCareProvider;
import com.github.mdeluise.plantit.plantinfo.care.PlantCareEnrichmentService;
import com.github.mdeluise.plantit.plantinfo.care.TrefleCareProvider;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

@DisplayName("Unit tests for plant care provider fallback")
class PlantCareEnrichmentServiceUnitTests {
    private BotanicalInfoService botanicalInfoService;
    private TrefleCareProvider trefleCareProvider;
    private CuratedCareProvider curatedCareProvider;
    private PerenualCareProvider perenualCareProvider;
    private PlantCareEnrichmentService service;
    private BotanicalInfo botanicalInfo;


    @BeforeEach
    void setUp() {
        botanicalInfoService = Mockito.mock(BotanicalInfoService.class);
        trefleCareProvider = Mockito.mock(TrefleCareProvider.class);
        curatedCareProvider = Mockito.mock(CuratedCareProvider.class);
        perenualCareProvider = Mockito.mock(PerenualCareProvider.class);
        service = new PlantCareEnrichmentService(
            botanicalInfoService, trefleCareProvider, curatedCareProvider, perenualCareProvider);
        botanicalInfo = new BotanicalInfo();
        botanicalInfo.setId(42L);
        botanicalInfo.setSpecies("Monstera deliciosa");
        Mockito.when(botanicalInfoService.get(42L)).thenReturn(botanicalInfo);
        Mockito.when(botanicalInfoService.updateCareInfo(Mockito.eq(42L), Mockito.any()))
               .thenReturn(botanicalInfo);
    }


    @Test
    @DisplayName("Should use curated care before calling a paid fallback")
    void shouldUseCuratedCareBeforePerenual() {
        final PlantCareInfo curatedCare = careFrom("CURATED_CATALOG");
        Mockito.when(trefleCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(trefleCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.empty());
        Mockito.when(curatedCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.of(curatedCare));
        final BotanicalInfo result = service.refresh(42L);

        Assertions.assertSame(botanicalInfo, result);
        Mockito.verify(botanicalInfoService).updateCareInfo(Mockito.eq(42L), Mockito.any());
        Mockito.verify(perenualCareProvider).isConfigured();
        Mockito.verify(perenualCareProvider, Mockito.never()).fetch(Mockito.anyString());
    }


    @Test
    @DisplayName("Should preview curated care without requiring a saved catalog record")
    void shouldPreviewCareForUnsavedSearchResult() {
        final PlantCareInfo curatedCare = careFrom("CURATED_CATALOG");
        Mockito.when(trefleCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(trefleCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.empty());
        Mockito.when(curatedCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.of(curatedCare));

        final PlantCareInfo result = service.preview("Monstera deliciosa");

        Assertions.assertEquals(curatedCare.getLight(), result.getLight());
        Assertions.assertEquals(curatedCare.getSoilHumidity(), result.getSoilHumidity());
        Mockito.verify(botanicalInfoService, Mockito.never())
               .updateCareInfo(Mockito.anyLong(), Mockito.any());
    }


    @Test
    @DisplayName("Should use Perenual when Trefle and curated care have no values")
    void shouldFallBackToPerenual() {
        final PlantCareInfo perenualCare = careFrom("PERENUAL");
        Mockito.when(trefleCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(perenualCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(trefleCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.empty());
        Mockito.when(curatedCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.empty());
        Mockito.when(perenualCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.of(perenualCare));
        service.refresh(42L);

        Mockito.verify(botanicalInfoService).updateCareInfo(Mockito.eq(42L), Mockito.any());
    }


    @Test
    @DisplayName("Should preserve Trefle priority when it has usable data")
    void shouldPreserveTreflePriority() {
        final PlantCareInfo trefleCare = careFrom("TREFLE");
        Mockito.when(trefleCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(trefleCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.of(trefleCare));
        Mockito.when(curatedCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.empty());

        service.refresh(42L);

        Mockito.verify(botanicalInfoService).updateCareInfo(Mockito.eq(42L), Mockito.any());
        Mockito.verify(curatedCareProvider).fetch("Monstera deliciosa");
    }


    @Test
    @DisplayName("Should recover with curated care when Trefle is unavailable")
    void shouldRecoverFromTrefleFailure() {
        final PlantCareInfo curatedCare = careFrom("CURATED_CATALOG");
        Mockito.when(trefleCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(trefleCareProvider.fetch("Monstera deliciosa"))
               .thenThrow(new InfoExtractionException("Trefle returned HTTP 503"));
        Mockito.when(curatedCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.of(curatedCare));
        service.refresh(42L);

        Mockito.verify(botanicalInfoService).updateCareInfo(Mockito.eq(42L), Mockito.any());
    }


    @Test
    @DisplayName("Should work without external provider configuration")
    void shouldWorkWithoutExternalProviderConfiguration() {
        final PlantCareInfo curatedCare = careFrom("CURATED_CATALOG");
        Mockito.when(trefleCareProvider.isConfigured()).thenReturn(false);
        Mockito.when(perenualCareProvider.isConfigured()).thenReturn(false);
        Mockito.when(curatedCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.of(curatedCare));
        service.refresh(42L);

        Mockito.verify(botanicalInfoService).updateCareInfo(Mockito.eq(42L), Mockito.any());
    }


    @Test
    @DisplayName("Should report provider failure when no fallback succeeds")
    void shouldReportProviderFailure() {
        Mockito.when(trefleCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(perenualCareProvider.isConfigured()).thenReturn(false);
        Mockito.when(trefleCareProvider.fetch("Monstera deliciosa"))
               .thenThrow(new InfoExtractionException("Trefle returned HTTP 503"));
        Mockito.when(curatedCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.empty());

        Assertions.assertThrows(CareProviderUnavailableException.class, () -> service.refresh(42L));
    }


    @Test
    @DisplayName("Should return an empty preview when all providers have no species data")
    void shouldReturnEmptyPreviewWhenProvidersHaveNoData() {
        Mockito.when(trefleCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(perenualCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(trefleCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.empty());
        Mockito.when(curatedCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.empty());
        Mockito.when(perenualCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.empty());

        Assertions.assertTrue(service.preview("Monstera deliciosa").isAllNull());
    }


    @Test
    @DisplayName("Should merge complementary provider fields without overwriting higher-priority data")
    void shouldMergeCareFieldByField() {
        final PlantCareInfo trefleCare = careFrom("TREFLE");
        trefleCare.setSoilHumidity(null);
        final PlantCareInfo curatedCare = careFrom("CURATED_CATALOG");
        curatedCare.setLight(9);
        curatedCare.setHumidity(7);
        final PlantCareInfo perenualCare = careFrom("PERENUAL");
        perenualCare.setLight(2);
        perenualCare.setHumidity(3);
        Mockito.when(trefleCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(perenualCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(trefleCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.of(trefleCare));
        Mockito.when(curatedCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.of(curatedCare));
        Mockito.when(perenualCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.of(perenualCare));

        final PlantCareInfo result = service.preview("Monstera deliciosa");

        Assertions.assertEquals(6, result.getLight());
        Assertions.assertEquals(7, result.getHumidity());
        Assertions.assertEquals(6, result.getSoilHumidity());
        Assertions.assertEquals("MULTIPLE", result.getSource());
    }


    private PlantCareInfo careFrom(String source) {
        final PlantCareInfo result = new PlantCareInfo();
        result.setSource(source);
        result.setLight(6);
        result.setSoilHumidity(6);
        return result;
    }
}
