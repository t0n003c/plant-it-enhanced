import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:plant_it/dto/hike_session_dto.dart';
import 'package:plant_it/dto/observation_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/observation/add_observation_page.dart';
import 'package:plant_it/observation/offline_hike_session.dart';
import 'package:plant_it/observation/offline_observation_draft.dart';
import 'package:plant_it/observation/trail_sync_service.dart';
import 'package:uuid/uuid.dart';

class ObservationJournalPage extends StatefulWidget {
  final Environment env;

  const ObservationJournalPage({
    super.key,
    required this.env,
  });

  @override
  State<ObservationJournalPage> createState() => _ObservationJournalPageState();
}

class _ObservationJournalPageState extends State<ObservationJournalPage> {
  List<ObservationDTO> _observations = [];
  List<OfflineObservationDraft> _drafts = [];
  List<OfflineHikeSession> _localHikes = [];
  List<HikeSessionDTO> _serverHikes = [];
  OfflineHikeSession? _activeHike;
  bool _loading = true;
  bool _syncing = false;
  String? _remoteError;

  TrailSyncService get _syncService => TrailSyncService(
        http: widget.env.http,
        repository: widget.env.trailDraftRepository,
        accountScope: widget.env.offlineAccountScope,
      );

  Future<void> _refresh({bool synchronize = true}) async {
    if (mounted) setState(() => _loading = true);
    await _loadLocal();
    await _loadRemote();
    if (synchronize && _hasPendingWork) {
      if (mounted) setState(() => _syncing = true);
      await _syncService.synchronizePending();
      await _loadLocal();
      await _loadRemote();
      if (mounted) setState(() => _syncing = false);
    }
    if (mounted) setState(() => _loading = false);
  }

  bool get _hasPendingWork {
    if (_drafts.isNotEmpty) return true;
    return _localHikes.any(
      (session) => session.syncState != TrailSyncState.synced,
    );
  }

  Future<void> _loadLocal() async {
    final results = await Future.wait([
      widget.env.trailDraftRepository
          .listObservationDrafts(widget.env.offlineAccountScope),
      widget.env.trailDraftRepository
          .listHikeSessions(widget.env.offlineAccountScope),
    ]);
    final drafts = results[0] as List<OfflineObservationDraft>;
    final hikes = results[1] as List<OfflineHikeSession>;
    OfflineHikeSession? active;
    for (final session in hikes) {
      if (session.isActive) {
        active = session;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _drafts = drafts;
      _localHikes = hikes;
      _activeHike = active;
    });
  }

