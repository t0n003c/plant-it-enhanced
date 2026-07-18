import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:plant_it/dto/observation_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/observation/add_observation_page.dart';

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
  bool _loading = true;
  String? _errorMessage;

  Future<void> _loadObservations() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final response = await widget.env.http.get(
        'observation?pageSize=100&sortBy=observedAt&sortDir=DESC',
      );
      if (response.statusCode != 200) {
        throw Exception('Observation request returned ${response.statusCode}');
      }
      final Map<String, dynamic> page =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final List<dynamic> content = page['content'] as List<dynamic>? ?? [];
      if (!mounted) return;
      setState(() {
        _observations = content
            .map(
                (item) => ObservationDTO.fromJson(item as Map<String, dynamic>))
            .toList();
      });
    } catch (error, stackTrace) {
      widget.env.logger.error(error, stackTrace);
      if (!mounted) return;
      setState(() {
        _errorMessage = AppLocalizations.of(context).trailJournalLoadError;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addObservation() async {
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddObservationPage(env: widget.env),
      ),
    );
    if (created == true) await _loadObservations();
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
    _loadObservations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).trailJournal)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addObservation,
        icon: const Icon(Icons.camera_alt_outlined),
        label: Text(AppLocalizations.of(context).recordTrailFind),
      ),
      body: RefreshIndicator(
        onRefresh: _loadObservations,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.cloud_off_outlined,
            size: 54,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: _loadObservations,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).retry),
            ),
          ),
        ],
      );
    }
    if (_observations.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 100, 24, 140),
        children: [
          const Icon(Icons.hiking_outlined, size: 72, color: Color(0xFF9BE59F)),
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
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 120),
      itemCount: _observations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final observation = _observations[index];
        return _ObservationCard(
          observation: observation,
          env: widget.env,
          onDelete: () => _deleteObservation(observation),
        );
      },
    );
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
