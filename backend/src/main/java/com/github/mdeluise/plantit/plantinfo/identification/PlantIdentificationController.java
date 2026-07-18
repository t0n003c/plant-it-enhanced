package com.github.mdeluise.plantit.plantinfo.identification;

import java.util.ArrayList;
import java.util.List;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoDTO;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoDTOConverter;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoService;
import com.github.mdeluise.plantit.plantinfo.search.TrustedCommonNameIndex;
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
    private final TrustedCommonNameIndex trustedCommonNameIndex;


    @Autowired
    public PlantIdentificationController(PlantIdentificationService identificationService,
                                         BotanicalInfoDTOConverter botanicalInfoDTOConverter,
                                         BotanicalInfoService botanicalInfoService,
                                         TrustedCommonNameIndex trustedCommonNameIndex) {
        this.identificationService = identificationService;
        this.botanicalInfoDTOConverter = botanicalInfoDTOConverter;
        this.botanicalInfoService = botanicalInfoService;
        this.trustedCommonNameIndex = trustedCommonNameIndex;
    }


    @PostMapping(value = "/plant-identification", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<List<BotanicalInfoDTO>> identify(
        @RequestPart(value = "images", required = false) List<MultipartFile> images,
        @RequestPart(value = "image", required = false) MultipartFile legacyImage,
        @RequestParam(required = false) List<String> organs,
        @RequestParam(required = false) String language) {
        final List<MultipartFile> submittedImages = new ArrayList<>();
        if (images != null) {
            submittedImages.addAll(images);
        }
        if (legacyImage != null) {
            submittedImages.add(legacyImage);
        }
        final List<PlantIdentificationPhoto> photos = new ArrayList<>();
        for (int index = 0; index < submittedImages.size(); index++) {
            final String organ = organs != null && index < organs.size() ? organs.get(index) : "auto";
            photos.add(new PlantIdentificationPhoto(submittedImages.get(index), organ));
        }
        final List<BotanicalInfoDTO> result = identificationService.identify(photos, language).stream()
                                                                     .map(this::toDto)
                                                                     .toList();
        return ResponseEntity.ok(result);
    }


    private BotanicalInfoDTO toDto(PlantIdentificationCandidate candidate) {
        final BotanicalInfoDTO result = botanicalInfoDTOConverter.convertToDTO(
            trustedCommonNameIndex.applyCatalogMetadata(
                botanicalInfoService.findCatalogMatch(candidate.botanicalInfo())
                                    .orElse(candidate.botanicalInfo())));
        result.setIdentificationConfidence(candidate.confidence());
        result.setIdentificationProvider("Pl@ntNet");
        result.setIdentificationModel(candidate.modelVersion());
        return result;
    }
}
