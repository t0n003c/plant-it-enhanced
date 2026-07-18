package com.github.mdeluise.plantit.unit.service;

import java.util.Optional;
import java.util.Set;

import com.github.mdeluise.plantit.authentication.User;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoService;
import com.github.mdeluise.plantit.common.AuthenticatedUserService;
import com.github.mdeluise.plantit.exception.UnauthorizedException;
import com.github.mdeluise.plantit.image.ObservationImage;
import com.github.mdeluise.plantit.image.storage.ImageStorageService;
import com.github.mdeluise.plantit.hike.HikeSessionService;
import com.github.mdeluise.plantit.observation.Observation;
import com.github.mdeluise.plantit.observation.ObservationLocationPrivacy;
import com.github.mdeluise.plantit.observation.ObservationRepository;
import com.github.mdeluise.plantit.observation.ObservationService;
import com.github.mdeluise.plantit.observation.ObservationStatus;
import org.assertj.core.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.springframework.test.context.junit.jupiter.SpringExtension;

@ExtendWith(SpringExtension.class)
@DisplayName("Unit tests for ObservationService")
class ObservationServiceUnitTests {
    @Mock
    private AuthenticatedUserService authenticatedUserService;
    @Mock
    private ObservationRepository observationRepository;
    @Mock
    private BotanicalInfoService botanicalInfoService;
    @Mock
    private HikeSessionService hikeSessionService;
    @Mock
    private ImageStorageService imageStorageService;
    @InjectMocks
    private ObservationService observationService;


    @Test
    @DisplayName("Should save a confirmed observation with private defaults")
    void shouldSaveConfirmedObservationWithPrivateDefaults() {
        final User authenticated = user(1L);
        final BotanicalInfo reference = new BotanicalInfo();
        reference.setId(7L);
        final BotanicalInfo persistedTaxon = new BotanicalInfo();
        persistedTaxon.setId(7L);
        persistedTaxon.setSpecies("Monarda fistulosa");
        final Observation observation = new Observation();
        observation.setBotanicalInfo(reference);
        Mockito.when(authenticatedUserService.getAuthenticatedUser()).thenReturn(authenticated);
        Mockito.when(botanicalInfoService.get(7L)).thenReturn(persistedTaxon);
        Mockito.when(observationRepository.save(observation)).thenReturn(observation);

        final Observation result = observationService.save(observation);

        Assertions.assertThat(result.getOwner()).isSameAs(authenticated);
        Assertions.assertThat(result.getBotanicalInfo()).isSameAs(persistedTaxon);
        Assertions.assertThat(result.getStatus()).isEqualTo(ObservationStatus.CONFIRMED);
        Assertions.assertThat(result.getLocationPrivacy()).isEqualTo(ObservationLocationPrivacy.PRIVATE);
        Assertions.assertThat(result.getObservedAt()).isNotNull();
        Assertions.assertThat(result.getCreatedAt()).isNotNull();
        Mockito.verify(observationRepository).save(observation);
    }


    @Test
    @DisplayName("Should reject incomplete coordinates")
    void shouldRejectIncompleteCoordinates() {
        final Observation observation = new Observation();
        observation.setLatitude(42.0);
        Mockito.when(authenticatedUserService.getAuthenticatedUser()).thenReturn(user(1L));

        Assertions.assertThatThrownBy(() -> observationService.save(observation))
                  .isInstanceOf(IllegalArgumentException.class)
                  .hasMessageContaining("provided together");
        Mockito.verifyNoInteractions(observationRepository);
    }


    @Test
    @DisplayName("Should not return another user's observation")
    void shouldNotReturnAnotherUsersObservation() {
        final Observation observation = new Observation();
        observation.setId(3L);
        observation.setOwner(user(2L));
        Mockito.when(observationRepository.findById(3L)).thenReturn(Optional.of(observation));
        Mockito.when(authenticatedUserService.getAuthenticatedUser()).thenReturn(user(1L));

        Assertions.assertThatThrownBy(() -> observationService.get(3L))
                  .isInstanceOf(UnauthorizedException.class);
    }


    @Test
    @DisplayName("Should remove observation photos when deleting")
    void shouldRemoveObservationPhotosWhenDeleting() {
        final User authenticated = user(1L);
        final Observation observation = new Observation();
        observation.setId(3L);
        observation.setOwner(authenticated);
        final ObservationImage image = new ObservationImage();
        image.setId("field-photo");
        image.setTarget(observation);
        observation.setImages(Set.of(image));
        Mockito.when(observationRepository.findById(3L)).thenReturn(Optional.of(observation));
        Mockito.when(authenticatedUserService.getAuthenticatedUser()).thenReturn(authenticated);

        observationService.delete(3L);

        Mockito.verify(imageStorageService).remove("field-photo");
        Mockito.verify(observationRepository).delete(observation);
    }


    @Test
    @DisplayName("Should return an existing observation for a repeated offline client reference")
    void shouldReturnExistingObservationForRepeatedClientReference() {
        final User authenticated = user(1L);
        final Observation existing = new Observation();
        existing.setId(12L);
        existing.setOwner(authenticated);
        existing.setClientReference("offline-draft-1");
        final Observation repeated = new Observation();
        repeated.setClientReference(" offline-draft-1 ");
        Mockito.when(authenticatedUserService.getAuthenticatedUser()).thenReturn(authenticated);
        Mockito.when(observationRepository.findByOwnerAndClientReference(authenticated, "offline-draft-1"))
               .thenReturn(Optional.of(existing));

        final Observation result = observationService.save(repeated);

        Assertions.assertThat(result).isSameAs(existing);
        Mockito.verify(observationRepository, Mockito.never()).save(Mockito.any());
        Mockito.verifyNoInteractions(botanicalInfoService, hikeSessionService);
    }


    private User user(Long id) {
        final User result = new User();
        result.setId(id);
        return result;
    }
}
