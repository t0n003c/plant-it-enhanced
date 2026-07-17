package com.github.mdeluise.plantit.unit.component;

import com.github.mdeluise.plantit.plantinfo.config.INaturalistProperties;
import com.github.mdeluise.plantit.plantinfo.inaturalist.INaturalistRequestThrottle;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

@DisplayName("Unit tests for outbound iNaturalist request throttling")
class INaturalistRequestThrottleUnitTests {

    @Test
    @DisplayName("Should allow a small interactive burst and reject excess requests")
    void shouldLimitBurstRequests() {
        final INaturalistProperties properties = Mockito.mock(INaturalistProperties.class);
        Mockito.when(properties.getRequestsPerSecond()).thenReturn(1);
        Mockito.when(properties.getRequestBurst()).thenReturn(2);
        final INaturalistRequestThrottle throttle = new INaturalistRequestThrottle(properties);

        Assertions.assertTrue(throttle.tryAcquire());
        Assertions.assertTrue(throttle.tryAcquire());
        Assertions.assertFalse(throttle.tryAcquire());
    }
}
