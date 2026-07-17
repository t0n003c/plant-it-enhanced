import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/search/photo_source_sheet.dart';

import 'localizations_injector.dart';

void main() {
  late NavigatorObserver navigatorObserver;

  setUp(() {
    navigatorObserver = NavigatorObserver();
  });

  testWidgets('photo actions are readable and have large mobile targets',
      (tester) async {
    var cameraSelected = false;
    var gallerySelected = false;
    await tester.pumpWidget(
      LocalizationsInjector(
        navigatorObserver: navigatorObserver,
        child: PhotoSourceSheet(
          onCamera: () => cameraSelected = true,
          onGallery: () => gallerySelected = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Take a plant photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(
      contrastRatio(
        PhotoSourceSheet.primaryTextColor,
        PhotoSourceSheet.actionBackgroundColor,
      ),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(
        PhotoSourceSheet.secondaryTextColor,
        PhotoSourceSheet.backgroundColor,
      ),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      tester.getSize(find.byKey(const Key('takePlantPhotoAction'))).height,
      greaterThanOrEqualTo(64),
    );
    expect(
      tester.getSize(find.byKey(const Key('choosePlantPhotoAction'))).height,
      greaterThanOrEqualTo(64),
    );

    await tester.tap(find.byKey(const Key('takePlantPhotoAction')));
    await tester.tap(find.byKey(const Key('choosePlantPhotoAction')));

    expect(cameraSelected, isTrue);
    expect(gallerySelected, isTrue);
  });
}

double contrastRatio(Color foreground, Color background) {
  final double lighter = foreground.computeLuminance() + 0.05;
  final double darker = background.computeLuminance() + 0.05;
  return lighter > darker ? lighter / darker : darker / lighter;
}
