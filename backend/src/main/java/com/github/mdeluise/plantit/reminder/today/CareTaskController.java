package com.github.mdeluise.plantit.reminder.today;

import java.util.Collection;

import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/care-tasks")
@Tag(name = "Care Tasks", description = "Daily plant-care workflow endpoints")
public class CareTaskController {
    private final CareTaskService careTaskService;


    @Autowired
    public CareTaskController(CareTaskService careTaskService) {
        this.careTaskService = careTaskService;
    }


    @GetMapping
    public ResponseEntity<Collection<CareTaskDTO>> getTasks(
        @RequestParam(defaultValue = "7", required = false) int days) {
        return ResponseEntity.ok(careTaskService.getTasks(days));
    }


    @PostMapping("/{id}/complete")
    public ResponseEntity<Void> complete(@PathVariable long id,
                                         @RequestBody(required = false) CompleteCareTaskRequest request) {
        careTaskService.complete(id, request == null ? null : request.note());
        return ResponseEntity.noContent().build();
    }


    @PostMapping("/{id}/snooze")
    public ResponseEntity<Void> snooze(@PathVariable long id, @RequestBody SnoozeCareTaskRequest request) {
        careTaskService.snooze(id, request.until());
        return ResponseEntity.noContent().build();
    }


    @PostMapping("/{id}/skip")
    public ResponseEntity<Void> skip(@PathVariable long id) {
        careTaskService.skip(id);
        return ResponseEntity.noContent().build();
    }
}
