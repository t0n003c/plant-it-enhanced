import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PrimaryNavigationBar extends StatelessWidget {
  static const Color backgroundColor = Color(0xFF182C25);
  static const Color indicatorColor = Color(0xFF315D4E);
  static const Color selectedColor = Color(0xFFC7F9CC);
  static const Color unselectedColor = Color(0xFFB8D6C4);

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const PrimaryNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: backgroundColor,
        indicatorColor: indicatorColor,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? selectedColor
                : unselectedColor,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? selectedColor
                : unselectedColor,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
      child: NavigationBar(
        key: const ValueKey<String>('primary-navigation'),
        height: 72,
        selectedIndex: selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: onDestinationSelected,
        destinations: <NavigationDestination>[
          NavigationDestination(
            key: const ValueKey<String>('primary-navigation-home'),
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: localizations.home,
          ),
          NavigationDestination(
            key: const ValueKey<String>('primary-navigation-calendar'),
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: localizations.calendar,
          ),
          NavigationDestination(
            key: const ValueKey<String>('primary-navigation-search'),
            icon: const Icon(Icons.search_outlined),
            selectedIcon: const Icon(Icons.search),
            label: localizations.search,
          ),
          NavigationDestination(
            key: const ValueKey<String>('primary-navigation-trail'),
            icon: const Icon(Icons.hiking_outlined),
            selectedIcon: const Icon(Icons.hiking),
            label: localizations.trail,
          ),
          NavigationDestination(
            key: const ValueKey<String>('primary-navigation-settings'),
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: localizations.settings,
          ),
        ],
      ),
    );
  }
}
