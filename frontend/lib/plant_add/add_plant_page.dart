import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_it/app_exception.dart';
import 'package:plant_it/back_button.dart';
import 'package:plant_it/change_notifiers.dart';
import 'package:plant_it/dto/plant_dto.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/plant_add/add_plant_body.dart';
import 'package:plant_it/plant_add/header.dart';
import 'package:plant_it/toast/toast_manager.dart';
import 'package:provider/provider.dart';

class AddPlantPage extends StatefulWidget {
  final SpeciesDTO species;
  final Environment env;
  final XFile? identificationImage;

  const AddPlantPage({
    super.key,
    required this.species,
    required this.env,
    this.identificationImage,
  });

  @override
  State<AddPlantPage> createState() => _AddPlantPageState();
}

class _AddPlantPageState extends State<AddPlantPage> {
  late final PlantDTO _toCreate;
  late Future<String> _initialPlantName;
  bool _nameInitializationStarted = false;
  bool _createSuggestedWateringReminder = true;
  bool _isCreating = false;

  String _defaultPlantName() {
    final Locale locale = Localizations.localeOf(context);
    return widget.species.searchDisplayCommonNameFor(
          locale.languageCode,
          region: locale.countryCode,
        ) ??
        widget.species.preferredCommonNameFor(
          locale.languageCode,
          region: locale.countryCode,
        ) ??
        widget.species.scientificName;
  }

  Future<String> _getAndSetInitialPlantName() async {
    final String scientificName = widget.species.scientificName;
    final String defaultName = _defaultPlantName();
    if (widget.species.id == null) {
      _toCreate.info.personalName = defaultName;
      return defaultName;
    }
    try {
      final response = await widget.env.http
          .get("botanical-info/${widget.species.id}/_count");
      if (response.statusCode != 200) {
        widget.env.logger.warning(
          "Could not get plant name count for $scientificName; using $defaultName",
        );
        _toCreate.info.personalName = defaultName;
        return defaultName;
      }
      final int count = int.tryParse(response.body.trim()) ?? 0;
      final String name = "$defaultName${count == 0 ? "" : " $count"}";
      _toCreate.info.personalName = name;
      return name;
    } catch (e, st) {
      widget.env.logger.error(e, st);
      _toCreate.info.personalName = defaultName;
      return defaultName;
    }
  }

