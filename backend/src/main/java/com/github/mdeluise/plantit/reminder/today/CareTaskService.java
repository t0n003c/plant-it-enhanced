package com.github.mdeluise.plantit.reminder.today;

import java.time.LocalDate;
import java.time.ZonedDateTime;
import java.util.Collection;
import java.util.Comparator;
import java.util.Date;
import java.util.Optional;

import com.github.mdeluise.plantit.diary.entry.DiaryEntry;
import com.github.mdeluise.plantit.diary.entry.DiaryEntryService;
import com.github.mdeluise.plantit.diary.entry.DiaryEntryType;
import com.github.mdeluise.plantit.plant.care.CareScheduleSuggestion;
import com.github.mdeluise.plantit.plant.care.CareScheduleSuggestionService;
import com.github.mdeluise.plantit.reminder.Reminder;
import com.github.mdeluise.plantit.reminder.ReminderRepository;
import com.github.mdeluise.plantit.reminder.ReminderScheduleCalculator;
import com.github.mdeluise.plantit.reminder.ReminderService;
import com.github.mdeluise.plantit.reminder.frequency.Frequency;
import com.github.mdeluise.plantit.reminder.frequency.Unit;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class CareTaskService {
    private static final int MAXIMUM_WINDOW_DAYS = 31;
    private final ReminderService reminderService;
    private final ReminderRepository reminderRepository;
    private final ReminderScheduleCalculator scheduleCalculator;
    private final DiaryEntryService diaryEntryService;
    private final CareScheduleSuggestionService suggestionService;


    @Autowired
    public CareTaskService(ReminderService reminderService, ReminderRepository reminderRepository,
                           ReminderScheduleCalculator scheduleCalculator, DiaryEntryService diaryEntryService,
                           CareScheduleSuggestionService suggestionService) {
        this.reminderService = reminderService;
        this.reminderRepository = reminderRepository;
        this.scheduleCalculator = scheduleCalculator;
        this.diaryEntryService = diaryEntryService;
        this.suggestionService = suggestionService;
    }


    public CareTaskService(ReminderService reminderService, ReminderRepository reminderRepository,
                           ReminderScheduleCalculator scheduleCalculator, DiaryEntryService diaryEntryService) {
        this(reminderService, reminderRepository, scheduleCalculator, diaryEntryService, null);
    }


    public Collection<CareTaskDTO> getTasks(int days) {
        final int boundedDays = Math.min(MAXIMUM_WINDOW_DAYS, Math.max(0, days));
        final Date now = scheduleCalculator.now();
        final ZonedDateTime windowEnd = now.toInstant().atZone(scheduleCalculator.getClock().getZone())
                                               .toLocalDate().plusDays(boundedDays + 1L)
                                               .atStartOfDay(scheduleCalculator.getClock().getZone());
        return reminderService.getAll().stream()
                              .filter(Reminder::isEnabled)
                              .map(reminder -> toTask(reminder, now))
                              .flatMap(Optional::stream)
                              .filter(task -> task.actionAt().toInstant().isBefore(windowEnd.toInstant()))
                              .sorted(Comparator.comparing(CareTaskDTO::actionAt)
                                                .thenComparing(CareTaskDTO::plantName,
                                                               Comparator.nullsLast(String::compareToIgnoreCase)))
                              .toList();
    }


    @Transactional
    public void complete(long reminderId, String note) {
        final Reminder reminder = reminderService.get(reminderId);
        final DiaryEntry entry = new DiaryEntry();
        entry.setDiary(reminder.getTarget().getDiary());
        entry.setType(reminder.getAction());
        entry.setDate(scheduleCalculator.now());
        entry.setNote(note);
        diaryEntryService.save(entry);
        adaptWateringReminder(reminder);
        clearTransientState(reminder);
        reminderRepository.save(reminder);
    }


    @Transactional
    public void snooze(long reminderId, Date until) {
        final Date now = scheduleCalculator.now();
        if (until == null || !until.after(now)) {
            throw new IllegalArgumentException("Snooze time must be in the future");
        }
        final Reminder reminder = reminderService.get(reminderId);
        reminder.setSnoozedUntil(until);
        reminder.setLastNotified(null);
        reminderRepository.save(reminder);
    }


    @Transactional
    public void skip(long reminderId) {
        final Reminder reminder = reminderService.get(reminderId);
        final Optional<DiaryEntry> lastEntry = diaryEntryService.getLast(
            reminder.getTarget().getId(), reminder.getAction());
        final Date dueAt = scheduleCalculator.calculateDueAt(
            reminder, lastEntry.map(DiaryEntry::getDate).orElse(null));
        if (dueAt.after(scheduleCalculator.now())) {
            throw new IllegalArgumentException("Only a due care task can be skipped");
        }
        reminder.setLastSkippedOccurrence(dueAt);
        clearTransientState(reminder);
        reminderRepository.save(reminder);
    }


    private Optional<CareTaskDTO> toTask(Reminder reminder, Date now) {
        if (reminder.getEnd() != null && reminder.getEnd().before(now)) {
            return Optional.empty();
        }
        final Optional<DiaryEntry> lastEntry = diaryEntryService.getLast(
            reminder.getTarget().getId(), reminder.getAction());
        final Date lastCompletedAt = lastEntry.map(DiaryEntry::getDate).orElse(null);
        final Date dueAt = scheduleCalculator.calculateDueAt(reminder, lastCompletedAt);
        if (reminder.getEnd() != null && dueAt.after(reminder.getEnd())) {
            return Optional.empty();
        }
        final Date actionAt = scheduleCalculator.calculateActionAt(reminder, dueAt);
        final CareTaskStatus status = getStatus(reminder, dueAt, now);
        return Optional.of(new CareTaskDTO(
            reminder.getId(), reminder.getTarget().getId(), reminder.getTarget().getInfo().getPersonalName(),
            reminder.getAction(), dueAt, actionAt, reminder.getSnoozedUntil(), lastCompletedAt, status
        ));
    }


    private CareTaskStatus getStatus(Reminder reminder, Date dueAt, Date now) {
        final CareTaskStatus result;
        if (reminder.getSnoozedUntil() != null && reminder.getSnoozedUntil().after(now) && !dueAt.after(now)) {
            result = CareTaskStatus.SNOOZED;
        } else {
            final LocalDate dueDate = dueAt.toInstant().atZone(scheduleCalculator.getClock().getZone()).toLocalDate();
            final LocalDate today = now.toInstant().atZone(scheduleCalculator.getClock().getZone()).toLocalDate();
            if (dueDate.isBefore(today)) {
                result = CareTaskStatus.OVERDUE;
            } else if (dueDate.equals(today)) {
                result = CareTaskStatus.DUE_TODAY;
            } else {
                result = CareTaskStatus.UPCOMING;
            }
        }
        return result;
    }


    private void clearTransientState(Reminder reminder) {
        reminder.setSnoozedUntil(null);
        reminder.setLastNotified(null);
    }


    private void adaptWateringReminder(Reminder reminder) {
        if (suggestionService == null || reminder.getAction() != DiaryEntryType.WATERING) {
            return;
        }
        final CareScheduleSuggestion suggestion = suggestionService.suggest(reminder.getTarget());
        final Frequency frequency = new Frequency();
        frequency.setQuantity(suggestion.intervalDays());
        frequency.setUnit(Unit.DAYS);
        reminder.setFrequency(frequency);
    }
}
