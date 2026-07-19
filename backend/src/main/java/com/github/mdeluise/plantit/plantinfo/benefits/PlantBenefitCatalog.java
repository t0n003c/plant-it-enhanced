package com.github.mdeluise.plantit.plantinfo.benefits;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;

import com.github.mdeluise.plantit.botanicalinfo.benefits.PlantBenefitEntry;
import com.github.mdeluise.plantit.botanicalinfo.benefits.PlantBenefitInfo;
import com.github.mdeluise.plantit.botanicalinfo.benefits.PlantBenefitSource;
import com.google.gson.Gson;
import com.google.gson.JsonParseException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Component;

/**
 * Exact, reviewed benefit/use notes. Unknown taxa intentionally remain unknown rather than inheriting
 * a food or medicinal claim from a related plant.
 */
@Component
public class PlantBenefitCatalog {
    private final Map<String, CatalogProfile> profiles;
    private final Instant verifiedAt;


    @Autowired
    public PlantBenefitCatalog(@Value("classpath:plant-benefit-catalog.json") Resource resource) {
        final CatalogData catalog = load(resource);
        final Map<String, CatalogProfile> loaded = new HashMap<>();
        for (CatalogProfile profile : catalog.profiles) {
            validate(profile);
            for (String scientificName : profile.scientificNames) {
                if (loaded.putIfAbsent(normalize(scientificName), profile) != null) {
                    throw new IllegalStateException("Duplicate plant-benefit profile for " + scientificName);
                }
            }
        }
        profiles = Map.copyOf(loaded);
        verifiedAt = Instant.parse(catalog.verifiedAt);
    }


    public PlantBenefitInfo find(String scientificName) {
        if (scientificName == null || scientificName.isBlank()) {
            return PlantBenefitInfo.unknown();
        }
        final CatalogProfile profile = profiles.get(normalize(scientificName));
        if (profile == null) {
            return PlantBenefitInfo.unknown();
        }
        return new PlantBenefitInfo(
            profile.entries.stream()
                    .map(entry -> new PlantBenefitEntry(
                        entry.audience, entry.category, entry.title, entry.summary, entry.caution))
                    .toList(),
            profile.sources.stream().map(source -> new PlantBenefitSource(source.name, source.url)).toList(),
            verifiedAt,
            true,
            scientificName.trim()
        );
    }


    public int profileCount() {
        return profiles.size();
    }


    private CatalogData load(Resource resource) {
        try (Reader reader = new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8)) {
            final CatalogData result = new Gson().fromJson(reader, CatalogData.class);
            if (result == null || result.verifiedAt == null || result.profiles == null || result.profiles.isEmpty()) {
                throw new IllegalStateException("The plant-benefit catalog is incomplete");
            }
            return result;
        } catch (IOException | JsonParseException exception) {
            throw new IllegalStateException("Unable to load the plant-benefit catalog", exception);
        }
    }


    private void validate(CatalogProfile profile) {
        profile.scientificNames = safeList(profile.scientificNames);
        profile.entries = safeList(profile.entries);
        profile.sources = safeList(profile.sources);
        if (profile.scientificNames.isEmpty() || profile.entries.isEmpty() || profile.sources.isEmpty()) {
            throw new IllegalStateException("A plant-benefit profile is incomplete");
        }
        if (profile.scientificNames.stream().anyMatch(this::isBlank) ||
                profile.entries.stream().anyMatch(this::hasInvalidEntry)) {
            throw new IllegalStateException("A plant-benefit profile contains invalid entries");
        }
        if (profile.sources.stream().anyMatch(this::hasInvalidSource)) {
            throw new IllegalStateException("A plant-benefit profile is incomplete");
        }
    }


    private boolean hasInvalidEntry(BenefitEntryData entry) {
        if (entry == null) {
            return true;
        }
        return Stream.of(entry.audience, entry.category, entry.title, entry.summary).anyMatch(this::isBlank);
    }


    private boolean hasInvalidSource(SourceData source) {
        if (source == null) {
            return true;
        }
        return Stream.of(source.name, source.url).anyMatch(this::isBlank);
    }


    private <T> List<T> safeList(List<T> values) {
        return values == null ? new ArrayList<>() : values;
    }


    private String normalize(String value) {
        return value.trim().toLowerCase().replaceAll("\\s+", " ");
    }


    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }


    private static final class CatalogData {
        private String verifiedAt;
        private List<CatalogProfile> profiles = new ArrayList<>();
    }


    private static final class CatalogProfile {
        private List<String> scientificNames = new ArrayList<>();
        private List<BenefitEntryData> entries = new ArrayList<>();
        private List<SourceData> sources = new ArrayList<>();
    }


    private static final class BenefitEntryData {
        private String audience;
        private String category;
        private String title;
        private String summary;
        private String caution;
    }


    private static final class SourceData {
        private String name;
        private String url;
    }
}
