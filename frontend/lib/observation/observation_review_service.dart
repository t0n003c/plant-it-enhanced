import 'dart:typed_data';

import 'package:plant_it/dto/observation_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/observation/offline_observation_draft.dart';

class ObservationReviewService {
  final Environment env;

  const ObservationReviewService(this.env);

  Future<OfflineObservationDraft> createDraft(
    ObservationDTO observation,
  ) async {
    if (observation.id == null) {
      throw ArgumentError('A saved observation ID is required for review');
    }
    final List<OfflineObservationPhoto> photos = [];
    for (final String imageId in observation.imageIds) {
      final response = await env.http.get('image/content/$imageId');
      if (response.statusCode != 200) {
        throw Exception('Could not load the saved field photo');
      }
      final String contentType =
          response.headers['content-type'] ?? 'image/jpeg';
      photos.add(
        OfflineObservationPhoto(
          localId: 'server-image-$imageId',
          name: '$imageId.${_extension(contentType)}',
          contentType: contentType.split(';').first.trim(),
          organ: 'auto',
          bytes: Uint8List.fromList(response.bodyBytes),
          serverImageId: imageId,
        ),
      );
    }
    return OfflineObservationDraft(
      localId: 'server-observation-${observation.id}',
      accountScope: env.offlineAccountScope,
      createdAt: observation.createdAt ?? observation.observedAt,
      updatedAt: DateTime.now(),
      observedAt: observation.observedAt,
      serverObservationId: observation.id,
      botanicalInfoId: observation.botanicalInfoId,
      displayName: observation.displayName,
      trailName: observation.trailName,
      habitat: observation.habitat,
      notes: observation.notes,
      latitude: observation.latitude,
      longitude: observation.longitude,
      accuracyMeters: observation.accuracyMeters,
      elevationMeters: observation.elevationMeters,
      locationPrivacy: observation.locationPrivacy,
      status: observation.status,
      identificationConfidence: observation.identificationConfidence,
      identificationProvider: observation.identificationProvider,
      hikeSessionId: observation.hikeSessionId,
      hikeSessionName: observation.hikeSessionName,
      photos: photos,
      syncState: TrailSyncState.pending,
    );
  }

  String _extension(String contentType) {
    final String normalized = contentType.toLowerCase();
    if (normalized.contains('png')) return 'png';
    if (normalized.contains('webp')) return 'webp';
    return 'jpg';
  }
}
