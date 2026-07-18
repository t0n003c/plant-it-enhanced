package com.github.mdeluise.plantit.systeminfo;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

import com.github.mdeluise.plantit.systeminfo.ProviderStatusRegistry.ProviderStatus;
import com.github.mdeluise.plantit.systeminfo.SystemDiagnostics.ComponentStatus;
import com.github.mdeluise.plantit.systeminfo.SystemDiagnostics.ProviderDiagnostic;
import org.springframework.data.redis.connection.RedisConnection;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.core.env.Environment;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
public class SystemDiagnosticsService {
    private final JdbcTemplate jdbcTemplate;
    private final StringRedisTemplate redisTemplate;
    private final ProviderStatusRegistry providerStatusRegistry;
    private final Environment environment;


    public SystemDiagnosticsService(JdbcTemplate jdbcTemplate, StringRedisTemplate redisTemplate,
                                    ProviderStatusRegistry providerStatusRegistry,
                                    Environment environment) {
        this.jdbcTemplate = jdbcTemplate;
        this.redisTemplate = redisTemplate;
        this.providerStatusRegistry = providerStatusRegistry;
        this.environment = environment;
    }


    public SystemDiagnostics get() {
        final Map<String, ProviderDiagnostic> providers = new LinkedHashMap<>();
        providers.put("PLANTNET", provider("PLANTNET", hasValue("plantnet.api-key")));
        providers.put("TREFLE", provider("TREFLE", hasValue("trefle.token")));
        providers.put("PERENUAL", provider("PERENUAL", hasValue("perenual.api-key")));
        providers.put("INATURALIST", provider("INATURALIST", isEnabled("inaturalist.enabled")));
        providers.put("GBIF", provider("GBIF", true));
        final String publicOutboundIp = environment.getProperty("diagnostics.public-outbound-ip");
        return new SystemDiagnostics(
            environment.getProperty("app.version", "unknown"), Instant.now(),
            databaseStatus(), cacheStatus(), providers,
            publicOutboundIp == null || publicOutboundIp.isBlank() ? null : publicOutboundIp.trim()
        );
    }


    private ComponentStatus databaseStatus() {
        try {
            final Integer result = jdbcTemplate.queryForObject("SELECT 1", Integer.class);
            return new ComponentStatus(Integer.valueOf(1).equals(result), "MySQL query succeeded");
        } catch (DataAccessException exception) {
            return new ComponentStatus(false, safeMessage(exception));
        }
    }


    private ComponentStatus cacheStatus() {
        try (RedisConnection connection = redisTemplate.getConnectionFactory().getConnection()) {
            final String response = connection.ping();
            return new ComponentStatus("PONG".equalsIgnoreCase(response), "Redis " + response);
        } catch (DataAccessException exception) {
            return new ComponentStatus(false, safeMessage(exception));
        }
    }


    private ProviderDiagnostic provider(String name, boolean configured) {
        final ProviderStatus status = providerStatusRegistry.get(name);
        if (status == null) {
            return new ProviderDiagnostic(configured, null, null, null, null, null, null);
        }
        return new ProviderDiagnostic(
            configured, status.lastAttemptAt(), status.lastSuccessAt(), status.lastFailureAt(),
            status.lastHttpStatus(), status.lastError(), status.quotaRemaining()
        );
    }


    private boolean hasValue(String property) {
        final String value = environment.getProperty(property);
        return value != null && !value.isBlank();
    }


    private boolean isEnabled(String property) {
        return Boolean.parseBoolean(environment.getProperty(property, "false"));
    }


    private String safeMessage(RuntimeException exception) {
        final String message = exception.getMessage();
        return message == null || message.isBlank() ? exception.getClass().getSimpleName() : message;
    }
}
