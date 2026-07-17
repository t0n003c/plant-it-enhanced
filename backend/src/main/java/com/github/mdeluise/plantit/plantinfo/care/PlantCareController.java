package com.github.mdeluise.plantit.plantinfo.care;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoDTO;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoDTOConverter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/botanical-info/{botanicalInfoId}/care")
@Tag(name = "Plant Care", description = "Structured, attributable plant-care information")
public class PlantCareController {
    private final PlantCareEnrichmentService enrichmentService;
    private final BotanicalInfoDTOConverter botanicalInfoDTOConverter;


    @Autowired
    public PlantCareController(PlantCareEnrichmentService enrichmentService,
                               BotanicalInfoDTOConverter botanicalInfoDTOConverter) {
        this.enrichmentService = enrichmentService;
        this.botanicalInfoDTOConverter = botanicalInfoDTOConverter;
    }


    @PostMapping("/refresh")
    public ResponseEntity<BotanicalInfoDTO> refresh(@PathVariable long botanicalInfoId) {
        final BotanicalInfo refreshed = enrichmentService.refresh(botanicalInfoId);
        return ResponseEntity.ok(botanicalInfoDTOConverter.convertToDTO(refreshed));
    }
}
