import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/app_extended_floating_action_button.dart';
import 'package:plant_it/theme.dart';

void main() {
  testWidgets('renders a readable pill even when compact FABs are circular',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          floatingActionButton: AppExtendedFloatingActionButton(
            onPressed: () {},
            icon: Icons.event_available_outlined,
            label: 'Add new event',
            tooltip: 'Add new event',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final FloatingActionButton button =
        tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
    final Size size = tester.getSize(find.byType(FloatingActionButton));

    expect(button.shape, isA<StadiumBorder>());
    expect(button.backgroundColor,
        AppExtendedFloatingActionButton.backgroundColor);
    expect(button.foregroundColor,
        AppExtendedFloatingActionButton.foregroundColor);
    expect(size.width, greaterThan(size.height));
    expect(find.text('Add new event'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
      _contrastRatio(
        AppExtendedFloatingActionButton.foregroundColor,
        AppExtendedFloatingActionButton.backgroundColor,
      ),
      greaterThanOrEqualTo(4.5),
    );
  });
}

double _contrastRatio(Color foreground, Color background) {
  final double lighter = foreground.computeLuminance() + 0.05;
  final double darker = background.computeLuminance() + 0.05;
  return lighter > darker ? lighter / darker : darker / lighter;
}
