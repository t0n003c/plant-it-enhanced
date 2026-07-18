package com.github.mdeluise.plantit.unit.controller;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;

import com.github.mdeluise.plantit.proxy.ImageProxyController;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletResponse;

@DisplayName("Unit tests for resilient image proxying")
class ImageProxyControllerUnitTests {
    private static final byte[] IMAGE_CONTENT = "image-content".getBytes(StandardCharsets.UTF_8);
    private HttpServer server;
    private String serverUrl;


    @BeforeEach
    void setUp() throws IOException {
        server = HttpServer.create(new InetSocketAddress(0), 0);
        serverUrl = "http://127.0.0.1:" + server.getAddress().getPort();
        server.createContext("/missing", exchange -> respond(exchange, 404, "text/plain", new byte[0]));
        server.createContext("/text", exchange -> respond(
            exchange, 200, "text/plain", "not-an-image".getBytes(StandardCharsets.UTF_8)));
        server.createContext("/image", exchange -> respond(exchange, 200, "image/jpeg", IMAGE_CONTENT));
        server.start();
    }


    @AfterEach
    void tearDown() {
        server.stop(0);
    }


    @Test
    @DisplayName("Should use the fallback URL when the primary image is unavailable")
    void shouldUseFallbackImage() throws IOException {
        final MockHttpServletResponse response = new MockHttpServletResponse();

        new ImageProxyController().proxyImage(serverUrl + "/missing", serverUrl + "/image", response);

        Assertions.assertEquals(200, response.getStatus());
        Assertions.assertEquals("image/jpeg", response.getContentType());
        Assertions.assertArrayEquals(IMAGE_CONTENT, response.getContentAsByteArray());
    }


    @Test
    @DisplayName("Should reject a response that is not an image")
    void shouldRejectNonImageContent() throws IOException {
        final MockHttpServletResponse response = new MockHttpServletResponse();

        new ImageProxyController().proxyImage(serverUrl + "/text", null, response);

        Assertions.assertEquals(502, response.getStatus());
    }


    private void respond(HttpExchange exchange, int status, String contentType, byte[] content) throws IOException {
        exchange.getResponseHeaders().set("Content-Type", contentType);
        exchange.sendResponseHeaders(status, content.length);
        exchange.getResponseBody().write(content);
        exchange.close();
    }
}
