package com.github.mdeluise.plantit.catalog;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfo;
import com.google.gson.Gson;
import com.google.gson.JsonParseException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Component;

/**
 * Loads the release-quality policy without duplicating plant identities from the trusted name index.
 */
@Component
public class CatalogQualityManifest {
    private static final Set<String> SUPPORTED_CARE_FIELDS = Set.of(
        PlantCareInfo.LIGHT_FIELD,
        PlantCareInfo.HUMIDITY_FIELD,
        PlantCareInfo.SOIL_HUMIDITY_FIELD,
        PlantCareInfo.MIN_TEMP_FIELD,
        PlantCareInfo.MAX_TEMP_FIELD,
        PlantCareInfo.PH_MIN_FIELD,
        PlantCareInfo.PH_MAX_FIELD
    );
    private final int schemaVersion;
    private final List<TierPolicy> tiers;
    private final List<LiveCanary> liveCanaries;


    @Autowired
    public CatalogQualityManifest(@Value("classpath:catalog-quality-manifest.json") Resource resource) {
        final ManifestData loaded = load(resource);
        schemaVersion = loaded.schemaVersion;
        tiers = loaded.tiers.stream().map(this::toPolicy).toList();
        liveCanaries = loaded.liveCanaries.stream().map(this::toCanary).toList();
        validate();
    }


    public int getSchemaVersion() {
        return schemaVersion;
    }


    public List<TierPolicy> getTiers() {
        return tiers;
    }


    public List<LiveCanary> getLiveCanaries() {
        return liveCanaries;
    }


    public TierPolicy policyFor(Set<String> catalogTags) {
        final Set<String> safeTags = catalogTags == null ? Set.of() : catalogTags;
        final List<TierPolicy> matching = tiers.stream().filter(policy -> policy.matches(safeTags)).toList();
        if (matching.size() != 1) {
            throw new IllegalStateException(
                "Catalog entry must match exactly one quality tier but matched " + matching.size());
        }
        return matching.get(0);
    }


    private ManifestData load(Resource resource) {
        try (Reader reader = new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8)) {
            final ManifestData result = new Gson().fromJson(reader, ManifestData.class);
            if (result == null || result.tiers == null || result.liveCanaries == null) {
                throw new IllegalStateException("The catalog quality manifest is incomplete");
            }
            return result;
        } catch (IOException | JsonParseException exception) {
            throw new IllegalStateException("Unable to load the catalog quality manifest", exception);
        }
    }


    private TierPolicy toPolicy(TierPolicyData source) {
        return new TierPolicy(
            source.name,
            copy(source.includeTags),
            copy(source.excludeTags),
            source.requiresImage,
            copy(source.requiredCareFields)
        );
    }


    private LiveCanary toCanary(LiveCanaryData source) {
        return new LiveCanary(
            source.query,
            source.providerTerm,
            copy(source.acceptedScientificNames),
            source.requiresImage
        );
    }


    private List<String> copy(List<String> values) {
        return values == null ? List.of() : List.copyOf(values);
    }


    private void validate() {
        if (schemaVersion < 1 || tiers.isEmpty() || liveCanaries.isEmpty()) {
            throw new IllegalStateException("The catalog quality manifest has no enforceable policy");
        }
        final Set<String> tierNames = new HashSet<>();
        for (TierPolicy tier : tiers) {
            if (isBlank(tier.name()) || !tierNames.add(tier.name()) ||
                    tier.requiredCareFields().stream().anyMatch(field -> !SUPPORTED_CARE_FIELDS.contains(field))) {
                throw new IllegalStateException("The catalog quality manifest contains an invalid tier");
            }
        }
        for (LiveCanary canary : liveCanaries) {
            if (isBlank(canary.query()) || isBlank(canary.providerTerm()) ||
                    canary.acceptedScientificNames().isEmpty() ||
                    canary.acceptedScientificNames().stream().anyMatch(this::isBlank)) {
                throw new IllegalStateException("The catalog quality manifest contains an invalid live canary");
            }
        }
    }


    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }


    public record TierPolicy(String name, List<String> includeTags, List<String> excludeTags,
                             boolean requiresImage, List<String> requiredCareFields) {
        public boolean matches(Set<String> tags) {
            return tags.containsAll(includeTags) && excludeTags.stream().noneMatch(tags::contains);
        }
    }


    public record LiveCanary(String query, String providerTerm,
                             List<String> acceptedScientificNames, boolean requiresImage) {
    }


    private static final class ManifestData {
        private int schemaVersion;
        private List<TierPolicyData> tiers = new ArrayList<>();
        private List<LiveCanaryData> liveCanaries = new ArrayList<>();
    }


    private static final class TierPolicyData {
        private String name;
        private List<String> includeTags = new ArrayList<>();
        private List<String> excludeTags = new ArrayList<>();
        private boolean requiresImage;
        private List<String> requiredCareFields = new ArrayList<>();
    }


    private static final class LiveCanaryData {
        private String query;
        private String providerTerm;
        private List<String> acceptedScientificNames = new ArrayList<>();
        private boolean requiresImage;
    }
}
