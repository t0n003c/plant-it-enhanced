import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/search/search_result_photo.dart';

void main() {
  testWidgets('search photos remain centered and uncropped', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: SearchResultPhotoFrame(
                imageProvider: AssetImage('assets/images/no-image.png'),
                semanticLabel: 'Lily',
              ),
            ),
          ),
        ),
      ),
    );

    final Image image = tester.widget<Image>(
      find.byKey(const ValueKey('search-result-centered-image')),
    );
    final Size frameSize = tester.getSize(
      find.byKey(const ValueKey('search-result-photo-frame')),
    );

    expect(image.fit, BoxFit.contain);
    expect(image.alignment, Alignment.center);
    expect(frameSize.width, 320);
    expect(frameSize.height, 240);
    expect(find.bySemanticsLabel('Lily'), findsOneWidget);
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading keeps the final photo dimensions stable',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: SearchResultPhotoFrame(
                imageProvider: AssetImage('assets/images/no-image.png'),
                semanticLabel: 'Loading lily photo',
                loading: true,
              ),
            ),
          ),
        ),
      ),
    );

    final Size frameSize = tester.getSize(
      find.byKey(const ValueKey('search-result-photo-frame')),
    );
    expect(frameSize, const Size(360, 270));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
