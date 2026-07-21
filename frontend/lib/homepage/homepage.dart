import 'package:flutter/material.dart';
import 'package:plant_it/app_layout.dart';
import 'package:plant_it/change_notifiers.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/homepage/homepage_header.dart';
import 'package:plant_it/homepage/plant_list.dart';
import 'package:plant_it/event/recent_events.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  final Environment env;
  const HomePage({
    super.key,
    required this.env,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  EventsNotifier? _eventsNotifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final EventsNotifier? nextNotifier =
        Provider.of<EventsNotifier?>(context, listen: false);
    if (identical(_eventsNotifier, nextNotifier)) return;
    _eventsNotifier?.removeListener(_handlePlantsChanged);
    _eventsNotifier = nextNotifier;
    _eventsNotifier?.addListener(_handlePlantsChanged);
  }

  void _handlePlantsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _eventsNotifier?.removeListener(_handlePlantsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: AppContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomePageHeader(
              username: widget.env.credentials.username,
              plantCount: widget.env.plants.length,
            ),
            PlantList(env: widget.env),
            const SizedBox(height: 20),
            RecentEvents(env: widget.env),
            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }
}
