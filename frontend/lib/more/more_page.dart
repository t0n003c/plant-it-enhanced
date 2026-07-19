import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plant_it/app_layout.dart';
import 'package:plant_it/app_exception.dart';
import 'package:plant_it/care/care_tools_page.dart';
import 'package:plant_it/deployment_build_info.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/logger/logger.dart' as my_logger;
import 'package:plant_it/more/change_language_page.dart';
import 'package:plant_it/more/change_notifications.dart';
import 'package:plant_it/more/change_password_page.dart';
import 'package:plant_it/more/change_server_page.dart';
import 'package:plant_it/more/catalog_health_page.dart';
import 'package:plant_it/more/edit_profile.dart';
import 'package:plant_it/more/gotify_settings.dart';
import 'package:plant_it/more/ntfy_settings.dart';
import 'package:plant_it/more/settings.dart';
import 'package:plant_it/more/system_diagnostics_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/notify_conf_notifier.dart';
import 'package:plant_it/theme.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MorePage extends StatefulWidget {
  final Environment env;

  const MorePage({
    super.key,
    required this.env,
  });

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final Map<String, int> _stats = {};
  bool _statsLoading = true;
  late String _appVersion;
  bool _appVersionLoading = true;
  bool _ntfyVisible = false;
  bool _gotifyVisible = false;
  late final NotifyConfNotifier _notifyConfNotifier;

  void _fetchAndSetStats() async {
    try {
      final response = await widget.env.http.get("stats");
      final responseBody = json.decode(response.body);
      if (response.statusCode != 200) {
        if (!mounted) return;
        widget.env.logger.error(responseBody["message"]);
        throw AppException(responseBody["message"]);
      }
      _stats.clear();
      responseBody.forEach((key, value) {
        _stats[key] = value as int;
      });
      setState(() {
        _statsLoading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      widget.env.logger.error(e, st);
      setState(() => _statsLoading = false);
    }
  }

  List<Widget> _buildStatsList() {
    if (_statsLoading) {
      return [1, 2, 3].map((element) {
        return Skeletonizer(
          enabled: true,
          effect: skeletonizerEffect,
          child: SettingsInfo(
            title: element.toString() * (8 + element),
            value: element.toString() * (8 + element),
            icon: Icons.bar_chart_rounded,
          ),
        );
      }).toList();
    } else {
      return _stats.entries.map((entry) {
        return SettingsInfo(
          title: _formatStats(context, entry.key),
          value: entry.value.toString(),
          icon: _statsIcon(entry.key),
        );
      }).toList();
    }
  }

  IconData _statsIcon(String statName) {
    return switch (statName) {
      'diaryEntryCount' => Icons.event_note_rounded,
      'plantCount' => Icons.local_florist_rounded,
      'botanicalInfoCount' => Icons.eco_rounded,
      'imageCount' => Icons.photo_library_rounded,
      _ => Icons.bar_chart_rounded,
    };
  }

  String _formatStats(BuildContext context, String statName) {
    if (statName == "diaryEntryCount") {
      return AppLocalizations.of(context).eventCount;
    } else if (statName == "plantCount") {
      return AppLocalizations.of(context).plantCount;
    } else if (statName == "botanicalInfoCount") {
      return AppLocalizations.of(context).speciesCount;
    } else if (statName == "imageCount") {
      return AppLocalizations.of(context).imageCount;
    } else {
      return AppLocalizations.of(context).unknown;
    }
  }

  void _fetchAndSetAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    _appVersion = packageInfo.version;
    setState(() {
      _appVersionLoading = false;
    });
  }

  bool _isNotificationDispatcherActiveAndEnabled(String name) {
    if (!widget.env.notificationDispatcher.map((e) => e.name).contains(name)) {
      return false;
    }
    final NotificationDispatcher dispatcher =
        widget.env.notificationDispatcher.firstWhere((e) => e.name == name);
    return dispatcher.enabled;
  }

  void _setNotificationServiceSettingVisibility() {
    if (!mounted) return;
    setState(() {
      _ntfyVisible = _isNotificationDispatcherActiveAndEnabled("NTFY");
      _gotifyVisible = _isNotificationDispatcherActiveAndEnabled("GOTIFY");
    });
  }

  @override
  void initState() {
    super.initState();
    _setNotificationServiceSettingVisibility();
    _notifyConfNotifier =
        Provider.of<NotifyConfNotifier>(context, listen: false);
    _notifyConfNotifier.addListener(_setNotificationServiceSettingVisibility);
    _fetchAndSetStats();
    _fetchAndSetAppVersion();
  }

  @override
  void dispose() {
    _notifyConfNotifier
        .removeListener(_setNotificationServiceSettingVisibility);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: AppContent(
        maxWidth: appReadableMaxWidth,
        child: Column(
          children: [
            AppPageHeader(
              icon: Icons.tune_rounded,
              title: AppLocalizations.of(context).settings,
              subtitle: AppLocalizations.of(context).settingsSubtitle,
            ),
            SettingsHeader(
              username: widget.env.credentials.username,
              email: widget.env.credentials.email,
            ),
            SettingsSection(
              title: AppLocalizations.of(context).account,
              children: [
                SettingsInternalLink(
                  title: AppLocalizations.of(context).editProfile,
                  icon: Icons.manage_accounts_outlined,
                  onClick: () async {
                    final dynamic isUpdated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfilePage(
                          env: widget.env,
                        ),
                      ),
                    );
                    if (isUpdated is bool && isUpdated) {
                      setState(() {});
                    }
                  },
                ),
                SettingsInternalLink(
                  title: AppLocalizations.of(context).changePassword,
                  icon: Icons.lock_outline_rounded,
                  onClick: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangePasswordPage(
                        env: widget.env,
                      ),
                    ),
                  ),
                ),
                SettingsInternalLink(
                  title: AppLocalizations.of(context).changeLanguage,
                  icon: Icons.translate_rounded,
                  onClick: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeLanguagePage(
                        env: widget.env,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: AppLocalizations.of(context).stats,
              children: _buildStatsList(),
            ),
            SettingsSection(
              title: AppLocalizations.of(context).careTools,
              children: [
                SettingsInternalLink(
                  title: AppLocalizations.of(context).openCareTools,
                  icon: Icons.health_and_safety_outlined,
                  onClick: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CareToolsPage(env: widget.env),
                    ),
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: AppLocalizations.of(context).server,
              children: [
                SettingsInternalLink(
                  title: AppLocalizations.of(context).serverURL,
                  icon: Icons.dns_outlined,
                  onClick: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeServerPage(
                        env: widget.env,
                      ),
                    ),
                  ), //
                ),
                SettingsInternalLink(
                  title: AppLocalizations.of(context).notifications,
                  icon: Icons.notifications_outlined,
                  onClick: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotificationsPage(
                        env: widget.env,
                      ),
                    ),
                  ),
                ),
                SettingsInternalLink(
                  title: AppLocalizations.of(context).systemDiagnostics,
                  icon: Icons.monitor_heart_outlined,
                  onClick: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SystemDiagnosticsPage(
                        env: widget.env,
                      ),
                    ),
                  ),
                ),
                SettingsInternalLink(
                  title: AppLocalizations.of(context).catalogHealth,
                  icon: Icons.fact_check_outlined,
                  onClick: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CatalogHealthPage(
                        env: widget.env,
                      ),
                    ),
                  ),
                ),
                if (_ntfyVisible)
                  SettingsInternalLink(
                    title: AppLocalizations.of(context).ntfySettings,
                    icon: Icons.campaign_outlined,
                    onClick: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NtfySettingsPage(
                          env: widget.env,
                        ),
                      ),
                    ),
                  ),
                if (_gotifyVisible)
                  SettingsInternalLink(
                    title: AppLocalizations.of(context).gotifySettings,
                    icon: Icons.send_to_mobile_outlined,
                    onClick: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GotifySettingsPage(
                          env: widget.env,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SettingsSection(
              title: AppLocalizations.of(context).supportTheProject,
              children: [
                SettingsExternalLink(
                  title: AppLocalizations.of(context).buyMeACoffee,
                  url: "https://www.buymeacoffee.com/mdeluise",
                  icon: Icons.coffee_outlined,
                ),
              ],
            ),
            SettingsSection(
              title: AppLocalizations.of(context).more,
              children: [
                SettingsInfo(
                  title: AppLocalizations.of(context).appVersion,
                  isValueLoading: _appVersionLoading,
                  value: _appVersionLoading ? "loading..." : _appVersion,
                  icon: Icons.apps_rounded,
                ),
                SettingsInfo(
                  title: AppLocalizations.of(context).serverVersion,
                  value: widget.env.backendVersion,
                  icon: Icons.dns_outlined,
                ),
                SettingsInfo(
                  title: AppLocalizations.of(context).interfaceBuild,
                  value: DeploymentBuildInfo.displayRevision(
                    frontendBuildRevision,
                  ),
                  icon: Icons.commit_rounded,
                ),
                SettingsExternalLink(
                  title: AppLocalizations.of(context).documentation,
                  url:
                      "https://github.com/t0n003c/plant-it-enhanced/tree/main/online-resources/documentation/docs",
                  icon: Icons.menu_book_outlined,
                ),
                SettingsExternalLink(
                  title: AppLocalizations.of(context).openSource,
                  url: "https://github.com/t0n003c/plant-it-enhanced",
                  icon: Icons.code_rounded,
                ),
                SettingsExternalLink(
                  title: AppLocalizations.of(context).reportIssue,
                  url:
                      "https://github.com/t0n003c/plant-it-enhanced/issues/new/choose",
                  icon: Icons.bug_report_outlined,
                ),
                SettingsInternalLink(
                  title: AppLocalizations.of(context).appLog,
                  icon: Icons.receipt_long_outlined,
                  onClick: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TalkerScreen(
                        talker: (widget.env.logger as my_logger.TalkerLogger)
                            .talker,
                        appBarTitle: AppLocalizations.of(context).appLog,
                        theme: TalkerScreenTheme(
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            LogoutButton(
              env: widget.env,
            ),
            const SizedBox(
              height: 100,
            ),
          ],
        ),
      ),
    );
  }
}
