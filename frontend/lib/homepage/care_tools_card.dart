import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/app_layout.dart';
import 'package:plant_it/care/care_tools_page.dart';
import 'package:plant_it/care/light_check_page.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/health/plant_health_page.dart';

class HomeCareToolsCard extends StatelessWidget {
  final Environment env;

  const HomeCareToolsCard({super.key, required this.env});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final Widget healthAction = _HomeCareAction(
      key: const ValueKey<String>('home-health-check'),
      icon: Icons.health_and_safety_outlined,
      title: localizations.plantHealthCheck,
      subtitle: localizations.plantHealthCheckHomeHint,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PlantHealthPage(env: env),
        ),
      ),
    );
    final Widget lightAction = _HomeCareAction(
      key: const ValueKey<String>('home-light-check'),
      icon: Icons.wb_sunny_outlined,
      title: localizations.lightPlacementCheck,
      subtitle: localizations.lightPlacementHomeHint,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LightCheckPage(env: env),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: localizations.careTools,
          subtitle: localizations.careToolsIntro,
          action: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CareToolsPage(env: env),
              ),
            ),
            child: Text(localizations.viewAll),
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 620) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: healthAction),
                      const VerticalDivider(width: 1),
                      Expanded(child: lightAction),
                    ],
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  healthAction,
                  const Divider(height: 1),
                  lightAction,
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HomeCareAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeCareAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colors.onPrimaryContainer),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded,
                  size: 20, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
