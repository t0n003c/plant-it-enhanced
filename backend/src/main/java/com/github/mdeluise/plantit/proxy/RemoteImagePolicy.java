package com.github.mdeluise.plantit.proxy;

import java.io.IOException;
import java.net.IDN;
import java.net.InetAddress;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.UnknownHostException;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Restricts the authenticated image proxy to known remote image providers.
 */
@Component
public class RemoteImagePolicy {
    private final List<String> allowedHostPatterns;
    private final Set<Integer> allowedPorts;
    private final boolean allowPrivateAddresses;


    public RemoteImagePolicy(@Value("${image.proxy.allowed-hosts}") String allowedHosts,
                             @Value("${image.proxy.allowed-ports:80,443}") String allowedPorts,
                             @Value("${image.proxy.allow-private-addresses:false}") boolean allowPrivateAddresses) {
        this.allowedHostPatterns = csvValues(allowedHosts).stream()
                                                           .map(RemoteImagePolicy::normalizeHostPattern)
                                                           .toList();
        this.allowedPorts = csvValues(allowedPorts).stream()
                                                       .map(Integer::parseInt)
                                                       .collect(Collectors.toUnmodifiableSet());
        this.allowPrivateAddresses = allowPrivateAddresses;
    }


    public URI validate(String value) throws IOException {
        try {
            return validate(new URI(value));
        } catch (URISyntaxException | IllegalArgumentException invalidUri) {
            throw new IOException("Invalid remote image URL", invalidUri);
        }
    }


    public URI validate(URI uri) throws IOException {
        final String scheme = uri.getScheme() == null ? "" : uri.getScheme().toLowerCase(Locale.ROOT);
        if (!"http".equals(scheme) && !"https".equals(scheme)) {
            throw new IOException("Only HTTP image URLs are supported");
        }
        if (uri.getRawUserInfo() != null) {
            throw new IOException("Remote image URLs cannot contain user information");
        }
        final String host = normalizeHost(uri.getHost());
        if (host.isEmpty() || !isAllowedHost(host)) {
            throw new IOException("Remote image host is not allowed");
        }
        final int port = uri.getPort() >= 0 ? uri.getPort() : defaultPort(scheme);
        if (!allowedPorts.contains(port)) {
            throw new IOException("Remote image port is not allowed");
        }
        if (!allowPrivateAddresses) {
            validatePublicAddresses(host);
        }
        return uri.normalize();
    }


    private boolean isAllowedHost(String host) {
        return allowedHostPatterns.stream().anyMatch(pattern -> matches(pattern, host));
    }


    private static boolean matches(String pattern, String host) {
        if (pattern.startsWith("*.")) {
            final String suffix = pattern.substring(1);
            return host.endsWith(suffix) && host.length() > suffix.length();
        }
        return pattern.equals(host);
    }


    private static int defaultPort(String scheme) {
        return "https".equals(scheme) ? 443 : 80;
    }


    private static void validatePublicAddresses(String host) throws IOException {
        final InetAddress[] addresses;
        try {
            addresses = InetAddress.getAllByName(host);
        } catch (UnknownHostException resolutionFailure) {
            throw new IOException("Remote image host could not be resolved", resolutionFailure);
        }
        if (addresses.length == 0 || Arrays.stream(addresses).anyMatch(RemoteImagePolicy::isNonPublicAddress)) {
            throw new IOException("Remote image host resolves to a non-public address");
        }
    }


    @SuppressWarnings("BooleanExpressionComplexity")
    private static boolean isNonPublicAddress(InetAddress address) {
        if (address.isAnyLocalAddress() || address.isLoopbackAddress() || address.isLinkLocalAddress()
            || address.isSiteLocalAddress() || address.isMulticastAddress()) {
            return true;
        }
        final byte[] bytes = address.getAddress();
        if (bytes.length == 4) {
            final int first = Byte.toUnsignedInt(bytes[0]);
            final int second = Byte.toUnsignedInt(bytes[1]);
            return first == 0 || first >= 224 || first == 127 || first == 10
                || first == 100 && second >= 64 && second <= 127
                || first == 169 && second == 254
                || first == 172 && second >= 16 && second <= 31
                || first == 192 && (second == 0 || second == 168)
                || first == 198 && (second == 18 || second == 19);
        }
        final int first = Byte.toUnsignedInt(bytes[0]);
        final int second = Byte.toUnsignedInt(bytes[1]);
        return (first & 0xfe) == 0xfc
            || first == 0xfe && (second & 0xc0) == 0x80
            || first == 0x20 && second == 0x01 && Byte.toUnsignedInt(bytes[2]) == 0x0d
            && Byte.toUnsignedInt(bytes[3]) == 0xb8;
    }


    private static String normalizeHostPattern(String value) {
        final String cleaned = value.trim().toLowerCase(Locale.ROOT);
        if (cleaned.startsWith("*.")) {
            return "*." + normalizeHost(cleaned.substring(2));
        }
        return normalizeHost(cleaned);
    }


    private static String normalizeHost(String value) {
        if (value == null || value.isBlank()) {
            return "";
        }
        return IDN.toASCII(value.trim().toLowerCase(Locale.ROOT));
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
}
