import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_it/dto/observation_dto.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/search/guided_photo_sheet.dart';
import 'package:plant_it/search/photo_source_sheet.dart';
import 'package:plant_it/toast/toast_manager.dart';

class AddObservationPage extends StatefulWidget {
  final Environment env;

  const AddObservationPage({
    super.key,
    required this.env,
  });

  @override
  State<AddObservationPage> createState() => _AddObservationPageState();
}

class _AddObservationPageState extends State<AddObservationPage> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _trailController = TextEditingController();
  final TextEditingController _habitatController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  List<XFile> _photos = [];
  List<String> _organs = [];
  List<SpeciesDTO> _candidates = [];
  SpeciesDTO? _selectedCandidate;
  Position? _position;
  String _locationPrivacy = 'PRIVATE';
  bool _identifying = false;
  bool _gettingLocation = false;
  bool _saving = false;
  String? _identificationError;

  Future<void> _startGuidedCapture(ImageSource source) async {
    Navigator.of(context).pop();
    final XFile? initialImage = await ImagePicker().pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (initialImage == null || !mounted) return;
    final GuidedPhotoSelection? selection =
        await showModalBottomSheet<GuidedPhotoSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PhotoSourceSheet.backgroundColor,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * .92,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) => GuidedPhotoSheet(initialImage: initialImage),
    );
    if (selection == null || !mounted) return;
    setState(() {
      _photos = selection.images;
      _organs = selection.organs;
      _candidates = [];
      _selectedCandidate = null;
      _identificationError = null;
    });
    await _identifyPhotos();
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PhotoSourceSheet.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) => PhotoSourceSheet(
        onCamera: () => _startGuidedCapture(ImageSource.camera),
        onGallery: () => _startGuidedCapture(ImageSource.gallery),
      ),
    );
  }

  Future<void> _identifyPhotos() async {
    if (_photos.isEmpty) return;
    setState(() => _identifying = true);
    try {
      final response = await widget.env.http.identifyPlant(
        _photos,
        _organs,
        Localizations.localeOf(context).languageCode,
      );
      final dynamic body = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode != 200) {
        throw Exception(
          body is Map
              ? body['message'] ?? 'Plant identification failed'
              : 'Plant identification failed',
        );
      }
      if (!mounted) return;
      setState(() {
        _candidates = (body as List<dynamic>)
            .map((item) => SpeciesDTO.fromJson(item as Map<String, dynamic>))
            .take(3)
            .toList();
        if (_candidates.isEmpty) {
          _identificationError =
              AppLocalizations.of(context).identificationFailedSaveAnyway;
        }
      });
    } catch (error, stackTrace) {
      widget.env.logger.warning('Field identification failed: $error');
      widget.env.logger.debug(stackTrace);
      if (!mounted) return;
      setState(() {
        _identificationError =
            AppLocalizations.of(context).identificationFailedSaveAnyway;
      });
    } finally {
      if (mounted) setState(() => _identifying = false);
    }
  }

  Future<void> _captureLocation() async {
    setState(() => _gettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context).locationPermissionDenied),
          ),
        );
        return;
      }
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      setState(() {
        _position = position;
        _locationPrivacy = 'PRIVATE';
      });
    } catch (error, stackTrace) {
      widget.env.logger.warning('Could not capture field location: $error');
      widget.env.logger.debug(stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).locationUnavailable),
        ),
      );
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  Future<SpeciesDTO?> _persistSelectedTaxon() async {
    final SpeciesDTO? selected = _selectedCandidate;
    if (selected == null || selected.id != null) return selected;
    final response =
        await widget.env.http.post('botanical-info', selected.toMap());
    final dynamic body = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200) {
      throw Exception(
        body is Map ? body['message'] ?? 'Could not save taxon' : body,
      );
    }
    return SpeciesDTO.fromJson(body as Map<String, dynamic>);
  }

  Future<void> _saveObservation() async {
    final AppLocalizations localizations = AppLocalizations.of(context);
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.photosRequired)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final SpeciesDTO? taxon = await _persistSelectedTaxon();
      final observation = ObservationDTO(
        botanicalInfoId: taxon?.id,
        observedAt: DateTime.now(),
        displayName: _displayNameController.text,
        trailName: _trailController.text,
        habitat: _habitatController.text,
        notes: _notesController.text,
        latitude: _position?.latitude,
        longitude: _position?.longitude,
        accuracyMeters: _position?.accuracy,
        elevationMeters: _position?.altitude,
        locationPrivacy: _locationPrivacy,
        status: taxon == null ? 'UNIDENTIFIED' : 'CONFIRMED',
        identificationConfidence: taxon?.identificationConfidence,
        identificationProvider: taxon?.identificationProvider,
      );
      final response =
          await widget.env.http.post('observation', observation.toMap());
      final dynamic body = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode != 200) {
        throw Exception(
          body is Map
              ? body['message'] ?? localizations.observationSaveError
              : localizations.observationSaveError,
        );
      }
      final ObservationDTO created =
          ObservationDTO.fromJson(body as Map<String, dynamic>);
      bool photoUploadFailed = false;
      for (int index = 0; index < _photos.length; index++) {
        final uploadResponse = await widget.env.http.uploadObservationImage(
          _photos[index],
          created.id!,
          description: _organs[index],
        );
        if (uploadResponse.statusCode != 200) photoUploadFailed = true;
      }
      if (!mounted) return;
      widget.env.toastManager.showToast(
        context,
        photoUploadFailed
            ? ToastNotificationType.warning
            : ToastNotificationType.success,
        photoUploadFailed
            ? localizations.observationPhotoUploadWarning
            : localizations.observationSaved,
      );
      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      widget.env.logger.error(error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _trailController.dispose();
    _habitatController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).recordTrailFind)),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          key: const ValueKey('save-trail-observation-button'),
          onPressed: _saving ? null : _saveObservation,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(58),
            backgroundColor: const Color(0xFFC7F9CC),
            foregroundColor: const Color(0xFF10231C),
          ),
          icon: _saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.bookmark_add_outlined),
          label: Text(
            AppLocalizations.of(context).saveTrailObservation,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _safetyCard(context),
          const SizedBox(height: 14),
          _photoSection(context),
          if (_identifying) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_identificationError != null) ...[
            const SizedBox(height: 12),
            _messageCard(
              Icons.cloud_off_outlined,
              _identificationError!,
              const Color(0xFFFFD166),
            ),
          ],
          if (_candidates.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).chooseIdentification,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 5),
            Text(AppLocalizations.of(context).identificationOptional),
            const SizedBox(height: 8),
            ..._candidates.map((candidate) => _candidateTile(candidate)),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _displayNameController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).name,
              hintText: AppLocalizations.of(context).unidentifiedTrailFind,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _trailController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).trailOrPark,
              prefixIcon: const Icon(Icons.route_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _habitatController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).habitat,
              prefixIcon: const Icon(Icons.forest_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _notesController,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).fieldNotes,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 18),
          _locationSection(context),
        ],
      ),
    );
  }

  Widget _safetyCard(BuildContext context) {
    return Card(
      color: const Color(0xFF263E35),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.eco_outlined, color: Color(0xFF9BE59F)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).leaveWhatYouFind,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).leaveWhatYouFindHint,
                    style: const TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoSection(BuildContext context) {
    return Card(
      color: const Color(0xFF182C25),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context).startWithPhoto,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).observationPhotoIntro,
              style: const TextStyle(color: Colors.white70),
            ),
            if (_photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: FutureBuilder<Uint8List>(
                      future: _photos[index].readAsBytes(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox(
                            width: 96,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return Image.memory(
                          snapshot.data!,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          semanticLabel: _organs[index],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('trail-photo-button'),
              onPressed: _identifying ? null : _showPhotoOptions,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                backgroundColor: const Color(0xFF315D4E),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(
                _photos.isEmpty
                    ? AppLocalizations.of(context).startWithPhoto
                    : AppLocalizations.of(context).changeObservationPhotos,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _candidateTile(SpeciesDTO candidate) {
    final Locale locale = Localizations.localeOf(context);
    final String commonName = candidate.preferredCommonNameFor(
          locale.languageCode,
          region: locale.countryCode,
        ) ??
        candidate.scientificName;
    return Card(
      color: _selectedCandidate == candidate
          ? const Color(0xFF315D4E)
          : const Color(0xFF182C25),
      child: RadioListTile<SpeciesDTO>(
        value: candidate,
        groupValue: _selectedCandidate,
        activeColor: const Color(0xFFC7F9CC),
        onChanged: (value) => setState(() => _selectedCandidate = value),
        title: Text(
          commonName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (commonName != candidate.scientificName)
              Text(
                candidate.scientificName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (candidate.identificationConfidence != null)
              Text(
                '${candidate.identificationProvider ?? 'AI'} '
                '${(candidate.identificationConfidence! * 100).round()}%',
                style: const TextStyle(color: Colors.white70),
              ),
            if (candidate.catalogTags.contains('CONTACT_HAZARD'))
              Text(
                AppLocalizations.of(context).avoidPlantContact,
                style: const TextStyle(
                  color: Color(0xFFFFD166),
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _locationSection(BuildContext context) {
    return Card(
      color: const Color(0xFF182C25),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_position == null)
              OutlinedButton.icon(
                onPressed: _gettingLocation ? null : _captureLocation,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  minimumSize: const Size.fromHeight(56),
                ),
                icon: _gettingLocation
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_outlined),
                label: Text(
                  _gettingLocation
                      ? AppLocalizations.of(context).recordingLocation
                      : AppLocalizations.of(context).recordLocation,
                ),
              )
            else ...[
              _messageCard(
                Icons.lock_outline,
                AppLocalizations.of(context)
                    .locationCaptured(_position!.accuracy.round()),
                const Color(0xFF9BE59F),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _locationPrivacy,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).locationPrivacy,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'PRIVATE',
                    child: Text(AppLocalizations.of(context).privateLocation),
                  ),
                  DropdownMenuItem(
                    value: 'OBSCURED',
                    child: Text(AppLocalizations.of(context).obscuredLocation),
                  ),
                  DropdownMenuItem(
                    value: 'OPEN',
                    child: Text(AppLocalizations.of(context).openLocation),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _locationPrivacy = value);
                },
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _position = null),
                icon: const Icon(Icons.location_off_outlined),
                label: Text(AppLocalizations.of(context).removeLocation),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _messageCard(IconData icon, String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
