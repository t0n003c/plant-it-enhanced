package com.github.mdeluise.plantit.hike;

import com.github.mdeluise.plantit.observation.ObservationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class HikeSessionDTOConverter {
    private final ObservationRepository observationRepository;


    @Autowired
    public HikeSessionDTOConverter(ObservationRepository observationRepository) {
        this.observationRepository = observationRepository;
    }


    public HikeSession convertFromDTO(HikeSessionDTO dto) {
        final HikeSession result = new HikeSession();
        result.setId(dto.getId());
        result.setName(dto.getName());
        result.setStartedAt(dto.getStartedAt());
        result.setEndedAt(dto.getEndedAt());
        result.setNotes(dto.getNotes());
        result.setClientReference(dto.getClientReference());
        return result;
    }


    public HikeSessionDTO convertToDTO(HikeSession data) {
        final HikeSessionDTO result = new HikeSessionDTO();
        result.setId(data.getId());
        result.setName(data.getName());
        result.setStartedAt(data.getStartedAt());
        result.setEndedAt(data.getEndedAt());
        result.setNotes(data.getNotes());
        result.setClientReference(data.getClientReference());
        result.setCreatedAt(data.getCreatedAt());
        result.setUpdatedAt(data.getUpdatedAt());
        result.setObservationCount(observationRepository.countByHikeSession(data));
        return result;
    }
}
