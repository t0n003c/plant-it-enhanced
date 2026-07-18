package com.github.mdeluise.plantit.plantinfo.identification;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import com.github.mdeluise.plantit.plantinfo.search.PlantNameNormalizer;
import com.google.gson.Gson;
import com.google.gson.JsonParseException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Component;

/**
 * Exact-name lookup for reviewed trail ecology and lookalike comparisons.
 */
@Component
public class TrailFieldGuideIndex {
    private final List<TrailFieldGuideProfile> profiles;


    @Autowired
    public TrailFieldGuideIndex(@Value("classpath:trail-field-guide.json") Resource resource) {
        profiles = load(resource);
    }


    private TrailFieldGuideIndex(List<TrailFieldGuideProfile> profiles) {
        this.profiles = List.copyOf(profiles);
    }


    public Optional<TrailFieldGuideProfile> find(String scientificName) {
        final String normalizedName = PlantNameNormalizer.normalize(scientificName);
        if (normalizedName.isBlank()) {
            return Optional.empty();
        }
        return profiles.stream().filter(profile -> matches(normalizedName, profile)).findFirst();
    }


    private boolean matches(String normalizedName, TrailFieldGuideProfile profile) {
        if (PlantNameNormalizer.normalize(profile.scientificName()).equals(normalizedName)) {
            return true;
        }
        return profile.scientificSynonyms().stream()
                      .map(PlantNameNormalizer::normalize)
                      .anyMatch(normalizedName::equals);
    }


    private List<TrailFieldGuideProfile> load(Resource resource) {
        try (Reader reader = new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8)) {
            final TrailFieldGuideCatalog catalog = new Gson().fromJson(reader, TrailFieldGuideCatalog.class);
            if (catalog == null || catalog.profiles == null || catalog.profiles.isEmpty()) {
                throw new IllegalStateException("The trail field guide is empty");
            }
            validate(catalog.profiles);
            return List.copyOf(catalog.profiles);
        } catch (IOException | JsonParseException exception) {
            throw new IllegalStateException("Unable to load the trail field guide", exception);
        }
    }


    private void validate(List<TrailFieldGuideProfile> toValidate) {
        final Map<String, String> ownersByScientificName = new HashMap<>();
        for (TrailFieldGuideProfile profile : toValidate) {
            validateProfile(profile);
            registerName(profile.scientificName(), profile.scientificName(), ownersByScientificName);
            profile.scientificSynonyms().forEach(
                synonym -> registerName(synonym, profile.scientificName(), ownersByScientificName));
        }
    }


    private void validateProfile(TrailFieldGuideProfile profile) {
        if (profile == null) {
            throw new IllegalStateException("A trail field-guide profile has no scientific name");
        }
        requireText(profile.scientificName(), "A trail field-guide profile has no scientific name");
        if (profile.ecology() == null) {
            throw new IllegalStateException("Trail ecology requires an attributable HTTPS source");
        }
        requireText(profile.ecology().source(), "Trail ecology requires an attributable HTTPS source");
        requireSecureReference(profile.ecology().sourceReference(),
            "Trail ecology requires an attributable HTTPS source");
        for (PlantLookalike lookalike : profile.lookalikes()) {
            final String message = "A reviewed lookalike is incomplete or unattributed";
            requireText(lookalike.scientificName(), message);
            requireText(lookalike.commonName(), message);
            requireText(lookalike.comparison(), message);
            requireText(lookalike.source(), message);
            requireSecureReference(lookalike.sourceReference(), message);
        }
    }


    private void requireText(String value, String message) {
        if (value == null || value.isBlank()) {
            throw new IllegalStateException(message);
        }
    }


    private void requireSecureReference(String sourceReference, String message) {
        if (sourceReference == null || !sourceReference.startsWith("https://")) {
            throw new IllegalStateException(message);
        }
    }


    private void registerName(String name, String owner, Map<String, String> ownersByScientificName) {
        final String normalizedName = PlantNameNormalizer.normalize(name);
        final String previousOwner = ownersByScientificName.putIfAbsent(normalizedName, owner);
        if (normalizedName.isBlank() || previousOwner != null && !previousOwner.equalsIgnoreCase(owner)) {
            throw new IllegalStateException("Ambiguous trail field-guide scientific name: " + name);
        }
    }


    public static TrailFieldGuideIndex empty() {
        return new TrailFieldGuideIndex(List.of());
    }


    private static final class TrailFieldGuideCatalog {
        private List<TrailFieldGuideProfile> profiles;
    }
}
