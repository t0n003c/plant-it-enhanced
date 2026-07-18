package com.github.mdeluise.plantit.observation;

import java.util.Objects;

import com.github.mdeluise.plantit.authentication.User;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoService;
import com.github.mdeluise.plantit.common.AuthenticatedUserService;
import com.github.mdeluise.plantit.exception.ResourceNotFoundException;
import com.github.mdeluise.plantit.exception.UnauthorizedException;
import com.github.mdeluise.plantit.image.storage.ImageStorageService;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

@Service
public class ObservationService {
    private static final double MIN_LATITUDE = -90;
    private static final double MAX_LATITUDE = 90;
    private static final double MIN_LONGITUDE = -180;
    private static final double MAX_LONGITUDE = 180;
    private final AuthenticatedUserService authenticatedUserService;
    private final ObservationRepository observationRepository;
    private final BotanicalInfoService botanicalInfoService;
    private final ImageStorageService imageStorageService;


    @Autowired
    public ObservationService(AuthenticatedUserService authenticatedUserService,
                              ObservationRepository observationRepository,
                              BotanicalInfoService botanicalInfoService,
                              ImageStorageService imageStorageService) {
        this.authenticatedUserService = authenticatedUserService;
        this.observationRepository = observationRepository;
        this.botanicalInfoService = botanicalInfoService;
        this.imageStorageService = imageStorageService;
    }


    public Page<Observation> getAll(Pageable pageable) {
        return observationRepository.findAllByOwner(authenticatedUserService.getAuthenticatedUser(), pageable);
    }


    public Observation get(Long id) {
        final Observation result = observationRepository.findById(id)
                                                        .orElseThrow(() -> new ResourceNotFoundException(id));
        ensureOwner(result, authenticatedUserService.getAuthenticatedUser());
        return result;
    }


    public long count() {
        return observationRepository.countByOwner(authenticatedUserService.getAuthenticatedUser());
    }


    @Transactional
    public Observation save(Observation toSave) {
        final User authenticatedUser = authenticatedUserService.getAuthenticatedUser();
        if (toSave.getOwner() != null && !sameUser(toSave.getOwner(), authenticatedUser)) {
            throw new UnauthorizedException();
        }
        toSave.setOwner(authenticatedUser);
        resolveBotanicalInfo(toSave);
        normalizeAndValidate(toSave);
        toSave.setCreationDefaults();
        return observationRepository.save(toSave);
    }


    @Transactional
    public Observation update(Long id, Observation updated) {
        final Observation toUpdate = get(id);
        toUpdate.setObservedAt(updated.getObservedAt());
        toUpdate.setDisplayName(updated.getDisplayName());
        toUpdate.setTrailName(updated.getTrailName());
        toUpdate.setHabitat(updated.getHabitat());
        toUpdate.setNotes(updated.getNotes());
        toUpdate.setLatitude(updated.getLatitude());
        toUpdate.setLongitude(updated.getLongitude());
        toUpdate.setAccuracyMeters(updated.getAccuracyMeters());
        toUpdate.setElevationMeters(updated.getElevationMeters());
        toUpdate.setLocationPrivacy(updated.getLocationPrivacy());
        toUpdate.setStatus(updated.getStatus());
        toUpdate.setIdentificationConfidence(updated.getIdentificationConfidence());
        toUpdate.setIdentificationProvider(updated.getIdentificationProvider());
        toUpdate.setBotanicalInfo(updated.getBotanicalInfo());
        resolveBotanicalInfo(toUpdate);
        normalizeAndValidate(toUpdate);
        return observationRepository.save(toUpdate);
    }


    @Transactional
    public void delete(Long id) {
        final Observation toDelete = get(id);
        toDelete.getImages().forEach(image -> imageStorageService.remove(image.getId()));
        observationRepository.delete(toDelete);
    }


    private void resolveBotanicalInfo(Observation observation) {
        final BotanicalInfo botanicalInfo = observation.getBotanicalInfo();
        if (botanicalInfo != null) {
            observation.setBotanicalInfo(botanicalInfoService.get(botanicalInfo.getId()));
        }
    }


    private void normalizeAndValidate(Observation observation) {
        if (observation.getLocationPrivacy() == null) {
            observation.setLocationPrivacy(ObservationLocationPrivacy.PRIVATE);
        }
        if (observation.getStatus() == null) {
            observation.setStatus(observation.getBotanicalInfo() == null
                                      ? ObservationStatus.UNIDENTIFIED
                                      : ObservationStatus.CONFIRMED);
        }
        if (observation.getBotanicalInfo() == null && observation.getStatus() == ObservationStatus.CONFIRMED) {
            throw new IllegalArgumentException("A confirmed observation must reference a botanical taxon");
        }
        final boolean hasLatitude = observation.getLatitude() != null;
        final boolean hasLongitude = observation.getLongitude() != null;
        if (hasLatitude != hasLongitude) {
            throw new IllegalArgumentException("Latitude and longitude must be provided together");
        }
        if (hasLatitude &&
                (observation.getLatitude() < MIN_LATITUDE || observation.getLatitude() > MAX_LATITUDE)) {
            throw new IllegalArgumentException("Latitude must be between -90 and 90");
        }
        if (hasLongitude &&
                (observation.getLongitude() < MIN_LONGITUDE || observation.getLongitude() > MAX_LONGITUDE)) {
            throw new IllegalArgumentException("Longitude must be between -180 and 180");
        }
        if (observation.getAccuracyMeters() != null && observation.getAccuracyMeters() < 0) {
            throw new IllegalArgumentException("Location accuracy cannot be negative");
        }
        final Double confidence = observation.getIdentificationConfidence();
        if (confidence != null && (confidence < 0 || confidence > 1)) {
            throw new IllegalArgumentException("Identification confidence must be between 0 and 1");
        }
    }


    private void ensureOwner(Observation observation, User authenticatedUser) {
        if (!sameUser(observation.getOwner(), authenticatedUser)) {
            throw new UnauthorizedException();
        }
    }


    private boolean sameUser(User left, User right) {
        return left == right || left != null && right != null && Objects.equals(left.getId(), right.getId());
    }
}
