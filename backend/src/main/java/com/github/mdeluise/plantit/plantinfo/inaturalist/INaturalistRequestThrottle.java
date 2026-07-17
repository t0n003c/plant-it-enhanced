package com.github.mdeluise.plantit.plantinfo.inaturalist;

import java.time.Duration;

import com.github.mdeluise.plantit.plantinfo.config.INaturalistProperties;
import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import org.springframework.stereotype.Component;

@Component
public class INaturalistRequestThrottle {
    private static final Duration REFILL_INTERVAL = Duration.ofSeconds(1);
    private final Bucket bucket;


    public INaturalistRequestThrottle(INaturalistProperties properties) {
        final long requestsPerSecond = Math.max(1, properties.getRequestsPerSecond());
        final long burst = Math.max(requestsPerSecond, properties.getRequestBurst());
        final Bandwidth limit = Bandwidth.builder()
                                         .capacity(burst)
                                         .refillGreedy(requestsPerSecond, REFILL_INTERVAL)
                                         .build();
        bucket = Bucket.builder().addLimit(limit).build();
    }


    public boolean tryAcquire() {
        return bucket.tryConsume(1);
    }
}
