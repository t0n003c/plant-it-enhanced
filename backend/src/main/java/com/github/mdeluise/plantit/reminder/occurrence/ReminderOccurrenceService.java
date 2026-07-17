package com.github.mdeluise.plantit.reminder.occurrence;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Date;
import java.util.List;
import java.util.Optional;

import com.github.mdeluise.plantit.diary.entry.DiaryEntry;
import com.github.mdeluise.plantit.diary.entry.DiaryEntryService;
import com.github.mdeluise.plantit.reminder.Reminder;
import com.github.mdeluise.plantit.reminder.ReminderScheduleCalculator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class ReminderOccurrenceService {
    private final DiaryEntryService diaryEntryService;
    private final ReminderScheduleCalculator scheduleCalculator;


    @Autowired
    public ReminderOccurrenceService(DiaryEntryService diaryEntryService,
                                     ReminderScheduleCalculator scheduleCalculator) {
        this.diaryEntryService = diaryEntryService;
        this.scheduleCalculator = scheduleCalculator;
    }


    public Collection<ReminderOccurrence> getOccurrences(Reminder reminder, Date start, Date end) {
        if (!reminder.isEnabled() || reminder.getStart().after(end) ||
                reminder.getEnd() != null && reminder.getEnd().before(start)) {
            return List.of();
        }

        final List<ReminderOccurrence> occurrences = new ArrayList<>();
        final Optional<DiaryEntry> lastAction = diaryEntryService.getLast(
            reminder.getTarget().getId(), reminder.getAction());
        Date occurrenceDate;
        if (lastAction.isPresent()) {
            final Date lastActionDate = lastAction.get().getDate();
            occurrenceDate = scheduleCalculator.calculateDueAt(reminder, lastActionDate);
        } else {
            occurrenceDate = scheduleCalculator.calculateDueAt(reminder, null);
        }
        while (occurrenceDate.before(end) &&
                (reminder.getEnd() == null || !occurrenceDate.after(reminder.getEnd()))) {
            if (occurrenceDate.after(start)) {
                final ReminderOccurrence occurrence = new ReminderOccurrence();
                occurrence.setDate(occurrenceDate);
                occurrence.setReminder(reminder);
                occurrences.add(occurrence);
            }
            occurrenceDate = scheduleCalculator.add(occurrenceDate, reminder.getFrequency());
        }
        return occurrences;
    }
}
