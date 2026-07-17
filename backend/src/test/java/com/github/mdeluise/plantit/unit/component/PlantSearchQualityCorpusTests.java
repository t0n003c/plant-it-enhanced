package com.github.mdeluise.plantit.unit.component;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalCommonName;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoCreator;
import com.github.mdeluise.plantit.plantinfo.search.PlantSearchScorer;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvFileSource;

@DisplayName("Common household plant search quality corpus")
class PlantSearchQualityCorpusTests {

    @ParameterizedTest(name = "{0} should rank {1} first")
    @CsvFileSource(resources = "/search-quality/common-name-ranking.csv", numLinesToSkip = 1)
    void shouldRankExpectedPlantFirst(String query, String expectedScientificName) {
        final BotanicalInfo bestMatch = catalog().stream()
                                                   .max(Comparator.comparingInt(
                                                       candidate -> PlantSearchScorer.score(query, candidate)))
                                                   .orElseThrow();

        Assertions.assertTrue(PlantSearchScorer.score(query, bestMatch) > 0);
        Assertions.assertEquals(expectedScientificName, bestMatch.getSpecies());
    }


    private List<BotanicalInfo> catalog() {
        final List<BotanicalInfo> result = new ArrayList<>();
        result.add(plant("Dracaena trifasciata",
                         List.of("Snake Plant", "Mother-in-Law's Tongue"),
                         List.of("Sansevieria trifasciata")));
        result.add(plant("Epipremnum aureum",
                         List.of("Pothos", "Golden Pothos", "Devil's Ivy"), List.of()));
        result.add(plant("Monstera deliciosa",
                         List.of("Swiss Cheese Plant", "Split Leaf Philodendron"), List.of()));
        result.add(plant("Pachira aquatica", List.of("Money Tree"), List.of()));
        result.add(plant("Spathiphyllum wallisii", List.of("Peace Lily"), List.of()));
        result.add(plant("Chlorophytum comosum", List.of("Spider Plant"), List.of()));
        result.add(plant("Ficus lyrata", List.of("Fiddle Leaf Fig"), List.of()));
        result.add(plant("Zamioculcas zamiifolia", List.of("ZZ Plant", "Zanzibar Gem"), List.of()));
        result.add(plant("Aloe vera", List.of("Aloe Vera"), List.of()));
        result.add(plant("Crassula ovata", List.of("Jade Plant"), List.of()));
        result.add(plant("Pilea peperomioides", List.of("Chinese Money Plant"), List.of()));
        result.add(plant("Philodendron hederaceum", List.of("Heartleaf Philodendron"), List.of()));
        result.add(plant("Schlumbergera truncata",
                         List.of("Thanksgiving Cactus", "Holiday Cactus"), List.of()));
        result.add(plant("Ficus elastica", List.of("Rubber Plant"), List.of()));
        result.add(plant("Maranta leuconeura", List.of("Prayer Plant"), List.of()));
        result.add(plant("Curio rowleyanus", List.of("String of Pearls"), List.of("Senecio rowleyanus")));
        result.add(plant("Beaucarnea recurvata", List.of("Ponytail Palm"), List.of()));
        return result;
    }


    private BotanicalInfo plant(String scientificName, List<String> commonNames, List<String> synonyms) {
        final BotanicalInfo result = new BotanicalInfo();
        result.setSpecies(scientificName);
        result.getSynonyms().addAll(synonyms);
        commonNames.forEach(commonName -> result.getCommonNames().add(new BotanicalCommonName(
            commonName, "en", "US", result.getCommonNames().isEmpty(), BotanicalInfoCreator.INATURALIST
        )));
        return result;
    }
}
