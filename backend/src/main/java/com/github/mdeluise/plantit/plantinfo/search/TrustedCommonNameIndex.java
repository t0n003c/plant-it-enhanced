package com.github.mdeluise.plantit.plantinfo.search;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalCommonName;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoCreator;
import com.google.gson.Gson;
import com.google.gson.JsonParseException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Component;

@Component
public class TrustedCommonNameIndex {
    public static final String NORTH_AMERICAN_TRAIL_TAG = "NORTH_AMERICAN_TRAIL";
    public static final String CONTACT_HAZARD_TAG = "CONTACT_HAZARD";
    private final List<TrustedNameEntry> entries;


    @Autowired
    public TrustedCommonNameIndex(@Value("classpath:trusted-common-names.json") Resource resource) {
        entries = load(resource);
    }


    public List<BotanicalInfo> search(String query, int size) {
        return entries.stream()
                      .map(this::toBotanicalInfo)
                      .filter(candidate -> PlantSearchScorer.evaluate(query, candidate).isRelevant())
                      .sorted(PlantSearchScorer.relevanceComparator(query))
                      .limit(size)
                      .peek(candidate -> PlantSearchScorer.applyMatchMetadata(query, candidate))
                      .toList();
    }


    /**
     * Resolves an exact reviewed everyday name or scientific synonym to the accepted scientific name used by
     * taxonomy and media providers. Partial and fuzzy queries intentionally remain unchanged so discovery searches
     * can still return several relevant taxa.
     */
    public String resolveProviderSearchTerm(String query) {
        final String normalizedQuery = PlantNameNormalizer.normalize(query);
        if (normalizedQuery.isBlank()) {
            return query;
        }
        return entries.stream()
                      .filter(entry -> matchesExactName(normalizedQuery, entry))
                      .map(entry -> entry.scientificName)
                      .findFirst()
                      .orElse(query);
    }


    public List<TrustedNameExample> qualityExamples() {
        final List<TrustedNameExample> result = new ArrayList<>();
        entries.forEach(entry -> {
            result.add(new TrustedNameExample(entry.scientificName, entry.scientificName));
            entry.commonNames.forEach(name -> result.add(new TrustedNameExample(name, entry.scientificName)));
            entry.scientificSynonyms.forEach(name -> result.add(new TrustedNameExample(name, entry.scientificName)));
        });
        return List.copyOf(result);
    }


    public List<CatalogEntry> catalogEntries() {
        return entries.stream()
                      .map(entry -> new CatalogEntry(
                          entry.scientificName,
                          List.copyOf(entry.scientificSynonyms),
                          List.copyOf(entry.commonNames),
                          Set.copyOf(entry.catalogTags)
                      ))
                      .toList();
    }


    public BotanicalInfo applyCatalogMetadata(BotanicalInfo botanicalInfo) {
        if (botanicalInfo == null || botanicalInfo.getSpecies() == null) {
            return botanicalInfo;
        }
        final String normalizedScientificName = PlantNameNormalizer.normalize(botanicalInfo.getSpecies());
        entries.stream()
               .filter(entry -> matchesScientificName(normalizedScientificName, entry))
               .findFirst()
               .ifPresent(entry -> {
                   if (botanicalInfo.getCatalogTags() == null) {
                       botanicalInfo.setCatalogTags(new LinkedHashSet<>());
                   }
                   botanicalInfo.getCatalogTags().addAll(entry.catalogTags);
               });
        return botanicalInfo;
    }


    private boolean matchesScientificName(String normalizedScientificName, TrustedNameEntry entry) {
        if (PlantNameNormalizer.normalize(entry.scientificName).equals(normalizedScientificName)) {
            return true;
        }
        return entry.scientificSynonyms.stream()
                                       .map(PlantNameNormalizer::normalize)
                                       .anyMatch(normalizedScientificName::equals);
    }


