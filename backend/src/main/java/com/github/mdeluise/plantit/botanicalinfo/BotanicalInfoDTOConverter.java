package com.github.mdeluise.plantit.botanicalinfo;

import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.stream.Collectors;

import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfo;
import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfoDTO;
import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfoDTOConverter;
import com.github.mdeluise.plantit.common.AbstractDTOConverter;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class BotanicalInfoDTOConverter extends AbstractDTOConverter<BotanicalInfo, BotanicalInfoDTO> {
    private final PlantCareInfoDTOConverter plantCareInfoDtoConverter;


    @Autowired
    public BotanicalInfoDTOConverter(ModelMapper modelMapper, PlantCareInfoDTOConverter plantCareInfoDtoConverter) {
        super(modelMapper);
        this.plantCareInfoDtoConverter = plantCareInfoDtoConverter;
    }


    @Override
    public BotanicalInfo convertFromDTO(BotanicalInfoDTO dto) {
        final BotanicalInfo result = modelMapper.map(dto, BotanicalInfo.class);
        result.setCommonNames(convertCommonNames(dto.getCommonNames()));
        result.setExternalReferences(dto.getExternalReferences() == null
                                         ? new HashMap<>() : new HashMap<>(dto.getExternalReferences()));
        result.setCanonicalTaxonKey(dto.getCanonicalTaxonKey());
        result.setLastVerifiedAt(dto.getLastVerifiedAt());
        final PlantCareInfo plantCareInfo = plantCareInfoDtoConverter.convertFromDTO(dto.getPlantCareInfo());
        result.setPlantCareInfo(plantCareInfo);
        if (dto.getImageContentType() != null) {
            result.getImage().setContentType(dto.getImageContentType());
        }
        return result;
    }


    @Override
    public BotanicalInfoDTO convertToDTO(BotanicalInfo data) {
        final BotanicalInfoDTO result = modelMapper.map(data, BotanicalInfoDTO.class);
        result.setPreferredCommonName(data.getPreferredCommonName());
        result.setCommonNames(convertCommonNameDtos(data.getCommonNames()));
        result.setExternalReferences(data.getExternalReferences() == null
                                         ? new HashMap<>() : new HashMap<>(data.getExternalReferences()));
        result.setCanonicalTaxonKey(data.getCanonicalTaxonKey());
        result.setLastVerifiedAt(data.getLastVerifiedAt());
        result.setSearchMatchReason(data.getSearchMatchReason());
        result.setSearchMatchConfidence(data.getSearchMatchConfidence());
        result.setCatalogTags(data.getCatalogTags() == null
                                  ? new LinkedHashSet<>() : new LinkedHashSet<>(data.getCatalogTags()));
        final PlantCareInfoDTO plantCareInfoDTO = plantCareInfoDtoConverter.convertToDTO(data.getPlantCareInfo());
        result.setPlantCareInfo(plantCareInfoDTO);
        return result;
    }


    private Set<BotanicalCommonName> convertCommonNames(Set<BotanicalCommonNameDTO> commonNames) {
        if (commonNames == null) {
            return new LinkedHashSet<>();
        }
        return commonNames.stream()
                          .filter(dto -> dto.getName() != null && !dto.getName().isBlank())
                          .map(dto -> new BotanicalCommonName(
                              dto.getName(), dto.getLanguage(), dto.getRegion(), dto.isPreferred(),
                              readSource(dto.getSource())
                          ))
                          .collect(Collectors.toCollection(LinkedHashSet::new));
    }


    private Set<BotanicalCommonNameDTO> convertCommonNameDtos(Set<BotanicalCommonName> commonNames) {
        if (commonNames == null) {
            return new LinkedHashSet<>();
        }
        return commonNames.stream().map(commonName -> {
            final BotanicalCommonNameDTO dto = new BotanicalCommonNameDTO();
            dto.setName(commonName.getName());
            dto.setLanguage(commonName.getLanguage());
            dto.setRegion(commonName.getRegion());
            dto.setPreferred(commonName.isPreferred());
            dto.setSource(commonName.getSource().name());
            return dto;
        }).collect(Collectors.toCollection(LinkedHashSet::new));
    }


    private BotanicalInfoCreator readSource(String source) {
        if (source == null || source.isBlank()) {
            return BotanicalInfoCreator.USER;
        }
        try {
            return BotanicalInfoCreator.valueOf(source);
        } catch (IllegalArgumentException exception) {
            return BotanicalInfoCreator.USER;
        }
    }
}
