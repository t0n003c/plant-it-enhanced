package com.github.mdeluise.plantit;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.core.env.Environment;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("integration")
class ApplicationTest {
    @Autowired
    private Environment environment;

    @Test
    void contextLoads() {
    }

    @Test
    void cacheKeysAreScopedToTheApplicationVersion() {
        final String applicationVersion = environment.getProperty("app.version");
        Assertions.assertEquals(
            "plant-it:" + applicationVersion + ":",
            environment.getProperty("spring.cache.redis.key-prefix")
        );
    }
}
