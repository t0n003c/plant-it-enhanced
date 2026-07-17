import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PhotoSourceSheet extends StatelessWidget {
  static const Color backgroundColor = Color(0xFF182C25);
  static const Color actionBackgroundColor = Color(0xFF315E4E);
  static const Color primaryTextColor = Colors.white;
  static const Color secondaryTextColor = Color(0xFFE2ECE7);
  static const Color iconColor = Color(0xFFC7F9CC);

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const PhotoSourceSheet({
    super.key,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(context).photoIdentificationPrivacy,
                style: const TextStyle(
                  color: secondaryTextColor,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              _PhotoSourceAction(
                key: const Key('takePlantPhotoAction'),
                icon: Icons.camera_alt_outlined,
                label: AppLocalizations.of(context).takePlantPhoto,
                onTap: onCamera,
              ),
              const SizedBox(height: 12),
              _PhotoSourceAction(
                key: const Key('choosePlantPhotoAction'),
                icon: Icons.photo_library_outlined,
                label: AppLocalizations.of(context).choosePlantPhoto,
                onTap: onGallery,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoSourceAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoSourceAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PhotoSourceSheet.actionBackgroundColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: PhotoSourceSheet.iconColor,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: PhotoSourceSheet.primaryTextColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: PhotoSourceSheet.primaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
