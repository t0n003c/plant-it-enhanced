import 'package:flutter/material.dart';
import 'package:plant_it/app_layout.dart';
import 'package:plant_it/app_extended_floating_action_button.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/event/add_new_event.dart';
import 'package:plant_it/event/events_done_section.dart';
import 'package:plant_it/floating_tabbar.dart';
import 'package:plant_it/event/reminder_section.dart';
import 'package:plant_it/event/today_care_section.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EventsPage extends StatefulWidget {
  final Environment env;

  const EventsPage({super.key, required this.env});

  @override
  State<StatefulWidget> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  int _activeIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _activeIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget getCurrentSection() {
      if (_activeIndex == 0) {
        return TodayCareSection(env: widget.env);
      } else if (_activeIndex == 1) {
        return ReminderSection(env: widget.env);
      } else {
        return EventsDoneSection(
          env: widget.env,
          includeUpcomingCareTasks: true,
        );
      }
    }

    return Scaffold(
      floatingActionButton: AppExtendedFloatingActionButton(
        key: const ValueKey<String>('calendar-add-event'),
        heroTag: 'calendar-add-event',
        onPressed: () => Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => AddNewEventPage(env: widget.env),
          ),
        ),
        icon: Icons.event_available_outlined,
        label: AppLocalizations.of(context).addNewEvent,
        tooltip: AppLocalizations.of(context).addNewEvent,
      ),
      body: AppContent(
        child: Column(
          children: [
            AppPageHeader(
              icon: Icons.calendar_month_rounded,
              title: AppLocalizations.of(context).calendar,
              subtitle: AppLocalizations.of(context).careCalendarSubtitle,
            ),
            FloatingTabBar(
              selectedIndex: _activeIndex,
              titles: [
                AppLocalizations.of(context).careTasks,
                AppLocalizations.of(context).calendar,
                AppLocalizations.of(context).events,
              ],
              onSelected: _onTabSelected,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: getCurrentSection(),
            ),
          ],
        ),
      ),
    );
  }
}
