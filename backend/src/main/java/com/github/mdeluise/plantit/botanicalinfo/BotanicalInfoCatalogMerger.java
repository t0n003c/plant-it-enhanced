package com.github.mdeluise.plantit.botanicalinfo;

import java.time.Instant;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfo;
import com.github.mdeluise.plantit.plantinfo.search.PlantNameNormalizer;

/**
 * Combines provider records without replacing values that a catalog entry already owns.
 */
public final class BotanicalInfoCatalogMerger {
    private static final String GBIF_PROVIDER = BotanicalInfoCreator.GBIF.name();


    private BotanicalInfoCatalogMerger() {
    }


    public static void prepareCanonicalIdentity(BotanicalInfo botanicalInfo) {
        if (botanicalInfo == null) {
            return;
        }
        if (botanicalInfo.getExternalReferences() == null) {
            botanicalInfo.setExternalReferences(new HashMap<>());
        }
        final String gbifReference = clean(botanicalInfo.getExternalReferences().get(GBIF_PROVIDER));
        final String currentKey = clean(botanicalInfo.getCanonicalTaxonKey());
        if (gbifReference != null) {
            botanicalInfo.setCanonicalTaxonKey(gbifReference);
        } else if (currentKey != null) {
            botanicalInfo.setCanonicalTaxonKey(currentKey);
            botanicalInfo.getExternalReferences().put(GBIF_PROVIDER, currentKey);
        }
    }


    public static boolean describesSameTaxon(BotanicalInfo left, BotanicalInfo right) {
        prepareCanonicalIdentity(left);
        prepareCanonicalIdentity(right);
        final String leftKey = clean(left.getCanonicalTaxonKey());
        final String rightKey = clean(right.getCanonicalTaxonKey());
        if (leftKey != null && rightKey != null) {
            return leftKey.equals(rightKey);
        }
        if (hasSharedProviderReference(left, right)) {
            return true;
        }
        final String leftSpecies = PlantNameNormalizer.normalize(left.getSpecies());
        final String rightSpecies = PlantNameNormalizer.normalize(right.getSpecies());
        return !leftSpecies.isBlank() && leftSpecies.equals(rightSpecies);
    }


    public static BotanicalInfo mergeInto(BotanicalInfo target, BotanicalInfo source) {
        prepareCanonicalIdentity(target);
        prepareCanonicalIdentity(source);
        final boolean newerVerifiedSource = isNewerVerifiedSource(target, source);

        mergeScientificIdentity(target, source, newerVerifiedSource);
        mergeSynonyms(target, source);
        mergeCommonNames(target, source);
        mergeExternalReferences(target, source);
        mergeCareInfo(target.getPlantCareInfo(), source.getPlantCareInfo());
        if (clean(target.getCanonicalTaxonKey()) == null) {
            target.setCanonicalTaxonKey(clean(source.getCanonicalTaxonKey()));
        }
        if (newerVerifiedSource || target.getLastVerifiedAt() == null) {
            target.setLastVerifiedAt(source.getLastVerifiedAt());
        }
        return target;
    }


    private static void mergeScientificIdentity(BotanicalInfo target, BotanicalInfo source,
                                                 boolean newerVerifiedSource) {
        if (newerVerifiedSource && clean(source.getSpecies()) != null) {
            final String previousScientificName = target.getSpecies();
            target.setSpecies(source.getSpecies());
            addSynonym(target, previousScientificName);
            setIfPresent(source.getFamily(), target::setFamily);
            setIfPresent(source.getGenus(), target::setGenus);
            return;
        }
        if (clean(target.getSpecies()) == null) {
            target.setSpecies(source.getSpecies());
        }
        if (clean(target.getFamily()) == null) {
            target.setFamily(source.getFamily());
        }
        if (clean(target.getGenus()) == null) {
            target.setGenus(source.getGenus());
        }
    }


    private static void mergeSynonyms(BotanicalInfo target, BotanicalInfo source) {
        if (target.getSynonyms() == null) {
            target.setSynonyms(new LinkedHashSet<>());
        }
        if (source.getSynonyms() == null) {
            return;
        }
        source.getSynonyms().forEach(synonym -> addSynonym(target, synonym));
    }


