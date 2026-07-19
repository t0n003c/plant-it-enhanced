import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/more/settings.dart';
import 'package:plant_it/theme.dart';

void main() {
  testWidgets('settings use one grouped, icon-led and tappable surface',
      (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: SettingsSection(
            title: 'Account',
            children: [
              SettingsInternalLink(
                title: 'Edit profile',
                icon: Icons.manage_accounts_outlined,
                onClick: () => tapped = true,
              ),
              const SettingsInfo(
                title: 'Plant count',
                value: '12',
                icon: Icons.local_florist_outlined,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(Card), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.byIcon(Icons.manage_accounts_outlined), findsOneWidget);

    await tester.tap(find.text('Edit profile'));
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });
}
