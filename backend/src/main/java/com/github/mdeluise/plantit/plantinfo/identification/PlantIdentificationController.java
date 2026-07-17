package com.github.mdeluise.plantit.plantinfo.identification;

import java.util.List;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoDTO;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoDTOConverter;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoService;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@Tag(name = "Plant Identification", description = "Photo-based plant identification")
public class PlantIdentificationController {
    private final PlantIdentificationService identificationService;
    private final BotanicalInfoDTOConverter botanicalInfoDTOConverter;
    private final BotanicalInfoService botanicalInfoService;


    @Autowired
    public PlantIdentificationController(PlantIdentificationService identificationService,
                                         BotanicalInfoDTOConverter botanicalInfoDTOConverter,
                                         BotanicalInfoService botanicalInfoService) {
        this.identificationService = identificationService;
        this.botanicalInfoDTOConverter = botanicalInfoDTOConverter;
        this.botanicalInfoService = botanicalInfoService;
    }


    @PostMapping(value = "/plant-identification", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<List<BotanicalInfoDTO>> identify(
        @RequestPart("image") MultipartFile image,
        @RequestParam(required = false) String language) {
        final List<BotanicalInfoDTO> result = identificationService.identify(image, language).stream()
                                                                     .map(this::toDto)
                                                                     .toList();
        return ResponseEntity.ok(result);
    }


    private BotanicalInfoDTO toDto(PlantIdentificationCandidate candidate) {
        final BotanicalInfoDTO result = botanicalInfoDTOConverter.convertToDTO(
            botanicalInfoService.findCatalogMatch(candidate.botanicalInfo())
                                .orElse(candidate.botanicalInfo()));
        result.setIdentificationConfidence(candidate.confidence());
        result.setIdentificationProvider("Pl@ntNet");
        result.setIdentificationModel(candidate.modelVersion());
        return result;
    }
}
