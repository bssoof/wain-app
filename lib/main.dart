import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wain_app/l10n/app_localizations.dart';

import 'core/providers/app_bootstrap_provider.dart';
import 'core/providers/location_provider.dart';
import 'core/routing/app_router.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/device_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/platform_logger.dart';
import 'core/theme/app_theme.dart';
import 'features/favorites/presentation/providers/favorites_provider.dart';
import 'features/profile/presentation/providers/settings_providers.dart';
import 'firebase_options.dart';

const bool _useFirebaseEmulators = bool.fromEnvironment(
  'WAIN_USE_FIREBASE_EMULATORS',
  defaultValue: false,
);

const String _firebaseEmulatorHostOverride = String.fromEnvironment(
  'WAIN_FIREBASE_EMULATOR_HOST',
  defaultValue: '',
);

const String _webRecaptchaSiteKey = String.fromEnvironment(
  'WAIN_WEB_RECAPTCHA_SITE_KEY',
  defaultValue: '',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isWindows = !kIsWeb && Platform.isWindows;
  bool firebaseReady = false;
  bool notificationsReady = false;
  String? warningMessage;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
    PlatformLogger.info(
      'bootstrap',
      'Firebase initialized.',
      platform: isWindows ? 'windows' : null,
    );

    await _configureFirebaseEmulatorsIfEnabled();

    // Explicitly enable Firestore persistence on mobile.
    if (!kIsWeb && !isWindows) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      PlatformLogger.info(
        'bootstrap',
        'Firestore offline persistence enabled explicitly.',
      );
    }
  } catch (e, st) {
    warningMessage = _appendWarning(
      warningMessage,
      'Firebase is unavailable for this run. Running in degraded mode.',
    );
    PlatformLogger.error(
      'bootstrap',
      'Firebase initialization failed.',
      platform: isWindows ? 'windows' : null,
      error: e,
      stackTrace: st,
    );
  }

  if (firebaseReady && !isWindows) {
    await _initializeAppCheck();
  } else if (isWindows) {
    PlatformLogger.info(
      'bootstrap',
      'Skipping Firebase App Check on Windows.',
      platform: 'windows',
    );
  }

  if (firebaseReady && !isWindows) {
    try {
      await NotificationService().initialize();
      notificationsReady = true;
    } catch (e, st) {
      warningMessage = _appendWarning(
        warningMessage,
        'Notifications are unavailable for this run.',
      );
      PlatformLogger.error(
        'bootstrap',
        'NotificationService initialization failed.',
        error: e,
        stackTrace: st,
      );
    }
  } else if (isWindows) {
    PlatformLogger.info(
      'bootstrap',
      'Skipping Firebase Messaging initialization on Windows.',
      platform: 'windows',
    );
  }

  final sharedPrefs = await SharedPreferences.getInstance();

  if (kDebugMode) {
    if (firebaseReady) {
      await _ensureAnonymousAuthForDebug();
    } else {
      PlatformLogger.warn(
        'bootstrap',
        'Skipping debug anonymous auth because Firebase is unavailable.',
        platform: isWindows ? 'windows' : null,
      );
    }
  }

  final bootstrapStatus = AppBootstrapStatus(
    firebaseReady: firebaseReady,
    notificationsReady: notificationsReady,
    warningMessage: warningMessage,
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        deviceServiceProvider.overrideWithValue(DeviceService(sharedPrefs)),
        appBootstrapStatusProvider.overrideWithValue(bootstrapStatus),
      ],
      child: const WainApp(),
    ),
  );
}

String _appendWarning(String? current, String message) {
  if (current == null || current.trim().isEmpty) {
    return message;
  }
  if (current.contains(message)) {
    return current;
  }
  return '$current\n$message';
}

