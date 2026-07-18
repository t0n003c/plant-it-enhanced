package com.github.mdeluise.plantit.unit.component;

import com.github.mdeluise.plantit.security.ratelimit.ClientIpResolver;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;

@DisplayName("Unit tests for reverse-proxy-aware client address resolution")
class ClientIpResolverUnitTests {

    @Test
    @DisplayName("Should ignore forwarding headers from an untrusted caller")
    void shouldIgnoreUntrustedForwardingHeaders() {
        final ClientIpResolver resolver = resolver();
        final MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRemoteAddr("203.0.113.12");
        request.addHeader("CF-Connecting-IP", "198.51.100.25");
        request.addHeader("X-Forwarded-For", "198.51.100.30");

        Assertions.assertEquals("203.0.113.12", resolver.resolve(request));
    }


    @Test
    @DisplayName("Should prefer Cloudflare's client header when NPM is trusted")
    void shouldResolveCloudflareClientBehindTrustedProxy() {
        final ClientIpResolver resolver = resolver();
        final MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRemoteAddr("172.20.0.8");
        request.addHeader("CF-Connecting-IP", "198.51.100.25");
        request.addHeader("X-Forwarded-For", "198.51.100.25, 203.0.113.40");

        Assertions.assertEquals("198.51.100.25", resolver.resolve(request));
    }


    @Test
    @DisplayName("Should walk X-Forwarded-For from the trusted proxy side")
    void shouldIgnoreSpoofedLeftmostForwardedAddress() {
        final ClientIpResolver resolver = new ClientIpResolver("172.20.0.0/16", "X-Forwarded-For");
        final MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRemoteAddr("172.20.0.8");
        request.addHeader("X-Forwarded-For", "192.0.2.99, 198.51.100.25");

        Assertions.assertEquals("198.51.100.25", resolver.resolve(request));
    }


    private ClientIpResolver resolver() {
        return new ClientIpResolver("172.20.0.0/16", "CF-Connecting-IP,X-Forwarded-For");
    }
}
