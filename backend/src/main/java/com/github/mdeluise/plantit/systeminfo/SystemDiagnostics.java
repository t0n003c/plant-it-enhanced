package com.github.mdeluise.plantit.systeminfo;

import java.time.Instant;
import java.util.Map;

public record SystemDiagnostics(String version, Instant checkedAt, ComponentStatus database,
                                ComponentStatus cache, Map<String, ProviderDiagnostic> providers,
                                String publicOutboundIp) {

    public record ComponentStatus(boolean healthy, String detail) {
    }

    public record ProviderDiagnostic(boolean configured, Instant lastAttemptAt, Instant lastSuccessAt,
                                     Instant lastFailureAt, Integer lastHttpStatus, String lastError,
                                     String quotaRemaining) {
    }
}
