import 'dart:typed_data';

class SpeciesDTO {
  int? id;
  String scientificName;
  List<String>? synonyms;
  String? preferredCommonName;
  List<BotanicalCommonNameDTO> commonNames;
  Map<String, String> externalReferences;
  DateTime? lastVerifiedAt;
  String? family;
  String? genus;
  String? species;
  SpeciesCareInfoDTO care;
  String? imageId;
  String? imageUrl;
  Uint8List? imageContent;
  String? imageContentType;
  String creator;
  String? externalId;

  SpeciesDTO({
    this.id,
    required this.scientificName,
    this.synonyms,
    this.preferredCommonName,
    this.commonNames = const [],
    this.externalReferences = const {},
    this.lastVerifiedAt,
    this.family,
    this.genus,
    this.species,
    required this.care,
    this.imageId,
    this.imageUrl,
    this.imageContent,
    this.imageContentType,
    required this.creator,
    this.externalId,
  });

  factory SpeciesDTO.fromJson(Map<String, dynamic> json) {
    return SpeciesDTO(
      id: json['id'],
      scientificName: json['scientificName'],
      synonyms: (json['synonyms'] as List<dynamic>?)
          ?.map((value) => value.toString())
          .toList(),
      preferredCommonName: json['preferredCommonName'],
      commonNames: (json['commonNames'] as List<dynamic>? ?? [])
          .map((value) =>
              BotanicalCommonNameDTO.fromJson(value as Map<String, dynamic>))
          .toList(),
      externalReferences:
          (json['externalReferences'] as Map<String, dynamic>? ?? {})
              .map((key, value) => MapEntry(key, value.toString())),
      lastVerifiedAt: json['lastVerifiedAt'] == null
          ? null
          : DateTime.parse(json['lastVerifiedAt']),
      family: json['family'],
      genus: json['genus'],
      species: json['species'],
      care: SpeciesCareInfoDTO.fromJson(json['plantCareInfo']),
      imageId: json['imageId'],
      imageUrl: json['imageUrl'],
      imageContent: json['imageContent'],
      imageContentType: json['imageContentType'],
      creator: json['creator'],
      externalId: json['externalId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'scientificName': scientificName,
      if (synonyms != null) 'synonyms': synonyms,
      if (preferredCommonName != null)
        'preferredCommonName': preferredCommonName,
      'commonNames': commonNames.map((name) => name.toMap()).toList(),
      'externalReferences': externalReferences,
      if (lastVerifiedAt != null)
        'lastVerifiedAt': lastVerifiedAt!.toIso8601String(),
      if (family != null) 'family': family,
      if (genus != null) 'genus': genus,
      if (species != null) 'species': species,
      'plantCareInfo': care.toMap(),
      if (imageId != null) 'imageId': imageId,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (imageContent != null) 'imageContent': imageContent,
      if (imageContentType != null) 'imageContentType': imageContentType,
      'creator': creator,
      if (externalId != null) 'externalId': externalId,
    };
  }
}

class BotanicalCommonNameDTO {
  String name;
  String? language;
  String? region;
  bool preferred;
  String source;

  BotanicalCommonNameDTO({
    required this.name,
    this.language,
    this.region,
    this.preferred = false,
    required this.source,
  });

  factory BotanicalCommonNameDTO.fromJson(Map<String, dynamic> json) {
    return BotanicalCommonNameDTO(
      name: json['name'],
      language: json['language'],
      region: json['region'],
      preferred: json['preferred'] ?? false,
      source: json['source'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (language != null) 'language': language,
      if (region != null) 'region': region,
      'preferred': preferred,
      'source': source,
    };
  }
}

class SpeciesCareInfoDTO {
  int? light;
  int? humidity;
  double? minTemp;
  double? maxTemp;
  double? phMin;
  double? phMax;
  bool? allNull;

  SpeciesCareInfoDTO({
    this.light,
    this.humidity,
    this.minTemp,
    this.maxTemp,
    this.phMin,
    this.phMax,
    this.allNull,
  });

  factory SpeciesCareInfoDTO.fromJson(Map<String, dynamic> json) {
    return SpeciesCareInfoDTO(
      light: json['light'],
      humidity: json['humidity'],
      minTemp: json['minTemp'],
      maxTemp: json['maxTemp'],
      phMin: json['phMin'],
      phMax: json['phMax'],
      allNull: json['allNull'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (light != null) 'light': light,
      if (humidity != null) 'humidity': humidity,
      if (minTemp != null) 'minTemp': minTemp,
      if (maxTemp != null) 'maxTemp': maxTemp,
      if (phMin != null) 'phMin': phMin,
      if (phMax != null) 'phMax': phMax,
      if (allNull != null) 'allNull': allNull,
    };
  }
}
