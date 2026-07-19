package com.github.mdeluise.plantit.plantinfo.safety;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import com.github.mdeluise.plantit.botanicalinfo.safety.PlantSafetyInfo;
import com.github.mdeluise.plantit.botanicalinfo.safety.PlantSafetySource;
import com.github.mdeluise.plantit.botanicalinfo.safety.PlantSafetyStatus;
import com.google.gson.Gson;
import com.google.gson.JsonParseException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Component;

/**
 * Exact and reviewed taxonomic-group safety profiles. Unknown taxa deliberately remain unknown rather than
 * inheriting a claim from a similar common name.
 */
@Component
public class PlantSafetyCatalog {
    private final Map<String, CatalogProfile> exactProfiles;
    private final List<ScopedProfile> scopedProfiles;
    private final Instant verifiedAt;
    private final int profileCount;


    @Autowired
    public PlantSafetyCatalog(@Value("classpath:plant-safety-catalog.json") Resource resource) {
        final LoadedCatalog loaded = load(resource);
        exactProfiles = loaded.exactProfiles();
        scopedProfiles = loaded.scopedProfiles();
        verifiedAt = loaded.verifiedAt();
        profileCount = loaded.profileCount();
    }


    public PlantSafetyInfo find(String scientificName) {
        if (scientificName == null || scientificName.isBlank()) {
            return PlantSafetyInfo.unknown();
        }
        final String normalizedName = normalize(scientificName);
        final CatalogProfile exact = exactProfiles.get(normalizedName);
        if (exact != null) {
            return toSafetyInfo(exact, scientificName.trim());
        }
        return scopedProfiles.stream()
                             .filter(profile -> isWithinTaxon(normalizedName, profile.normalizedTaxon()))
                             .findFirst()
                             .map(profile -> toSafetyInfo(profile.profile(), profile.taxon()))
                             .orElseGet(PlantSafetyInfo::unknown);
    }


    public int profileCount() {
        return profileCount;
    }


    private LoadedCatalog load(Resource resource) {
        try (Reader reader = new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8)) {
            final CatalogData catalog = new Gson().fromJson(reader, CatalogData.class);
            if (catalog == null || catalog.verifiedAt == null || catalog.profiles == null ||
                    catalog.profiles.isEmpty()) {
                throw new IllegalStateException("The plant-safety catalog is incomplete");
            }
            final Map<String, CatalogProfile> exact = new HashMap<>();
            final List<ScopedProfile> scoped = new ArrayList<>();
            for (CatalogProfile profile : catalog.profiles) {
                validate(profile);
                for (String scientificName : profile.scientificNames) {
                    if (exact.putIfAbsent(normalize(scientificName), profile) != null) {
                        throw new IllegalStateException("Duplicate plant-safety profile for " + scientificName);
                    }
                }
                for (String taxon : profile.taxonScopes) {
                    scoped.add(new ScopedProfile(taxon, normalize(taxon), profile));
                }
            }
            scoped.sort(Comparator.comparingInt(
                (ScopedProfile profile) -> profile.normalizedTaxon().length()).reversed());
            return new LoadedCatalog(
                Map.copyOf(exact),
                List.copyOf(scoped),
                Instant.parse(catalog.verifiedAt),
                catalog.profiles.size()
            );
        } catch (IOException | JsonParseException exception) {
            throw new IllegalStateException("Unable to load the plant-safety catalog", exception);
        }
    }


    private void validate(CatalogProfile profile) {
        if (isEmpty(profile.scientificNames) && isEmpty(profile.taxonScopes)) {
            throw new IllegalStateException("A plant-safety profile is incomplete");
        }
        if (profile.humanStatus == null || profile.catStatus == null || profile.dogStatus == null) {
            throw new IllegalStateException("A plant-safety profile is missing an audience status");
        }
        if (isBlank(profile.summary) || isEmpty(profile.sources)) {
            throw new IllegalStateException("A plant-safety profile is missing guidance or sources");
        }
        profile.scientificNames = safeList(profile.scientificNames);
        profile.taxonScopes = safeList(profile.taxonScopes);
        profile.hazardousParts = safeList(profile.hazardousParts);
        if (profile.scientificNames.stream().anyMatch(this::isBlank) ||
                profile.taxonScopes.stream().anyMatch(this::isBlank)) {
            throw new IllegalStateException("A plant-safety profile contains invalid identity or source data");
        }
        if (profile.sources.stream().anyMatch(this::isInvalidSource)) {
            throw new IllegalStateException("A plant-safety profile contains an invalid source");
        }
    }


    private PlantSafetyInfo toSafetyInfo(CatalogProfile profile, String matchedTaxon) {
        return new PlantSafetyInfo(
            profile.humanStatus,
            profile.catStatus,
            profile.dogStatus,
            profile.summary,
            List.copyOf(profile.hazardousParts),
            profile.sources.stream().map(source -> new PlantSafetySource(source.name, source.url)).toList(),
            verifiedAt,
            true,
            matchedTaxon
        );
    }


    private boolean isWithinTaxon(String scientificName, String taxon) {
        return scientificName.equals(taxon) || scientificName.startsWith(taxon + " ");
    }


    private List<String> safeList(List<String> values) {
        return values == null ? new ArrayList<>() : values;
    }


    private boolean isEmpty(List<?> values) {
        return values == null || values.isEmpty();
    }


    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }


    private boolean isInvalidSource(SourceData source) {
        if (source == null || isBlank(source.name) || isBlank(source.url)) {
            return true;
        }
        return !source.url.startsWith("https://");
    }


    private String normalize(String scientificName) {
        return scientificName.trim().toLowerCase(Locale.ROOT).replaceAll("\\s+", " ");
    }


    private static final class CatalogData {
        private String verifiedAt;
        private List<CatalogProfile> profiles = new ArrayList<>();
    }


    private static final class CatalogProfile {
        private List<String> scientificNames = new ArrayList<>();
        private List<String> taxonScopes = new ArrayList<>();
        private PlantSafetyStatus humanStatus;
        private PlantSafetyStatus catStatus;
        private PlantSafetyStatus dogStatus;
        private String summary;
        private List<String> hazardousParts = new ArrayList<>();
        private List<SourceData> sources = new ArrayList<>();
    }


    private static final class SourceData {
        private String name;
        private String url;
    }


    private record ScopedProfile(String taxon, String normalizedTaxon, CatalogProfile profile) {
    }


    private record LoadedCatalog(Map<String, CatalogProfile> exactProfiles,
                                 List<ScopedProfile> scopedProfiles,
                                 Instant verifiedAt, int profileCount) {
    }
}