  Future<void> _createPlant() async {
    if (_isCreating) return;
    final EventsNotifier? eventsNotifier =
        Provider.of<EventsNotifier?>(context, listen: false);
    setState(() => _isCreating = true);
    try {
      await _initialPlantName;
      int speciesId = widget.species.id ?? -1;
      SpeciesDTO? updatedSpecies;
      if (widget.species.id == null) {
        updatedSpecies = await _createSpecies();
      } else if (widget.species.care.allNull == true) {
        updatedSpecies = await _refreshCareGuide(widget.species);
      }
      _toCreate.speciesId = updatedSpecies?.id ?? speciesId;
      _toCreate.info.state = "PURCHASED";
      final response = await widget.env.http.post("plant", _toCreate.toMap());
      final responseBody = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode != 200) {
        widget.env.logger
            .error("Error while creating plant: ${responseBody["message"]}");
        if (!mounted) return;
        throw AppException(AppLocalizations.of(context).errorCreatingPlant);
      }
      final PlantDTO createdPlant = PlantDTO.fromJson(responseBody);
      final PlantDTO savedPlant = await _saveIdentificationImage(createdPlant);
      widget.env.plants.add(savedPlant);
      eventsNotifier?.notify();
      if (_createSuggestedWateringReminder && savedPlant.id != null) {
        await _createSuggestedReminder(savedPlant.id!);
      }
      widget.env.logger.info("Plant successfully created");
      if (!mounted) return;
      widget.env.toastManager.showToast(context, ToastNotificationType.success,
          AppLocalizations.of(context).plantCreatedSuccessfully);
      Navigator.pop(context, updatedSpecies);
    } catch (e, st) {
      widget.env.logger.error(e, st);
      if (mounted) {
        final String message = e is AppException
            ? e.cause
            : AppLocalizations.of(context).generalError;
        widget.env.toastManager.showToast(
          context,
          ToastNotificationType.error,
          message,
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<PlantDTO> _saveIdentificationImage(PlantDTO plant) async {
    final XFile? image = widget.identificationImage;
    if (image == null || plant.id == null) return plant;

    try {
      final imageResponse = await widget.env.http.uploadImage(image, plant.id!);
      if (imageResponse.statusCode != 200) {
        widget.env.logger.warning(
          'Plant was created, but its identification photo upload failed '
          '(${imageResponse.statusCode})',
        );
        return plant;
      }

      final String? imageId = _imageIdFromResponse(imageResponse.body);
      if (imageId == null) {
        widget.env.logger.warning(
          'Plant photo upload returned no image identifier',
        );
        return plant;
      }

      final avatarResponse = await widget.env.http.post(
        'image/plant/${plant.id}/$imageId',
        {},
      );
      if (avatarResponse.statusCode != 200) {
        widget.env.logger.warning(
          'Plant photo was uploaded, but could not be linked as the avatar '
          '(${avatarResponse.statusCode})',
        );
        return plant;
      }
      final decoded = json.decode(utf8.decode(avatarResponse.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        return PlantDTO.fromJson(decoded);
      }
    } catch (error, stackTrace) {
      widget.env.logger.warning(
        'Plant was created, but its identification photo could not be saved: $error',
      );
      widget.env.logger.debug(stackTrace);
    }
    return plant;
  }

  String? _imageIdFromResponse(String body) {
    final String trimmed = body.trim();
    if (trimmed.isEmpty) return null;
    try {
      final decoded = json.decode(trimmed);
      if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded.trim();
      }
    } catch (_) {
      // Older servers may return the identifier as plain text.
    }
    return trimmed.replaceAll(RegExp(r'^"|"$'), '');
  }

  Future<void> _createSuggestedReminder(int plantId) async {
    try {
      final response = await widget.env.http.post(
        'plant/$plantId/care-suggestion/reminder',
        {},
      );
      if (response.statusCode != 200) {
        widget.env.logger.warning(
          'Plant was created, but its suggested watering reminder was not',
        );
      }
    } catch (error, stackTrace) {
      widget.env.logger.warning(
        'Plant was created, but its suggested watering reminder failed: $error',
      );
      widget.env.logger.debug(stackTrace);
    }
  }

  Future<SpeciesDTO> _createSpecies() async {
    try {
      final response =
          await widget.env.http.post("botanical-info", widget.species.toMap());
      final responseBody = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode != 200) {
        widget.env.logger
            .error("Error while creating species: ${responseBody["message"]}");
        if (!mounted) throw AppException("Context not mounted, error.");
        throw AppException(AppLocalizations.of(context).errorCreatingSpecies);
      }
      widget.env.logger.info("Species successfully created");
      return _refreshCareGuide(SpeciesDTO.fromJson(responseBody));
    } catch (e, st) {
      widget.env.logger.error(e, st);
      if (e is AppException) rethrow;
      throw AppException(e.toString());
    }
  }

  Future<SpeciesDTO> _refreshCareGuide(SpeciesDTO species) async {
    if (species.id == null) return species;
    try {
      final careResponse = await widget.env.http.post(
        'botanical-info/${species.id}/care/refresh',
        {},
      );
      if (careResponse.statusCode == 200) {
        return SpeciesDTO.fromJson(
          json.decode(utf8.decode(careResponse.bodyBytes)),
        );
      }
      widget.env.logger.warning(
        'Species is available, but its care guide could not be enriched',
      );
    } catch (error, stackTrace) {
      widget.env.logger.warning(
        'Species is available, but its care guide could not be enriched: $error',
      );
      widget.env.logger.debug(stackTrace);
    }
    return species;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nameInitializationStarted) return;
    _nameInitializationStarted = true;
    _initialPlantName = _getAndSetInitialPlantName();
  }

  @override
  void initState() {
    super.initState();
    _toCreate = PlantDTO(info: PlantInfoDTO());
    _toCreate.info.currencySymbol = '\$';
    _toCreate.info.growingEnvironment = 'INDOOR';
    _toCreate.info.lightExposure = 'MEDIUM';
    _toCreate.info.potMaterial = 'PLASTIC';
    _toCreate.info.hasDrainage = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _isCreating ? null : _createPlant,
        child: _isCreating
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_outlined),
      ),
      body: FutureBuilder<String>(
        future: _initialPlantName,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            _toCreate.info.personalName = snapshot.data!;
            return Stack(
              children: [
                SingleChildScrollView(
                  physics: ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height * .3,
                          maxHeight: MediaQuery.of(context).size.height * .3,
                        ),
                        child: AddPlantImageHeader(
                          species: widget.species,
                          env: widget.env,
                          localImage: widget.identificationImage,
                        ),
                      ),
                      AddPlantBody(
                        toCreate: _toCreate,
                        care: widget.species.care,
                        createSuggestedReminder:
                            _createSuggestedWateringReminder,
                        onCreateSuggestedReminderChanged: (value) =>
                            _createSuggestedWateringReminder = value,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10.0,
                  left: 10.0,
                  child: AppBackButton(),
                ),
              ],
            );
          } else {
            return const Center(child: Text('Unexpected error'));
          }
        },
      ),
    );
  }
}
