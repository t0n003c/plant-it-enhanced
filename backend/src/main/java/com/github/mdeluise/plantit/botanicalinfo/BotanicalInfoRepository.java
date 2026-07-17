package com.github.mdeluise.plantit.botanicalinfo;

import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import com.github.mdeluise.plantit.authentication.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface BotanicalInfoRepository extends JpaRepository<BotanicalInfo, Long> {

    List<BotanicalInfo> findBySpeciesContainsIgnoreCase(String partialScientificName);

    @Query("SELECT DISTINCT b FROM BotanicalInfo b JOIN b.synonyms s WHERE LOCATE(LOWER(:synonym), LOWER(s)) > 0")
    List<BotanicalInfo> findBySynonymsContainsIgnoreCase(@Param("synonym") String synonym);

    @Query("SELECT DISTINCT b FROM BotanicalInfo b JOIN b.commonNames n WHERE LOCATE(:normalizedName, n.normalizedName) > 0")
    List<BotanicalInfo> findByCommonNameContains(@Param("normalizedName") String normalizedName);

    default List<BotanicalInfo> getBySpeciesSynonymOrCommonName(String search, String normalizedSearch) {
        final Set<BotanicalInfo> result = new LinkedHashSet<>();
        result.addAll(findBySpeciesContainsIgnoreCase(search));
        result.addAll(findBySynonymsContainsIgnoreCase(search));
        result.addAll(findByCommonNameContains(normalizedSearch));
        return result.stream().toList();
    }

    default List<BotanicalInfo> getBySpeciesOrSynonym(String search) {
        final Set<BotanicalInfo> result = new HashSet<>();
        result.addAll(findBySpeciesContainsIgnoreCase(search));
        result.addAll(findBySynonymsContainsIgnoreCase(search));
        return result.stream().toList();
    }

    List<BotanicalInfo> findAll();

    List<BotanicalInfo> findAllBySpecies(String species);

    List<BotanicalInfo> findAllBySpeciesIgnoreCase(String species);

    List<BotanicalInfo> findAllByCanonicalTaxonKey(String canonicalTaxonKey);

    List<BotanicalInfo> findAllByCreatorAndExternalId(BotanicalInfoCreator creator, String externalId);

    boolean existsBySpeciesAndCreatorAndUserCreator(String species, BotanicalInfoCreator creator, User userCreator);

    Optional<BotanicalInfo> findBySpeciesAndCreatorAndUserCreator(String species, BotanicalInfoCreator creator, User userCreator);
}
