import 'package:flutter/material.dart';
import 'package:flutter_advanced_avatar/flutter_advanced_avatar.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/login.dart';
import 'package:plant_it/theme.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 0, 9),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(children: _buildSeparatedChildren()),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSeparatedChildren() {
    final List<Widget> separatedChildren = [];
    for (int i = 0; i < children.length; i++) {
      separatedChildren.add(children[i]);
      if (i < children.length - 1) {
        separatedChildren.add(const Divider(height: 1, indent: 56));
      }
    }
    return separatedChildren;
  }
}

class SettingsInfo extends StatelessWidget {
  final String title;
  final String value;
  final bool? isValueLoading;
  final IconData? icon;

  const SettingsInfo({
    super.key,
    required this.title,
    required this.value,
    this.isValueLoading,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: icon == null
          ? null
          : Icon(icon, color: colors.onSurfaceVariant, size: 22),
      title: Text(title),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 170),
        child: Skeletonizer(
          enabled: isValueLoading ?? false,
          effect: skeletonizerEffect,
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }
}

class SettingsExternalLink extends StatelessWidget {
  final String title;
  final String url;
  final IconData? icon;
  const SettingsExternalLink({
    super.key,
    required this.title,
    required this.url,
    this.icon,
  });

  void _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        webOnlyWindowName: "_blank",
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: icon == null ? null : Icon(icon, size: 22),
      title: Text(title),
      trailing: Icon(
        Icons.open_in_new_rounded,
        size: 19,
        color: colors.onSurfaceVariant,
      ),
      onTap: () => _launchURL(url),
    );
  }
}

class SettingsHeader extends StatelessWidget {
  final String username;
  final String email;

  const SettingsHeader({
    super.key,
    required this.username,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 22),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            AdvancedAvatar(
              name: username,
              size: 58,
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
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

class LogoutButton extends StatelessWidget {
  final Environment env;

  const LogoutButton({
    super.key,
    required this.env,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            env.http.jwt = null;
            env.http.key = null;
            env.prefs.remove("serverKey");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LoginPage(env: env),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.error,
            side: BorderSide(color: colors.error.withOpacity(.75)),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: Text(AppLocalizations.of(context).logout),
        ),
      ),
    );
  }
}

class SettingsInternalLink extends StatelessWidget {
  final String title;
  final VoidCallback onClick;
  final IconData? icon;

  const SettingsInternalLink({
    super.key,
    required this.title,
    required this.onClick,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: icon == null ? null : Icon(icon, size: 22),
      title: Text(title),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colors.onSurfaceVariant,
      ),
      onTap: onClick,
    );
  }
}
