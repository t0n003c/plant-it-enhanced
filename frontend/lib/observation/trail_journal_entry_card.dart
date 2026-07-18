import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/observation/add_observation_page.dart';
import 'package:plant_it/observation/offline_hike_session.dart';
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
  int _offlineDraftCount = 0;
  OfflineHikeSession? _activeHike;

  Future<void> _loadCount() async {
    try {
      final drafts = await widget.env.trailDraftRepository
          .listObservationDrafts(widget.env.offlineAccountScope);
      final activeHike = await widget.env.trailDraftRepository
          .getActiveHikeSession(widget.env.offlineAccountScope);
      if (mounted) {
        setState(() {
          _offlineDraftCount = drafts.length;
          _activeHike = activeHike;
        });
      }
    } catch (error, stackTrace) {
      widget.env.logger.debug('Could not load offline trail finds: $error');
      widget.env.logger.debug(stackTrace);
    }
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
        builder: (context) => AddObservationPage(
          env: widget.env,
          activeHike: _activeHike,
        ),
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
                        if (_observationCount != null || _offlineDraftCount > 0)
                          Text(
                            AppLocalizations.of(context).trailObservationCount(
                              (_observationCount ?? 0) + _offlineDraftCount,
                            ),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        if (_activeHike != null)
                          Text(
                            AppLocalizations.of(context)
                                .addingToHike(_activeHike!.name),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFC7F9CC),
                            ),
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
