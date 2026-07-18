import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_it/search/guided_photo_sheet.dart';

import 'localizations_injector.dart';

void main() {
  testWidgets('guided photo controls remain readable on a small phone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      LocalizationsInjector(
        navigatorObserver: NavigatorObserver(),
        child: GuidedPhotoSheet(initialImage: XFile('whole-plant.jpg')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Whole plant'), findsOneWidget);
    expect(find.text('Leaf close-up'), findsOneWidget);
    expect(find.text('Flower or fruit'), findsOneWidget);
    expect(find.text('Take a plant photo'), findsNWidgets(3));
    expect(find.text('Choose from gallery'), findsNWidgets(3));
    expect(find.byKey(const Key('identifyGuidedPhotosAction')), findsOneWidget);

    final Finder cameraActions = find.ancestor(
      of: find.text('Take a plant photo').first,
      matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
    );
    final Finder galleryActions = find.ancestor(
      of: find.text('Choose from gallery').first,
      matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
    );
    expect(
        tester.getSize(cameraActions.first).height, greaterThanOrEqualTo(56));
    expect(
        tester.getSize(galleryActions.first).height, greaterThanOrEqualTo(56));
    expect(
      tester
          .getSize(find.byKey(const Key('identifyGuidedPhotosAction')))
          .height,
      greaterThanOrEqualTo(56),
    );
    expect(tester.takeException(), isNull);
  });
}
