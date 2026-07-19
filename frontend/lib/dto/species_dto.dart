import 'dart:typed_data';

class SpeciesDTO {
  int? id;
  String scientificName;
  List<String>? synonyms;
  String? preferredCommonName;
  List<BotanicalCommonNameDTO> commonNames;
  Map<String, String> externalReferences;
  String? canonicalTaxonKey;
  DateTime? lastVerifiedAt;
  String? family;
  String? genus;
  String? species;
  SpeciesCareInfoDTO care;
  String? imageId;
  String? imageUrl;
  String? imageFallbackUrl;
  String? imageSource;
  String? imageSourceUrl;
  String? imageLicenseCode;
  String? imageAttribution;
  Uint8List? imageContent;
  String? imageContentType;
  String creator;
  String? externalId;
  double? identificationConfidence;
  String? identificationProvider;
  String? identificationModel;
  String? identificationProject;
  String? identificationProjectTitle;
  double? contextualIdentificationScore;
  List<IdentificationEvidenceDTO> identificationEvidence;
  List<PlantLookalikeDTO> reviewedLookalikes;
  String? establishmentMeans;
  String? establishmentPlace;
  String? searchMatchReason;
  double? searchMatchConfidence;
  String? searchMatchedName;
  List<String> catalogTags;
  PlantSafetyInfoDTO safety;

  SpeciesDTO({
    this.id,
    required this.scientificName,
    this.synonyms,
    this.preferredCommonName,
    this.commonNames = const [],
    this.externalReferences = const {},
    this.canonicalTaxonKey,
    this.lastVerifiedAt,
    this.family,
    this.genus,
    this.species,
    required this.care,
    this.imageId,
    this.imageUrl,
    this.imageFallbackUrl,
    this.imageSource,
    this.imageSourceUrl,
    this.imageLicenseCode,
    this.imageAttribution,
    this.imageContent,
    this.imageContentType,
    required this.creator,
    this.externalId,
    this.identificationConfidence,
    this.identificationProvider,
    this.identificationModel,
    this.identificationProject,
    this.identificationProjectTitle,
    this.contextualIdentificationScore,
    this.identificationEvidence = const [],
    this.reviewedLookalikes = const [],
    this.establishmentMeans,
    this.establishmentPlace,
    this.searchMatchReason,
    this.searchMatchConfidence,
    this.searchMatchedName,
    this.catalogTags = const [],
    this.safety = const PlantSafetyInfoDTO.unknown(),
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
      canonicalTaxonKey: json['canonicalTaxonKey'],
      lastVerifiedAt: json['lastVerifiedAt'] == null
          ? null
          : DateTime.parse(json['lastVerifiedAt']),
      family: json['family'],
      genus: json['genus'],
      species: json['species'],
      care: SpeciesCareInfoDTO.fromJson(json['plantCareInfo']),
      imageId: json['imageId'],
      imageUrl: json['imageUrl'],
      imageFallbackUrl: json['imageFallbackUrl'],
      imageSource: json['imageSource'],
      imageSourceUrl: json['imageSourceUrl'],
      imageLicenseCode: json['imageLicenseCode'],
      imageAttribution: json['imageAttribution'],
      imageContent: json['imageContent'],
      imageContentType: json['imageContentType'],
      creator: json['creator'],
      externalId: json['externalId'],
      identificationConfidence:
          (json['identificationConfidence'] as num?)?.toDouble(),
      identificationProvider: json['identificationProvider'],
      identificationModel: json['identificationModel'],
      identificationProject: json['identificationProject'],
      identificationProjectTitle: json['identificationProjectTitle'],
      contextualIdentificationScore:
          (json['contextualIdentificationScore'] as num?)?.toDouble(),
      identificationEvidence:
          (json['identificationEvidence'] as List<dynamic>? ?? [])
              .map(
                (value) => IdentificationEvidenceDTO.fromJson(
                  value as Map<String, dynamic>,
                ),
              )
              .toList(),
      reviewedLookalikes: (json['reviewedLookalikes'] as List<dynamic>? ?? [])
          .map(
            (value) => PlantLookalikeDTO.fromJson(
              value as Map<String, dynamic>,
            ),
          )
          .toList(),
      establishmentMeans: json['establishmentMeans'],
      establishmentPlace: json['establishmentPlace'],
      searchMatchReason: json['searchMatchReason'],
      searchMatchConfidence:
          (json['searchMatchConfidence'] as num?)?.toDouble(),
      searchMatchedName: json['searchMatchedName'] as String?,
      catalogTags: (json['catalogTags'] as List<dynamic>? ?? [])
          .map((value) => value.toString())
          .toList(),
      safety: PlantSafetyInfoDTO.fromJson(
        json['safety'] as Map<String, dynamic>?,
      ),
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
      if (canonicalTaxonKey != null) 'canonicalTaxonKey': canonicalTaxonKey,
      if (lastVerifiedAt != null)
        'lastVerifiedAt': lastVerifiedAt!.toIso8601String(),
      if (family != null) 'family': family,
      if (genus != null) 'genus': genus,
      if (species != null) 'species': species,
      'plantCareInfo': care.toMap(),
      if (imageId != null) 'imageId': imageId,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (imageFallbackUrl != null) 'imageFallbackUrl': imageFallbackUrl,
      if (imageSource != null) 'imageSource': imageSource,
      if (imageSourceUrl != null) 'imageSourceUrl': imageSourceUrl,
      if (imageLicenseCode != null) 'imageLicenseCode': imageLicenseCode,
      if (imageAttribution != null) 'imageAttribution': imageAttribution,
      if (imageContent != null) 'imageContent': imageContent,
      if (imageContentType != null) 'imageContentType': imageContentType,
      'creator': creator,
      if (externalId != null) 'externalId': externalId,
      if (identificationConfidence != null)
        'identificationConfidence': identificationConfidence,
      if (identificationProvider != null)
        'identificationProvider': identificationProvider,
      if (identificationModel != null)
        'identificationModel': identificationModel,
      if (identificationProject != null)
        'identificationProject': identificationProject,
      if (identificationProjectTitle != null)
        'identificationProjectTitle': identificationProjectTitle,
      if (contextualIdentificationScore != null)
        'contextualIdentificationScore': contextualIdentificationScore,
      if (identificationEvidence.isNotEmpty)
        'identificationEvidence':
            identificationEvidence.map((evidence) => evidence.toMap()).toList(),
      if (reviewedLookalikes.isNotEmpty)
        'reviewedLookalikes':
            reviewedLookalikes.map((lookalike) => lookalike.toMap()).toList(),
      if (establishmentMeans != null) 'establishmentMeans': establishmentMeans,
      if (establishmentPlace != null) 'establishmentPlace': establishmentPlace,
      'catalogTags': catalogTags,
      'safety': safety.toMap(),
    };
  }

