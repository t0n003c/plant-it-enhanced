package com.github.mdeluise.plantit.unit.service;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.Collection;
import java.util.Date;
import java.util.List;
import java.util.Optional;

import com.github.mdeluise.plantit.diary.Diary;
import com.github.mdeluise.plantit.diary.entry.DiaryEntry;
import com.github.mdeluise.plantit.diary.entry.DiaryEntryService;
import com.github.mdeluise.plantit.diary.entry.DiaryEntryType;
import com.github.mdeluise.plantit.plant.Plant;
import com.github.mdeluise.plantit.reminder.Reminder;
import com.github.mdeluise.plantit.reminder.ReminderRepository;
import com.github.mdeluise.plantit.reminder.ReminderScheduleCalculator;
import com.github.mdeluise.plantit.reminder.ReminderService;
import com.github.mdeluise.plantit.reminder.frequency.Frequency;
import com.github.mdeluise.plantit.reminder.frequency.Unit;
import com.github.mdeluise.plantit.reminder.today.CareTaskDTO;
import com.github.mdeluise.plantit.reminder.today.CareTaskService;
import com.github.mdeluise.plantit.reminder.today.CareTaskStatus;
import com.github.mdeluise.plantit.plant.care.CareScheduleSuggestion;
import com.github.mdeluise.plantit.plant.care.CareScheduleSuggestionService;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mockito;

@DisplayName("Unit tests for the Today care workflow")
class CareTaskServiceUnitTests {
    private static final ZoneId CHICAGO = ZoneId.of("America/Chicago");
    private static final Instant NOW = Instant.parse("2026-07-17T12:00:00Z");
    private ReminderService reminderService;
    private ReminderRepository reminderRepository;
    private DiaryEntryService diaryEntryService;
    private CareTaskService careTaskService;


    @BeforeEach
    void setUp() {
        reminderService = Mockito.mock(ReminderService.class);
        reminderRepository = Mockito.mock(ReminderRepository.class);
        diaryEntryService = Mockito.mock(DiaryEntryService.class);
        final ReminderScheduleCalculator scheduleCalculator = new ReminderScheduleCalculator(
            Clock.fixed(NOW, CHICAGO));
        careTaskService = new CareTaskService(
            reminderService, reminderRepository, scheduleCalculator, diaryEntryService);
    }


    @Test
    @DisplayName("Should expose a due reminder as today's actionable care task")
    void shouldExposeDueReminder() {
        final Reminder reminder = reminderAt(6, 0);
        Mockito.when(reminderService.getAll()).thenReturn(List.of(reminder));
        Mockito.when(diaryEntryService.getLast(42L, DiaryEntryType.WATERING))
               .thenReturn(Optional.empty());

        final Collection<CareTaskDTO> result = careTaskService.getTasks(7);

        Assertions.assertEquals(1, result.size());
        final CareTaskDTO task = result.iterator().next();
        Assertions.assertEquals(CareTaskStatus.DUE_TODAY, task.status());
        Assertions.assertEquals("Kitchen monstera", task.plantName());
        Assertions.assertEquals(42L, task.plantId());
    }


    @Test
    @DisplayName("Should complete a task by logging its diary action and clearing transient state")
    void shouldCompleteCareTask() {
        final Reminder reminder = reminderAt(6, 0);
        reminder.setSnoozedUntil(Date.from(NOW.plusSeconds(3600)));
        reminder.setLastNotified(Date.from(NOW.minusSeconds(60)));
        Mockito.when(reminderService.get(7L)).thenReturn(reminder);

        careTaskService.complete(7L, "Soil was dry");

        final ArgumentCaptor<DiaryEntry> entryCaptor = ArgumentCaptor.forClass(DiaryEntry.class);
        Mockito.verify(diaryEntryService).save(entryCaptor.capture());
        final DiaryEntry savedEntry = entryCaptor.getValue();
        Assertions.assertEquals(reminder.getTarget().getDiary(), savedEntry.getDiary());
        Assertions.assertEquals(DiaryEntryType.WATERING, savedEntry.getType());
        Assertions.assertEquals("Soil was dry", savedEntry.getNote());
        Assertions.assertEquals(Date.from(NOW), savedEntry.getDate());
        Assertions.assertNull(reminder.getSnoozedUntil());
        Assertions.assertNull(reminder.getLastNotified());
        Mockito.verify(reminderRepository).save(reminder);
    }


    @Test
    @DisplayName("Should adapt a watering reminder after completing care")
    void shouldAdaptWateringReminderAfterCompletion() {
        final CareScheduleSuggestionService suggestionService = Mockito.mock(CareScheduleSuggestionService.class);
        Mockito.when(suggestionService.suggest(Mockito.any(Plant.class)))
               .thenReturn(new CareScheduleSuggestion(5, 0.8, List.of("RECENT_WATERING_HISTORY")));
        final CareTaskService adaptiveService = new CareTaskService(
            reminderService,
            reminderRepository,
            new ReminderScheduleCalculator(Clock.fixed(NOW, CHICAGO)),
            diaryEntryService,
            suggestionService
        );
        final Reminder reminder = reminderAt(6, 0);
        Mockito.when(reminderService.get(7L)).thenReturn(reminder);

        adaptiveService.complete(7L, "Soil was dry");

        Assertions.assertEquals(5, reminder.getFrequency().getQuantity());
        Assertions.assertEquals(Unit.DAYS, reminder.getFrequency().getUnit());
    }


    @Test
    @DisplayName("Should keep expired reminders out of the Today list")
    void shouldExcludeExpiredReminder() {
        final Reminder reminder = reminderAt(6, 0);
        reminder.setEnd(Date.from(NOW.minusSeconds(1)));
        Mockito.when(reminderService.getAll()).thenReturn(List.of(reminder));
        Mockito.when(diaryEntryService.getLast(42L, DiaryEntryType.WATERING))
               .thenReturn(Optional.empty());

        final Collection<CareTaskDTO> result = careTaskService.getTasks(7);

        Assertions.assertTrue(result.isEmpty());
    }


    private Reminder reminderAt(int hour, int minute) {
        final Plant plant = new Plant();
        plant.setId(42L);
        plant.getInfo().setPersonalName("Kitchen monstera");
        final Diary diary = new Diary();
        diary.setId(84L);
        plant.setDiary(diary);
        final Frequency frequency = new Frequency();
        frequency.setQuantity(7);
        frequency.setUnit(Unit.DAYS);
        final Reminder reminder = new Reminder();
        reminder.setId(7L);
        reminder.setTarget(plant);
        reminder.setEnabled(true);
        reminder.setAction(DiaryEntryType.WATERING);
        reminder.setFrequency(frequency);
        reminder.setStart(Date.from(
            ZonedDateTime.of(2026, 7, 17, hour, minute, 0, 0, CHICAGO).toInstant()));
        return reminder;
    }
}
