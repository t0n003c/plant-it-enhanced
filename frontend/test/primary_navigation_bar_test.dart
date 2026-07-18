import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/primary_navigation_bar.dart';

void main() {
  testWidgets('shows five readable destinations and selects Trail',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    int selectedIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            bottomNavigationBar: PrimaryNavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                setState(() => selectedIndex = index);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationDestination), findsNWidgets(5));
    for (final label in ['Home', 'Calendar', 'Search', 'Trail', 'Settings']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      tester
          .getSize(find.byKey(const ValueKey<String>('primary-navigation')))
          .height,
      72,
    );
    expect(
      _contrastRatio(
        PrimaryNavigationBar.unselectedColor,
        PrimaryNavigationBar.backgroundColor,
      ),
      greaterThanOrEqualTo(4.5),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('primary-navigation-trail')),
    );
    await tester.pumpAndSettle();

    expect(selectedIndex, 3);
    expect(tester.takeException(), isNull);
  });
}

double _contrastRatio(Color foreground, Color background) {
  final double lighter = foreground.computeLuminance() + 0.05;
  final double darker = background.computeLuminance() + 0.05;
  return lighter > darker ? lighter / darker : darker / lighter;
}
