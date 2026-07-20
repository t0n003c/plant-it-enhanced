import 'package:plant_it/dto/reminder_dto.dart';

class ReminderOccurrenceDTO {
  int? id;
  int? reminderId;
  DateTime? date;
  FrequencyDTO? reminderFrequency;
  DateTime? lastNotified;
  String? reminderAction;
  int? reminderTargetId;
  String? reminderTargetInfoPersonalName;

  ReminderOccurrenceDTO({
    this.id,
    this.reminderId,
    this.date,
    this.reminderFrequency,
    this.lastNotified,
    this.reminderAction,
    this.reminderTargetId,
    this.reminderTargetInfoPersonalName,
  });

  factory ReminderOccurrenceDTO.fromJson(Map<String, dynamic> json) {
    final dynamic rawDate = json['date'] ?? json['start'];
    final dynamic rawFrequency = json['reminderFrequency'] ?? json['frequency'];
    return ReminderOccurrenceDTO(
      id: json['id'],
      reminderId: json['reminderId'] ?? json['targetId'],
      date: rawDate == null ? null : DateTime.parse(rawDate),
      reminderFrequency: rawFrequency == null
          ? null
          : FrequencyDTO.fromJson(rawFrequency as Map<String, dynamic>),
      lastNotified: json['lastNotified'] != null
          ? DateTime.parse(json['lastNotified'])
          : null,
      reminderAction: json['reminderAction'] ?? json['action'],
      reminderTargetId: json['reminderTargetId'],
      reminderTargetInfoPersonalName: json['reminderTargetInfoPersonalName'],
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {};
    if (id != null) map['id'] = id;
    if (reminderAction != null) map['action'] = reminderAction;
    if (reminderId != null) map['targetId'] = reminderId;
    if (date != null) map['start'] = date!.toIso8601String();
    if (reminderFrequency != null) {
      map['frequency'] = reminderFrequency!.toMap();
    }
    if (lastNotified != null) {
      map['lastNotified'] = lastNotified!.toIso8601String();
    }
    if (reminderTargetId != null) map['reminderTargetId'] = reminderTargetId;
    if (reminderTargetInfoPersonalName != null) {
      map['reminderTargetInfoPersonalName'] = reminderTargetInfoPersonalName;
    }
    return map;
  }
}
