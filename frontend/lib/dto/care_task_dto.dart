enum CareTaskStatus { overdue, dueToday, upcoming, snoozed }

class CareTaskDTO {
  final int reminderId;
  final int plantId;
  final String plantName;
  final String action;
  final DateTime dueAt;
  final DateTime actionAt;
  final DateTime? snoozedUntil;
  final DateTime? lastCompletedAt;
  final CareTaskStatus status;

  const CareTaskDTO({
    required this.reminderId,
    required this.plantId,
    required this.plantName,
    required this.action,
    required this.dueAt,
    required this.actionAt,
    this.snoozedUntil,
    this.lastCompletedAt,
    required this.status,
  });

  factory CareTaskDTO.fromJson(Map<String, dynamic> json) {
    return CareTaskDTO(
      reminderId: json['reminderId'],
      plantId: json['plantId'],
      plantName: json['plantName'],
      action: json['action'],
      dueAt: DateTime.parse(json['dueAt']).toLocal(),
      actionAt: DateTime.parse(json['actionAt']).toLocal(),
      snoozedUntil: json['snoozedUntil'] == null
          ? null
          : DateTime.parse(json['snoozedUntil']).toLocal(),
      lastCompletedAt: json['lastCompletedAt'] == null
          ? null
          : DateTime.parse(json['lastCompletedAt']).toLocal(),
      status: _readStatus(json['status']),
    );
  }

  static CareTaskStatus _readStatus(String value) {
    switch (value) {
      case 'OVERDUE':
        return CareTaskStatus.overdue;
      case 'DUE_TODAY':
        return CareTaskStatus.dueToday;
      case 'SNOOZED':
        return CareTaskStatus.snoozed;
      default:
        return CareTaskStatus.upcoming;
    }
  }
}
