package com.github.mdeluise.plantit.proxy;

import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URI;
import java.util.Locale;
import java.util.Set;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

/**
 * Downloads a bounded raster image after every destination has passed the outbound URL policy.
 */
@Component
public class RemoteImageFetcher {
    private static final int CONNECTION_TIMEOUT_MILLISECONDS = 5_000;
    private static final int READ_TIMEOUT_MILLISECONDS = 8_000;
    private static final int MAX_IMAGE_BYTES = 10 * 1024 * 1024;
    private static final int MAX_REDIRECTS = 3;
    private static final String USER_AGENT = "Plant-it image fetcher/1.0";
    private static final Set<String> ALLOWED_CONTENT_TYPES = Set.of(
        "image/avif", "image/gif", "image/jpeg", "image/png", "image/webp"
    );
    private static final Set<Integer> REDIRECT_STATUS_CODES = Set.of(
        HttpURLConnection.HTTP_MOVED_PERM,
        HttpURLConnection.HTTP_MOVED_TEMP,
        HttpURLConnection.HTTP_SEE_OTHER,
        307,
        308
    );
    private final RemoteImagePolicy remoteImagePolicy;


    public RemoteImageFetcher(RemoteImagePolicy remoteImagePolicy) {
        this.remoteImagePolicy = remoteImagePolicy;
    }


    public URI validate(String value) throws IOException {
        return remoteImagePolicy.validate(value);
    }


    public RemoteImageContent fetch(String value) throws IOException {
        URI currentUri = validate(value);
        for (int redirectCount = 0; redirectCount <= MAX_REDIRECTS; redirectCount++) {
            final HttpURLConnection connection = openConnection(currentUri);
            try {
                final int statusCode = connection.getResponseCode();
                if (isRedirect(statusCode)) {
                    if (redirectCount == MAX_REDIRECTS) {
                        throw new IOException("Remote image exceeded the redirect limit");
                    }
                    final String location = connection.getHeaderField("Location");
                    if (location == null || location.isBlank()) {
                        throw new IOException("Remote image redirect did not include a destination");
                    }
                    currentUri = remoteImagePolicy.validate(currentUri.resolve(location));
                    continue;
                }
                return readImage(connection, statusCode);
            } finally {
                connection.disconnect();
            }
        }
        throw new IOException("Remote image exceeded the redirect limit");
    }


    private HttpURLConnection openConnection(URI uri) throws IOException {
        final HttpURLConnection connection = (HttpURLConnection) uri.toURL().openConnection();
        connection.setRequestMethod("GET");
        connection.setRequestProperty("Accept", "image/*");
        connection.setRequestProperty("User-Agent", USER_AGENT);
        connection.setConnectTimeout(CONNECTION_TIMEOUT_MILLISECONDS);
        connection.setReadTimeout(READ_TIMEOUT_MILLISECONDS);
        connection.setInstanceFollowRedirects(false);
        return connection;
    }


    private RemoteImageContent readImage(HttpURLConnection connection, int statusCode) throws IOException {
        if (statusCode < HttpStatus.OK.value() || statusCode >= HttpStatus.MULTIPLE_CHOICES.value()) {
            throw new IOException("Image provider returned HTTP " + statusCode);
        }
        final String contentType = normalizedContentType(connection.getContentType());
        if (!ALLOWED_CONTENT_TYPES.contains(contentType)) {
            throw new IOException("The provided URL does not point to a supported raster image");
        }
        final long declaredLength = connection.getContentLengthLong();
        if (declaredLength > MAX_IMAGE_BYTES) {
            throw new IOException("The remote image exceeds the proxy size limit");
        }
        try (InputStream inputStream = connection.getInputStream()) {
            final byte[] content = inputStream.readNBytes(MAX_IMAGE_BYTES + 1);
            if (content.length > MAX_IMAGE_BYTES) {
                throw new IOException("The remote image exceeds the proxy size limit");
            }
            return new RemoteImageContent(contentType, content);
        }
    }


    private static boolean isRedirect(int statusCode) {
        return REDIRECT_STATUS_CODES.contains(statusCode);
    }


    private static String normalizedContentType(String contentType) {
        if (contentType == null) {
            return "";
        }
        return contentType.split(";", 2)[0].trim().toLowerCase(Locale.ROOT);
    }
}
