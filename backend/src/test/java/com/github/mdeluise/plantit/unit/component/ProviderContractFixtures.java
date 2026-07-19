package com.github.mdeluise.plantit.unit.component;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;

final class ProviderContractFixtures {
    private ProviderContractFixtures() {
    }


    static String load(String name) {
        final String path = "/provider-contracts/" + name;
        try (InputStream input = ProviderContractFixtures.class.getResourceAsStream(path)) {
            if (input == null) {
                throw new IllegalStateException("Missing provider contract fixture " + path);
            }
            return new String(input.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException exception) {
            throw new UncheckedIOException("Unable to read provider contract fixture " + path, exception);
        }
    }
}