  Future<void> _loadRemote() async {
    try {
      final responses = await Future.wait([
        widget.env.http.get(
          'observation?pageSize=100&sortBy=observedAt&sortDir=DESC',
        ),
        widget.env.http.get('hike-session'),
      ]);
      if (responses.any((response) => response.statusCode != 200)) {
        throw Exception('The field journal server is unavailable');
      }
      final Map<String, dynamic> page = json
          .decode(utf8.decode(responses[0].bodyBytes)) as Map<String, dynamic>;
      final List<dynamic> content = page['content'] as List<dynamic>? ?? [];
      final List<dynamic> hikeContent =
          json.decode(utf8.decode(responses[1].bodyBytes)) as List<dynamic>;
      final hikes = hikeContent
          .map((item) => HikeSessionDTO.fromJson(item as Map<String, dynamic>))
          .toList();
      await _mirrorServerHikes(hikes);
      if (!mounted) return;
      setState(() {
        _observations = content
            .map(
              (item) => ObservationDTO.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
        _serverHikes = hikes;
        _remoteError = null;
      });
      await _loadLocal();
    } catch (error, stackTrace) {
      widget.env.logger.warning('Could not refresh Trail Journal: $error');
      widget.env.logger.debug(stackTrace);
      if (!mounted) return;
      setState(() {
        _remoteError = widget.env.durableTrailStorage
            ? AppLocalizations.of(context).trailJournalOffline
            : AppLocalizations.of(context).offlineStorageUnavailable;
      });
    }
  }

  Future<void> _mirrorServerHikes(List<HikeSessionDTO> hikes) async {
    final local = await widget.env.trailDraftRepository
        .listHikeSessions(widget.env.offlineAccountScope);
    for (final server in hikes) {
      OfflineHikeSession? match;
      for (final candidate in local) {
        if (candidate.serverId == server.id ||
            server.clientReference == candidate.localId) {
          match = candidate;
          break;
        }
      }
      if (match != null && match.syncState != TrailSyncState.synced) {
        continue;
      }
      final OfflineHikeSession mirrored = match ??
          OfflineHikeSession(
            localId: server.clientReference ?? 'server-hike-${server.id}',
            accountScope: widget.env.offlineAccountScope,
            name: server.name,
            startedAt: server.startedAt,
            updatedAt: DateTime.now(),
          );
      mirrored.serverId = server.id;
      mirrored.name = server.name;
      mirrored.startedAt = server.startedAt;
      mirrored.endedAt = server.endedAt;
      mirrored.notes = server.notes;
      mirrored.syncState = TrailSyncState.synced;
      mirrored.lastError = null;
      mirrored.updatedAt = DateTime.now();
      await widget.env.trailDraftRepository.saveHikeSession(mirrored);
    }
  }

  Future<void> _addObservation() async {
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddObservationPage(
          env: widget.env,
          activeHike: _activeHike,
        ),
      ),
    );
    if (created == true) await _refresh();
  }

  Future<void> _editDraft(OfflineObservationDraft draft) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddObservationPage(
          env: widget.env,
          initialDraft: draft,
        ),
      ),
    );
    if (changed == true) await _refresh();
  }

  Future<void> _retryDraft(OfflineObservationDraft draft) async {
    setState(() {
      draft.syncState = TrailSyncState.syncing;
      _syncing = true;
    });
    await _syncService.synchronizeObservation(draft.localId);
    await _refresh(synchronize: false);
    if (mounted) setState(() => _syncing = false);
  }

  Future<void> _deleteDraft(OfflineObservationDraft draft) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).discardOfflineDraft),
        content: Text(AppLocalizations.of(context).discardOfflineDraftConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context).discard),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      if (draft.serverObservationId != null) {
        final response = await widget.env.http.delete(
          'observation/${draft.serverObservationId}',
        );
        if (response.statusCode != 200) {
          throw Exception('Could not delete the synchronized observation');
        }
      }
      await widget.env.trailDraftRepository.deleteObservationDraft(
        widget.env.offlineAccountScope,
        draft.localId,
      );
      await _loadLocal();
    } catch (error, stackTrace) {
      widget.env.logger.warning('Could not discard offline draft: $error');
      widget.env.logger.debug(stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).discardNeedsConnection),
        ),
      );
    }
  }

  Future<void> _startHike() async {
    if (!widget.env.durableTrailStorage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).offlineStorageUnavailable),
        ),
      );
      return;
    }
    final TextEditingController nameController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).startHike),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('hike-name-field'),
              controller: nameController,
              autofocus: true,
              maxLength: 120,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).hikeName,
                hintText: AppLocalizations.of(context).hikeNameHint,
              ),
            ),
            TextField(
              controller: notesController,
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).hikeNotesOptional,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            key: const ValueKey('confirm-start-hike'),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text(AppLocalizations.of(context).startHike),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      nameController.dispose();
      notesController.dispose();
      return;
    }
    final DateTime now = DateTime.now();
    final session = OfflineHikeSession(
      localId: const Uuid().v4(),
      accountScope: widget.env.offlineAccountScope,
      name: nameController.text.trim(),
      notes: notesController.text.trim(),
      startedAt: now,
      updatedAt: now,
    );
    nameController.dispose();
    notesController.dispose();
    await widget.env.trailDraftRepository.saveHikeSession(session);
    await _loadLocal();
    if (mounted) setState(() => _syncing = true);
    await _syncService.synchronizeHikeSession(session.localId);
    await _refresh(synchronize: false);
    if (mounted) setState(() => _syncing = false);
  }

  Future<void> _endHike() async {
    final OfflineHikeSession? active = _activeHike;
    if (active == null) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).finishHike),
        content: Text(AppLocalizations.of(context).finishHikeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context).finishHike),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    active.endedAt = DateTime.now();
    active.syncState = TrailSyncState.pending;
    active.updatedAt = DateTime.now();
    await widget.env.trailDraftRepository.saveHikeSession(active);
    await _loadLocal();
    if (mounted) setState(() => _syncing = true);
    await _syncService.synchronizeHikeSession(active.localId);
    await _refresh(synchronize: false);
    if (mounted) setState(() => _syncing = false);
  }

  Future<void> _deleteObservation(ObservationDTO observation) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteObservation),
        content: Text(AppLocalizations.of(context).deleteObservationConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context).deleteObservation),
          ),
        ],
      ),
    );
    if (confirmed != true || observation.id == null) return;
    try {
      final response =
          await widget.env.http.delete('observation/${observation.id}');
      if (response.statusCode != 200) {
        throw Exception('Delete returned ${response.statusCode}');
      }
      if (!mounted) return;
      setState(() => _observations.remove(observation));
    } catch (error, stackTrace) {
      widget.env.logger.error(error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).generalError)),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).trailJournal),
        actions: [
          if (_syncing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              tooltip: AppLocalizations.of(context).syncNow,
              onPressed: _refresh,
              icon: const Icon(Icons.sync),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addObservation,
        icon: const Icon(Icons.camera_alt_outlined),
        label: Text(AppLocalizations.of(context).recordTrailFind),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _drafts.isEmpty && _observations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final List<Widget> children = [
      _HikeSessionCard(
        activeHike: _activeHike,
        recentHikes: _serverHikes,
        pendingSessionCount: _localHikes
            .where(
              (session) => session.syncState != TrailSyncState.synced,
            )
            .length,
        onStart: _startHike,
        onEnd: _endHike,
        onRetry: _localHikes.every(
          (session) => session.syncState == TrailSyncState.synced,
        )
            ? null
            : () async {
                setState(() => _syncing = true);
                await _syncService.synchronizePending();
                await _refresh(synchronize: false);
                if (mounted) setState(() => _syncing = false);
              },
      ),
    ];
    if (_remoteError != null) {
      children.add(_offlineBanner(context));
    }
    if (_drafts.isNotEmpty) {
      children.add(
        _sectionTitle(
          context,
          AppLocalizations.of(context).offlineDraftCount(_drafts.length),
          Icons.cloud_upload_outlined,
        ),
      );
      children.addAll(
        _drafts.map(
          (draft) => _OfflineDraftCard(
            draft: draft,
            onRetry: () => _retryDraft(draft),
            onEdit: () => _editDraft(draft),
            onDelete: () => _deleteDraft(draft),
          ),
        ),
      );
    }
    if (_observations.isNotEmpty) {
      children.add(
        _sectionTitle(
          context,
          AppLocalizations.of(context).savedTrailFinds,
          Icons.auto_stories_outlined,
        ),
      );
      children.addAll(
        _observations.map(
          (observation) => _ObservationCard(
            observation: observation,
            env: widget.env,
            onDelete: () => _deleteObservation(observation),
          ),
        ),
      );
    }
    if (_drafts.isEmpty && _observations.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 52, 24, 140),
          child: Column(
            children: [
              const Icon(
                Icons.hiking_outlined,
                size: 72,
                color: Color(0xFF9BE59F),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context).noTrailObservations,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, height: 1.4),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _addObservation,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(AppLocalizations.of(context).recordTrailFind),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 120),
      children: children
          .expand((child) => [child, const SizedBox(height: 10)])
          .toList(),
    );
  }

  Widget _offlineBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD166).withOpacity(.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD166)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: Color(0xFFFFD166)),
          const SizedBox(width: 10),
          Expanded(child: Text(_remoteError!)),
          TextButton(
            onPressed: _refresh,
            child: Text(AppLocalizations.of(context).retry),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 2),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9BE59F)),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _HikeSessionCard extends StatelessWidget {
  final OfflineHikeSession? activeHike;
  final List<HikeSessionDTO> recentHikes;
  final int pendingSessionCount;
  final VoidCallback onStart;
  final VoidCallback onEnd;
  final VoidCallback? onRetry;

  const _HikeSessionCard({
    required this.activeHike,
    required this.recentHikes,
    required this.pendingSessionCount,
    required this.onStart,
    required this.onEnd,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final OfflineHikeSession? active = activeHike;
    return Card(
      color: const Color(0xFF213B32),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.hiking_outlined, color: Color(0xFF9BE59F)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    active?.name ?? AppLocalizations.of(context).hikeSessions,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
                if (active != null) _syncIcon(active.syncState),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              active == null
                  ? AppLocalizations.of(context).hikeSessionIntro
                  : AppLocalizations.of(context).hikeStarted(
                      DateFormat.jm().format(active.startedAt.toLocal()),
                    ),
              style: const TextStyle(color: Colors.white70),
            ),
            if (active?.lastError != null) ...[
              const SizedBox(height: 6),
              Text(
                active!.lastError!,
                style: const TextStyle(color: Color(0xFFFFD166)),
              ),
            ],
            if (pendingSessionCount > 0 && active?.lastError == null) ...[
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context)
                    .hikeSyncPending(pendingSessionCount),
                style: const TextStyle(color: Color(0xFFFFD166)),
              ),
            ],
            const SizedBox(height: 12),
            if (active == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('start-hike-button'),
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(AppLocalizations.of(context).startHike),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.sync),
                      label: Text(AppLocalizations.of(context).retrySync),
                    ),
                  ],
                ],
              )
            else
              Row(
                children: [
                  if (active.syncState == TrailSyncState.failed &&
                      onRetry != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.sync),
                        label: Text(AppLocalizations.of(context).retry),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('finish-hike-button'),
                      onPressed: onEnd,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: Text(AppLocalizations.of(context).finishHike),
                    ),
                  ),
                ],
              ),
            if (recentHikes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)
                    .recentHikeCount(recentHikes.length),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _syncIcon(TrailSyncState state) {
    switch (state) {
      case TrailSyncState.synced:
        return const Icon(Icons.cloud_done_outlined, color: Color(0xFF9BE59F));
      case TrailSyncState.failed:
        return const Icon(Icons.sync_problem, color: Color(0xFFFFD166));
      case TrailSyncState.syncing:
        return const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case TrailSyncState.pending:
        return const Icon(Icons.cloud_upload_outlined, color: Colors.white70);
    }
  }
}

