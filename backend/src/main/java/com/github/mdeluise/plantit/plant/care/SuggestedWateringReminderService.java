package com.github.mdeluise.plantit.plant.care;

import java.util.Date;
import java.util.List;

import com.github.mdeluise.plantit.diary.entry.DiaryEntryType;
import com.github.mdeluise.plantit.plant.Plant;
import com.github.mdeluise.plantit.plant.PlantService;
import com.github.mdeluise.plantit.reminder.Reminder;
import com.github.mdeluise.plantit.reminder.ReminderRepository;
import com.github.mdeluise.plantit.reminder.frequency.Frequency;
import com.github.mdeluise.plantit.reminder.frequency.Unit;
import org.springframework.stereotype.Service;

@Service
public class SuggestedWateringReminderService {
    private final PlantService plantService;
    private final ReminderRepository reminderRepository;
    private final CareScheduleSuggestionService suggestionService;


    public SuggestedWateringReminderService(PlantService plantService, ReminderRepository reminderRepository,
                                            CareScheduleSuggestionService suggestionService) {
        this.plantService = plantService;
        this.reminderRepository = reminderRepository;
        this.suggestionService = suggestionService;
    }


    public Reminder createIfMissing(long plantId) {
        final Plant plant = plantService.get(plantId);
        final List<Reminder> existing = reminderRepository.findAllByTargetOwnerAndTargetAndAction(
            plant.getOwner(), plant, DiaryEntryType.WATERING);
        if (!existing.isEmpty()) {
            return existing.get(0);
        }
        final CareScheduleSuggestion suggestion = suggestionService.suggest(plant);
        final Reminder result = new Reminder();
        result.setTarget(plant);
        result.setStart(new Date());
        result.setAction(DiaryEntryType.WATERING);
        result.setFrequency(frequency(suggestion.intervalDays()));
        result.setRepeatAfter(frequency(1));
        result.setEnabled(true);
        return reminderRepository.save(result);
    }


    private Frequency frequency(int days) {
        final Frequency result = new Frequency();
        result.setQuantity(days);
        result.setUnit(Unit.DAYS);
        return result;
    }
}
