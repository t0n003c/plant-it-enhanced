package com.github.mdeluise.plantit.hike;

import java.util.List;

import com.github.mdeluise.plantit.common.MessageResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/hike-session")
@Tag(name = "Hike Session", description = "Named field outings that group wild plant observations.")
public class HikeSessionController {
    private final HikeSessionService hikeSessionService;
    private final HikeSessionDTOConverter hikeSessionDTOConverter;


    @Autowired
    public HikeSessionController(HikeSessionService hikeSessionService,
                                 HikeSessionDTOConverter hikeSessionDTOConverter) {
        this.hikeSessionService = hikeSessionService;
        this.hikeSessionDTOConverter = hikeSessionDTOConverter;
    }


    @GetMapping
    @Operation(summary = "List the current user's hike sessions.")
    public ResponseEntity<List<HikeSessionDTO>> getAll() {
        return ResponseEntity.ok(hikeSessionService.getAll().stream()
                                                   .map(hikeSessionDTOConverter::convertToDTO)
                                                   .toList());
    }


    @GetMapping("/active")
    @Operation(summary = "Get the current user's active hike, if any.")
    public ResponseEntity<HikeSessionDTO> getActive() {
        return hikeSessionService.getActive()
                                 .map(hikeSessionDTOConverter::convertToDTO)
                                 .map(ResponseEntity::ok)
                                 .orElseGet(() -> ResponseEntity.noContent().build());
    }


    @PostMapping
    @Operation(summary = "Start a hike session.")
    public ResponseEntity<HikeSessionDTO> save(@RequestBody HikeSessionDTO dto) {
        final HikeSession saved = hikeSessionService.save(hikeSessionDTOConverter.convertFromDTO(dto));
        return ResponseEntity.ok(hikeSessionDTOConverter.convertToDTO(saved));
    }


    @PutMapping("/{id}")
    @Operation(summary = "Update or finish a hike session.")
    public ResponseEntity<HikeSessionDTO> update(@PathVariable Long id, @RequestBody HikeSessionDTO dto) {
        final HikeSession saved = hikeSessionService.update(id, hikeSessionDTOConverter.convertFromDTO(dto));
        return ResponseEntity.ok(hikeSessionDTOConverter.convertToDTO(saved));
    }


    @PostMapping("/{id}/end")
    @Operation(summary = "Finish an active hike at the current time.")
    public ResponseEntity<HikeSessionDTO> end(@PathVariable Long id) {
        return ResponseEntity.ok(hikeSessionDTOConverter.convertToDTO(hikeSessionService.end(id)));
    }


    @DeleteMapping("/{id}")
    @Operation(summary = "Delete a hike session without deleting its observations.")
    public ResponseEntity<MessageResponse> delete(@PathVariable Long id) {
        hikeSessionService.delete(id);
        return ResponseEntity.ok(new MessageResponse("Success"));
    }
}
