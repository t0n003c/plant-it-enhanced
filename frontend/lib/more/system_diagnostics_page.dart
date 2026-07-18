import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/environment.dart';

class SystemDiagnosticsPage extends StatefulWidget {
  final Environment env;

  const SystemDiagnosticsPage({
    super.key,
    required this.env,
  });

  @override
  State<SystemDiagnosticsPage> createState() => _SystemDiagnosticsPageState();
}

class _SystemDiagnosticsPageState extends State<SystemDiagnosticsPage> {
  Map<String, dynamic>? _diagnostics;
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
      final response = await widget.env.http.get('diagnostics');
      final dynamic body = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode != 200 || body is! Map<String, dynamic>) {
        throw Exception(body is Map
            ? body['message'] ?? 'Diagnostics request failed'
            : 'Diagnostics request failed');
      }
      if (mounted) setState(() => _diagnostics = body);
    } catch (error, stackTrace) {
      widget.env.logger.error(error, stackTrace);
      if (mounted) {
        setState(() {
          _diagnostics = null;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).systemDiagnostics),
        actions: [
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
                    padding: const EdgeInsets.all(16),
                    children: _buildDiagnostics(context),
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

  List<Widget> _buildDiagnostics(BuildContext context) {
    final Map<String, dynamic> data = _diagnostics!;
    final Map<String, dynamic> database =
        data['database'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> cache =
        data['cache'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> providers =
        data['providers'] as Map<String, dynamic>? ?? {};
    return [
      _StatusCard(
        title: AppLocalizations.of(context).database,
        healthy: database['healthy'] == true,
        details: [database['detail']?.toString()],
      ),
      _StatusCard(
        title: AppLocalizations.of(context).cache,
        healthy: cache['healthy'] == true,
        details: [cache['detail']?.toString()],
      ),
      const SizedBox(height: 12),
      Text(
        AppLocalizations.of(context).plantDataProviders,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      ...providers.entries.map((entry) {
        final Map<String, dynamic> provider =
            entry.value as Map<String, dynamic>? ?? {};
        final bool configured = provider['configured'] == true;
        final bool attempted = provider['lastAttemptAt'] != null;
        final int? status = provider['lastHttpStatus'] as int?;
        return _StatusCard(
          title: entry.key,
          healthy: configured && attempted && status != null && status < 400,
          neutral: !configured || !attempted,
          details: [
            configured
                ? AppLocalizations.of(context).configured
                : AppLocalizations.of(context).notConfigured,
            if (status != null) 'HTTP $status',
            if (provider['lastSuccessAt'] != null)
              '${AppLocalizations.of(context).lastSuccess}: '
                  '${_formatDate(provider['lastSuccessAt'].toString())}',
            if (provider['quotaRemaining'] != null)
              '${AppLocalizations.of(context).quotaRemaining}: '
                  '${provider['quotaRemaining']}',
            provider['lastError']?.toString(),
          ],
        );
      }),
      const SizedBox(height: 12),
      _DiagnosticValue(
        label: AppLocalizations.of(context).serverVersion,
        value: data['version']?.toString(),
      ),
      _DiagnosticValue(
        label: AppLocalizations.of(context).serverBuild,
        value: data['revision']?.toString(),
      ),
      _DiagnosticValue(
        label: AppLocalizations.of(context).publicOutboundIp,
        value: data['publicOutboundIp']?.toString() ??
            AppLocalizations.of(context).notConfigured,
      ),
      const SizedBox(height: 8),
      Text(
        AppLocalizations.of(context).diagnosticsIpHint,
        style: const TextStyle(color: Colors.grey),
      ),
    ];
  }

  String _formatDate(String value) {
    final DateTime? parsed = DateTime.tryParse(value);
    return parsed == null ? value : parsed.toLocal().toString();
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final bool healthy;
  final bool neutral;
  final List<String?> details;

  const _StatusCard({
    required this.title,
    required this.healthy,
    required this.details,
    this.neutral = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = neutral
        ? Colors.amberAccent
        : healthy
            ? Colors.lightGreenAccent
            : Theme.of(context).colorScheme.error;
    final IconData icon = neutral
        ? Icons.remove_circle_outline
        : healthy
            ? Icons.check_circle_outline
            : Icons.error_outline;
    return Card(
      color: const Color.fromRGBO(24, 44, 37, 1),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...details
                      .whereType<String>()
                      .where((value) => value.isNotEmpty)
                      .map(
                        (value) => Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            value,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticValue extends StatelessWidget {
  final String label;
  final String? value;

  const _DiagnosticValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value ?? AppLocalizations.of(context).unknown),
    );
  }
}
