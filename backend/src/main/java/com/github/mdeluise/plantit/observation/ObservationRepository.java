package com.github.mdeluise.plantit.observation;

import com.github.mdeluise.plantit.authentication.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ObservationRepository extends JpaRepository<Observation, Long> {
    Page<Observation> findAllByOwner(User owner, Pageable pageable);

    long countByOwner(User owner);
}
