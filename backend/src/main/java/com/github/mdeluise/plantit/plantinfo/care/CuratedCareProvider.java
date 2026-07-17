package com.github.mdeluise.plantit.plantinfo.care;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoCreator;
import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfo;
import com.google.gson.Gson;
import com.google.gson.JsonParseException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Component;

@Component
public class CuratedCareProvider {
    private static final int SCALE_MINIMUM = 0;
    private static final int SCALE_MAXIMUM = 10;
    private final Map<String, CatalogProfile> profilesByScientificName;
    private final Instant verifiedAt;


    @Autowired
    public CuratedCareProvider(@Value("classpath:plant-care-catalog.json") Resource catalogResource) {
        final LoadedCatalog catalog = load(catalogResource);
        profilesByScientificName = catalog.profiles();
        verifiedAt = catalog.verifiedAt();
    }


    public Optional<PlantCareInfo> fetch(String scientificName) {
        Optional<PlantCareInfo> result = Optional.empty();
        if (scientificName != null && !scientificName.isBlank()) {
            final CatalogProfile profile = profilesByScientificName.get(normalize(scientificName));
            if (profile != null) {
                result = Optional.of(toCareInfo(profile));
            }
        }
        return result;
    }


    private LoadedCatalog load(Resource resource) {
        try (Reader reader = new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8)) {
            final CatalogData catalog = new Gson().fromJson(reader, CatalogData.class);
            if (catalog == null || catalog.verifiedAt == null || catalog.profiles == null) {
                throw new IllegalStateException("The curated plant-care catalog is incomplete");
            }
            final Instant catalogVerifiedAt = Instant.parse(catalog.verifiedAt);
            final Map<String, CatalogProfile> profiles = new HashMap<>();
            for (CatalogProfile profile : catalog.profiles) {
                validate(profile);
                for (String scientificName : profile.scientificNames) {
                    final String normalizedName = normalize(scientificName);
                    if (profiles.putIfAbsent(normalizedName, profile) != null) {
                        throw new IllegalStateException(
                            "Duplicate curated care profile for " + scientificName);
                    }
                }
            }
            return new LoadedCatalog(Collections.unmodifiableMap(profiles), catalogVerifiedAt);
        } catch (IOException | JsonParseException exception) {
            throw new IllegalStateException("Unable to load the curated plant-care catalog", exception);
        }
    }


    private void validate(CatalogProfile profile) {
        if (profile.scientificNames == null || profile.scientificNames.isEmpty() ||
                profile.scientificNames.stream().anyMatch(name -> name == null || name.isBlank())) {
            throw new IllegalStateException("A curated care profile is missing its scientific name");
        }
        if (!isValidScaleValue(profile.light) || !isValidScaleValue(profile.humidity) ||
                !isValidScaleValue(profile.soilHumidity)) {
            throw new IllegalStateException(
                "Curated care values must use Plant-it's zero-to-ten scale");
        }
        if (profile.light == null && profile.humidity == null && profile.soilHumidity == null) {
            throw new IllegalStateException("A curated care profile has no usable values");
        }
        if (profile.sourceReference == null || profile.sourceReference.isBlank()) {
            throw new IllegalStateException("A curated care profile is missing its source");
        }
    }


    private boolean isValidScaleValue(Integer value) {
        return value == null || value >= SCALE_MINIMUM && value <= SCALE_MAXIMUM;
    }


    private PlantCareInfo toCareInfo(CatalogProfile profile) {
        final PlantCareInfo result = new PlantCareInfo();
        result.setLight(profile.light);
        result.setHumidity(profile.humidity);
        result.setSoilHumidity(profile.soilHumidity);
        result.setSource(BotanicalInfoCreator.CURATED_CATALOG.name());
        result.setSourceReference(profile.sourceReference);
        result.setLastVerifiedAt(verifiedAt);
        return result;
    }


    private String normalize(String scientificName) {
        return scientificName.trim().toLowerCase(Locale.ROOT).replaceAll("\\s+", " ");
    }


    private static final class CatalogData {
        private String verifiedAt;
        private List<CatalogProfile> profiles;
    }


    private static final class CatalogProfile {
        private List<String> scientificNames;
        private Integer light;
        private Integer humidity;
        private Integer soilHumidity;
        private String sourceReference;
    }


    private record LoadedCatalog(Map<String, CatalogProfile> profiles, Instant verifiedAt) {
    }
}
