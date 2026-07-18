package com.github.mdeluise.plantit.systeminfo;

import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Component;

@Component
public class ProviderStatusRegistry {
    private final Map<String, ProviderStatus> statuses = new ConcurrentHashMap<>();


    public void recordSuccess(String provider, int httpStatus, String quotaRemaining) {
        final ProviderStatus previous = statuses.get(provider);
        statuses.put(provider, new ProviderStatus(
            Instant.now(), Instant.now(), previous == null ? null : previous.lastFailureAt(),
            httpStatus, null, quotaRemaining
        ));
    }


    public void recordFailure(String provider, int httpStatus, String message, String quotaRemaining) {
        final ProviderStatus previous = statuses.get(provider);
        statuses.put(provider, new ProviderStatus(
            Instant.now(), previous == null ? null : previous.lastSuccessAt(), Instant.now(),
            httpStatus, message, quotaRemaining
        ));
    }


    public ProviderStatus get(String provider) {
        return statuses.get(provider);
    }


    public record ProviderStatus(Instant lastAttemptAt, Instant lastSuccessAt, Instant lastFailureAt,
                                 Integer lastHttpStatus, String lastError, String quotaRemaining) {
    }
}
