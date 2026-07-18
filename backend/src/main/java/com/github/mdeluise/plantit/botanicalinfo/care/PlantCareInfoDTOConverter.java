package com.github.mdeluise.plantit.botanicalinfo.care;

import com.github.mdeluise.plantit.common.AbstractDTOConverter;
import org.modelmapper.ModelMapper;
import org.springframework.stereotype.Component;

@Component
public class PlantCareInfoDTOConverter extends AbstractDTOConverter<PlantCareInfo, PlantCareInfoDTO> {
    public PlantCareInfoDTOConverter(ModelMapper modelMapper) {
        super(modelMapper);
    }


    @Override
    public PlantCareInfo convertFromDTO(PlantCareInfoDTO dto) {
        if (dto == null) {
            return new PlantCareInfo();
        }
        final PlantCareInfo result = modelMapper.map(dto, PlantCareInfo.class);
        result.setFieldProvenance(dto.getFieldProvenance());
        return result;
    }


    @Override
    public PlantCareInfoDTO convertToDTO(PlantCareInfo data) {
        final PlantCareInfoDTO result = modelMapper.map(data, PlantCareInfoDTO.class);
        result.setLightRequirement(CareRequirementLevel.fromScale(data.getLight()));
        result.setWaterRequirement(CareRequirementLevel.fromScale(data.getSoilHumidity()));
        result.setAllNull(data.isAllNull());
        result.setFieldProvenance(data.getFieldProvenance());
        return result;
    }
}
