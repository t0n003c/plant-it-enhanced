import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PrimaryNavigationBar extends StatelessWidget {
  static const Color backgroundColor = Color(0xFF0B211A);
  static const Color indicatorColor = Color(0xFF315D4E);
  static const Color selectedColor = Color(0xFFC7F9CC);
  static const Color unselectedColor = Color(0xFF9FB9AB);

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

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF29483D))),
      ),
      child: NavigationBarTheme(
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
      ),
    );
  }
}

class PrimaryNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const PrimaryNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return NavigationRail(
      key: const ValueKey<String>('primary-navigation-rail'),
      backgroundColor: PrimaryNavigationBar.backgroundColor,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      groupAlignment: -.35,
      minWidth: 92,
      selectedIconTheme:
          const IconThemeData(color: PrimaryNavigationBar.selectedColor),
      unselectedIconTheme:
          const IconThemeData(color: PrimaryNavigationBar.unselectedColor),
      selectedLabelTextStyle: const TextStyle(
        color: PrimaryNavigationBar.selectedColor,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: const TextStyle(
        color: PrimaryNavigationBar.unselectedColor,
        fontWeight: FontWeight.w500,
      ),
      indicatorColor: PrimaryNavigationBar.indicatorColor,
      leading: Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 28),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.eco_rounded, color: colors.onPrimaryContainer),
        ),
      ),
      destinations: <NavigationRailDestination>[
        NavigationRailDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: Text(localizations.home),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.calendar_month_outlined),
          selectedIcon: const Icon(Icons.calendar_month),
          label: Text(localizations.calendar),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.search_outlined),
          selectedIcon: const Icon(Icons.search),
          label: Text(localizations.search),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.hiking_outlined),
          selectedIcon: const Icon(Icons.hiking),
          label: Text(localizations.trail),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: Text(localizations.settings),
        ),
      ],
    );
  }
}
