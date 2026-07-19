import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:material_loading_buttons/material_loading_buttons.dart';
import 'package:plant_it/app_exception.dart';
import 'package:plant_it/auth_scaffold.dart';
import 'package:plant_it/commons.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/login.dart';
import 'package:plant_it/toast/toast_manager.dart';

class SetServer extends StatefulWidget {
  final Environment env;

  const SetServer({
    super.key,
    required this.env,
  });

  @override
  State<SetServer> createState() => _SetServerState();
}

class _SetServerState extends State<SetServer> {
  final TextEditingController _backendController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool insertedBackendController = false;
  bool _isLoading = false;

  void _ping() async {
    setState(() {
      _isLoading = true;
    });
    try {
      String url = _backendController.text;
      url = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      widget.env.http.backendUrl = "$url/api/";
      widget.env.prefs.setString("serverURL", "$url/api/");
      final response = await widget.env.http
          .get('info/ping')
          .timeout(const Duration(seconds: 3));
      if (!mounted) return;
      if (response.statusCode == 200 && response.body == "pong") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(env: widget.env),
          ),
        );
      } else {
        widget.env.logger.error("Cannot connect to the server");
        throw AppException(AppLocalizations.of(context).noBackend);
      }
    } catch (e, st) {
      if (!mounted) return;
      widget.env.logger.error(e, st);
      widget.env.toastManager.showToast(context, ToastNotificationType.error,
          AppLocalizations.of(context).noBackend);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _backendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return AuthScaffold(
      title: localizations.appName,
      subtitle: localizations.insertBackendURL,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              autofocus: true,
              controller: _backendController,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).serverURL,
                  prefixIcon: const Icon(Icons.link_rounded),
                  border: const OutlineInputBorder(),
                  hintText: "http://192.168.1.5:8080"),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context).enterValue;
                }
                if (!isValidUrl(value)) {
                  return AppLocalizations.of(context).enterValidURL;
                }
                return null;
              },
              onFieldSubmitted: (value) {
                if (_formKey.currentState!.validate()) {
                  _ping();
                }
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedLoadingButton(
                isLoading: _isLoading,
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _ping();
                  }
                },
                child: Text(AppLocalizations.of(context).go),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
