package com.github.mdeluise.plantit.unit.controller;

import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfo;
import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfoDTO;
import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfoDTOConverter;
import com.github.mdeluise.plantit.catalog.CatalogGapService;
import com.github.mdeluise.plantit.plantinfo.care.PlantCareEnrichmentService;
import com.github.mdeluise.plantit.plantinfo.care.PlantCarePreviewController;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.junit.jupiter.SpringExtension;

@ExtendWith(SpringExtension.class)
@DisplayName("Unit tests for care previews")
class PlantCarePreviewControllerUnitTests {
    @Mock
    private PlantCareEnrichmentService enrichmentService;
    @Mock
    private PlantCareInfoDTOConverter plantCareInfoDTOConverter;
    @Mock
    private CatalogGapService catalogGapService;
    @InjectMocks
    private PlantCarePreviewController controller;


    @Test
    @DisplayName("Should return care data for an unsaved scientific name")
    void shouldReturnCarePreview() {
        final PlantCareInfo careInfo = new PlantCareInfo();
        final PlantCareInfoDTO careInfoDTO = new PlantCareInfoDTO();
        Mockito.when(enrichmentService.preview("Monstera deliciosa")).thenReturn(careInfo);
        Mockito.when(plantCareInfoDTOConverter.convertToDTO(careInfo)).thenReturn(careInfoDTO);

        final ResponseEntity<PlantCareInfoDTO> response = controller.preview("Monstera deliciosa");

        Assertions.assertEquals(HttpStatus.OK, response.getStatusCode());
        Assertions.assertSame(careInfoDTO, response.getBody());
        Mockito.verify(catalogGapService).observeCare("Monstera deliciosa", careInfo);
    }
}
