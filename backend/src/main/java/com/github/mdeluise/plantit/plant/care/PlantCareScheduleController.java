package com.github.mdeluise.plantit.plant.care;

import com.github.mdeluise.plantit.plant.Plant;
import com.github.mdeluise.plantit.plant.PlantService;
import com.github.mdeluise.plantit.reminder.Reminder;
import com.github.mdeluise.plantit.reminder.ReminderDTO;
import com.github.mdeluise.plantit.reminder.ReminderDTOConverter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/plant/{plantId}/care-suggestion")
@Tag(name = "Plant Care", description = "Personalized care schedule suggestions")
public class PlantCareScheduleController {
    private final PlantService plantService;
    private final CareScheduleSuggestionService suggestionService;
    private final SuggestedWateringReminderService reminderService;
    private final ReminderDTOConverter reminderDTOConverter;


    public PlantCareScheduleController(PlantService plantService,
                                       CareScheduleSuggestionService suggestionService,
                                       SuggestedWateringReminderService reminderService,
                                       ReminderDTOConverter reminderDTOConverter) {
        this.plantService = plantService;
        this.suggestionService = suggestionService;
        this.reminderService = reminderService;
        this.reminderDTOConverter = reminderDTOConverter;
    }


    @GetMapping
    public ResponseEntity<CareScheduleSuggestion> get(@PathVariable long plantId) {
        final Plant plant = plantService.get(plantId);
        return ResponseEntity.ok(suggestionService.suggest(plant));
    }


    @PostMapping("/reminder")
    public ResponseEntity<ReminderDTO> createReminder(@PathVariable long plantId) {
        final Reminder result = reminderService.createIfMissing(plantId);
        return ResponseEntity.ok(reminderDTOConverter.convertToDTO(result));
    }
}
