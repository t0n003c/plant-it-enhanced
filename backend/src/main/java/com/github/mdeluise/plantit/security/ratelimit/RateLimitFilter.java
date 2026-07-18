package com.github.mdeluise.plantit.security.ratelimit;

import java.io.IOException;
import java.time.Duration;
import java.util.Comparator;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.mdeluise.plantit.exception.error.ErrorCode;
import com.github.mdeluise.plantit.exception.error.ErrorMessage;
import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import io.github.bucket4j.ConsumptionProbe;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class RateLimitFilter extends OncePerRequestFilter {
    private final int perMinute;
    private final ObjectMapper objectMapper;
    private final ClientIpResolver clientIpResolver;
    private final int maximumClients;
    private final long idleTtlNanos;
    private final Map<String, BucketEntry> buckets = new ConcurrentHashMap<>();
    private final AtomicLong requests = new AtomicLong();


    public RateLimitFilter(@Value("${server.rateLimit.requestPerMinute}") int perMinute,
                           @Value("${server.rateLimit.maximumClients:10000}") int maximumClients,
                           @Value("${server.rateLimit.clientIdleTtlSeconds:600}") long clientIdleTtlSeconds,
                           ObjectMapper objectMapper,
                           ClientIpResolver clientIpResolver) {
        this.perMinute = perMinute;
        this.maximumClients = Math.max(1, maximumClients);
        this.idleTtlNanos = Duration.ofSeconds(Math.max(1, clientIdleTtlSeconds)).toNanos();
        this.objectMapper = objectMapper;
        this.clientIpResolver = clientIpResolver;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
        throws ServletException, IOException {
        final String clientIP = clientIpResolver.resolve(request);
        final Bucket bucket = getBucket(clientIP);

        final ConsumptionProbe consumptionProbe = bucket.tryConsumeAndReturnRemaining(1);
        if (!consumptionProbe.isConsumed()) {
            sendError(response, consumptionProbe);
            return;
        }
        response.setHeader("RateLimit-Limit", Integer.toString(perMinute));
        response.setHeader("RateLimit-Remaining", Long.toString(consumptionProbe.getRemainingTokens()));
        response.setHeader("X-Rate-Limit-Remaining", Long.toString(consumptionProbe.getRemainingTokens()));
        filterChain.doFilter(request, response);
    }


    private Bucket getBucket(String clientIP) {
        final long now = System.nanoTime();
        final BucketEntry existing = buckets.get(clientIP);
        if (existing != null) {
            existing.touch(now);
            periodicCleanup(now);
            return existing.bucket();
        }
        synchronized (buckets) {
            final BucketEntry concurrentEntry = buckets.get(clientIP);
            if (concurrentEntry != null) {
                concurrentEntry.touch(now);
                return concurrentEntry.bucket();
            }
            removeExpired(now);
            if (buckets.size() >= maximumClients) {
                removeLeastRecentlyUsed();
            }
            final BucketEntry created = new BucketEntry(createBucket(), now);
            buckets.put(clientIP, created);
            return created.bucket();
        }
    }


    private Bucket createBucket() {
        final Bandwidth limit = Bandwidth.builder()
                                         .capacity(perMinute)
                                         .refillIntervally(perMinute, Duration.ofMinutes(1))
                                         .build();
        return Bucket.builder().addLimit(limit).build();
    }


    private void periodicCleanup(long now) {
        if ((requests.incrementAndGet() & 255) == 0) {
            removeExpired(now);
        }
    }


    private void removeExpired(long now) {
        buckets.entrySet().removeIf(entry -> now - entry.getValue().lastAccessNanos() > idleTtlNanos);
    }


    private void removeLeastRecentlyUsed() {
        buckets.entrySet()
               .stream()
               .min(Comparator.comparingLong(entry -> entry.getValue().lastAccessNanos()))
               .map(Map.Entry::getKey)
               .ifPresent(buckets::remove);
    }


    private void sendError(HttpServletResponse response, ConsumptionProbe consumptionProbe) throws IOException {
        final ErrorMessage error = new ErrorMessage(
            HttpStatus.TOO_MANY_REQUESTS.value(),
            ErrorCode.TOO_MANY_REQUESTS,
            "Request rate limit exceeded"
        );
        response.setContentType("application/json");
        response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
        response.setHeader("RateLimit-Limit", Integer.toString(perMinute));
        response.setHeader("RateLimit-Remaining", "0");
        final long retryAfterSeconds = Math.max(1L,
            Duration.ofNanos(consumptionProbe.getNanosToWaitForRefill()).toSeconds());
        response.setHeader("Retry-After", Long.toString(retryAfterSeconds));
        response.getWriter().write(objectMapper.writeValueAsString(error));
    }


    private static final class BucketEntry {
        private final Bucket bucket;
        private volatile long lastAccessNanos;


        private BucketEntry(Bucket bucket, long lastAccessNanos) {
            this.bucket = bucket;
            this.lastAccessNanos = lastAccessNanos;
        }


        private Bucket bucket() {
            return bucket;
        }


        private long lastAccessNanos() {
            return lastAccessNanos;
        }


        private void touch(long now) {
            this.lastAccessNanos = now;
        }
    }
}
