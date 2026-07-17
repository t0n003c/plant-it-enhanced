import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_it/back_button.dart';
import 'package:plant_it/commons.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/plant_details/species_tab.dart';
import 'package:plant_it/search/header.dart';
import 'package:plant_it/search/species_details_bottom_bar.dart';
import 'package:plant_it/toast/toast_manager.dart';
import 'dart:convert';

class SpeciesDetailsPage extends StatefulWidget {
  final Environment env;
  final SpeciesDTO species;
  final Function(SpeciesDTO) updateSpeciesLocally;
  final XFile? identificationImage;

  const SpeciesDetailsPage({
    super.key,
    required this.env,
    required this.species,
    required this.updateSpeciesLocally,
    this.identificationImage,
  });

  @override
  State<StatefulWidget> createState() => _SpeciesDetailsPageState();
}

class _SpeciesDetailsPageState extends State<SpeciesDetailsPage> {
  late SpeciesDTO _species;
  bool _refreshingCare = false;

  @override
  void initState() {
    super.initState();
    _species = widget.species;
  }

  void _updateSpeciesLocally(SpeciesDTO species) {
    widget.updateSpeciesLocally(species);
    fetchAndSetPlants(context, widget.env);
  }

  Future<void> _refreshCareGuide() async {
    if (_species.id == null) return;
    setState(() => _refreshingCare = true);
    try {
      final response = await widget.env.http.post(
        'botanical-info/${_species.id}/care/refresh',
        {},
      );
      final dynamic body = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode != 200) {
        throw Exception(body is Map ? body['message'] : 'Care refresh failed');
      }
      final SpeciesDTO refreshed =
          SpeciesDTO.fromJson(body as Map<String, dynamic>);
      if (!mounted) return;
      setState(() => _species = refreshed);
      _updateSpeciesLocally(refreshed);
      widget.env.toastManager.showToast(
        context,
        refreshed.care.allNull == true
            ? ToastNotificationType.warning
            : ToastNotificationType.success,
        refreshed.care.allNull == true
            ? AppLocalizations.of(context).careGuideNotFound
            : AppLocalizations.of(context).careGuideUpdated,
      );
    } catch (error, stackTrace) {
      widget.env.logger.error(error, stackTrace);
      if (!mounted) return;
      widget.env.toastManager.showToast(
        context,
        ToastNotificationType.error,
        AppLocalizations.of(context).generalError,
      );
    } finally {
      if (mounted) setState(() => _refreshingCare = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SpeciesDetailsBottomActionBar(
        isDeletable: _species.creator == "USER",
        species: _species,
        http: widget.env.http,
        env: widget.env,
        updateSpeciesLocally: _updateSpeciesLocally,
        identificationImage: widget.identificationImage,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: ClampingScrollPhysics(),
            child: Column(
              children: [
                Container(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * .5,
                    maxHeight: MediaQuery.of(context).size.height * .5,
                  ),
                  child: SpeciesImageHeader(
                    species: _species,
                    env: widget.env,
                    localImage: widget.identificationImage,
                  ),
                ),
                SpeciesDetailsTab(
                  species: _species,
                  isLoading: false,
                  onRefreshCare: _species.id == null ? null : _refreshCareGuide,
                  refreshingCare: _refreshingCare,
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
      ),
    );
  }
}
