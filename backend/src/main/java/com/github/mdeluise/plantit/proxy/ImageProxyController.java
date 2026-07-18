package com.github.mdeluise.plantit.proxy;

import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import java.util.Locale;

import io.swagger.v3.oas.annotations.Hidden;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/proxy")
@Tag(name = "Image proxy", description = "Proxy for displaying images")
@Hidden
public class ImageProxyController {
    private static final int CONNECTION_TIMEOUT_MILLISECONDS = 5_000;
    private static final int READ_TIMEOUT_MILLISECONDS = 8_000;
    private static final int MAX_IMAGE_BYTES = 10 * 1024 * 1024;
    private static final String USER_AGENT = "Plant-it image proxy/1.0";

    @GetMapping
    public void proxyImage(@RequestParam String url,
                           @RequestParam(required = false) String fallbackUrl,
                           HttpServletResponse response) throws IOException {
        final ProxiedImage image;
        try {
            image = loadAvailableImage(url, fallbackUrl);
        } catch (IOException imageFailure) {
            response.sendError(HttpStatus.BAD_GATEWAY.value(), "Failed to retrieve the image or its fallback.");
            return;
        }
        write(image, response);
    }


    private ProxiedImage loadAvailableImage(String url, String fallbackUrl) throws IOException {
        try {
            return loadImage(url);
        } catch (IOException | URISyntaxException | IllegalArgumentException primaryFailure) {
            if (fallbackUrl == null || fallbackUrl.isBlank()) {
                throw new IOException("Failed to retrieve the image", primaryFailure);
            }
            try {
                return loadImage(fallbackUrl);
            } catch (IOException | URISyntaxException | IllegalArgumentException fallbackFailure) {
                throw new IOException("Failed to retrieve the image fallback", fallbackFailure);
            }
        }
    }


    private ProxiedImage loadImage(String value) throws IOException, URISyntaxException {
        final URI uri = new URI(value);
        final String scheme = uri.getScheme() == null ? "" : uri.getScheme().toLowerCase(Locale.ROOT);
        if (!"http".equals(scheme) && !"https".equals(scheme)) {
            throw new IllegalArgumentException("Only HTTP image URLs are supported");
        }
        final URL imageUrl = uri.toURL();
        final HttpURLConnection connection = (HttpURLConnection) imageUrl.openConnection();
        connection.setRequestMethod("GET");
        connection.setRequestProperty("Accept", "image/*");
        connection.setRequestProperty("User-Agent", USER_AGENT);
        connection.setConnectTimeout(CONNECTION_TIMEOUT_MILLISECONDS);
        connection.setReadTimeout(READ_TIMEOUT_MILLISECONDS);
        connection.setInstanceFollowRedirects(true);
        try {
            final int statusCode = connection.getResponseCode();
            if (statusCode < HttpStatus.OK.value() || statusCode >= HttpStatus.MULTIPLE_CHOICES.value()) {
                throw new IOException("Image provider returned HTTP " + statusCode);
            }
            final String contentType = connection.getContentType();
            if (contentType == null || !contentType.toLowerCase(Locale.ROOT).startsWith("image/")) {
                throw new IOException("The provided URL does not point to an image");
            }
            try (InputStream inputStream = connection.getInputStream()) {
                final byte[] content = inputStream.readNBytes(MAX_IMAGE_BYTES + 1);
                if (content.length > MAX_IMAGE_BYTES) {
                    throw new IOException("The remote image exceeds the proxy size limit");
                }
                return new ProxiedImage(contentType, content);
            }
        } finally {
            connection.disconnect();
        }
    }


    private void write(ProxiedImage image, HttpServletResponse response) throws IOException {
        response.setContentType(image.contentType());
        response.setContentLength(image.content().length);
        response.setHeader("Cache-Control", "private, max-age=3600");
        response.getOutputStream().write(image.content());
    }


    private record ProxiedImage(String contentType, byte[] content) {
    }
}
