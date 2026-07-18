package com.github.mdeluise.plantit.unit.component;

import java.util.Date;
import java.util.LinkedHashSet;

import com.github.mdeluise.plantit.authentication.User;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalCommonName;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.image.ObservationImage;
import com.github.mdeluise.plantit.observation.Observation;
import com.github.mdeluise.plantit.observation.ObservationDTO;
import com.github.mdeluise.plantit.observation.ObservationDTOConverter;
import com.github.mdeluise.plantit.observation.ObservationLocationPrivacy;
import com.github.mdeluise.plantit.observation.ObservationStatus;
import org.assertj.core.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("Unit tests for ObservationDTOConverter")
class ObservationDTOConverterUnitTests {
    private final ObservationDTOConverter converter = new ObservationDTOConverter();


    @Test
    @DisplayName("Should expose taxon names and chronologically ordered photos")
    void shouldExposeTaxonNamesAndChronologicallyOrderedPhotos() {
        final Observation observation = new Observation();
        observation.setId(8L);
        final User owner = new User();
        owner.setId(4L);
        observation.setOwner(owner);
        observation.setCreationDefaults();
        observation.setLocationPrivacy(ObservationLocationPrivacy.PRIVATE);
        observation.setStatus(ObservationStatus.CONFIRMED);
        final BotanicalInfo taxon = new BotanicalInfo();
        taxon.setId(9L);
        taxon.setSpecies("Monarda fistulosa");
        final BotanicalCommonName commonName = new BotanicalCommonName();
        commonName.setName("Wild bergamot");
        commonName.setPreferred(true);
        taxon.setCommonNames(new LinkedHashSet<>());
        taxon.getCommonNames().add(commonName);
        observation.setBotanicalInfo(taxon);
        final ObservationImage later = image("later", 2000L, observation);
        final ObservationImage earlier = image("earlier", 1000L, observation);
        observation.getImages().add(later);
        observation.getImages().add(earlier);

        final ObservationDTO result = converter.convertToDTO(observation);

        Assertions.assertThat(result.getScientificName()).isEqualTo("Monarda fistulosa");
        Assertions.assertThat(result.getPreferredCommonName()).isEqualTo("Wild bergamot");
        Assertions.assertThat(result.getImageIds()).containsExactly("earlier", "later");
    }


    private ObservationImage image(String id, long createdAt, Observation observation) {
        final ObservationImage result = new ObservationImage();
        result.setId(id);
        result.setCreateOn(new Date(createdAt));
        result.setTarget(observation);
        return result;
    }
}
