import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:plant_it/app_exception.dart';
import 'package:plant_it/app_http_client.dart';
import 'package:plant_it/commons.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/change_notifiers.dart';
import 'package:plant_it/notify_conf_notifier.dart';
import 'package:plant_it/observation/trail_draft_repository.dart';
import 'package:plant_it/set_server.dart';
import 'package:plant_it/splash_screen.dart';
import 'package:plant_it/template.dart';
import 'package:plant_it/theme.dart';
import 'package:plant_it/toast/toast_manager.dart';
import 'package:plant_it/locale_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    TrailDraftRepository trailDraftRepository = MemoryTrailDraftRepository();
    Object? offlineStorageError;
    StackTrace? offlineStorageStackTrace;
    try {
      await Hive.initFlutter();
      trailDraftRepository = HiveTrailDraftRepository(
        observationBox:
            await Hive.openBox<dynamic>('trail_observation_drafts_v1'),
        hikeSessionBox: await Hive.openBox<dynamic>('trail_hike_sessions_v1'),
      );
    } catch (error, stackTrace) {
      offlineStorageError = error;
      offlineStorageStackTrace = stackTrace;
    }
    final isLoggedIn = prefs.containsKey('serverKey');
    final AppHttpClient http = AppHttpClient();
    final Environment env = Environment(
      prefs: prefs,
      http: http,
      backendVersion: "",
      credentials: Credentials(
        username: "anonymous",
        email: "not@an.email",
      ),
      notificationDispatcher: [],
      eventTypes: [],
      plants: [],
      trailDraftRepository: trailDraftRepository,
      durableTrailStorage: offlineStorageError == null,
    );
    if (offlineStorageError != null) {
      env.logger.warning(
        'Durable offline storage is unavailable: $offlineStorageError',
      );
      env.logger.debug(offlineStorageStackTrace);
    }

    if (isLoggedIn) {
      if (prefs.containsKey('serverURL')) {
        final String? serverURL = prefs.getString("serverURL");
        if (serverURL != null) {
          http.backendUrl = serverURL;
        }
      }
      if (prefs.containsKey('serverKey')) {
        final String? serverKey = prefs.getString("serverKey");
        if (serverKey != null) {
          http.key = serverKey;
        }
      }
      if (prefs.containsKey('username')) {
        final String? username = prefs.getString("username");
        if (username != null) {
          env.credentials.username = username;
        }
      }
      if (prefs.containsKey('email')) {
        final String? email = prefs.getString("email");
        if (email != null) {
          env.credentials.email = email;
        }
      }
    }

    Locale? prefSavedLocale;
    if (prefs.containsKey('language_code')) {
      prefSavedLocale = Locale(
          prefs.getString('language_code')!, prefs.getString('country_code'));
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => EventsNotifier()),
          ChangeNotifierProvider(create: (context) => PhotosNotifier()),
          ChangeNotifierProvider(create: (context) => NotifyConfNotifier()),
          ChangeNotifierProvider(create: (context) => LocaleProvider()),
        ],
        child: Container(
          color: const Color(0xFF061913),
          child: Center(
            child: SizedBox(
              width: maxWidth,
              child: MyApp(
                env: env,
                isLoggedIn: isLoggedIn,
                prefSavedLocale: prefSavedLocale,
              ),
            ),
          ),
        ),
      ),
    );
  }, (error, stack) {
    if (error is AppException) {
      ToastificationToastManager().showToast(navigatorKey.currentContext!,
          ToastNotificationType.error, error.cause);
    }
  });
}

class MyApp extends StatefulWidget {
  final Environment env;
  final bool isLoggedIn;
  final Locale? prefSavedLocale;

  const MyApp({
    super.key,
    required this.env,
    required this.isLoggedIn,
    this.prefSavedLocale,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _updatedLocale;
  late final LocaleProvider _localeProvider;

  @override
  void initState() {
    super.initState();
    _updatedLocale = widget.prefSavedLocale;
    _localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    _localeProvider.addListener(_handleLocaleChanged);
  }

  void _handleLocaleChanged() {
    if (!mounted) return;
    setState(() => _updatedLocale = _localeProvider.locale);
  }

  @override
  void dispose() {
    _localeProvider.removeListener(_handleLocaleChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'Plant-it',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _updatedLocale ?? localeProvider.locale,
      theme: theme,
      home: widget.isLoggedIn
          ? SplashPage(env: widget.env)
          : SetServer(env: widget.env),
    );
  }
}
