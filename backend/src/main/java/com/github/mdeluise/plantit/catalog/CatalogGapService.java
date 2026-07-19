package com.github.mdeluise.plantit.catalog;

import java.time.Instant;
import java.util.Collection;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoCatalogMerger;
import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfo;
import com.github.mdeluise.plantit.common.AuthenticatedUserService;
import com.github.mdeluise.plantit.plantinfo.search.PlantNameNormalizer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Stores only sanitized, per-account quality gaps on the self-hosted database.
 */
@Service
public class CatalogGapService {
    private static final int MAXIMUM_SUBJECT_LENGTH = 150;
    private final CatalogGapObservationRepository repository;
    private final AuthenticatedUserService authenticatedUserService;
    private final Logger logger = LoggerFactory.getLogger(CatalogGapService.class);


    public CatalogGapService(CatalogGapObservationRepository repository,
                             AuthenticatedUserService authenticatedUserService) {
        this.repository = repository;
        this.authenticatedUserService = authenticatedUserService;
    }


    public void observeSearch(String query, Collection<BotanicalInfo> results) {
        try {
            final List<BotanicalInfo> safeResults = results == null ? List.of() : List.copyOf(results);
            final String queryKey = key(query);
            if (queryKey == null) {
                return;
            }
            updateGap(
                CatalogGapType.NO_RESULTS, queryKey, display(query), null, safeResults.isEmpty());
            if (safeResults.isEmpty()) {
                return;
            }
            final BotanicalInfo firstResult = safeResults.get(0);
            final String scientificName = firstResult.getSpecies();
            final String scientificKey = key(scientificName);
            if (scientificKey != null) {
                updateGap(
                    CatalogGapType.MISSING_IMAGE,
                    scientificKey,
                    display(scientificName),
                    display(scientificName),
                    !BotanicalInfoCatalogMerger.hasUsableImage(firstResult)
                );
            }
        } catch (RuntimeException exception) {
            logger.warn("Unable to record local catalog search quality", exception);
        }
    }


    public void observeCare(String scientificName, PlantCareInfo careInfo) {
        try {
            final String scientificKey = key(scientificName);
            if (scientificKey == null) {
                return;
            }
            updateGap(
                CatalogGapType.MISSING_CARE,
                scientificKey,
                display(scientificName),
                display(scientificName),
                careInfo == null || careInfo.isAllNull()
            );
        } catch (RuntimeException exception) {
            logger.warn("Unable to record local catalog care quality", exception);
        }
    }


    public List<CatalogGapSummary> activeGaps() {
        try {
            final Long ownerId = currentOwnerId();
            return repository.findTop20ByOwnerIdAndActiveTrueOrderByLastSeenAtDesc(ownerId).stream()
                             .map(this::toSummary)
                             .toList();
        } catch (RuntimeException exception) {
            logger.warn("Unable to read local catalog quality gaps", exception);
            return List.of();
        }
    }


    public long activeGapCount() {
        try {
            return repository.countByOwnerIdAndActiveTrue(currentOwnerId());
        } catch (RuntimeException exception) {
            logger.warn("Unable to count local catalog quality gaps", exception);
            return 0;
        }
    }


    public Map<CatalogGapType, Long> activeGapCounts() {
        try {
            final Long ownerId = currentOwnerId();
            final Map<CatalogGapType, Long> result = new EnumMap<>(CatalogGapType.class);
            for (CatalogGapType type : CatalogGapType.values()) {
                result.put(type, repository.countByOwnerIdAndIssueTypeAndActiveTrue(ownerId, type));
            }
            return Map.copyOf(result);
        } catch (RuntimeException exception) {
            logger.warn("Unable to count local catalog quality gap types", exception);
            return Map.of();
        }
    }


    private void updateGap(CatalogGapType type, String subjectKey, String displaySubject,
                           String scientificName, boolean active) {
        final Long ownerId = currentOwnerId();
        final Optional<CatalogGapObservation> saved = repository.findByOwnerIdAndIssueTypeAndSubjectKey(
            ownerId, type, subjectKey);
        if (!active && saved.isEmpty()) {
            return;
        }
        final Instant now = Instant.now();
        final CatalogGapObservation observation = saved.orElseGet(CatalogGapObservation::new);
        if (observation.getId() == null) {
            observation.setOwnerId(ownerId);
            observation.setIssueType(type);
            observation.setSubjectKey(subjectKey);
            observation.setFirstSeenAt(now);
            observation.setOccurrenceCount(0);
        }
        observation.setDisplaySubject(displaySubject);
        observation.setScientificName(scientificName);
        if (active) {
            observation.setOccurrenceCount(observation.getOccurrenceCount() + 1);
            observation.setLastSeenAt(now);
            observation.setActive(true);
            observation.setResolvedAt(null);
        } else {
            observation.setActive(false);
            observation.setResolvedAt(now);
        }
        repository.save(observation);
    }


    private CatalogGapSummary toSummary(CatalogGapObservation observation) {
        return new CatalogGapSummary(
            observation.getIssueType(),
            observation.getDisplaySubject(),
            observation.getScientificName(),
            observation.getOccurrenceCount(),
            observation.getFirstSeenAt(),
            observation.getLastSeenAt()
        );
    }


    private Long currentOwnerId() {
        return authenticatedUserService.getAuthenticatedUser().getId();
    }


    private String key(String value) {
        final String normalized = PlantNameNormalizer.normalize(value);
        if (normalized.isBlank()) {
            return null;
        }
        return normalized.substring(0, Math.min(normalized.length(), MAXIMUM_SUBJECT_LENGTH));
    }


    private String display(String value) {
        if (value == null) {
            return "Unknown";
        }
        final String sanitized = value.replaceAll("\\p{Cntrl}", " ").trim().replaceAll("\\s+", " ");
        if (sanitized.isBlank()) {
            return "Unknown";
        }
        return sanitized.substring(0, Math.min(sanitized.length(), MAXIMUM_SUBJECT_LENGTH));
    }
}
