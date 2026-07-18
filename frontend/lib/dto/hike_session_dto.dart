class HikeSessionDTO {
  final int? id;
  final String name;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? notes;
  final String? clientReference;
  final int observationCount;

  const HikeSessionDTO({
    this.id,
    required this.name,
    required this.startedAt,
    this.endedAt,
    this.notes,
    this.clientReference,
    this.observationCount = 0,
  });

  factory HikeSessionDTO.fromJson(Map<String, dynamic> json) {
    return HikeSessionDTO(
      id: json['id'] as int?,
      name: json['name'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      notes: json['notes'] as String?,
      clientReference: json['clientReference'] as String?,
      observationCount: (json['observationCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'startedAt': startedAt.toUtc().toIso8601String(),
      if (endedAt != null) 'endedAt': endedAt!.toUtc().toIso8601String(),
      if (notes?.trim().isNotEmpty == true) 'notes': notes!.trim(),
      if (clientReference?.trim().isNotEmpty == true)
        'clientReference': clientReference!.trim(),
    };
  }
}
