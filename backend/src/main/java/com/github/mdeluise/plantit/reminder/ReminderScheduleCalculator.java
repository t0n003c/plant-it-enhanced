package com.github.mdeluise.plantit.reminder;

import java.time.Clock;
import java.time.ZonedDateTime;
import java.util.Date;

import com.github.mdeluise.plantit.reminder.frequency.Frequency;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

/**
 * Performs reminder arithmetic in calendar time so that months, years, and
 * daylight-saving transitions retain their expected local time.
 */
@Component
public class ReminderScheduleCalculator {
    private final Clock clock;


    @Autowired
    public ReminderScheduleCalculator(Clock clock) {
        this.clock = clock;
    }


    public Date now() {
        return Date.from(clock.instant());
    }


    public Clock getClock() {
        return clock;
    }


    public Date add(Date anchor, Frequency frequency) {
        return add(anchor, frequency, 1);
    }


    public Date calculateDueAt(Reminder reminder, Date lastCompletedAt) {
        final Date baseDueAt = lastCompletedAt == null
                                   ? reminder.getStart() : add(lastCompletedAt, reminder.getFrequency());
        if (reminder.getLastSkippedOccurrence() == null) {
            return baseDueAt;
        }
        final Date dueAfterSkip = add(reminder.getLastSkippedOccurrence(), reminder.getFrequency());
        return dueAfterSkip.after(baseDueAt) ? dueAfterSkip : baseDueAt;
    }


    public Date calculateActionAt(Reminder reminder, Date dueAt) {
        final Date snoozedUntil = reminder.getSnoozedUntil();
        return snoozedUntil != null && snoozedUntil.after(dueAt) ? snoozedUntil : dueAt;
    }


    private Date add(Date anchor, Frequency frequency, int minimumQuantity) {
        if (anchor == null) {
            throw new IllegalArgumentException("Reminder date is required");
        }
        if (frequency == null || frequency.getUnit() == null) {
            throw new IllegalArgumentException("Reminder frequency is required");
        }
        final int quantity = Math.max(minimumQuantity, frequency.getQuantity());
        final ZonedDateTime source = anchor.toInstant().atZone(clock.getZone());
        final ZonedDateTime result = switch (frequency.getUnit()) {
            case DAYS -> source.plusDays(quantity);
            case WEEKS -> source.plusWeeks(quantity);
            case MONTHS -> source.plusMonths(quantity);
            case YEARS -> source.plusYears(quantity);
        };
        return Date.from(result.toInstant());
    }
}
