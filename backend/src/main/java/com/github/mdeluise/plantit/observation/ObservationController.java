package com.github.mdeluise.plantit.observation;

import com.github.mdeluise.plantit.common.MessageResponse;
import com.github.mdeluise.plantit.image.EntityImage;
import com.github.mdeluise.plantit.image.ObservationImage;
import com.github.mdeluise.plantit.image.ObservationImageRepository;
import com.github.mdeluise.plantit.image.storage.ImageStorageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/observation")
@Tag(name = "Observation", description = "Wild plant field-journal observations.")
public class ObservationController {
    private final ObservationService observationService;
    private final ObservationDTOConverter observationDTOConverter;
    private final ImageStorageService imageStorageService;
    private final ObservationImageRepository observationImageRepository;


    @Autowired
    public ObservationController(ObservationService observationService,
                                 ObservationDTOConverter observationDTOConverter,
                                 ImageStorageService imageStorageService,
                                 ObservationImageRepository observationImageRepository) {
        this.observationService = observationService;
        this.observationDTOConverter = observationDTOConverter;
        this.imageStorageService = imageStorageService;
        this.observationImageRepository = observationImageRepository;
    }


    @GetMapping
    @Operation(summary = "List the current user's observations.")
    public ResponseEntity<Page<ObservationDTO>> getAll(
        @RequestParam(defaultValue = "0", required = false) Integer pageNo,
        @RequestParam(defaultValue = "25", required = false) Integer pageSize,
        @RequestParam(defaultValue = "observedAt", required = false) String sortBy,
        @RequestParam(defaultValue = "DESC", required = false) Sort.Direction sortDir) {
        final Pageable pageable = PageRequest.of(pageNo, pageSize, Sort.by(sortDir, sortBy));
        return ResponseEntity.ok(observationService.getAll(pageable).map(observationDTOConverter::convertToDTO));
    }


    @GetMapping("/{id}")
    @Operation(summary = "Get one observation owned by the current user.")
    public ResponseEntity<ObservationDTO> get(@PathVariable Long id) {
        return ResponseEntity.ok(observationDTOConverter.convertToDTO(observationService.get(id)));
    }


    @GetMapping("/_count")
    @Operation(summary = "Count the current user's observations.")
    public ResponseEntity<Long> count() {
        return ResponseEntity.ok(observationService.count());
    }


    @PostMapping
    @Operation(summary = "Create a field observation.")
    public ResponseEntity<ObservationDTO> save(@RequestBody ObservationDTO dto) {
        final Observation saved = observationService.save(observationDTOConverter.convertFromDTO(dto));
        return ResponseEntity.ok(observationDTOConverter.convertToDTO(saved));
    }


    @PutMapping("/{id}")
    @Operation(summary = "Update a field observation.")
    public ResponseEntity<ObservationDTO> update(@PathVariable Long id, @RequestBody ObservationDTO dto) {
        final Observation saved = observationService.update(id, observationDTOConverter.convertFromDTO(dto));
        return ResponseEntity.ok(observationDTOConverter.convertToDTO(saved));
    }


    @DeleteMapping("/{id}")
    @Operation(summary = "Delete a field observation and its photos.")
    public ResponseEntity<MessageResponse> delete(@PathVariable Long id) {
        observationService.delete(id);
        return ResponseEntity.ok(new MessageResponse("Success"));
    }


    @PostMapping("/{id}/image")
    @Operation(summary = "Attach a field photo to an observation.")
    public ResponseEntity<String> saveImage(@PathVariable Long id,
                                            @RequestParam("image") MultipartFile file,
                                            @RequestParam(required = false) String description,
                                            @RequestParam(required = false) String clientReference) {
        final Observation observation = observationService.get(id);
        if (clientReference != null && !clientReference.isBlank()) {
            final var existing =
                observationImageRepository.findByTargetAndClientReference(observation, clientReference.trim());
            if (existing.isPresent()) {
                return ResponseEntity.ok(existing.get().getId());
            }
        }
        final EntityImage saved = imageStorageService.save(file, observation, null, description);
        if (saved instanceof ObservationImage observationImage &&
                clientReference != null && !clientReference.isBlank()) {
            observationImage.setClientReference(clientReference.trim());
            observationImageRepository.save(observationImage);
        }
        return ResponseEntity.ok(saved.getId());
    }
}
