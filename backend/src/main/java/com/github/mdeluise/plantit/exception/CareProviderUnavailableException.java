package com.github.mdeluise.plantit.exception;

public class CareProviderUnavailableException extends RuntimeException {
    public CareProviderUnavailableException() {
        super("The configured care data providers could not be reached. Try refreshing again later.");
    }
}
