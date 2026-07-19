import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/app_layout.dart';
import 'package:plant_it/theme.dart';

void main() {
  testWidgets('shared page hierarchy remains readable on a narrow phone',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: AppContent(
              child: Column(
                children: [
                  AppPageHeader(
                    icon: Icons.eco,
                    title: 'A deliberately long professional page title',
                    subtitle: 'A clear description of what this screen does.',
                    trailing: Icon(Icons.sync),
                  ),
                  AppSectionHeader(
                    title: 'Collection',
                    subtitle: 'Organized and easy to scan',
                  ),
                  Card(
                    child: AppEmptyState(
                      icon: Icons.local_florist_outlined,
                      title: 'Nothing here yet',
                      message: 'The next action stays clear and accessible.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Collection'), findsOneWidget);
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
