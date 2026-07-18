import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/deployment_build_info.dart';
import 'package:plant_it/environment.dart';
import 'package:url_launcher/url_launcher.dart';

typedef BuildInfoLoader = Future<DeploymentBuildInfo?> Function();

class DeploymentStatusBanner extends StatefulWidget {
  final Environment env;
  final String interfaceRevision;
  final BuildInfoLoader? loadBuildInfo;

  const DeploymentStatusBanner({
    super.key,
    required this.env,
    this.interfaceRevision = frontendBuildRevision,
    this.loadBuildInfo,
  });

  @override
  State<DeploymentStatusBanner> createState() => _DeploymentStatusBannerState();
}

class _DeploymentStatusBannerState extends State<DeploymentStatusBanner> {
  late final Future<DeploymentBuildInfo?> _buildInfo;

  @override
  void initState() {
    super.initState();
    _buildInfo = _loadBuildInfo();
  }

  Future<DeploymentBuildInfo?> _loadBuildInfo() async {
    if (!kIsWeb && widget.loadBuildInfo == null) return null;
    try {
      return await (widget.loadBuildInfo?.call() ??
          DeploymentBuildInfo.fetch(widget.env.http));
    } catch (error, stackTrace) {
      widget.env.logger.warning(
        'Unable to check the running build: $error',
        error,
        stackTrace,
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DeploymentBuildInfo?>(
      future: _buildInfo,
      builder: (context, snapshot) {
        final DeploymentBuildInfo? buildInfo = snapshot.data;
        if (buildInfo == null ||
            !buildInfo.differsFrom(widget.interfaceRevision)) {
          return const SizedBox.shrink();
        }
        return _StaleBuildNotice(onRefresh: _refreshSafely);
      },
    );
  }

  Future<void> _refreshSafely() async {
    final String? backendUrl = widget.env.http.backendUrl;
    if (backendUrl == null || backendUrl.isEmpty) return;
    final Uri backend = Uri.parse(backendUrl);
    final Uri updatePage = backend.replace(
      path: '/update.html',
      query: null,
      fragment: null,
    );
    await launchUrl(updatePage, webOnlyWindowName: '_self');
  }
}

class _StaleBuildNotice extends StatelessWidget {
  final VoidCallback onRefresh;

  const _StaleBuildNotice({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    const Color background = Color(0xFFFFE082);
    const Color foreground = Color(0xFF102018);
    return Semantics(
      container: true,
      liveRegion: true,
      label: '${localizations.staleAppTitle}. ${localizations.staleAppMessage}',
      child: Material(
        color: background,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final Widget message = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.system_update_alt, color: foreground),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.staleAppTitle,
                        style: const TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        localizations.staleAppMessage,
                        style: const TextStyle(color: foreground),
                      ),
                    ],
                  ),
                ),
              ],
            );
            final Widget refreshButton = TextButton(
              onPressed: onRefresh,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF064E3B),
                minimumSize: const Size(48, 48),
              ),
              child: Text(localizations.refreshAppSafely),
            );
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: constraints.maxWidth < 560
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        message,
                        Align(
                          alignment: Alignment.centerRight,
                          child: refreshButton,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: message),
                        const SizedBox(width: 8),
                        refreshButton,
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}
