package com.github.mdeluise.plantit.observation;

import java.util.Optional;

import com.github.mdeluise.plantit.authentication.User;
import com.github.mdeluise.plantit.hike.HikeSession;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ObservationRepository extends JpaRepository<Observation, Long> {
    Page<Observation> findAllByOwner(User owner, Pageable pageable);

    long countByOwner(User owner);

    long countByHikeSession(HikeSession hikeSession);

    Optional<Observation> findByOwnerAndClientReference(User owner, String clientReference);
}
