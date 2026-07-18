package com.github.mdeluise.plantit.unit.service;

import com.github.mdeluise.plantit.systeminfo.BuildInfo;
import com.github.mdeluise.plantit.systeminfo.BuildInfoService;
import org.assertj.core.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("Unit tests for BuildInfoService")
class BuildInfoServiceUnitTests {

    @Test
    @DisplayName("Should expose the packaged version and revision")
    void shouldExposeVersionAndRevision() {
        final BuildInfo result = new BuildInfoService("0.16.0", "abc123").get();

        Assertions.assertThat(result.version()).isEqualTo("0.16.0");
        Assertions.assertThat(result.revision()).isEqualTo("abc123");
    }


    @Test
    @DisplayName("Should normalize missing build values")
    void shouldNormalizeMissingValues() {
        final BuildInfo result = new BuildInfoService(" ", null).get();

        Assertions.assertThat(result.version()).isEqualTo("unknown");
        Assertions.assertThat(result.revision()).isEqualTo("development");
    }
}
