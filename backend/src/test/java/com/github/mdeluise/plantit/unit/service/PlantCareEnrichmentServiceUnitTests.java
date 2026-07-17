package com.github.mdeluise.plantit.unit.service;

import java.util.Optional;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoService;
import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfo;
import com.github.mdeluise.plantit.exception.CareProviderNotConfiguredException;
import com.github.mdeluise.plantit.exception.CareProviderUnavailableException;
import com.github.mdeluise.plantit.exception.InfoExtractionException;
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
    private PerenualCareProvider perenualCareProvider;
    private PlantCareEnrichmentService service;
    private BotanicalInfo botanicalInfo;


    @BeforeEach
    void setUp() {
        botanicalInfoService = Mockito.mock(BotanicalInfoService.class);
        trefleCareProvider = Mockito.mock(TrefleCareProvider.class);
        perenualCareProvider = Mockito.mock(PerenualCareProvider.class);
        service = new PlantCareEnrichmentService(
            botanicalInfoService, trefleCareProvider, perenualCareProvider);
        botanicalInfo = new BotanicalInfo();
        botanicalInfo.setId(42L);
        botanicalInfo.setSpecies("Monstera deliciosa");
        Mockito.when(botanicalInfoService.get(42L)).thenReturn(botanicalInfo);
    }


    @Test
    @DisplayName("Should use Perenual when Trefle has no usable care values")
    void shouldFallBackToPerenual() {
        final PlantCareInfo perenualCare = careFrom("PERENUAL");
        Mockito.when(trefleCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(perenualCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(trefleCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.empty());
        Mockito.when(perenualCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.of(perenualCare));
        Mockito.when(botanicalInfoService.updateCareInfo(42L, perenualCare)).thenReturn(botanicalInfo);

        final BotanicalInfo result = service.refresh(42L);

        Assertions.assertSame(botanicalInfo, result);
        Mockito.verify(botanicalInfoService).updateCareInfo(42L, perenualCare);
    }


    @Test
    @DisplayName("Should preview fallback care without requiring a saved catalog record")
    void shouldPreviewCareForUnsavedSearchResult() {
        final PlantCareInfo perenualCare = careFrom("PERENUAL");
        Mockito.when(trefleCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(perenualCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(trefleCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.empty());
        Mockito.when(perenualCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.of(perenualCare));

        final PlantCareInfo result = service.preview("Monstera deliciosa");

        Assertions.assertSame(perenualCare, result);
        Mockito.verify(botanicalInfoService, Mockito.never())
               .updateCareInfo(Mockito.anyLong(), Mockito.any());
    }


    @Test
    @DisplayName("Should preserve Trefle priority when it has usable data")
    void shouldPreserveTreflePriority() {
        final PlantCareInfo trefleCare = careFrom("TREFLE");
        Mockito.when(trefleCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(perenualCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(trefleCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.of(trefleCare));
        Mockito.when(botanicalInfoService.updateCareInfo(42L, trefleCare)).thenReturn(botanicalInfo);

        service.refresh(42L);

        Mockito.verify(botanicalInfoService).updateCareInfo(42L, trefleCare);
        Mockito.verifyNoInteractions(perenualCareProvider);
    }


    @Test
    @DisplayName("Should continue to Perenual when Trefle is unavailable")
    void shouldRecoverFromTrefleFailure() {
        final PlantCareInfo perenualCare = careFrom("PERENUAL");
        Mockito.when(trefleCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(perenualCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(trefleCareProvider.fetch("Monstera deliciosa"))
               .thenThrow(new InfoExtractionException("Trefle returned HTTP 503"));
        Mockito.when(perenualCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.of(perenualCare));
        Mockito.when(botanicalInfoService.updateCareInfo(42L, perenualCare)).thenReturn(botanicalInfo);

        service.refresh(42L);

        Mockito.verify(botanicalInfoService).updateCareInfo(42L, perenualCare);
    }


    @Test
    @DisplayName("Should distinguish missing configuration from missing species data")
    void shouldReportMissingConfiguration() {
        Mockito.when(trefleCareProvider.isConfigured()).thenReturn(false);
        Mockito.when(perenualCareProvider.isConfigured()).thenReturn(false);

        Assertions.assertThrows(CareProviderNotConfiguredException.class, () -> service.refresh(42L));
    }


    @Test
    @DisplayName("Should report provider failure when no fallback succeeds")
    void shouldReportProviderFailure() {
        Mockito.when(trefleCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(perenualCareProvider.isConfigured()).thenReturn(false);
        Mockito.when(trefleCareProvider.fetch("Monstera deliciosa"))
               .thenThrow(new InfoExtractionException("Trefle returned HTTP 503"));

        Assertions.assertThrows(CareProviderUnavailableException.class, () -> service.refresh(42L));
    }


    @Test
    @DisplayName("Should return an empty preview when configured providers have no species data")
    void shouldReturnEmptyPreviewWhenProvidersHaveNoData() {
        Mockito.when(trefleCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(perenualCareProvider.isConfigured()).thenReturn(true);
        Mockito.when(trefleCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.empty());
        Mockito.when(perenualCareProvider.fetch("Monstera deliciosa")).thenReturn(Optional.empty());

        Assertions.assertTrue(service.preview("Monstera deliciosa").isAllNull());
    }


    private PlantCareInfo careFrom(String source) {
        final PlantCareInfo result = new PlantCareInfo();
        result.setSource(source);
        result.setLight(6);
        result.setSoilHumidity(6);
        return result;
    }
}
