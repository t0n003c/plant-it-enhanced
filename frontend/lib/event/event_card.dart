import 'package:flutter/material.dart';
import 'package:plant_it/commons.dart';
import 'package:plant_it/dto/event_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/event/edit_event.dart';

class EventCard extends StatelessWidget {
  final Environment env;
  final String action;
  final String plant;
  final DateTime date;
  final EventDTO eventDTO;

  const EventCard({
    super.key,
    required this.env,
    required this.action,
    required this.plant,
    required this.date,
    required this.eventDTO,
  });

  String _formatTimePassed(BuildContext context, Duration timePassed) {
    if (timePassed.inDays == 0) {
      return AppLocalizations.of(context).today;
    } else if (timePassed.inDays == 1) {
      return AppLocalizations.of(context).yesterday;
    } else if (timePassed.inDays < 30) {
      if (timePassed.inDays > 0) {
        return AppLocalizations.of(context).nDaysAgo(timePassed.inDays);
      } else {
        return AppLocalizations.of(context)
            .nDaysInFuture(timePassed.inDays.abs());
      }
    } else if (timePassed.inDays < 365) {
      final months = (timePassed.inDays / 30).floor();
      return AppLocalizations.of(context).nMonthsAgo(months);
    } else {
      final years = (timePassed.inDays / 365).floor();
      return AppLocalizations.of(context).nYearsAgo(years);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color accent = typeColors[action] ?? colors.primary;
    final timePassed = DateTime.now().difference(date);
    final String formattedDate =
        MaterialLocalizations.of(context).formatMediumDate(date);
    final formattedTimePassed = _formatTimePassed(context, timePassed);
    final IconData actionIcon = typeIcons[action] ?? Icons.info_outline;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => goToPageSlidingUp(
          context,
          EditEventPage(env: env, eventDTO: eventDTO),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(actionIcon,
                    color: accent.computeLuminance() < .35
                        ? colors.onSurface
                        : accent),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getLocaleEvent(context, action),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (plant.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        plant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Text(
                      '$formattedDate · $formattedTimePassed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
