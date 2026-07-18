class PlantDTO {
  int? id;
  PlantInfoDTO info;
  int? ownerId;
  String? avatarImageId;
  String? avatarMode;
  int? diaryId;
  int? speciesId;
  String? species;

  PlantDTO({
    this.id,
    required this.info,
    this.ownerId,
    this.avatarImageId,
    this.avatarMode,
    this.diaryId,
    this.speciesId,
    this.species,
  });

  factory PlantDTO.fromJson(Map<String, dynamic> json) {
    return PlantDTO(
      id: json['id'],
      info: PlantInfoDTO.fromJson(json['info']),
      ownerId: json['ownerId'],
      avatarImageId: json['avatarImageId'],
      avatarMode: json['avatarMode'],
      diaryId: json['diaryId'],
      speciesId: json['botanicalInfoId'],
      species: json['botanicalInfoSpecies'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'info': info.toMap(),
      if (ownerId != null) 'ownerId': ownerId,
      if (avatarImageId != null) 'avatarImageId': avatarImageId,
      if (avatarMode != null) 'avatarMode': avatarMode,
      if (diaryId != null) 'diaryId': diaryId,
      if (speciesId != null) 'botanicalInfoId': speciesId,
      if (species != null) 'botanicalInfoName': species,
    };
  }
}

class PlantInfoDTO {
  String? startDate;
  String? personalName;
  String? endDate;
  String? state;
  String? note;
  double? purchasedPrice;
  String? currencySymbol;
  String? seller;
  String? location;
  String? growingEnvironment;
  String? lightExposure;
  String? windowDirection;
  double? potDiameterCm;
  String? potMaterial;
  bool? hasDrainage;
  String? soilType;
  String? lastWateredAt;
  String? lastRepottedAt;
  double? latitude;
  double? longitude;

  PlantInfoDTO({
    this.startDate,
    this.personalName,
    this.endDate,
    this.state,
    this.note,
    this.purchasedPrice,
    this.currencySymbol,
    this.seller,
    this.location,
    this.growingEnvironment,
    this.lightExposure,
    this.windowDirection,
    this.potDiameterCm,
    this.potMaterial,
    this.hasDrainage,
    this.soilType,
    this.lastWateredAt,
    this.lastRepottedAt,
    this.latitude,
    this.longitude,
  });

  factory PlantInfoDTO.fromJson(Map<String, dynamic> json) {
    return PlantInfoDTO(
      startDate: json['startDate'],
      personalName: json['personalName'],
      endDate: json['endDate'],
      state: json['state'],
      note: json['note'],
      purchasedPrice: json['purchasedPrice'],
      currencySymbol: json['currencySymbol'],
      seller: json['seller'],
      location: json['location'],
      growingEnvironment: json['growingEnvironment'],
      lightExposure: json['lightExposure'],
      windowDirection: json['windowDirection'],
      potDiameterCm: (json['potDiameterCm'] as num?)?.toDouble(),
      potMaterial: json['potMaterial'],
      hasDrainage: json['hasDrainage'],
      soilType: json['soilType'],
      lastWateredAt: json['lastWateredAt'],
      lastRepottedAt: json['lastRepottedAt'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (startDate != null) 'startDate': startDate,
      if (personalName != null) 'personalName': personalName,
      if (endDate != null) 'endDate': endDate,
      if (state != null) 'state': state,
      if (note != null) 'note': note,
      if (purchasedPrice != null) 'purchasedPrice': purchasedPrice,
      if (currencySymbol != null) 'currencySymbol': currencySymbol,
      if (seller != null) 'seller': seller,
      if (location != null) 'location': location,
      if (growingEnvironment != null) 'growingEnvironment': growingEnvironment,
      if (lightExposure != null) 'lightExposure': lightExposure,
      if (windowDirection != null) 'windowDirection': windowDirection,
      if (potDiameterCm != null) 'potDiameterCm': potDiameterCm,
      if (potMaterial != null) 'potMaterial': potMaterial,
      if (hasDrainage != null) 'hasDrainage': hasDrainage,
      if (soilType != null) 'soilType': soilType,
      if (lastWateredAt != null) 'lastWateredAt': lastWateredAt,
      if (lastRepottedAt != null) 'lastRepottedAt': lastRepottedAt,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}
