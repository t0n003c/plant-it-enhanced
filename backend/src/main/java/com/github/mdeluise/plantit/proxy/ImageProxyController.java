package com.github.mdeluise.plantit.proxy;

import java.io.IOException;

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
    private final RemoteImageFetcher remoteImageFetcher;


    public ImageProxyController(RemoteImageFetcher remoteImageFetcher) {
        this.remoteImageFetcher = remoteImageFetcher;
    }

    @GetMapping
    public void proxyImage(@RequestParam String url,
                           @RequestParam(required = false) String fallbackUrl,
                           HttpServletResponse response) throws IOException {
        final RemoteImageContent image;
        try {
            image = loadAvailableImage(url, fallbackUrl);
        } catch (IOException imageFailure) {
            response.sendError(HttpStatus.BAD_GATEWAY.value(), "Failed to retrieve the image or its fallback.");
            return;
        }
        write(image, response);
    }


    private RemoteImageContent loadAvailableImage(String url, String fallbackUrl) throws IOException {
        try {
            return remoteImageFetcher.fetch(url);
        } catch (IOException | IllegalArgumentException primaryFailure) {
            if (fallbackUrl == null || fallbackUrl.isBlank()) {
                throw new IOException("Failed to retrieve the image", primaryFailure);
            }
            try {
                return remoteImageFetcher.fetch(fallbackUrl);
            } catch (IOException | IllegalArgumentException fallbackFailure) {
                throw new IOException("Failed to retrieve the image fallback", fallbackFailure);
            }
        }
    }


    private void write(RemoteImageContent image, HttpServletResponse response) throws IOException {
        response.setContentType(image.contentType());
        response.setContentLength(image.content().length);
        response.setHeader("Cache-Control", "private, max-age=3600");
        response.setHeader("X-Content-Type-Options", "nosniff");
        response.setHeader("Content-Security-Policy", "default-src 'none'; sandbox");
        response.getOutputStream().write(image.content());
    }
}
