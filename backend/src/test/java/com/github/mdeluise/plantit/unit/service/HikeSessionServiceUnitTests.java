package com.github.mdeluise.plantit.unit.service;

import java.time.Instant;
import java.util.Optional;

import com.github.mdeluise.plantit.authentication.User;
import com.github.mdeluise.plantit.common.AuthenticatedUserService;
import com.github.mdeluise.plantit.exception.UnauthorizedException;
import com.github.mdeluise.plantit.hike.HikeSession;
import com.github.mdeluise.plantit.hike.HikeSessionRepository;
import com.github.mdeluise.plantit.hike.HikeSessionService;
import org.assertj.core.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.springframework.test.context.junit.jupiter.SpringExtension;

@ExtendWith(SpringExtension.class)
@DisplayName("Unit tests for HikeSessionService")
class HikeSessionServiceUnitTests {
    @Mock
    private AuthenticatedUserService authenticatedUserService;
    @Mock
    private HikeSessionRepository hikeSessionRepository;
    @InjectMocks
    private HikeSessionService hikeSessionService;


    @Test
    @DisplayName("Should create an owned active hike with normalized fields")
    void shouldCreateOwnedActiveHike() {
        final User authenticated = user(1L);
        final HikeSession session = new HikeSession();
        session.setName("  Waterfall Loop  ");
        session.setNotes("  Fern survey  ");
        session.setClientReference(" hike-local-1 ");
        Mockito.when(authenticatedUserService.getAuthenticatedUser()).thenReturn(authenticated);
        Mockito.when(hikeSessionRepository.findByOwnerAndClientReference(authenticated, "hike-local-1"))
               .thenReturn(Optional.empty());
        Mockito.when(hikeSessionRepository.findFirstByOwnerAndEndedAtIsNullOrderByStartedAtDesc(authenticated))
               .thenReturn(Optional.empty());
        Mockito.when(hikeSessionRepository.save(session)).thenReturn(session);

        final HikeSession result = hikeSessionService.save(session);

        Assertions.assertThat(result.getOwner()).isSameAs(authenticated);
        Assertions.assertThat(result.getName()).isEqualTo("Waterfall Loop");
        Assertions.assertThat(result.getNotes()).isEqualTo("Fern survey");
        Assertions.assertThat(result.getClientReference()).isEqualTo("hike-local-1");
        Assertions.assertThat(result.getStartedAt()).isNotNull();
        Mockito.verify(hikeSessionRepository).save(session);
    }


    @Test
    @DisplayName("Should make a repeated offline start idempotent")
    void shouldMakeRepeatedOfflineStartIdempotent() {
        final User authenticated = user(1L);
        final HikeSession existing = new HikeSession();
        existing.setId(8L);
        existing.setOwner(authenticated);
        final HikeSession repeated = new HikeSession();
        repeated.setName("Waterfall Loop");
        repeated.setClientReference("hike-local-1");
        Mockito.when(authenticatedUserService.getAuthenticatedUser()).thenReturn(authenticated);
        Mockito.when(hikeSessionRepository.findByOwnerAndClientReference(authenticated, "hike-local-1"))
               .thenReturn(Optional.of(existing));

        final HikeSession result = hikeSessionService.save(repeated);

        Assertions.assertThat(result).isSameAs(existing);
        Mockito.verify(hikeSessionRepository, Mockito.never()).save(Mockito.any());
    }


    @Test
    @DisplayName("Should reject a second active hike")
    void shouldRejectSecondActiveHike() {
        final User authenticated = user(1L);
        final HikeSession active = new HikeSession();
        active.setOwner(authenticated);
        final HikeSession requested = new HikeSession();
        requested.setName("Another trail");
        Mockito.when(authenticatedUserService.getAuthenticatedUser()).thenReturn(authenticated);
        Mockito.when(hikeSessionRepository.findFirstByOwnerAndEndedAtIsNullOrderByStartedAtDesc(authenticated))
               .thenReturn(Optional.of(active));

        Assertions.assertThatThrownBy(() -> hikeSessionService.save(requested))
                  .isInstanceOf(IllegalStateException.class)
                  .hasMessageContaining("active hike");
    }


    @Test
    @DisplayName("Should reject access to another user's hike")
    void shouldRejectAnotherUsersHike() {
        final HikeSession session = new HikeSession();
        session.setId(4L);
        session.setOwner(user(2L));
        Mockito.when(hikeSessionRepository.findById(4L)).thenReturn(Optional.of(session));
        Mockito.when(authenticatedUserService.getAuthenticatedUser()).thenReturn(user(1L));

        Assertions.assertThatThrownBy(() -> hikeSessionService.get(4L))
                  .isInstanceOf(UnauthorizedException.class);
    }


    @Test
    @DisplayName("Should reject a hike that ends before it starts")
    void shouldRejectInvalidTimes() {
        final User authenticated = user(1L);
        final HikeSession session = new HikeSession();
        session.setName("Time warp");
        session.setStartedAt(Instant.parse("2026-07-18T14:00:00Z"));
        session.setEndedAt(Instant.parse("2026-07-18T13:00:00Z"));
        Mockito.when(authenticatedUserService.getAuthenticatedUser()).thenReturn(authenticated);
        Mockito.when(hikeSessionRepository.findFirstByOwnerAndEndedAtIsNullOrderByStartedAtDesc(authenticated))
               .thenReturn(Optional.empty());

        Assertions.assertThatThrownBy(() -> hikeSessionService.save(session))
                  .isInstanceOf(IllegalArgumentException.class)
                  .hasMessageContaining("before it starts");
    }


    private User user(Long id) {
        final User result = new User();
        result.setId(id);
        return result;
    }
}
