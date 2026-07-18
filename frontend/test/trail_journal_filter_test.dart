import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/dto/observation_dto.dart';
import 'package:plant_it/observation/offline_observation_draft.dart';
import 'package:plant_it/observation/trail_journal_filter.dart';

void main() {
  final DateTime observedAt = DateTime(2026, 7, 18, 10, 30);
  final ObservationDTO confirmed = ObservationDTO(
    id: 1,
    observedAt: observedAt,
    scientificName: 'Monarda fistulosa',
    preferredCommonName: 'Wild bergamot',
    trailName: 'Prairie Loop',
    habitat: 'Prairie edge',
    hikeSessionId: 7,
    status: 'CONFIRMED',
  );
  final ObservationDTO unidentified = ObservationDTO(
    id: 2,
    observedAt: observedAt.add(const Duration(hours: 1)),
    displayName: 'Yellow trail flower',
    trailName: 'River Walk',
    hikeSessionId: 8,
  );
  final OfflineObservationDraft draft = OfflineObservationDraft(
    localId: 'draft-1',
    accountScope: 'server|hiker',
    createdAt: observedAt,
    updatedAt: observedAt,
    observedAt: observedAt,
    selectedTaxon: {
      'scientificName': 'Rosa carolina',
      'preferredCommonName': 'Carolina rose',
    },
    hikeSessionLocalId: 'local-hike-1',
    hikeSessionName: 'Woodland Hike',
    habitat: 'Woodland opening',
    photos: [],
  );

  test('filters saved observations by status, query, hike, and date', () {
    const TrailJournalFilter needsIdentification = TrailJournalFilter(
      status: TrailJournalStatusFilter.needsIdentification,
    );
    expect(needsIdentification.matchesObservation(confirmed), isFalse);
    expect(needsIdentification.matchesObservation(unidentified), isTrue);

    const TrailJournalFilter query = TrailJournalFilter(query: 'bergamot');
    expect(query.matchesObservation(confirmed), isTrue);
    expect(query.matchesObservation(unidentified), isFalse);

    const TrailJournalFilter hike = TrailJournalFilter(hikeKey: 'remote:7');
    expect(hike.matchesObservation(confirmed), isTrue);
    expect(hike.matchesObservation(unidentified), isFalse);

    final TrailJournalFilter date = TrailJournalFilter(
      from: DateTime(2026, 7, 18),
      through: DateTime(2026, 7, 18),
    );
    expect(date.matchesObservation(confirmed), isTrue);
    expect(
      date.matchesObservation(
        ObservationDTO(observedAt: DateTime(2026, 7, 19)),
      ),
      isFalse,
    );
  });

  test('filters offline drafts without losing local hike or taxon names', () {
    const TrailJournalFilter pending = TrailJournalFilter(
      status: TrailJournalStatusFilter.pendingSync,
    );
    expect(pending.matchesDraft(draft), isTrue);
    expect(pending.matchesObservation(unidentified), isFalse);

    const TrailJournalFilter commonName = TrailJournalFilter(query: 'rose');
    expect(commonName.matchesDraft(draft), isTrue);

    const TrailJournalFilter habitat = TrailJournalFilter(query: 'opening');
    expect(habitat.matchesDraft(draft), isTrue);

    const TrailJournalFilter hike = TrailJournalFilter(
      hikeKey: 'local:local-hike-1',
    );
    expect(hike.matchesDraft(draft), isTrue);
  });

  test('keeps a partially synchronized find visible only as its retry draft',
      () {
    final OfflineObservationDraft retryDraft = OfflineObservationDraft(
      localId: 'retry-draft',
      accountScope: 'server|hiker',
      createdAt: observedAt,
      updatedAt: observedAt,
      observedAt: observedAt,
      serverObservationId: confirmed.id,
      displayName: 'Partially synchronized find',
      photos: [],
      syncState: TrailSyncState.failed,
    );

    final List<ObservationDTO> result =
        TrailJournalFilter.deduplicateRemoteObservations(
      [confirmed, unidentified],
      [retryDraft],
    );

    expect(result, [unidentified]);
  });
}
