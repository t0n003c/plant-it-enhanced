package com.github.mdeluise.plantit.unit.component;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.Date;

import com.github.mdeluise.plantit.reminder.Reminder;
import com.github.mdeluise.plantit.reminder.ReminderScheduleCalculator;
import com.github.mdeluise.plantit.reminder.frequency.Frequency;
import com.github.mdeluise.plantit.reminder.frequency.Unit;
import org.assertj.core.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("Unit tests for calendar-aware reminder scheduling")
class ReminderScheduleCalculatorUnitTests {
    private static final ZoneId CHICAGO = ZoneId.of("America/Chicago");
    private static final Clock FIXED_CLOCK = Clock.fixed(
        Instant.parse("2026-07-17T12:00:00Z"), CHICAGO);
    private final ReminderScheduleCalculator calculator = new ReminderScheduleCalculator(FIXED_CLOCK);


    @Test
    @DisplayName("Should retain local time across daylight-saving transitions")
    void shouldRetainLocalTimeAcrossDaylightSavingTransitions() {
        final ZonedDateTime beforeDst = ZonedDateTime.of(2026, 3, 7, 8, 0, 0, 0, CHICAGO);

        final Date result = calculator.add(Date.from(beforeDst.toInstant()), frequency(1, Unit.DAYS));

        final ZonedDateTime localResult = result.toInstant().atZone(CHICAGO);
        Assertions.assertThat(localResult.getHour()).isEqualTo(8);
        Assertions.assertThat(localResult.toLocalDate()).isEqualTo(beforeDst.toLocalDate().plusDays(1));
        Assertions.assertThat(result.getTime() - Date.from(beforeDst.toInstant()).getTime())
                  .isEqualTo(23L * 60 * 60 * 1000);
    }


    @Test
    @DisplayName("Should use calendar months instead of epoch milliseconds")
    void shouldUseCalendarMonths() {
        final ZonedDateTime januaryEnd = ZonedDateTime.of(2025, 1, 31, 9, 30, 0, 0, CHICAGO);

        final Date result = calculator.add(Date.from(januaryEnd.toInstant()), frequency(1, Unit.MONTHS));

        Assertions.assertThat(result.toInstant().atZone(CHICAGO).toLocalDate())
                  .isEqualTo(januaryEnd.toLocalDate().plusMonths(1));
    }


    @Test
    @DisplayName("Should advance a skipped occurrence by one frequency")
    void shouldAdvanceSkippedOccurrence() {
        final ZonedDateTime start = ZonedDateTime.of(2026, 7, 1, 7, 0, 0, 0, CHICAGO);
        final Reminder reminder = new Reminder();
        reminder.setStart(Date.from(start.toInstant()));
        reminder.setFrequency(frequency(7, Unit.DAYS));
        reminder.setLastSkippedOccurrence(Date.from(start.toInstant()));

        final Date result = calculator.calculateDueAt(reminder, null);

        Assertions.assertThat(result.toInstant().atZone(CHICAGO).toLocalDate())
                  .isEqualTo(start.toLocalDate().plusDays(7));
    }


    private Frequency frequency(int quantity, Unit unit) {
        final Frequency result = new Frequency();
        result.setQuantity(quantity);
        result.setUnit(unit);
        return result;
    }
}