    private static void addSynonym(BotanicalInfo target, String synonym) {
        final String cleaned = clean(synonym);
        if (cleaned == null || cleaned.equalsIgnoreCase(target.getSpecies())) {
            return;
        }
        if (target.getSynonyms() == null) {
            target.setSynonyms(new LinkedHashSet<>());
        }
        final boolean alreadyPresent = target.getSynonyms().stream()
                                             .filter(Objects::nonNull)
                                             .anyMatch(cleaned::equalsIgnoreCase);
        if (!alreadyPresent) {
            target.getSynonyms().add(cleaned);
        }
    }


    private static void mergeCommonNames(BotanicalInfo target, BotanicalInfo source) {
        if (target.getCommonNames() == null) {
            target.setCommonNames(new LinkedHashSet<>());
        }
        if (source.getCommonNames() == null) {
            return;
        }
        source.getCommonNames().stream()
              .filter(commonName -> clean(commonName.getName()) != null)
              .forEach(commonName -> mergeCommonName(target.getCommonNames(), commonName));
    }


    private static void mergeCommonName(Set<BotanicalCommonName> targetNames, BotanicalCommonName incoming) {
        final BotanicalCommonName existing = targetNames.stream()
                                                         .filter(incoming::equals)
                                                         .findFirst()
                                                         .orElse(null);
        final boolean localeAlreadyHasPreferred = targetNames.stream()
                                                              .filter(BotanicalCommonName::isPreferred)
                                                              .anyMatch(name -> sameLocale(name, incoming));
        if (existing != null) {
            if (incoming.isPreferred() && !localeAlreadyHasPreferred) {
                existing.setPreferred(true);
            }
            return;
        }
        final BotanicalInfoCreator source = incoming.getSource() == null
                                                ? BotanicalInfoCreator.USER : incoming.getSource();
        targetNames.add(new BotanicalCommonName(
            incoming.getName(), incoming.getLanguage(), incoming.getRegion(),
            incoming.isPreferred() && !localeAlreadyHasPreferred, source
        ));
    }


    private static boolean sameLocale(BotanicalCommonName left, BotanicalCommonName right) {
        return equalsIgnoreCase(left.getLanguage(), right.getLanguage()) &&
                   equalsIgnoreCase(left.getRegion(), right.getRegion());
    }


    private static boolean equalsIgnoreCase(String left, String right) {
        if (left == null || right == null) {
            return left == right;
        }
        return left.equalsIgnoreCase(right);
    }


    private static void mergeExternalReferences(BotanicalInfo target, BotanicalInfo source) {
        if (source.getExternalReferences() == null) {
            return;
        }
        source.getExternalReferences().forEach((provider, externalId) -> {
            if (clean(provider) != null && clean(externalId) != null) {
                target.getExternalReferences().putIfAbsent(provider, externalId);
            }
        });
    }


    private static boolean hasSharedProviderReference(BotanicalInfo left, BotanicalInfo right) {
        for (Map.Entry<String, String> reference : left.getExternalReferences().entrySet()) {
            final String rightReference = right.getExternalReferences().get(reference.getKey());
            if (clean(reference.getValue()) != null && reference.getValue().equals(rightReference)) {
                return true;
            }
        }
        return false;
    }


    private static boolean isNewerVerifiedSource(BotanicalInfo target, BotanicalInfo source) {
        final Instant sourceVerifiedAt = source.getLastVerifiedAt();
        final Instant targetVerifiedAt = target.getLastVerifiedAt();
        return sourceVerifiedAt != null &&
                   (targetVerifiedAt == null || sourceVerifiedAt.isAfter(targetVerifiedAt)) &&
                   clean(source.getCanonicalTaxonKey()) != null;
    }


    private static void mergeCareInfo(PlantCareInfo target, PlantCareInfo source) {
        if (target.getLight() == null) {
            target.setLight(source.getLight());
        }
        if (target.getHumidity() == null) {
            target.setHumidity(source.getHumidity());
        }
        if (target.getMinTemp() == null) {
            target.setMinTemp(source.getMinTemp());
        }
        if (target.getMaxTemp() == null) {
            target.setMaxTemp(source.getMaxTemp());
        }
        if (target.getPhMin() == null) {
            target.setPhMin(source.getPhMin());
        }
        if (target.getPhMax() == null) {
            target.setPhMax(source.getPhMax());
        }
    }


    private static void setIfPresent(String value, java.util.function.Consumer<String> setter) {
        if (clean(value) != null) {
            setter.accept(value);
        }
    }


    private static String clean(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }
}
