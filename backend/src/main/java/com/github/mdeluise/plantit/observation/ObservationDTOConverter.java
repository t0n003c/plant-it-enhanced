package com.github.mdeluise.plantit.observation;

import java.util.Comparator;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.hike.HikeSession;
import com.github.mdeluise.plantit.image.EntityImage;
import org.springframework.stereotype.Component;

@Component
public class ObservationDTOConverter {
    public Observation convertFromDTO(ObservationDTO dto) {
        final Observation result = new Observation();
        result.setId(dto.getId());
        result.setObservedAt(dto.getObservedAt());
        result.setClientReference(dto.getClientReference());
        result.setDisplayName(dto.getDisplayName());
        result.setTrailName(dto.getTrailName());
        result.setHabitat(dto.getHabitat());
        result.setNotes(dto.getNotes());
        result.setLatitude(dto.getLatitude());
        result.setLongitude(dto.getLongitude());
        result.setAccuracyMeters(dto.getAccuracyMeters());
        result.setElevationMeters(dto.getElevationMeters());
        result.setIdentificationConfidence(dto.getIdentificationConfidence());
        result.setIdentificationProvider(dto.getIdentificationProvider());
        if (dto.getBotanicalInfoId() != null) {
            final BotanicalInfo botanicalInfo = new BotanicalInfo();
            botanicalInfo.setId(dto.getBotanicalInfoId());
            result.setBotanicalInfo(botanicalInfo);
        }
        if (dto.getHikeSessionId() != null) {
            final HikeSession hikeSession = new HikeSession();
            hikeSession.setId(dto.getHikeSessionId());
            result.setHikeSession(hikeSession);
        }
        if (dto.getLocationPrivacy() != null) {
            result.setLocationPrivacy(ObservationLocationPrivacy.valueOf(dto.getLocationPrivacy()));
        }
        if (dto.getStatus() != null) {
            result.setStatus(ObservationStatus.valueOf(dto.getStatus()));
        }
        return result;
    }


    public ObservationDTO convertToDTO(Observation data) {
        final ObservationDTO result = new ObservationDTO();
        result.setId(data.getId());
        result.setOwnerId(data.getOwner().getId());
        result.setObservedAt(data.getObservedAt());
        result.setClientReference(data.getClientReference());
        result.setCreatedAt(data.getCreatedAt());
        result.setUpdatedAt(data.getUpdatedAt());
        result.setDisplayName(data.getDisplayName());
        result.setTrailName(data.getTrailName());
        result.setHabitat(data.getHabitat());
        result.setNotes(data.getNotes());
        result.setLatitude(data.getLatitude());
        result.setLongitude(data.getLongitude());
        result.setAccuracyMeters(data.getAccuracyMeters());
        result.setElevationMeters(data.getElevationMeters());
        result.setLocationPrivacy(data.getLocationPrivacy().name());
        result.setStatus(data.getStatus().name());
        result.setIdentificationConfidence(data.getIdentificationConfidence());
        result.setIdentificationProvider(data.getIdentificationProvider());
        if (data.getBotanicalInfo() != null) {
            result.setBotanicalInfoId(data.getBotanicalInfo().getId());
            result.setScientificName(data.getBotanicalInfo().getScientificName());
            result.setPreferredCommonName(data.getBotanicalInfo().getPreferredCommonName());
        }
        if (data.getHikeSession() != null) {
            result.setHikeSessionId(data.getHikeSession().getId());
            result.setHikeSessionName(data.getHikeSession().getName());
        }
        result.setImageIds(data.getImages().stream()
                               .sorted(Comparator.comparing(EntityImage::getCreateOn))
                               .map(EntityImage::getId)
                               .toList());
        return result;
    }
}
