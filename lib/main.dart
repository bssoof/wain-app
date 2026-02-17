import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/device_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/providers/location_provider.dart';
import 'features/favorites/presentation/providers/favorites_provider.dart';
import 'features/profile/presentation/providers/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _initializeAppCheck();

  // Initialize Notifications
  await NotificationService().initialize();

  // Initialize SharedPreferences
  final sharedPrefs = await SharedPreferences.getInstance();

  // Debug-only DoD check (avoid startup side-effects in release)
  if (kDebugMode) {
    await _ensureAnonymousAuthForDebug();
    // Seed Offers (Run once then comment out/remove)
    // await seedOffers(); 
  }

  runApp(
    ProviderScope(
      overrides: [
        // Override SharedPreferences provider
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        
        // Override DeviceService provider
        deviceServiceProvider.overrideWithValue(DeviceService(sharedPrefs)),
      ],
      child: const WainApp(),
    ),
  );
}

Future<void> _initializeAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
    );
  } catch (e, st) {
    debugPrint("App Check init failed: $e");
    debugPrintStack(stackTrace: st);
  }
}

Future<void> _ensureAnonymousAuthForDebug() async {
  try {
    final auth = FirebaseAuth.instance;

    // Don't re-sign in if already signed in
    if (auth.currentUser == null) {
      final cred = await auth.signInAnonymously();
      debugPrint("✅ Firebase Connected! User ID: ${cred.user?.uid}");
    } else {
      debugPrint("✅ Firebase Connected! User ID: ${auth.currentUser!.uid} (existing)");
    }
  } catch (e, st) {
    debugPrint("❌ Firebase Auth Failed: $e");
    debugPrintStack(stackTrace: st);
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
    if (!_deepLinksInitialized) {
      _deepLinksInitialized = true;
      _deepLinkService.init(router);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsProvider);

    // Initialize deep links after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDeepLinks(router);
    });

    return MaterialApp.router(
      title: 'وين',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,

      locale: Locale(settings.language),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],

      routerConfig: router,

      builder: (context, child) {
        return Directionality(
          textDirection: settings.language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: LocationBootstrapper(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

/// Widget to trigger location initialization on startup
class LocationBootstrapper extends ConsumerStatefulWidget {
  final Widget child;
  const LocationBootstrapper({super.key, required this.child});

  @override
  ConsumerState<LocationBootstrapper> createState() => _LocationBootstrapperState();
}

class _LocationBootstrapperState extends ConsumerState<LocationBootstrapper> {
  @override
  void initState() {
    super.initState();
    // 🌍 Eagerly start fetching location
    // Since keepAlive is true, this will retain the location for mapping
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userLocationProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
