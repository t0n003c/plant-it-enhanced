package com.github.mdeluise.plantit.unit.component;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoCreator;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoDTO;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoDTOConverter;
import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfoDTOConverter;
import com.github.mdeluise.plantit.image.BotanicalInfoImage;
import com.github.mdeluise.plantit.plantinfo.benefits.PlantBenefitCatalog;
import com.github.mdeluise.plantit.plantinfo.safety.PlantSafetyCatalog;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.modelmapper.ModelMapper;

@DisplayName("Unit tests for botanical image DTO metadata")
class BotanicalInfoDTOConverterUnitTests {

    @Test
    @DisplayName("Should preserve provider image metadata in both conversion directions")
    void shouldPreserveImageMetadata() {
        final BotanicalInfo botanicalInfo = new BotanicalInfo();
        botanicalInfo.setSpecies("Monstera deliciosa");
        botanicalInfo.setCreator(BotanicalInfoCreator.INATURALIST);
        botanicalInfo.setImage(createImage());
        final BotanicalInfoDTOConverter converter = createConverter();

        final BotanicalInfoDTO dto = converter.convertToDTO(botanicalInfo);
        final BotanicalInfo restored = converter.convertFromDTO(dto);

        Assertions.assertEquals("https://example.org/medium.jpg", dto.getImageUrl());
        Assertions.assertEquals("https://example.org/square.jpg", dto.getImageFallbackUrl());
        Assertions.assertEquals("INATURALIST", dto.getImageSource());
        Assertions.assertEquals("cc-by", dto.getImageLicenseCode());
        Assertions.assertEquals("Example credit", dto.getImageAttribution());
        Assertions.assertNotNull(restored.getImage());
        Assertions.assertEquals(dto.getImageUrl(), restored.getImage().getUrl());
        Assertions.assertEquals(dto.getImageSourceUrl(), restored.getImage().getSourceUrl());
    }


    @Test
    @DisplayName("Should expose the plant name that matched the search")
    void shouldExposeMatchedSearchName() {
        final BotanicalInfo botanicalInfo = new BotanicalInfo();
        botanicalInfo.setSpecies("Capsicum annuum");
        botanicalInfo.setCreator(BotanicalInfoCreator.TRUSTED_NAME_INDEX);
        botanicalInfo.setSearchMatchReason("EXACT_COMMON_NAME");
        botanicalInfo.setSearchMatchConfidence(1.0);
        botanicalInfo.setSearchMatchedName("Thai pepper");

        final BotanicalInfoDTO dto = createConverter().convertToDTO(botanicalInfo);

        Assertions.assertEquals("EXACT_COMMON_NAME", dto.getSearchMatchReason());
        Assertions.assertEquals(1.0, dto.getSearchMatchConfidence());
        Assertions.assertEquals("Thai pepper", dto.getSearchMatchedName());
    }


    @Test
    @DisplayName("Should expose attributable safety without persisting it as user data")
    void shouldExposeReviewedSafety() {
        final BotanicalInfo botanicalInfo = new BotanicalInfo();
        botanicalInfo.setSpecies("Lilium candidum");
        botanicalInfo.setCreator(BotanicalInfoCreator.TRUSTED_NAME_INDEX);

        final BotanicalInfoDTO dto = createConverter().convertToDTO(botanicalInfo);

        Assertions.assertTrue(dto.getSafety().reviewed());
        Assertions.assertEquals("Lilium", dto.getSafety().matchedTaxon());
        Assertions.assertEquals("HIGHLY_TOXIC", dto.getSafety().catStatus().name());
        Assertions.assertFalse(dto.getSafety().sources().isEmpty());
    }


    @Test
    @DisplayName("Should expose the catalog variant and reviewed benefits")
    void shouldExposeCatalogVariantAndBenefits() {
        final BotanicalInfo botanicalInfo = new BotanicalInfo();
        botanicalInfo.setSpecies("Capsicum annuum");
        botanicalInfo.setCatalogVariant("Thai chili");
        botanicalInfo.setCreator(BotanicalInfoCreator.TRUSTED_NAME_INDEX);

        final BotanicalInfoDTO dto = createConverter().convertToDTO(botanicalInfo);

        Assertions.assertEquals("Thai chili", dto.getCatalogVariant());
        Assertions.assertTrue(dto.getBenefits().reviewed());
        Assertions.assertTrue(dto.getBenefits().entries().stream().anyMatch(entry ->
            entry.audience().equals("PET") && entry.category().equals("MEDICINE")));
    }


    private BotanicalInfoDTOConverter createConverter() {
        final ModelMapper modelMapper = new ModelMapper();
        return new BotanicalInfoDTOConverter(
            modelMapper,
            new PlantCareInfoDTOConverter(modelMapper),
            new PlantSafetyCatalog(new org.springframework.core.io.ClassPathResource(
                "plant-safety-catalog.json")),
            new PlantBenefitCatalog(new org.springframework.core.io.ClassPathResource(
                "plant-benefit-catalog.json"))
        );
    }


    private BotanicalInfoImage createImage() {
        final BotanicalInfoImage image = new BotanicalInfoImage();
        image.setId(null);
        image.setUrl("https://example.org/medium.jpg");
        image.setFallbackUrl("https://example.org/square.jpg");
        image.setSource("INATURALIST");
        image.setSourceUrl("https://www.inaturalist.org/photos/12345");
        image.setLicenseCode("cc-by");
        image.setAttribution("Example credit");
        return image;
    }
}
