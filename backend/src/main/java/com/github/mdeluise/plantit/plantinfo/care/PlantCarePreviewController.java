package com.github.mdeluise.plantit.plantinfo.care;

import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfo;
import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfoDTO;
import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfoDTOConverter;
import com.github.mdeluise.plantit.catalog.CatalogGapService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/plant-care")
@Tag(name = "Plant Care", description = "Structured, attributable plant-care information")
public class PlantCarePreviewController {
    private final PlantCareEnrichmentService enrichmentService;
    private final PlantCareInfoDTOConverter plantCareInfoDTOConverter;
    private final CatalogGapService catalogGapService;


    @Autowired
    public PlantCarePreviewController(PlantCareEnrichmentService enrichmentService,
                                      PlantCareInfoDTOConverter plantCareInfoDTOConverter,
                                      CatalogGapService catalogGapService) {
        this.enrichmentService = enrichmentService;
        this.plantCareInfoDTOConverter = plantCareInfoDTOConverter;
        this.catalogGapService = catalogGapService;
    }


    @GetMapping("/preview")
    @Operation(summary = "Preview care data for an unsaved scientific name")
    public ResponseEntity<PlantCareInfoDTO> preview(@RequestParam String scientificName) {
        final PlantCareInfo result = enrichmentService.preview(scientificName);
        catalogGapService.observeCare(scientificName, result);
        return ResponseEntity.ok(plantCareInfoDTOConverter.convertToDTO(result));
    }
}
