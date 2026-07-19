import 'package:flutter/material.dart';
import 'package:plant_it/app_layout.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/homepage/homepage_header.dart';
import 'package:plant_it/homepage/plant_list.dart';
import 'package:plant_it/event/recent_events.dart';
import 'package:plant_it/homepage/care_tools_card.dart';

class HomePage extends StatelessWidget {
  final Environment env;
  const HomePage({
    super.key,
    required this.env,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: AppContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomePageHeader(
              username: env.credentials.username,
              plantCount: env.plants.length,
            ),
            PlantList(env: env),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final Widget careTools = HomeCareToolsCard(env: env);
                final Widget recentEvents = RecentEvents(env: env);
                if (constraints.maxWidth < 820) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      careTools,
                      const SizedBox(height: 22),
                      recentEvents,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: careTools),
                    const SizedBox(width: 20),
                    Expanded(child: recentEvents),
                  ],
                );
              },
            ),
            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }
}
