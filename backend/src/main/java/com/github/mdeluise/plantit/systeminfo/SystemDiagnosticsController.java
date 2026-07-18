package com.github.mdeluise.plantit.systeminfo;

import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/diagnostics")
@Tag(name = "Diagnostics", description = "Authenticated self-hosting diagnostics")
public class SystemDiagnosticsController {
    private final SystemDiagnosticsService systemDiagnosticsService;


    public SystemDiagnosticsController(SystemDiagnosticsService systemDiagnosticsService) {
        this.systemDiagnosticsService = systemDiagnosticsService;
    }


    @GetMapping
    public ResponseEntity<SystemDiagnostics> get() {
        return ResponseEntity.ok(systemDiagnosticsService.get());
    }
}
