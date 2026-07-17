package com.github.mdeluise.plantit.reminder.today;

import java.util.Date;

import com.github.mdeluise.plantit.diary.entry.DiaryEntryType;
import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "Care task", description = "A reminder occurrence enriched for the Today workflow.")
public record CareTaskDTO(
    Long reminderId,
    Long plantId,
    String plantName,
    DiaryEntryType action,
    Date dueAt,
    Date actionAt,
    Date snoozedUntil,
    Date lastCompletedAt,
    CareTaskStatus status
) {
}
