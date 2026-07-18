package com.github.mdeluise.plantit.unit.controller;

import java.io.IOException;

import com.github.mdeluise.plantit.proxy.RemoteImagePolicy;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("Unit tests for outbound image URL restrictions")
class RemoteImagePolicyUnitTests {

    @Test
    @DisplayName("Should accept an explicitly allowed image provider")
    void shouldAcceptAllowedProvider() throws IOException {
        final RemoteImagePolicy policy = new RemoteImagePolicy("static.inaturalist.org", "443", true);

        final String actual = policy.validate("https://static.inaturalist.org/photos/123/medium.jpg").toString();

        Assertions.assertEquals("https://static.inaturalist.org/photos/123/medium.jpg", actual);
    }


    @Test
    @DisplayName("Should reject a host that only ends with the allowed host text")
    void shouldRejectSuffixConfusion() {
        final RemoteImagePolicy policy = new RemoteImagePolicy("static.inaturalist.org", "443", false);

        Assertions.assertThrows(IOException.class,
            () -> policy.validate("https://static.inaturalist.org.attacker.test/image.jpg"));
    }


    @Test
    @DisplayName("Should reject local network destinations by default")
    void shouldRejectPrivateDestination() {
        final RemoteImagePolicy policy = new RemoteImagePolicy("127.0.0.1,localhost", "80", false);

        Assertions.assertThrows(IOException.class, () -> policy.validate("http://127.0.0.1/private.jpg"));
    }


    @Test
    @DisplayName("Should reject user information and nonstandard ports")
    void shouldRejectAmbiguousAuthority() {
        final RemoteImagePolicy policy = new RemoteImagePolicy("static.inaturalist.org", "443", false);

        Assertions.assertThrows(IOException.class,
            () -> policy.validate("https://user@static.inaturalist.org/photos/123.jpg"));
        Assertions.assertThrows(IOException.class,
            () -> policy.validate("https://static.inaturalist.org:8443/photos/123.jpg"));
    }
}
