package com.github.mdeluise.plantit.security.ratelimit;

import java.net.Inet6Address;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.web.util.matcher.IpAddressMatcher;
import org.springframework.stereotype.Component;

/**
 * Resolves a client address without trusting forwarding headers from arbitrary callers.
 */
@Component
public class ClientIpResolver {
    private static final String X_FORWARDED_FOR = "x-forwarded-for";
    private static final String INTERNAL_PROXY_SOURCE = "X-Plantit-Proxy-Source";
    private final List<IpAddressMatcher> trustedProxies;
    private final List<String> trustedHeaders;


    public ClientIpResolver(@Value("${server.proxy.trusted-proxies:}") String trustedProxyCidrs,
                            @Value("${server.proxy.client-ip-headers:X-Forwarded-For}") String clientIpHeaders) {
        this.trustedProxies = csvValues(trustedProxyCidrs).stream()
                                                            .map(IpAddressMatcher::new)
                                                            .toList();
        this.trustedHeaders = csvValues(clientIpHeaders).stream()
                                                       .filter(ClientIpResolver::isSafeHeaderName)
                                                       .toList();
    }


    public String resolve(HttpServletRequest request) {
        final String remoteAddress = normalizeIpLiteral(request.getRemoteAddr())
            .orElse(request.getRemoteAddr());
        final String proxyAddress = resolveImmediateProxyAddress(request, remoteAddress);
        if (!isTrustedProxy(proxyAddress)) {
            return proxyAddress;
        }

        for (String headerName : trustedHeaders) {
            final String headerValue = request.getHeader(headerName);
            if (headerValue == null || headerValue.isBlank()) {
                continue;
            }
            final Optional<String> resolved = X_FORWARDED_FOR.equals(headerName.toLowerCase(Locale.ROOT))
                ? resolveForwardedFor(headerValue)
                : firstValidAddress(headerValue);
            if (resolved.isPresent()) {
                return resolved.get();
            }
        }
        return proxyAddress;
    }


    private String resolveImmediateProxyAddress(HttpServletRequest request, String remoteAddress) {
        if (!isLoopbackAddress(remoteAddress)) {
            return remoteAddress;
        }
        return normalizeIpLiteral(request.getHeader(INTERNAL_PROXY_SOURCE)).orElse(remoteAddress);
    }


    private Optional<String> resolveForwardedFor(String headerValue) {
        final List<String> addresses = Arrays.stream(headerValue.split(","))
                                             .map(String::trim)
                                             .map(ClientIpResolver::normalizeIpLiteral)
                                             .flatMap(Optional::stream)
                                             .toList();
        for (int index = addresses.size() - 1; index >= 0; index--) {
            final String address = addresses.get(index);
            if (!isTrustedProxy(address)) {
                return Optional.of(address);
            }
        }
        return Optional.empty();
    }


    private Optional<String> firstValidAddress(String headerValue) {
        return Arrays.stream(headerValue.split(","))
                     .map(String::trim)
                     .map(ClientIpResolver::normalizeIpLiteral)
                     .flatMap(Optional::stream)
                     .findFirst();
    }


    private boolean isTrustedProxy(String address) {
        return trustedProxies.stream().anyMatch(matcher -> matcher.matches(address));
    }


    private static boolean isLoopbackAddress(String address) {
        try {
            return InetAddress.getByName(address).isLoopbackAddress();
        } catch (UnknownHostException invalidAddress) {
            return false;
        }
    }


    private static List<String> csvValues(String value) {
        if (value == null || value.isBlank()) {
            return List.of();
        }
        return Arrays.stream(value.split(","))
                     .map(String::trim)
                     .filter(item -> !item.isEmpty())
                     .toList();
    }


    private static boolean isSafeHeaderName(String value) {
        return value.matches("[A-Za-z0-9-]+");
    }


    @SuppressWarnings("ReturnCount")
    private static Optional<String> normalizeIpLiteral(String value) {
        if (value == null || value.isBlank()) {
            return Optional.empty();
        }
        String candidate = value.trim();
        if (candidate.startsWith("[") && candidate.endsWith("]")) {
            candidate = candidate.substring(1, candidate.length() - 1);
        }
        final int zoneSeparator = candidate.indexOf('%');
        if (zoneSeparator >= 0) {
            candidate = candidate.substring(0, zoneSeparator);
        }
        try {
            if (candidate.contains(":")) {
                final InetAddress parsed = InetAddress.getByName(candidate);
                if (!(parsed instanceof Inet6Address)) {
                    return Optional.empty();
                }
                return Optional.of(parsed.getHostAddress());
            }
            final String[] octets = candidate.split("\\.", -1);
            if (octets.length != 4) {
                return Optional.empty();
            }
            final byte[] bytes = new byte[4];
            for (int index = 0; index < octets.length; index++) {
                if (!octets[index].matches("[0-9]{1,3}")) {
                    return Optional.empty();
                }
                final int octet = Integer.parseInt(octets[index]);
                if (octet > 255) {
                    return Optional.empty();
                }
                bytes[index] = (byte) octet;
            }
            return Optional.of(InetAddress.getByAddress(bytes).getHostAddress());
        } catch (UnknownHostException | NumberFormatException invalidAddress) {
            return Optional.empty();
        }
    }
}
