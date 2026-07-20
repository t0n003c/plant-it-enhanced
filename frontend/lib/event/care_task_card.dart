import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/commons.dart';
import 'package:plant_it/dto/care_task_dto.dart';

class CareTaskCard extends StatelessWidget {
  final CareTaskDTO task;
  final bool busy;
  final bool showActions;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final VoidCallback? onSnooze;

  const CareTaskCard({
    super.key,
    required this.task,
    this.busy = false,
    this.showActions = false,
    this.onComplete,
    this.onSkip,
    this.onSnooze,
  });

  bool get _actionable =>
      task.status == CareTaskStatus.overdue ||
      task.status == CareTaskStatus.dueToday;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final Color accent = _statusColor(task.status);
    final DateTime displayedDate =
        task.status == CareTaskStatus.snoozed ? task.actionAt : task.dueAt;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      color: const Color.fromRGBO(24, 44, 37, 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accent.withOpacity(.65)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: accent.withOpacity(.2),
                  foregroundColor: accent,
                  child: Icon(typeIcons[task.action] ?? Icons.eco_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.plantName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(getLocaleEvent(context, task.action)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(localizations, task.status),
                    style: TextStyle(color: accent, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              MaterialLocalizations.of(context).formatMediumDate(displayedDate),
              style: const TextStyle(color: Colors.grey),
            ),
            if (showActions && _actionable) ...[
              const SizedBox(height: 12),
              if (busy)
                const Center(child: CircularProgressIndicator())
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check),
                      label: Text(localizations.complete),
                    ),
                    OutlinedButton.icon(
                      onPressed: onSnooze,
                      icon: const Icon(Icons.snooze),
                      label: Text(localizations.snooze),
                    ),
                    TextButton(
                      onPressed: onSkip,
                      child: Text(localizations.skip),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(CareTaskStatus status) {
    switch (status) {
      case CareTaskStatus.overdue:
        return Colors.orangeAccent;
      case CareTaskStatus.dueToday:
        return Colors.lightGreenAccent;
      case CareTaskStatus.snoozed:
        return Colors.lightBlueAccent;
      case CareTaskStatus.upcoming:
        return Colors.grey;
    }
  }

  String _statusLabel(AppLocalizations localizations, CareTaskStatus status) {
    switch (status) {
      case CareTaskStatus.overdue:
        return localizations.overdue;
      case CareTaskStatus.dueToday:
        return localizations.dueToday;
      case CareTaskStatus.snoozed:
        return localizations.snoozed;
      case CareTaskStatus.upcoming:
        return localizations.upcoming;
    }
  }
}
