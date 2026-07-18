import 'dart:convert';

import 'package:plant_it/app_http_client.dart';

const String frontendBuildRevision = String.fromEnvironment(
  'APP_BUILD_REVISION',
  defaultValue: 'development',
);

class DeploymentBuildInfo {
  final String version;
  final String revision;

  const DeploymentBuildInfo({
    required this.version,
    required this.revision,
  });

  factory DeploymentBuildInfo.fromJson(Map<String, dynamic> json) {
    return DeploymentBuildInfo(
      version: _normalize(json['version']?.toString(), 'unknown'),
      revision: _normalize(json['revision']?.toString(), 'development'),
    );
  }

  static Future<DeploymentBuildInfo?> fetch(AppHttpClient http) async {
    final response = await http.getNoAuth('info/build');
    if (response.statusCode != 200) return null;
    final dynamic decoded = json.decode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) return null;
    return DeploymentBuildInfo.fromJson(decoded);
  }

  bool differsFrom(String otherRevision) {
    final String backend = revision.trim().toLowerCase();
    final String frontend = otherRevision.trim().toLowerCase();
    if (!_isComparable(backend) || !_isComparable(frontend)) return false;
    if (backend == frontend) return false;
    if (backend.length >= 7 && frontend.length >= 7) {
      return !backend.startsWith(frontend) && !frontend.startsWith(backend);
    }
    return true;
  }

  static String displayRevision(String revision) {
    final String normalized = revision.trim();
    if (normalized.isEmpty) return 'unknown';
    return normalized.length > 12 ? normalized.substring(0, 12) : normalized;
  }

  static bool _isComparable(String revision) {
    return revision.isNotEmpty &&
        revision != 'development' &&
        revision != 'unknown' &&
        revision != 'local';
  }

  static String _normalize(String? value, String fallback) {
    return value == null || value.trim().isEmpty ? fallback : value.trim();
  }
}
