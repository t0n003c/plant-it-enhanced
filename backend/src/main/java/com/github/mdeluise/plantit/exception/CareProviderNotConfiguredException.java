package com.github.mdeluise.plantit.exception;

public class CareProviderNotConfiguredException extends RuntimeException {
    public CareProviderNotConfiguredException() {
        super("Care lookup is not configured. Set TREFLE_TOKEN or PERENUAL_API_KEY on the server.");
    }
}
