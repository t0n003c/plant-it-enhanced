package com.github.mdeluise.plantit.catalog;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CatalogGapObservationRepository extends JpaRepository<CatalogGapObservation, Long> {
    Optional<CatalogGapObservation> findByOwnerIdAndIssueTypeAndSubjectKey(
        Long ownerId, CatalogGapType issueType, String subjectKey);

    List<CatalogGapObservation> findTop20ByOwnerIdAndActiveTrueOrderByLastSeenAtDesc(Long ownerId);

    long countByOwnerIdAndActiveTrue(Long ownerId);

    long countByOwnerIdAndIssueTypeAndActiveTrue(Long ownerId, CatalogGapType issueType);
}