Future<void> _initializeAppCheck() async {
  try {
    if (kIsWeb) {
      if (_webRecaptchaSiteKey.isEmpty) {
        PlatformLogger.warn(
          'bootstrap',
          'Skipping Firebase App Check on web because WAIN_WEB_RECAPTCHA_SITE_KEY is not set.',
        );
        return;
      }

      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider(_webRecaptchaSiteKey),
      );
      PlatformLogger.info(
        'bootstrap',
        'App Check initialized with web reCAPTCHA provider.',
      );
      return;
    }

    final useDebugProvider = !kReleaseMode;
    await FirebaseAppCheck.instance.activate(
      androidProvider: useDebugProvider
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: useDebugProvider
          ? AppleProvider.debug
          : AppleProvider.deviceCheck,
    );
    PlatformLogger.info(
      'bootstrap',
      'App Check initialized with ${useDebugProvider ? 'debug' : 'release'} provider.',
    );
  } catch (e, st) {
    PlatformLogger.error(
      'bootstrap',
      'App Check initialization failed.',
      error: e,
      stackTrace: st,
    );
  }
}

Future<void> _configureFirebaseEmulatorsIfEnabled() async {
  if (!_useFirebaseEmulators) {
    return;
  }

  final host = _resolveFirebaseEmulatorHost();

  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFunctions.instanceFor(
    region: 'us-central1',
  ).useFunctionsEmulator(host, 5001);
  FirebaseStorage.instance.useStorageEmulator(host, 9199);

  PlatformLogger.info(
    'bootstrap',
    'Firebase emulators enabled at $host (firestore:8080, auth:9099, functions:5001, storage:9199).',
  );
}

String _resolveFirebaseEmulatorHost() {
  final overrideHost = _firebaseEmulatorHostOverride.trim();
  if (overrideHost.isNotEmpty) {
    return overrideHost;
  }

  if (kIsWeb) {
    return '127.0.0.1';
  }

  if (Platform.isAndroid) {
    return '10.0.2.2';
  }

  return '127.0.0.1';
}

Future<void> _ensureAnonymousAuthForDebug() async {
  try {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      final cred = await auth.signInAnonymously();
      PlatformLogger.info(
        'bootstrap',
        'Firebase connected (anonymous): ${cred.user?.uid}',
      );
    } else {
      PlatformLogger.info(
        'bootstrap',
        'Firebase connected (existing): ${auth.currentUser!.uid}',
      );
    }
  } catch (e, st) {
    PlatformLogger.error(
      'bootstrap',
      'Firebase debug anonymous auth failed.',
      error: e,
      stackTrace: st,
    );
  }
}

class WainApp extends ConsumerStatefulWidget {
  const WainApp({super.key});

  @override
  ConsumerState<WainApp> createState() => _WainAppState();
}

class _WainAppState extends ConsumerState<WainApp> {
  final DeepLinkService _deepLinkService = DeepLinkService();
  bool _deepLinksInitialized = false;

  void _initDeepLinks(GoRouter router) {
    if (_deepLinksInitialized) {
      return;
    }
    _deepLinksInitialized = true;
    _deepLinkService.init(router);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsProvider);
    final bootstrapStatus = ref.watch(appBootstrapStatusProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDeepLinks(router);
    });

    return MaterialApp.router(
      title: 'Wain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      locale: Locale(settings.language),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) {
        final appBody = Directionality(
          textDirection: settings.language == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: LocationBootstrapper(child: child ?? const SizedBox.shrink()),
        );

        final warning = bootstrapStatus.warningMessage;
        if (warning == null || warning.trim().isEmpty) {
          return appBody;
        }

        return Stack(
          children: [
            appBody,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: _BootstrapWarningBanner(message: warning),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BootstrapWarningBanner extends StatelessWidget {
  final String message;

  const _BootstrapWarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.6),
          ),
        ),
        child: Text(
          message,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onErrorContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class LocationBootstrapper extends ConsumerStatefulWidget {
  final Widget child;

  const LocationBootstrapper({super.key, required this.child});

  @override
  ConsumerState<LocationBootstrapper> createState() =>
      _LocationBootstrapperState();
}

class _LocationBootstrapperState extends ConsumerState<LocationBootstrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userLocationProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
