package com.github.mdeluise.plantit.hike;

import java.util.List;
import java.util.Optional;

import com.github.mdeluise.plantit.authentication.User;
import org.springframework.data.jpa.repository.JpaRepository;

public interface HikeSessionRepository extends JpaRepository<HikeSession, Long> {
    List<HikeSession> findAllByOwnerOrderByStartedAtDesc(User owner);

    Optional<HikeSession> findFirstByOwnerAndEndedAtIsNullOrderByStartedAtDesc(User owner);

    Optional<HikeSession> findByOwnerAndClientReference(User owner, String clientReference);
}
