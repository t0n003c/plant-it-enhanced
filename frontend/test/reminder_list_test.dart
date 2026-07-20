import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/dto/reminder_occurrence.dart';
import 'package:plant_it/event/reminder_list.dart';

import 'localizations_injector.dart';

void main() {
  test('parses the reminder id from a calendar occurrence', () {
    final occurrence = ReminderOccurrenceDTO.fromJson({
      'reminderId': 42,
      'date': '2026-07-19T12:00:00Z',
      'reminderFrequency': {'quantity': 3, 'unit': 'DAYS'},
      'reminderAction': 'WATERING',
      'reminderTargetId': 7,
      'reminderTargetInfoPersonalName': 'Basil',
    });

    expect(occurrence.reminderId, 42);
    expect(occurrence.reminderAction, 'WATERING');
    expect(occurrence.reminderFrequency!.quantity, 3);
  });

  testWidgets('calendar reminder cards expose the edit callback',
      (tester) async {
    final occurrence = ReminderOccurrenceDTO.fromJson({
      'reminderId': 42,
      'date': '2026-07-19T12:00:00Z',
      'reminderFrequency': {'quantity': 3, 'unit': 'DAYS'},
      'reminderAction': 'WATERING',
      'reminderTargetInfoPersonalName': 'Basil',
    });
    ReminderOccurrenceDTO? tappedOccurrence;

    await tester.pumpWidget(
      LocalizationsInjector(
        navigatorObserver: NavigatorObserver(),
        child: ReminderList(
          occurrences: [occurrence],
          onOccurrenceTap: (value) async {
            tappedOccurrence = value;
          },
        ),
      ),
    );

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    await tester.tap(find.text('Basil'));
    await tester.pump();

    expect(tappedOccurrence?.reminderId, 42);
  });
}