  void clearImageMetadata() {
    imageFallbackUrl = null;
    imageSource = null;
    imageSourceUrl = null;
    imageLicenseCode = null;
    imageAttribution = null;
  }

  String? preferredCommonNameFor(String language, {String? region}) {
    final String normalizedLanguage = language.toLowerCase();
    final String? normalizedRegion = region?.toUpperCase();

    BotanicalCommonNameDTO? findName(
        bool Function(BotanicalCommonNameDTO) matches) {
      for (final name in commonNames) {
        if (name.name.trim().isNotEmpty && matches(name)) return name;
      }
      return null;
    }

    bool matchesLanguage(BotanicalCommonNameDTO name) =>
        name.language?.toLowerCase() == normalizedLanguage;
    bool matchesRegion(BotanicalCommonNameDTO name) =>
        normalizedRegion != null &&
        name.region?.toUpperCase() == normalizedRegion;

    final BotanicalCommonNameDTO? localized = findName((name) =>
            name.preferred && matchesLanguage(name) && matchesRegion(name)) ??
        findName((name) => matchesLanguage(name) && matchesRegion(name)) ??
        findName((name) => name.preferred && matchesLanguage(name)) ??
        findName(matchesLanguage);
    if (localized != null) return localized.name.trim();

    final String? serverPreferred = preferredCommonName?.trim();
    if (serverPreferred != null && serverPreferred.isNotEmpty) {
      return serverPreferred;
    }
    return findName((name) => name.preferred)?.name.trim() ??
        findName((name) => true)?.name.trim();
  }

  String? searchDisplayCommonNameFor(String language, {String? region}) {
    final String? matchedName = searchMatchedName?.trim();
    if (matchedName != null &&
        matchedName.isNotEmpty &&
        _matchedByCommonName()) {
      return matchedName;
    }
    return preferredCommonNameFor(language, region: region);
  }

