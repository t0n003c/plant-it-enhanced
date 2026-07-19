package com.github.mdeluise.plantit.catalog;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/catalog-health")
@Tag(name = "Catalog Health", description = "Authenticated catalog coverage and local quality gaps")
public class CatalogHealthController {
    private final CatalogHealthService catalogHealthService;


    public CatalogHealthController(CatalogHealthService catalogHealthService) {
        this.catalogHealthService = catalogHealthService;
    }


    @GetMapping
    @Operation(summary = "Get the reviewed catalog coverage and this account's recent quality gaps")
    public ResponseEntity<CatalogHealthSnapshot> get() {
        return ResponseEntity.ok()
                             .cacheControl(CacheControl.noStore())
                             .body(catalogHealthService.get());
    }
}
