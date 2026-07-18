import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/observation/add_observation_page.dart';
import 'package:plant_it/observation/observation_journal_page.dart';

class TrailJournalEntryCard extends StatefulWidget {
  final Environment env;

  const TrailJournalEntryCard({
    super.key,
    required this.env,
  });

  @override
  State<TrailJournalEntryCard> createState() => _TrailJournalEntryCardState();
}

class _TrailJournalEntryCardState extends State<TrailJournalEntryCard> {
  int? _observationCount;

  Future<void> _loadCount() async {
    try {
      final response = await widget.env.http.get('observation/_count');
      if (response.statusCode != 200 || !mounted) return;
      setState(() => _observationCount = int.tryParse(response.body));
    } catch (error, stackTrace) {
      widget.env.logger.debug('Could not load observation count: $error');
      widget.env.logger.debug(stackTrace);
    }
  }

  Future<void> _openJournal() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => ObservationJournalPage(env: widget.env),
      ),
    );
    await _loadCount();
  }

  Future<void> _recordObservation() async {
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddObservationPage(env: widget.env),
      ),
    );
    if (created == true) await _loadCount();
  }

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Card(
        color: const Color(0xFF182C25),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF315D4E),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.hiking_outlined,
                      color: Color(0xFFC7F9CC),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).trailJournal,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_observationCount != null)
                          Text(
                            AppLocalizations.of(context)
                                .trailObservationCount(_observationCount!),
                            style: const TextStyle(color: Colors.white70),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context).trailJournalSubtitle,
                style: const TextStyle(color: Colors.white70, height: 1.35),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _recordObservation,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: const Color(0xFFC7F9CC),
                  foregroundColor: const Color(0xFF10231C),
                ),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(AppLocalizations.of(context).recordTrailFind),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _openJournal,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                ),
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(AppLocalizations.of(context).viewTrailJournal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