  bool _matchedByCommonName() {
    return switch (searchMatchReason) {
      'EXACT_COMMON_NAME' ||
      'COMMON_NAME_PREFIX' ||
      'COMMON_NAME_KEYWORDS' ||
      'COMMON_NAME_TYPO' =>
        true,
      _ => false,
    };
  }
}

class PlantSafetyInfoDTO {
  final String humanStatus;
  final String catStatus;
  final String dogStatus;
  final String? summary;
  final List<String> hazardousParts;
  final List<PlantSafetySourceDTO> sources;
  final DateTime? lastVerifiedAt;
  final bool reviewed;
  final String? matchedTaxon;

  const PlantSafetyInfoDTO({
    required this.humanStatus,
    required this.catStatus,
    required this.dogStatus,
    this.summary,
    this.hazardousParts = const [],
    this.sources = const [],
    this.lastVerifiedAt,
    required this.reviewed,
    this.matchedTaxon,
  });

  const PlantSafetyInfoDTO.unknown()
      : humanStatus = 'UNKNOWN',
        catStatus = 'UNKNOWN',
        dogStatus = 'UNKNOWN',
        summary = null,
        hazardousParts = const [],
        sources = const [],
        lastVerifiedAt = null,
        reviewed = false,
        matchedTaxon = null;

  factory PlantSafetyInfoDTO.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PlantSafetyInfoDTO.unknown();
    return PlantSafetyInfoDTO(
      humanStatus: json['humanStatus'] as String? ?? 'UNKNOWN',
      catStatus: json['catStatus'] as String? ?? 'UNKNOWN',
      dogStatus: json['dogStatus'] as String? ?? 'UNKNOWN',
      summary: json['summary'] as String?,
      hazardousParts: (json['hazardousParts'] as List<dynamic>? ?? [])
          .map((value) => value.toString())
          .toList(),
      sources: (json['sources'] as List<dynamic>? ?? [])
          .map(
            (value) => PlantSafetySourceDTO.fromJson(
              value as Map<String, dynamic>,
            ),
          )
          .toList(),
      lastVerifiedAt: json['lastVerifiedAt'] == null
          ? null
          : DateTime.parse(json['lastVerifiedAt'] as String),
      reviewed: json['reviewed'] as bool? ?? false,
      matchedTaxon: json['matchedTaxon'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'humanStatus': humanStatus,
      'catStatus': catStatus,
      'dogStatus': dogStatus,
      if (summary != null) 'summary': summary,
      'hazardousParts': hazardousParts,
      'sources': sources.map((source) => source.toMap()).toList(),
      if (lastVerifiedAt != null)
        'lastVerifiedAt': lastVerifiedAt!.toIso8601String(),
      'reviewed': reviewed,
      if (matchedTaxon != null) 'matchedTaxon': matchedTaxon,
    };
  }

  bool get hasUrgentHazard =>
      humanStatus == 'HIGHLY_TOXIC' ||
      catStatus == 'HIGHLY_TOXIC' ||
      dogStatus == 'HIGHLY_TOXIC';
}

class PlantSafetySourceDTO {
  final String name;
  final String url;

  const PlantSafetySourceDTO({required this.name, required this.url});

  factory PlantSafetySourceDTO.fromJson(Map<String, dynamic> json) {
    return PlantSafetySourceDTO(
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'url': url};
}

class PlantLookalikeDTO {
  final String scientificName;
  final String commonName;
  final String comparison;
  final String source;
  final String sourceReference;
  final bool contactHazard;

  const PlantLookalikeDTO({
    required this.scientificName,
    required this.commonName,
    required this.comparison,
    required this.source,
    required this.sourceReference,
    required this.contactHazard,
  });

  factory PlantLookalikeDTO.fromJson(Map<String, dynamic> json) {
    return PlantLookalikeDTO(
      scientificName: json['scientificName'] as String? ?? '',
      commonName: json['commonName'] as String? ?? '',
      comparison: json['comparison'] as String? ?? '',
      source: json['source'] as String? ?? '',
      sourceReference: json['sourceReference'] as String? ?? '',
      contactHazard: json['contactHazard'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scientificName': scientificName,
      'commonName': commonName,
      'comparison': comparison,
      'source': source,
      'sourceReference': sourceReference,
      'contactHazard': contactHazard,
    };
  }
}

class IdentificationEvidenceDTO {
  final String code;
  final double adjustment;
  final String source;
  final String? sourceReference;
  final int? observationCount;
  final String? detail;

