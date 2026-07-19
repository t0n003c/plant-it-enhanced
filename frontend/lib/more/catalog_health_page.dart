import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/environment.dart';

class CatalogHealthPage extends StatefulWidget {
  final Environment env;

  const CatalogHealthPage({
    super.key,
    required this.env,
  });

  @override
  State<CatalogHealthPage> createState() => _CatalogHealthPageState();
}

class _CatalogHealthPageState extends State<CatalogHealthPage> {
  Map<String, dynamic>? _health;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await widget.env.http.get('catalog-health');
      final dynamic body = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode != 200 || body is! Map<String, dynamic>) {
        throw Exception(body is Map
            ? body['message'] ?? 'Catalog health request failed'
            : 'Catalog health request failed');
      }
      if (mounted) setState(() => _health = body);
    } catch (error, stackTrace) {
      widget.env.logger.error(error, stackTrace);
      if (mounted) {
        setState(() {
          _health = null;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copyReport() async {
    if (_health == null) return;
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(_health)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).catalogReportCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).catalogHealth),
        actions: [
          IconButton(
            key: const ValueKey('copy-catalog-health-report'),
            onPressed: _loading || _health == null ? null : _copyReport,
            tooltip: AppLocalizations.of(context).copyCatalogReport,
            icon: const Icon(Icons.copy_all_outlined),
          ),
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: AppLocalizations.of(context).refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView(context)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: _content(context),
                  ),
                ),
    );
  }

  Widget _errorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).tryAgain),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context) {
    final Map<String, dynamic> data = _health!;
    final Map<String, dynamic> totals =
        data['totals'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final List<dynamic> tiers = data['tiers'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> gaps =
        data['recentGaps'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> policyIssues =
        data['policyIssues'] as List<dynamic>? ?? <dynamic>[];
    final bool healthy = data['healthy'] == true;
    return [
      _HealthBanner(healthy: healthy),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          final double width = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricTile(
                width: width,
                icon: Icons.local_florist_outlined,
                label: AppLocalizations.of(context).reviewedPlants,
                value: _integer(totals['reviewedEntries']).toString(),
              ),
              _MetricTile(
                width: width,
                icon: Icons.manage_search,
                label: AppLocalizations.of(context).reviewedPlantNames,
                value: _integer(totals['reviewedQueries']).toString(),
              ),
              _MetricTile(
                width: width,
                icon: Icons.water_drop_outlined,
                label: AppLocalizations.of(context).curatedCareProfiles,
                value: _integer(totals['curatedCareProfiles']).toString(),
              ),
              _MetricTile(
                width: width,
                icon: Icons.monitor_heart_outlined,
                label: AppLocalizations.of(context).providerCanaries,
                value: _integer(totals['liveCanaries']).toString(),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 24),
      _sectionTitle(context, AppLocalizations.of(context).coverageByTier),
      const SizedBox(height: 8),
      ...tiers.whereType<Map<String, dynamic>>().map(
            (tier) => _TierCoverageCard(tier: tier),
          ),
      const SizedBox(height: 24),
      _sectionTitle(context, AppLocalizations.of(context).recentCatalogGaps),
      const SizedBox(height: 8),
      if (gaps.isEmpty)
        _EmptyState(
          icon: Icons.check_circle_outline,
          message: AppLocalizations.of(context).noCatalogGaps,
        )
      else
        ...gaps.whereType<Map<String, dynamic>>().map(
              (gap) => _GapCard(gap: gap),
            ),
      if (policyIssues.isNotEmpty) ...[
        const SizedBox(height: 24),
        _sectionTitle(
            context, AppLocalizations.of(context).catalogPolicyIssues),
        const SizedBox(height: 8),
        ...policyIssues.map(
          (issue) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(issue.toString()),
          ),
        ),
      ],
      const SizedBox(height: 24),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline),
              const SizedBox(width: 12),
              Expanded(
                child: Text(AppLocalizations.of(context).catalogHealthPrivacy),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }

  int _integer(dynamic value) => value is num ? value.toInt() : 0;
}

class _HealthBanner extends StatelessWidget {
  final bool healthy;

  const _HealthBanner({required this.healthy});

  @override
  Widget build(BuildContext context) {
    final Color background = healthy
        ? const Color.fromRGBO(23, 73, 52, 1)
        : const Color.fromRGBO(105, 43, 36, 1);
    return Card(
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              healthy ? Icons.verified_outlined : Icons.warning_amber_rounded,
              size: 34,
              color: Colors.white,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                healthy
                    ? AppLocalizations.of(context).catalogHealthy
                    : AppLocalizations.of(context).catalogNeedsAttention,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;

  const _MetricTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 10),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 3),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierCoverageCard extends StatelessWidget {
  final Map<String, dynamic> tier;

  const _TierCoverageCard({required this.tier});

  @override
  Widget build(BuildContext context) {
    final String name = tier['name']?.toString() ?? '';
    final int searchCoverage = _integer(tier['searchCoveragePercent']);
    final int careCoverage = _integer(tier['careCoveragePercent']);
    final int careRequired = _integer(tier['careRequiredEntries']);
    final int imageRequired = _integer(tier['imageRequiredEntries']);
    final String title = name == 'NORTH_AMERICAN_TRAIL'
        ? AppLocalizations.of(context).trailCatalog
        : AppLocalizations.of(context).cultivatedCatalog;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Text('${_integer(tier['entries'])}'),
              ],
            ),
            const SizedBox(height: 14),
            _CoverageBar(
              label: AppLocalizations.of(context).searchCoverage,
              percent: searchCoverage,
            ),
            if (careRequired > 0) ...[
              const SizedBox(height: 12),
              _CoverageBar(
                label: AppLocalizations.of(context).careCoverage,
                percent: careCoverage,
              ),
            ],
            if (imageRequired > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.image_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)
                          .imagesMonitoredAtRuntime(imageRequired),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _integer(dynamic value) => value is num ? value.toInt() : 0;
}

class _CoverageBar extends StatelessWidget {
  final String label;
  final int percent;

  const _CoverageBar({required this.label, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text('$percent%'),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          minHeight: 8,
          borderRadius: BorderRadius.circular(6),
          value: percent.clamp(0, 100) / 100,
        ),
      ],
    );
  }
}

class _GapCard extends StatelessWidget {
  final Map<String, dynamic> gap;

  const _GapCard({required this.gap});

  @override
  Widget build(BuildContext context) {
    final String type = gap['type']?.toString() ?? '';
    final String label = switch (type) {
      'NO_RESULTS' => AppLocalizations.of(context).missingSearchResult,
      'MISSING_IMAGE' => AppLocalizations.of(context).missingCatalogImage,
      'MISSING_CARE' => AppLocalizations.of(context).missingCatalogCare,
      _ => type,
    };
    final int occurrences =
        gap['occurrences'] is num ? (gap['occurrences'] as num).toInt() : 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          type == 'NO_RESULTS' ? Icons.search_off : Icons.report_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(
            gap['subject']?.toString() ?? AppLocalizations.of(context).unknown),
        subtitle: Text(
          '$label · ${AppLocalizations.of(context).observedTimes(occurrences)}',
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: Colors.lightGreen),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
