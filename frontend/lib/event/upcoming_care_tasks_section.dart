import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/app_exception.dart';
import 'package:plant_it/app_layout.dart';
import 'package:plant_it/dto/care_task_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/event/care_task_card.dart';

class UpcomingCareTasksSection extends StatefulWidget {
  final Environment env;

  const UpcomingCareTasksSection({super.key, required this.env});

  @override
  State<UpcomingCareTasksSection> createState() =>
      _UpcomingCareTasksSectionState();
}

class _UpcomingCareTasksSectionState extends State<UpcomingCareTasksSection> {
  List<CareTaskDTO> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_tasks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: AppLocalizations.of(context).careTasks,
        ),
        ..._tasks.map(
          (task) => CareTaskCard(
            task: task,
            showActions: false,
          ),
        ),
      ],
    );
  }
}
