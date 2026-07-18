import 'package:plant_it/dto/observation_dto.dart';
import 'package:plant_it/observation/offline_observation_draft.dart';

enum TrailJournalStatusFilter {
  all,
  needsIdentification,
  confirmed,
  pendingSync,
}

class TrailJournalFilter {
  final String query;
  final TrailJournalStatusFilter status;
  final String? hikeKey;
  final DateTime? from;
  final DateTime? through;

  const TrailJournalFilter({
    this.query = '',
    this.status = TrailJournalStatusFilter.all,
    this.hikeKey,
    this.from,
    this.through,
  });

  bool matchesObservation(ObservationDTO observation) {
    if (!_matchesStatus(observation.status, pending: false)) return false;
    if (!_matchesDate(observation.observedAt)) return false;
    if (hikeKey != null &&
        hikeKey != remoteHikeKey(observation.hikeSessionId)) {
      return false;
    }
    return _matchesQuery([
      observation.displayName,
      observation.preferredCommonName,
      observation.scientificName,
      observation.trailName,
      observation.habitat,
      observation.hikeSessionName,
      observation.notes,
    ]);
  }

  bool matchesDraft(OfflineObservationDraft draft) {
    if (!_matchesStatus(draft.status, pending: true)) return false;
    if (!_matchesDate(draft.observedAt)) return false;
    if (hikeKey != null && hikeKey != draftHikeKey(draft)) return false;
    final dynamic scientificName = draft.selectedTaxon?['scientificName'];
    final dynamic preferredCommonName =
        draft.selectedTaxon?['preferredCommonName'];
    return _matchesQuery([
      draft.displayName,
      scientificName?.toString(),
      preferredCommonName?.toString(),
      draft.trailName,
      draft.habitat,
      draft.hikeSessionName,
      draft.notes,
    ]);
  }

  bool _matchesStatus(String value, {required bool pending}) {
    return switch (status) {
      TrailJournalStatusFilter.all => true,
      TrailJournalStatusFilter.needsIdentification => value != 'CONFIRMED',
      TrailJournalStatusFilter.confirmed => value == 'CONFIRMED',
      TrailJournalStatusFilter.pendingSync => pending,
    };
  }

  bool _matchesDate(DateTime value) {
    final DateTime local = value.toLocal();
    if (from != null && local.isBefore(_startOfDay(from!))) return false;
    if (through != null &&
        !local.isBefore(_startOfDay(through!).add(
          const Duration(days: 1),
        ))) {
      return false;
    }
    return true;
  }

  bool _matchesQuery(List<String?> values) {
    final String normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;
    return values.whereType<String>().any(
          (value) => value.toLowerCase().contains(normalizedQuery),
        );
  }

  DateTime _startOfDay(DateTime value) {
    final DateTime local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static String? remoteHikeKey(int? id) => id == null ? null : 'remote:$id';

  static String? draftHikeKey(OfflineObservationDraft draft) {
    if (draft.hikeSessionId != null) return remoteHikeKey(draft.hikeSessionId);
    return draft.hikeSessionLocalId == null
        ? null
        : 'local:${draft.hikeSessionLocalId}';
  }

  static List<ObservationDTO> deduplicateRemoteObservations(
    List<ObservationDTO> observations,
    List<OfflineObservationDraft> drafts,
  ) {
    final Set<int> pendingServerIds = drafts
        .map((draft) => draft.serverObservationId)
        .whereType<int>()
        .toSet();
    return observations
        .where(
          (observation) =>
              observation.id == null ||
              !pendingServerIds.contains(observation.id),
        )
        .toList(growable: false);
  }
}
