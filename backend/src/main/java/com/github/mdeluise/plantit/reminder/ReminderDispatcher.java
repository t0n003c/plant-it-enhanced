package com.github.mdeluise.plantit.reminder;

import java.util.Date;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

import com.github.mdeluise.plantit.diary.entry.DiaryEntry;
import com.github.mdeluise.plantit.diary.entry.DiaryEntryService;
import com.github.mdeluise.plantit.notification.NotifyException;
import com.github.mdeluise.plantit.notification.dispatcher.NotificationDispatcher;
import com.github.mdeluise.plantit.notification.dispatcher.NotificationDispatcherName;
import com.github.mdeluise.plantit.notification.dispatcher.config.AbstractNotificationDispatcherConfig;
import com.github.mdeluise.plantit.notification.dispatcher.config.NotificationDispatcherConfigImplRepository;
import jakarta.transaction.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class ReminderDispatcher {
    private final List<NotificationDispatcher> notificationsDispatchers;
    private final NotificationDispatcherConfigImplRepository notificationDispatcherConfigImplRepository;
    private final ReminderRepository reminderRepository;
    private final DiaryEntryService diaryEntryService;
    private final ReminderScheduleCalculator scheduleCalculator;
    private final Logger logger = LoggerFactory.getLogger(ReminderDispatcher.class);


    @Autowired
    public ReminderDispatcher(List<NotificationDispatcher> notificationsDispatchers,
                              NotificationDispatcherConfigImplRepository notificationDispatcherConfigImplRepository,
                              ReminderRepository reminderRepository, DiaryEntryService diaryEntryService,
                              ReminderScheduleCalculator scheduleCalculator) {
        this.notificationsDispatchers = notificationsDispatchers;
        this.notificationDispatcherConfigImplRepository = notificationDispatcherConfigImplRepository;
        this.reminderRepository = reminderRepository;
        this.diaryEntryService = diaryEntryService;
        this.scheduleCalculator = scheduleCalculator;
    }


    @Transactional
    public void dispatch() {
        logger.info("Starting reminder dispatching...");
        reminderRepository.findAllByEnabledTrue().forEach(reminder -> {
            if (isToNotify(reminder)) {
                logger.debug("Reminder {} is to dispatch", reminder.getId());
                dispatchInternal(reminder);
            }
        });
    }


    @SuppressWarnings("ReturnCount") //FIXME
    private boolean isToNotify(Reminder reminder) {
        final Optional<DiaryEntry> lastEntry =
            diaryEntryService.getLast(reminder.getTarget().getId(), reminder.getAction());
        final Date now = scheduleCalculator.now();
        if (reminder.getStart().after(now) ||
                reminder.getEnd() != null && reminder.getEnd().before(now)) {
            return false;
        }
        final Date lastCompletedAt = lastEntry.map(DiaryEntry::getDate).orElse(null);
        final Date dueAt = scheduleCalculator.calculateDueAt(reminder, lastCompletedAt);
        if (reminder.getEnd() != null && dueAt.after(reminder.getEnd())) {
            return false;
        }
        final Date actionAt = scheduleCalculator.calculateActionAt(reminder, dueAt);
        if (actionAt.after(now)) {
            return false;
        }
        if (reminder.getLastNotified() == null || reminder.getLastNotified().before(dueAt)) {
            return true;
        }
        if (reminder.getRepeatAfter() == null) {
            return false;
        }
        final Date repeatAt = scheduleCalculator.add(reminder.getLastNotified(), reminder.getRepeatAfter());
        return !repeatAt.after(now);
    }


    private void dispatchInternal(Reminder reminder) {
        final Set<NotificationDispatcher> notificationDispatchersToUse = getUserNotificationDispatcher(reminder);
        notificationDispatchersToUse.forEach(dispatcher -> {
            final Optional<AbstractNotificationDispatcherConfig> config =
                notificationDispatcherConfigImplRepository.findByServiceAndUser(dispatcher.getName(),
                                                                                reminder.getTarget().getOwner()
                );
            if (config.isPresent()) {
                logger.debug("Loading config for notification service {} for user {}", dispatcher.getName(),
                             reminder.getTarget().getOwner().getUsername()
                );
                dispatcher.loadConfig(config.get());
            } else {
                logger.debug("Unloading previous config for the service {}", dispatcher.getName());
                dispatcher.initConfig();
            }
            try {
                dispatcher.notifyReminder(reminder);
            } catch (NotifyException e) {
                logger.error("Error while dispatch reminder {} using dispatcher {}", reminder.getId(),
                             dispatcher.getName(), e
                );
            }
        });
        reminder.setLastNotified(scheduleCalculator.now());
        reminderRepository.save(reminder);
    }


    protected Set<NotificationDispatcher> getUserNotificationDispatcher(Reminder reminder) {
        final Set<NotificationDispatcherName> userNotificationDispatchers =
            reminder.getTarget().getOwner().getNotificationDispatchers();
        return notificationsDispatchers.stream().filter(NotificationDispatcher::isEnabled).filter(
                                           notificationDispatcher -> userNotificationDispatchers.contains(notificationDispatcher.getName()))
                                       .collect(Collectors.toSet());
    }
}
