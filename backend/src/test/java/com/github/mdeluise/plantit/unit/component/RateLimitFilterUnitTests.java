package com.github.mdeluise.plantit.unit.component;

import java.io.IOException;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.mdeluise.plantit.security.ratelimit.ClientIpResolver;
import com.github.mdeluise.plantit.security.ratelimit.RateLimitFilter;
import jakarta.servlet.ServletException;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

@DisplayName("Unit tests for bounded per-client rate limiting")
class RateLimitFilterUnitTests {

    @Test
    @DisplayName("Should return 429 with retry information when the client limit is exhausted")
    void shouldReturnTooManyRequests() throws ServletException, IOException {
        final RateLimitFilter filter = new RateLimitFilter(
            1,
            10,
            600,
            new ObjectMapper(),
            new ClientIpResolver("", "X-Forwarded-For")
        );
        final MockHttpServletRequest firstRequest = request();
        final MockHttpServletResponse firstResponse = new MockHttpServletResponse();
        filter.doFilter(firstRequest, firstResponse, new MockFilterChain());

        final MockHttpServletResponse secondResponse = new MockHttpServletResponse();
        filter.doFilter(request(), secondResponse, new MockFilterChain());

        Assertions.assertEquals(200, firstResponse.getStatus());
        Assertions.assertEquals(429, secondResponse.getStatus());
        Assertions.assertEquals("0", secondResponse.getHeader("RateLimit-Remaining"));
        Assertions.assertNotNull(secondResponse.getHeader("Retry-After"));
        Assertions.assertTrue(secondResponse.getContentAsString().contains("TOO_MANY_REQUESTS"));
    }


    private MockHttpServletRequest request() {
        final MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/info/ping");
        request.setRemoteAddr("198.51.100.25");
        request.addHeader("X-Forwarded-For", "192.0.2.99");
        return request;
    }
}
