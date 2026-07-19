import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      localizations.careTools,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CareToolsPage(env: env),
                      ),
                    ),
                    child: Text(localizations.viewAll),
                  ),
                ],
              ),
            ),
            _HomeCareAction(
              key: const ValueKey<String>('home-health-check'),
              icon: Icons.health_and_safety_outlined,
              title: localizations.plantHealthCheck,
              subtitle: localizations.plantHealthCheckHomeHint,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PlantHealthPage(env: env),
                ),
              ),
            ),
            const Divider(height: 1),
            _HomeCareAction(
              key: const ValueKey<String>('home-light-check'),
              icon: Icons.wb_sunny_outlined,
              title: localizations.lightPlacementCheck,
              subtitle: localizations.lightPlacementHomeHint,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LightCheckPage(env: env),
                ),
              ),
            ),
          ],
        ),
      ),
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
    return ListTile(
      minVerticalPadding: 12,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colors.onPrimaryContainer),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
