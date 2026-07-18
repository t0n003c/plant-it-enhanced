import 'package:flutter/material.dart';

/// The shared extended action used on primary collection screens.
///
/// The application theme keeps compact floating action buttons circular. An
/// extended button needs its own stadium shape so its icon and label are not
/// squeezed into that circle.
class AppExtendedFloatingActionButton extends StatelessWidget {
  static const Color backgroundColor = Color(0xFF6DD075);
  static const Color foregroundColor = Color(0xFF061913);

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final String tooltip;
  final Object? heroTag;

  const AppExtendedFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.tooltip,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: heroTag,
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 3,
      shape: const StadiumBorder(),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
      icon: Icon(icon, size: 22),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
