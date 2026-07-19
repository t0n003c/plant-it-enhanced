package com.github.mdeluise.plantit.botanicalinfo;

import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.stream.Collectors;

import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfo;
import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfoDTO;
import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfoDTOConverter;
import com.github.mdeluise.plantit.common.AbstractDTOConverter;
import com.github.mdeluise.plantit.image.BotanicalInfoImage;
import com.github.mdeluise.plantit.plantinfo.benefits.PlantBenefitCatalog;
import com.github.mdeluise.plantit.plantinfo.safety.PlantSafetyCatalog;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class BotanicalInfoDTOConverter extends AbstractDTOConverter<BotanicalInfo, BotanicalInfoDTO> {
    private final PlantCareInfoDTOConverter plantCareInfoDtoConverter;
    private final PlantSafetyCatalog plantSafetyCatalog;
    private final PlantBenefitCatalog plantBenefitCatalog;


    @Autowired
    public BotanicalInfoDTOConverter(ModelMapper modelMapper,
                                     PlantCareInfoDTOConverter plantCareInfoDtoConverter,
                                     PlantSafetyCatalog plantSafetyCatalog,
                                     PlantBenefitCatalog plantBenefitCatalog) {
        super(modelMapper);
        this.plantCareInfoDtoConverter = plantCareInfoDtoConverter;
        this.plantSafetyCatalog = plantSafetyCatalog;
        this.plantBenefitCatalog = plantBenefitCatalog;
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
        result.setImage(convertImage(dto));
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
        result.setSearchMatchedName(data.getSearchMatchedName());
        result.setCatalogTags(data.getCatalogTags() == null
                                  ? new LinkedHashSet<>() : new LinkedHashSet<>(data.getCatalogTags()));
        result.setSafety(plantSafetyCatalog.find(data.getSpecies()));
        result.setBenefits(plantBenefitCatalog.find(data.getSpecies()));
        applyImage(data.getImage(), result);
        final PlantCareInfoDTO plantCareInfoDTO = plantCareInfoDtoConverter.convertToDTO(data.getPlantCareInfo());
        result.setPlantCareInfo(plantCareInfoDTO);
        return result;
    }


    private BotanicalInfoImage convertImage(BotanicalInfoDTO dto) {
        if (!hasImage(dto)) {
            return null;
        }
        final BotanicalInfoImage image = new BotanicalInfoImage();
        image.setId(dto.getImageId());
        image.setUrl(dto.getImageUrl());
        image.setFallbackUrl(dto.getImageFallbackUrl());
        image.setContent(dto.getImageContent());
        image.setContentType(dto.getImageContentType());
        image.setSource(dto.getImageSource());
        image.setSourceUrl(dto.getImageSourceUrl());
        image.setLicenseCode(dto.getImageLicenseCode());
        image.setAttribution(dto.getImageAttribution());
        return image;
    }


    private boolean hasImage(BotanicalInfoDTO dto) {
        return isPresent(dto.getImageId()) || isPresent(dto.getImageUrl()) || dto.getImageContent() != null;
    }


    private void applyImage(BotanicalInfoImage image, BotanicalInfoDTO dto) {
        if (image == null) {
            dto.setImageId(null);
            dto.setImageUrl(null);
            dto.setImageFallbackUrl(null);
            dto.setImageSource(null);
            dto.setImageSourceUrl(null);
            dto.setImageLicenseCode(null);
            dto.setImageAttribution(null);
            return;
        }
        dto.setImageId(image.getId());
        dto.setImageUrl(image.getUrl());
        dto.setImageFallbackUrl(image.getFallbackUrl());
        dto.setImageSource(image.getSource());
        dto.setImageSourceUrl(image.getSourceUrl());
        dto.setImageLicenseCode(image.getLicenseCode());
        dto.setImageAttribution(image.getAttribution());
    }


    private boolean isPresent(String value) {
        return value != null && !value.isBlank();
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
