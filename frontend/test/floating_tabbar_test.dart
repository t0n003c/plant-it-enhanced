import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/floating_tabbar.dart';
import 'package:plant_it/theme.dart';

void main() {
  testWidgets('shows every controlled section and changes selection',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int selected = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => FloatingTabBar(
              titles: const ['Care tasks', 'Calendar', 'Events'],
              selectedIndex: selected,
              onSelected: (index) => setState(() => selected = index),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ChoiceChip), findsNWidgets(3));
    expect(find.text('Care tasks'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('section-tab-2')));
    await tester.pump();

    expect(selected, 2);
    final ChoiceChip selectedChip = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey<String>('section-tab-2')),
    );
    expect(selectedChip.selected, isTrue);
    expect(tester.takeException(), isNull);
  });
}
