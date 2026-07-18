package com.github.mdeluise.plantit.image;

import java.util.List;
import java.util.Optional;

import com.github.mdeluise.plantit.authentication.User;
import com.github.mdeluise.plantit.observation.Observation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ObservationImageRepository extends JpaRepository<ObservationImage, String> {
    @Query("SELECT i.id FROM ObservationImage i WHERE i.target = ?1 ORDER BY i.createOn DESC")
    List<String> findAllIdsByObservationOrderBySavedAtDesc(Observation target);

    Integer countByTargetOwner(User user);

    Optional<ObservationImage> findByTargetAndClientReference(Observation target, String clientReference);
}
