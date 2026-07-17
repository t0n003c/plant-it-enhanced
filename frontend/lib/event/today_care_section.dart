import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/app_exception.dart';
import 'package:plant_it/change_notifiers.dart';
import 'package:plant_it/commons.dart';
import 'package:plant_it/dto/care_task_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/toast/toast_manager.dart';
import 'package:provider/provider.dart';

class TodayCareSection extends StatefulWidget {
  final Environment env;

  const TodayCareSection({super.key, required this.env});

  @override
  State<TodayCareSection> createState() => _TodayCareSectionState();
}

class _TodayCareSectionState extends State<TodayCareSection> {
  List<CareTaskDTO> _tasks = [];
  bool _loading = true;
  String? _error;
  int? _activeReminderId;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final response = await widget.env.http.get('care-tasks?days=7');
      if (response.statusCode != 200) {
        throw AppException('Failed to load care tasks');
      }
      final List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
      if (!mounted) return;
      setState(() {
        _tasks = body
            .map((item) => CareTaskDTO.fromJson(item as Map<String, dynamic>))
            .toList();
      });
    } catch (error, stackTrace) {
      widget.env.logger.error(error, stackTrace);
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _complete(CareTaskDTO task) async {
    await _performAction(
      task,
      'care-tasks/${task.reminderId}/complete',
      {},
      AppLocalizations.of(context).careTaskCompleted,
    );
    if (mounted) {
      Provider.of<EventsNotifier>(context, listen: false).notify();
    }
  }

  Future<void> _skip(CareTaskDTO task) async {
    await _performAction(
      task,
      'care-tasks/${task.reminderId}/skip',
      {},
      AppLocalizations.of(context).careTaskSkipped,
    );
  }

  Future<void> _snooze(CareTaskDTO task, Duration duration) async {
    final DateTime until = DateTime.now().add(duration);
    await _performAction(
      task,
      'care-tasks/${task.reminderId}/snooze',
      {'until': until.toIso8601String()},
      AppLocalizations.of(context).careTaskSnoozed,
    );
  }

  Future<void> _performAction(
    CareTaskDTO task,
    String endpoint,
    Map<String, dynamic> body,
    String successMessage,
  ) async {
    setState(() => _activeReminderId = task.reminderId);
    try {
      final response = await widget.env.http.post(endpoint, body);
      if (response.statusCode != 204) {
        throw AppException('Care task action failed');
      }
      if (!mounted) return;
      widget.env.toastManager.showToast(
        context,
        ToastNotificationType.success,
        successMessage,
      );
      await _loadTasks();
    } catch (error, stackTrace) {
      widget.env.logger.error(error, stackTrace);
      if (!mounted) return;
      widget.env.toastManager.showToast(
        context,
        ToastNotificationType.error,
        AppLocalizations.of(context).generalError,
      );
    } finally {
      if (mounted) setState(() => _activeReminderId = null);
    }
  }

  void _showSnoozeOptions(CareTaskDTO task) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color.fromRGBO(24, 44, 37, 1),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(context).snoozeFor,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _SnoozeOption(
                label: AppLocalizations.of(context).oneDay,
                onPressed: () => _chooseSnooze(task, const Duration(days: 1)),
              ),
              _SnoozeOption(
                label: AppLocalizations.of(context).threeDays,
                onPressed: () => _chooseSnooze(task, const Duration(days: 3)),
              ),
              _SnoozeOption(
                label: AppLocalizations.of(context).oneWeek,
                onPressed: () => _chooseSnooze(task, const Duration(days: 7)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _chooseSnooze(CareTaskDTO task, Duration duration) {
    Navigator.of(context).pop();
    _snooze(task, duration);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context).careTasksLoadError),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadTasks,
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      );
    }
    if (_tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadTasks,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Icon(Icons.eco_outlined, size: 64, color: Colors.green.shade300),
            const SizedBox(height: 16),
            Center(child: Text(AppLocalizations.of(context).allCaughtUp)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return _CareTaskCard(
            task: task,
            busy: _activeReminderId == task.reminderId,
            onComplete: () => _complete(task),
            onSkip: () => _skip(task),
            onSnooze: () => _showSnoozeOptions(task),
          );
        },
      ),
    );
  }
}

class _CareTaskCard extends StatelessWidget {
  final CareTaskDTO task;
  final bool busy;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final VoidCallback onSnooze;

  const _CareTaskCard({
    required this.task,
    required this.busy,
    required this.onComplete,
    required this.onSkip,
    required this.onSnooze,
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
            if (_actionable) ...[
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

class _SnoozeOption extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SnoozeOption({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Align(alignment: Alignment.centerLeft, child: Text(label)),
    );
  }
}