  const IdentificationEvidenceDTO({
    required this.code,
    required this.adjustment,
    required this.source,
    this.sourceReference,
    this.observationCount,
    this.detail,
  });

  factory IdentificationEvidenceDTO.fromJson(Map<String, dynamic> json) {
    return IdentificationEvidenceDTO(
      code: json['code'] as String,
      adjustment: (json['adjustment'] as num?)?.toDouble() ?? 0,
      source: json['source'] as String? ?? '',
      sourceReference: json['sourceReference'] as String?,
      observationCount: (json['observationCount'] as num?)?.toInt(),
      detail: json['detail'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'adjustment': adjustment,
      'source': source,
      if (sourceReference != null) 'sourceReference': sourceReference,
      if (observationCount != null) 'observationCount': observationCount,
      if (detail != null) 'detail': detail,
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
  int? soilHumidity;
  double? minTemp;
  double? maxTemp;
  double? phMin;
  double? phMax;
  bool? allNull;
  String? lightRequirement;
  String? waterRequirement;
  String? source;
  String? sourceReference;
  DateTime? lastVerifiedAt;
  Map<String, CareFieldProvenanceDTO> fieldProvenance;

  SpeciesCareInfoDTO({
    this.light,
    this.humidity,
    this.soilHumidity,
    this.minTemp,
    this.maxTemp,
    this.phMin,
    this.phMax,
    this.allNull,
    this.lightRequirement,
    this.waterRequirement,
    this.source,
    this.sourceReference,
    this.lastVerifiedAt,
    this.fieldProvenance = const {},
  });

  factory SpeciesCareInfoDTO.fromJson(Map<String, dynamic> json) {
    return SpeciesCareInfoDTO(
      light: json['light'],
      humidity: json['humidity'],
      soilHumidity: json['soilHumidity'],
      minTemp: json['minTemp'],
      maxTemp: json['maxTemp'],
      phMin: json['phMin'],
      phMax: json['phMax'],
      allNull: json['allNull'],
      lightRequirement: json['lightRequirement'],
      waterRequirement: json['waterRequirement'],
      source: json['source'],
      sourceReference: json['sourceReference'],
      lastVerifiedAt: json['lastVerifiedAt'] == null
          ? null
          : DateTime.parse(json['lastVerifiedAt']),
      fieldProvenance:
          (json['fieldProvenance'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(
          key,
          CareFieldProvenanceDTO.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (light != null) 'light': light,
      if (humidity != null) 'humidity': humidity,
      if (soilHumidity != null) 'soilHumidity': soilHumidity,
      if (minTemp != null) 'minTemp': minTemp,
      if (maxTemp != null) 'maxTemp': maxTemp,
      if (phMin != null) 'phMin': phMin,
      if (phMax != null) 'phMax': phMax,
      if (allNull != null) 'allNull': allNull,
      if (source != null) 'source': source,
      if (sourceReference != null) 'sourceReference': sourceReference,
      if (lastVerifiedAt != null)
        'lastVerifiedAt': lastVerifiedAt!.toIso8601String(),
      'fieldProvenance': fieldProvenance.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
    };
  }
}

class CareFieldProvenanceDTO {
  String? source;
  String? sourceReference;
  double? confidence;
  DateTime? verifiedAt;

  CareFieldProvenanceDTO({
    this.source,
    this.sourceReference,
    this.confidence,
    this.verifiedAt,
  });

  factory CareFieldProvenanceDTO.fromJson(Map<String, dynamic> json) {
    return CareFieldProvenanceDTO(
      source: json['source'],
      sourceReference: json['sourceReference'],
      confidence: (json['confidence'] as num?)?.toDouble(),
      verifiedAt: json['verifiedAt'] == null
          ? null
          : DateTime.parse(json['verifiedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (source != null) 'source': source,
      if (sourceReference != null) 'sourceReference': sourceReference,
      if (confidence != null) 'confidence': confidence,
      if (verifiedAt != null) 'verifiedAt': verifiedAt!.toIso8601String(),
    };
  }
}
