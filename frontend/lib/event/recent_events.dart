import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:plant_it/app_exception.dart';
import 'package:plant_it/app_layout.dart';
import 'package:plant_it/dto/event_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/event/event_card.dart';
import 'package:plant_it/change_notifiers.dart';
import 'package:plant_it/theme.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class RecentEvents extends StatefulWidget {
  final Environment env;
  const RecentEvents({
    super.key,
    required this.env,
  });

  @override
  State<StatefulWidget> createState() => _RecentEventsState();
}

class _RecentEventsState extends State<RecentEvents> {
  final int _pageSize = 5;
  bool _isLoading = true;
  String? _errorMessage;
  List<Widget> _recentEvents = [];
  late final EventsNotifier _eventsNotifier;

  @override
  void initState() {
    super.initState();
    _eventsNotifier = Provider.of<EventsNotifier>(context, listen: false);
    _eventsNotifier.addListener(_fetchRecentEvents);
    _fetchRecentEvents();
  }

  @override
  void dispose() {
    _eventsNotifier.removeListener(_fetchRecentEvents);
    super.dispose();
  }

  Future<void> _fetchRecentEvents() async {
    if (mounted) {
      setState(() {
        _errorMessage = null;
        _createDummyEventSkeletons();
      });
    }
    try {
      final response =
          await widget.env.http.get("diary/entry?pageNo=0&pageSize=$_pageSize");
      if (response.statusCode != 200) {
        throw AppException('Failed to load events');
      }
      final responseBody = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> entries = responseBody["content"];
      final List<EventCard> newEvents = entries.map((entry) {
        return EventCard(
          action: entry["type"],
          plant: entry["diaryTargetPersonalName"],
          date: DateTime.parse(entry["date"]),
          eventDTO: EventDTO.fromJson(entry),
          env: widget.env,
        );
      }).toList();
      if (!mounted) return;
      setState(() => _recentEvents = newEvents);
    } catch (error, stackTrace) {
      widget.env.logger.error(error, stackTrace);
      if (!mounted) return;
      setState(() {
        _recentEvents = [];
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _createDummyEventSkeletons() {
    _isLoading = true;
    _recentEvents = List.generate(
      _pageSize,
      (index) => Skeletonizer(
        enabled: _isLoading,
        effect: skeletonizerEffect,
        child: EventCard(
          action: "",
          plant: "",
          date: DateTime.now(),
          eventDTO: EventDTO(
            date: DateTime.now(),
            diaryId: 42,
            type: "42",
          ),
          env: widget.env,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: AppLocalizations.of(context).activity,
          subtitle: AppLocalizations.of(context).recentActivitySubtitle,
        ),
        if (_errorMessage != null)
          Card(
            child: AppEmptyState(
              icon: Icons.cloud_off_outlined,
              title: AppLocalizations.of(context).generalError,
              action: OutlinedButton.icon(
                onPressed: _fetchRecentEvents,
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context).retry),
              ),
            ),
          )
        else if (!_isLoading && _recentEvents.isEmpty)
          Card(
            child: AppEmptyState(
              icon: Icons.history_rounded,
              title: AppLocalizations.of(context).noRecentActivity,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 30,
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _recentEvents,
          ),
      ],
    );
  }
}