    private boolean matchesExactName(String normalizedQuery, TrustedNameEntry entry) {
        if (PlantNameNormalizer.normalize(entry.scientificName).equals(normalizedQuery)) {
            return true;
        }
        return entry.scientificSynonyms.stream()
                                       .map(PlantNameNormalizer::normalize)
                                       .anyMatch(normalizedQuery::equals) ||
                   entry.commonNames.stream()
                                    .map(PlantNameNormalizer::normalize)
                                    .anyMatch(normalizedQuery::equals);
    }


    private BotanicalInfo toBotanicalInfo(TrustedNameEntry entry) {
        final BotanicalInfo result = new BotanicalInfo();
        result.setSpecies(entry.scientificName);
        result.setGenus(entry.scientificName.split(" ")[0]);
        result.setCreator(BotanicalInfoCreator.TRUSTED_NAME_INDEX);
        result.setExternalId("trusted-name:" + PlantNameNormalizer.normalize(entry.scientificName));
        result.setSynonyms(new LinkedHashSet<>(entry.scientificSynonyms));
        result.setCatalogTags(new LinkedHashSet<>(entry.catalogTags));
        for (String commonName : entry.commonNames) {
            result.getCommonNames().add(new BotanicalCommonName(
                commonName, "en", null, result.getCommonNames().isEmpty(),
                BotanicalInfoCreator.TRUSTED_NAME_INDEX
            ));
        }
        return result;
    }


    private List<TrustedNameEntry> load(Resource resource) {
        try (Reader reader = new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8)) {
            final TrustedNameCatalog catalog = new Gson().fromJson(reader, TrustedNameCatalog.class);
            if (catalog == null || catalog.entries == null || catalog.entries.isEmpty()) {
                throw new IllegalStateException("The trusted common-name index is empty");
            }
            validate(catalog.entries);
            return List.copyOf(catalog.entries);
        } catch (IOException | JsonParseException exception) {
            throw new IllegalStateException("Unable to load the trusted common-name index", exception);
        }
    }


    private void validate(List<TrustedNameEntry> toValidate) {
        final Map<String, String> ownersByName = new HashMap<>();
        for (TrustedNameEntry entry : toValidate) {
            if (entry.scientificName == null || entry.scientificName.isBlank() ||
                    entry.commonNames == null || entry.commonNames.isEmpty()) {
                throw new IllegalStateException("A trusted common-name entry is incomplete");
            }
            entry.scientificSynonyms = entry.scientificSynonyms == null
                                           ? new ArrayList<>() : entry.scientificSynonyms;
            entry.catalogTags = entry.catalogTags == null ? new ArrayList<>() : entry.catalogTags;
            registerName(ownersByName, entry.scientificName, entry.scientificName);
            entry.scientificSynonyms.forEach(name -> registerName(ownersByName, name, entry.scientificName));
            entry.commonNames.forEach(name -> registerName(ownersByName, name, entry.scientificName));
        }
    }


    private void registerName(Map<String, String> ownersByName, String name, String scientificName) {
        final String normalizedName = PlantNameNormalizer.normalize(name);
        final String previousOwner = ownersByName.putIfAbsent(normalizedName, scientificName);
        if (normalizedName.isBlank() || previousOwner != null &&
                !previousOwner.equalsIgnoreCase(scientificName)) {
            throw new IllegalStateException("Ambiguous trusted plant name: " + name);
        }
    }


    public record TrustedNameExample(String query, String scientificName) {
    }


    public record CatalogEntry(String scientificName, List<String> scientificSynonyms,
                               List<String> commonNames, Set<String> catalogTags) {
    }


    private static final class TrustedNameCatalog {
        private List<TrustedNameEntry> entries;
    }


    private static final class TrustedNameEntry {
        private String scientificName;
        private List<String> scientificSynonyms = new ArrayList<>();
        private List<String> commonNames = new ArrayList<>();
        private List<String> catalogTags = new ArrayList<>();
    }
}
