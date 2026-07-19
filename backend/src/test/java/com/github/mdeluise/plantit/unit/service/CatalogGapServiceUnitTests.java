package com.github.mdeluise.plantit.unit.service;

import java.util.List;
import java.util.Optional;

import com.github.mdeluise.plantit.authentication.User;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.catalog.CatalogGapObservation;
import com.github.mdeluise.plantit.catalog.CatalogGapObservationRepository;
import com.github.mdeluise.plantit.catalog.CatalogGapService;
import com.github.mdeluise.plantit.catalog.CatalogGapType;
import com.github.mdeluise.plantit.common.AuthenticatedUserService;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mockito;

@DisplayName("Unit tests for private catalog quality observations")
class CatalogGapServiceUnitTests {
    private CatalogGapObservationRepository repository;
    private CatalogGapService service;


    @BeforeEach
    void setUp() {
        repository = Mockito.mock(CatalogGapObservationRepository.class);
        final AuthenticatedUserService authenticatedUserService = Mockito.mock(AuthenticatedUserService.class);
        final User user = new User();
        user.setId(42L);
        Mockito.when(authenticatedUserService.getAuthenticatedUser()).thenReturn(user);
        service = new CatalogGapService(repository, authenticatedUserService);
    }


    @Test
    @DisplayName("Should store a sanitized account-scoped no-result observation")
    void shouldStoreNoResultGap() {
        Mockito.when(repository.findByOwnerIdAndIssueTypeAndSubjectKey(
            42L, CatalogGapType.NO_RESULTS, "mystery plant")).thenReturn(Optional.empty());

        service.observeSearch("  Mystery\nPlant  ", List.of());

        final ArgumentCaptor<CatalogGapObservation> captor = ArgumentCaptor.forClass(
            CatalogGapObservation.class);
        Mockito.verify(repository).save(captor.capture());
        final CatalogGapObservation saved = captor.getValue();
        Assertions.assertEquals(42L, saved.getOwnerId());
        Assertions.assertEquals(CatalogGapType.NO_RESULTS, saved.getIssueType());
        Assertions.assertEquals("mystery plant", saved.getSubjectKey());
        Assertions.assertEquals("Mystery Plant", saved.getDisplaySubject());
        Assertions.assertTrue(saved.isActive());
        Assertions.assertEquals(1, saved.getOccurrenceCount());
    }


    @Test
    @DisplayName("Should resolve a prior failure and record a missing top-result image")
    void shouldResolveSearchAndRecordMissingImage() {
        final CatalogGapObservation prior = observation(CatalogGapType.NO_RESULTS, "aloe vera");
        Mockito.when(repository.findByOwnerIdAndIssueTypeAndSubjectKey(
            42L, CatalogGapType.NO_RESULTS, "aloe vera")).thenReturn(Optional.of(prior));
        Mockito.when(repository.findByOwnerIdAndIssueTypeAndSubjectKey(
            42L, CatalogGapType.MISSING_IMAGE, "aloe vera")).thenReturn(Optional.empty());
        final BotanicalInfo result = new BotanicalInfo();
        result.setSpecies("Aloe vera");

        service.observeSearch("aloe vera", List.of(result));

        final ArgumentCaptor<CatalogGapObservation> captor = ArgumentCaptor.forClass(
            CatalogGapObservation.class);
        Mockito.verify(repository, Mockito.times(2)).save(captor.capture());
        Assertions.assertFalse(captor.getAllValues().get(0).isActive());
        Assertions.assertEquals(CatalogGapType.MISSING_IMAGE, captor.getAllValues().get(1).getIssueType());
        Assertions.assertTrue(captor.getAllValues().get(1).isActive());
    }


    private CatalogGapObservation observation(CatalogGapType type, String key) {
        final CatalogGapObservation result = new CatalogGapObservation();
        result.setId(1L);
        result.setOwnerId(42L);
        result.setIssueType(type);
        result.setSubjectKey(key);
        result.setDisplaySubject(key);
        result.setOccurrenceCount(1);
        result.setActive(true);
        result.setFirstSeenAt(java.time.Instant.now());
        result.setLastSeenAt(java.time.Instant.now());
        return result;
    }
}
