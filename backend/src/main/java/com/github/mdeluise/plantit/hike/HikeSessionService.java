package com.github.mdeluise.plantit.hike;

import java.time.Instant;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

import com.github.mdeluise.plantit.authentication.User;
import com.github.mdeluise.plantit.common.AuthenticatedUserService;
import com.github.mdeluise.plantit.exception.ResourceNotFoundException;
import com.github.mdeluise.plantit.exception.UnauthorizedException;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class HikeSessionService {
    private final AuthenticatedUserService authenticatedUserService;
    private final HikeSessionRepository hikeSessionRepository;


    @Autowired
    public HikeSessionService(AuthenticatedUserService authenticatedUserService,
                              HikeSessionRepository hikeSessionRepository) {
        this.authenticatedUserService = authenticatedUserService;
        this.hikeSessionRepository = hikeSessionRepository;
    }


    public List<HikeSession> getAll() {
        return hikeSessionRepository.findAllByOwnerOrderByStartedAtDesc(
            authenticatedUserService.getAuthenticatedUser());
    }


    public Optional<HikeSession> getActive() {
        return hikeSessionRepository.findFirstByOwnerAndEndedAtIsNullOrderByStartedAtDesc(
            authenticatedUserService.getAuthenticatedUser());
    }


    public HikeSession get(Long id) {
        final HikeSession result = hikeSessionRepository.findById(id)
                                                        .orElseThrow(() -> new ResourceNotFoundException(id));
        ensureOwner(result, authenticatedUserService.getAuthenticatedUser());
        return result;
    }


    @Transactional
    public HikeSession save(HikeSession toSave) {
        final User authenticated = authenticatedUserService.getAuthenticatedUser();
        final String clientReference = normalize(toSave.getClientReference());
        if (clientReference != null) {
            final Optional<HikeSession> existing =
                hikeSessionRepository.findByOwnerAndClientReference(authenticated, clientReference);
            if (existing.isPresent()) {
                return existing.get();
            }
        }
        if (toSave.getOwner() != null && !sameUser(toSave.getOwner(), authenticated)) {
            throw new UnauthorizedException();
        }
        if (getActive().isPresent()) {
            throw new IllegalStateException("End the active hike before starting another one");
        }
        toSave.setOwner(authenticated);
        toSave.setName(requireName(toSave.getName()));
        toSave.setNotes(normalize(toSave.getNotes()));
        toSave.setClientReference(clientReference);
        toSave.setCreationDefaults();
        validateTimes(toSave);
        return hikeSessionRepository.save(toSave);
    }


    @Transactional
    public HikeSession update(Long id, HikeSession updated) {
        final HikeSession toUpdate = get(id);
        toUpdate.setName(requireName(updated.getName()));
        toUpdate.setStartedAt(updated.getStartedAt() == null ? toUpdate.getStartedAt() : updated.getStartedAt());
        toUpdate.setEndedAt(updated.getEndedAt());
        toUpdate.setNotes(normalize(updated.getNotes()));
        validateTimes(toUpdate);
        return hikeSessionRepository.save(toUpdate);
    }


    @Transactional
    public HikeSession end(Long id) {
        final HikeSession toUpdate = get(id);
        if (toUpdate.getEndedAt() == null) {
            toUpdate.setEndedAt(Instant.now());
        }
        return hikeSessionRepository.save(toUpdate);
    }


    @Transactional
    public void delete(Long id) {
        hikeSessionRepository.delete(get(id));
    }


    private void validateTimes(HikeSession session) {
        if (session.getEndedAt() != null && session.getEndedAt().isBefore(session.getStartedAt())) {
            throw new IllegalArgumentException("A hike cannot end before it starts");
        }
    }


    private String requireName(String value) {
        final String normalized = normalize(value);
        if (normalized == null) {
            throw new IllegalArgumentException("Hike name is required");
        }
        return normalized;
    }


    private String normalize(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        return value.trim();
    }


    private void ensureOwner(HikeSession session, User authenticatedUser) {
        if (!sameUser(session.getOwner(), authenticatedUser)) {
            throw new UnauthorizedException();
        }
    }


    private boolean sameUser(User left, User right) {
        return left == right || left != null && right != null && Objects.equals(left.getId(), right.getId());
    }
}
