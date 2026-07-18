import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/search/tag.dart';

void main() {
  testWidgets('catalog tags retain readable contrast', (tester) async {
    const Color warningBackground = Color(0xFFFFD166);
    const Color warningForeground = Color(0xFF2B2100);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TagChip(
            tag: 'Avoid contact · verify independently',
            backgroundColor: warningBackground,
            foregroundColor: warningForeground,
          ),
        ),
      ),
    );

    expect(find.text('Avoid contact · verify independently'), findsOneWidget);
    expect(
      contrastRatio(warningForeground, warningBackground),
      greaterThanOrEqualTo(4.5),
    );
  });
}

double contrastRatio(Color foreground, Color background) {
  final double lighter = foreground.computeLuminance() + 0.05;
  final double darker = background.computeLuminance() + 0.05;
  return lighter > darker ? lighter / darker : darker / lighter;
}