class _OfflineDraftCard extends StatelessWidget {
  final OfflineObservationDraft draft;
  final VoidCallback onRetry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OfflineDraftCard({
    required this.draft,
    required this.onRetry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = draft.syncState == TrailSyncState.failed
        ? const Color(0xFFFFD166)
        : const Color(0xFF9BE59F);
    return Card(
      color: const Color(0xFF182C25),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: draft.photos.isEmpty
                      ? Container(
                          width: 64,
                          height: 64,
                          color: const Color(0xFF27483D),
                          child: const Icon(Icons.local_florist_outlined),
                        )
                      : Image.memory(
                          draft.photos.first.bytes,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.displayName?.trim().isNotEmpty == true
                            ? draft.displayName!.trim()
                            : AppLocalizations.of(context)
                                .unidentifiedTrailFind,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (draft.hikeSessionName != null)
                        Text(
                          draft.hikeSessionName!,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            draft.syncState == TrailSyncState.failed
                                ? Icons.sync_problem
                                : Icons.cloud_upload_outlined,
                            size: 17,
                            color: statusColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _statusText(context),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (draft.lastError != null) ...[
              const SizedBox(height: 8),
              Text(
                draft.lastError!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFFFD166)),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(AppLocalizations.of(context).edit),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: draft.syncState == TrailSyncState.syncing
                        ? null
                        : onRetry,
                    icon: const Icon(Icons.sync),
                    label: Text(AppLocalizations.of(context).retrySync),
                  ),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context).discard,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusText(BuildContext context) {
    switch (draft.syncState) {
      case TrailSyncState.pending:
        return AppLocalizations.of(context).waitingToSync;
      case TrailSyncState.syncing:
        return AppLocalizations.of(context).syncing;
      case TrailSyncState.failed:
        return AppLocalizations.of(context).syncFailed;
      case TrailSyncState.synced:
        return AppLocalizations.of(context).synced;
    }
  }
}

class _ObservationCard extends StatelessWidget {
  final ObservationDTO observation;
  final Environment env;
  final VoidCallback onDelete;

  const _ObservationCard({
    required this.observation,
    required this.env,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool confirmed = observation.status == 'CONFIRMED';
    final String observed = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).add_jm().format(observation.observedAt.toLocal());
    return Card(
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFF182C25),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        leading: _buildPhoto(),
        title: Text(
          observation.bestDisplayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (observation.scientificName != null &&
                observation.scientificName != observation.bestDisplayName)
              Text(
                observation.scientificName!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
            Text(observed, style: const TextStyle(color: Colors.white70)),
            if (observation.hikeSessionName != null)
              Text(
                observation.hikeSessionName!,
                style: const TextStyle(color: Color(0xFF9BE59F)),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          tooltip: MaterialLocalizations.of(context).showMenuTooltip,
          onSelected: (value) {
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Text(AppLocalizations.of(context).deleteObservation),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            children: [
              Icon(
                confirmed ? Icons.verified_outlined : Icons.help_outline,
                size: 19,
                color: confirmed
                    ? const Color(0xFF9BE59F)
                    : const Color(0xFFFFD166),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  confirmed
                      ? AppLocalizations.of(context).confirmedIdentification
                      : AppLocalizations.of(context).needsIdentification,
                ),
              ),
            ],
          ),
          if (observation.hikeSessionName?.isNotEmpty == true)
            _detail(Icons.hiking_outlined, observation.hikeSessionName!),
          if (observation.trailName?.isNotEmpty == true)
            _detail(Icons.route_outlined, observation.trailName!),
          if (observation.habitat?.isNotEmpty == true)
            _detail(Icons.forest_outlined, observation.habitat!),
          if (observation.notes?.isNotEmpty == true)
            _detail(Icons.notes_outlined, observation.notes!),
          if (observation.latitude != null)
            _detail(
              Icons.lock_outline,
              AppLocalizations.of(context).exactLocationPrivate,
            ),
        ],
      ),
    );
  }

  Widget _buildPhoto() {
    if (observation.imageIds.isEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF27483D),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.local_florist_outlined, color: Colors.white70),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl:
            '${env.http.backendUrl}image/content/${observation.imageIds.first}',
        httpHeaders: {
          if (env.http.key != null) 'Key': env.http.key!,
          if (env.http.jwt != null) 'Authorization': 'Bearer ${env.http.jwt}',
        },
        imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(
          width: 64,
          height: 64,
          color: const Color(0xFF27483D),
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
