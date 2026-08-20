import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wain_app/core/routing/app_router.dart';
import 'package:wain_app/features/auth/domain/entities/app_user.dart';
import 'package:wain_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/features/auth/presentation/screens/login_screen.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_analytics_funnel.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_route_access.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_venue.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';
import 'package:wain_app/features/merchant/presentation/screens/merchant_dashboard_screen.dart';
import 'package:wain_app/features/merchant/presentation/screens/merchant_invite_screen.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/features/notifications/presentation/providers/notifications_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  final AppUser? _currentUser;

  _FakeAuthRepository({required AppUser? currentUser})
    : _currentUser = currentUser;

  @override
  Stream<AppUser?> get authStateChanges => Stream<AppUser?>.multi((controller) {
    controller.addSync(_currentUser);
    controller.closeSync();
  });

  @override
  Future<AppUser?> get currentUser async => _currentUser;

  @override
  Future<bool> get isLoggedIn async => _currentUser != null;

  @override
  Future<bool> get isGuest async => _currentUser?.isAnonymous ?? true;

  @override
  Future<AppUser> continueAsGuest() => throw UnimplementedError();

  @override
  Future<AppUser?> getUserFromFirestore(String uid) =>
      throw UnimplementedError();

  @override
  Future<bool> isEmailVerified() => throw UnimplementedError();

  @override
  Future<bool> isUsernameAvailable(String username) =>
      throw UnimplementedError();

  @override
  Future<AppUser> linkPhoneToGuest({
    required String verificationId,
    required String smsCode,
  }) => throw UnimplementedError();

  @override
  Future<void> saveUserToFirestore(AppUser user) => throw UnimplementedError();

  @override
  Future<String> sendOtp(String phoneNumber) => throw UnimplementedError();

  @override
  Future<void> sendEmailVerification() => throw UnimplementedError();

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<AppUser> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
  }) => throw UnimplementedError();

  @override
  Future<void> updateUsername(String uid, String username) =>
      throw UnimplementedError();

  @override
  Future<AppUser> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) => throw UnimplementedError();
}

Widget _buildRouterApp({
  required SharedPreferences prefs,
  required AuthRepository authRepository,
  required void Function(GoRouter router) onRouterReady,
  List overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(authRepository),
      if (authRepository is _FakeAuthRepository)
        authStateProvider.overrideWithValue(
          AsyncValue<AppUser?>.data(authRepository._currentUser),
        ),
      ...overrides,
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(appRouterProvider);
        onRouterReady(router);
        return MaterialApp.router(
          routerConfig: router,
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
    ),
  );
}

AppUser _authenticatedUser() => AppUser(
  uid: 'merchant-user',
  phoneNumber: '+970599000000',
  createdAt: DateTime(2026, 4, 1),
  isAnonymous: false,
);

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 30,
}) async {
  for (var i = 0; i < maxPumps; i += 1) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
}

Future<void> _pumpToHome(WidgetTester tester, GoRouter router) async {
  router.go('/home');
  for (var i = 0; i < 10; i += 1) {
    await tester.pump(const Duration(milliseconds: 100));
    if (router.routerDelegate.currentConfiguration.uri.path == '/home') {
      return;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Merchant route guard', () {
    late SharedPreferences prefs;
    late GoRouter router;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'seenOnboarding': true});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('unauthenticated merchant route redirects to login', (
      tester,
    ) async {
      final authRepository = _FakeAuthRepository(currentUser: null);

      await tester.pumpWidget(
        _buildRouterApp(
          prefs: prefs,
          authRepository: authRepository,
          onRouterReady: (value) => router = value,
        ),
      );
      await _pumpToHome(tester, router);

      router.go('/merchant/dashboard');
      await _pumpUntilFound(tester, find.byType(LoginScreen));

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('authenticated non-merchant user is redirected to invite', (
      tester,
    ) async {
      final authRepository = _FakeAuthRepository(
        currentUser: _authenticatedUser(),
      );

      await tester.pumpWidget(
        _buildRouterApp(
          prefs: prefs,
          authRepository: authRepository,
          onRouterReady: (value) => router = value,
          overrides: [
            merchantRouteAccessProvider.overrideWith(
              (ref) async => const MerchantRouteAccess.needsInvite(),
            ),
          ],
        ),
      );
      await _pumpToHome(tester, router);

      router.go('/merchant/offers');
      await _pumpUntilFound(tester, find.byType(MerchantInviteScreen));

      expect(find.byType(MerchantInviteScreen), findsOneWidget);
    });

    testWidgets('ready merchant user cannot stay on invite route', (
      tester,
    ) async {
      final authRepository = _FakeAuthRepository(
        currentUser: _authenticatedUser(),
      );

      await tester.pumpWidget(
        _buildRouterApp(
          prefs: prefs,
          authRepository: authRepository,
          onRouterReady: (value) => router = value,
          overrides: [
            merchantRouteAccessProvider.overrideWith(
              (ref) async => const MerchantRouteAccess.ready('venue-1'),
            ),
            merchantVenueIdProvider.overrideWith((ref) async => 'venue-1'),
            merchantVenueProvider.overrideWith(
              (ref) async => const MerchantVenue(
                id: 'venue-1',
                nameAr: 'Test Venue',
                nameEn: 'Test Venue',
                city: 'Ramallah',
                phone: '0591234567',
                photos: <String>[],
                categories: ['Restaurant'],
                moodLabels: ['Chill'],
                hours: <String, List<MerchantVenueHoursSlot>>{},
                is24Hours: false,
                activeMenuVersionId: null,
                lastStoryAt: null,
                rating: 4.2,
                minPrice: 20,
                maxPrice: 80,
                lat: 31.9,
                lng: 35.2,
              ),
            ),
            merchantStatsProvider.overrideWith(
              (ref) async => MerchantStats.empty(),
            ),
            merchantOffersProvider.overrideWith(
              (ref) async => <MerchantOffer>[],
            ),
            merchantAnalyticsProvider.overrideWith(
              (ref) async => MerchantAnalytics.empty(),
            ),
            merchantDashboardAnalyticsDrilldownProvider.overrideWith(
              (ref) async => buildMerchantAnalyticsDrilldownPayload(
                analytics: MerchantAnalytics.empty(),
                currentPoints: const <MerchantDailyPoint>[],
                previousPoints: const <MerchantDailyPoint>[],
                periodDays: 7,
                offers: const <MerchantOfferAnalyticsSummary>[],
              ),
            ),
            merchantAnalyticsDailyProvider(14).overrideWith((ref) async => []),
            merchantAnalyticsDailyProvider(7).overrideWith((ref) async => []),
            merchantAnalyticsDailyProvider(30).overrideWith((ref) async => []),
            merchantAnalyticsDailyProvider(60).overrideWith((ref) async => []),
            unreadNotificationsCountProvider.overrideWith(
              (ref) => Stream.value(0),
            ),
          ],
        ),
      );
      await _pumpToHome(tester, router);

      router.go('/merchant/invite');
      await _pumpUntilFound(tester, find.byType(MerchantDashboardScreen));

      expect(find.byType(MerchantDashboardScreen), findsOneWidget);
    });

    testWidgets('broken venue link shows access issue state', (tester) async {
      final authRepository = _FakeAuthRepository(
        currentUser: _authenticatedUser(),
      );

      await tester.pumpWidget(
        _buildRouterApp(
          prefs: prefs,
          authRepository: authRepository,
          onRouterReady: (value) => router = value,
          overrides: [
            merchantRouteAccessProvider.overrideWith(
              (ref) async =>
                  const MerchantRouteAccess.brokenVenueLink(venueId: 'venue-1'),
            ),
          ],
        ),
      );
      await _pumpToHome(tester, router);

      router.go('/merchant/dashboard');
      await _pumpUntilFound(
        tester,
        find.text(
          'الحساب غير مربوط كتاجر بشكل صحيح. افتح كود الدعوة وأعد الربط.',
        ),
      );

      expect(
        find.text(
          'الحساب غير مربوط كتاجر بشكل صحيح. افتح كود الدعوة وأعد الربط.',
        ),
        findsOneWidget,
      );
      expect(find.byType(MerchantDashboardScreen), findsNothing);
    });
  });

  group('Demo merchant walkthrough', () {
    late SharedPreferences prefs;
    late GoRouter router;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'seenOnboarding': true});
      prefs = await SharedPreferences.getInstance();
    });

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        _buildRouterApp(
          prefs: prefs,
          authRepository: _FakeAuthRepository(currentUser: null),
          onRouterReady: (value) => router = value,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('/demo/merchant reaches the dashboard without a login', (
      tester,
    ) async {
      await pump(tester);

      router.go('/demo/merchant');
      await tester.pumpAndSettle();

      // The guard sends unauthenticated merchant routes to login; the
      // walkthrough has no user to authenticate, so this is the case that
      // would silently make the whole merchant demo unreachable.
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(MerchantDashboardScreen), findsOneWidget);
    });

    testWidgets('the walkthrough does not widen the admin routes', (
      tester,
    ) async {
      await pump(tester);

      router.go('/demo/merchant');
      await tester.pumpAndSettle();
      expect(find.byType(MerchantDashboardScreen), findsOneWidget);

      // Session on, still unauthenticated: admin must stay shut.
      router.go('/admin/topups');
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('merchant routes still need a login without the walkthrough', (
      tester,
    ) async {
      await pump(tester);

      router.go('/merchant/dashboard');
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(MerchantDashboardScreen), findsNothing);
    });

    testWidgets('every merchant surface renders on local data', (tester) async {
      // The provider audit proves nothing reaches Firebase; this proves the
      // screens on top of it actually build. The two fail differently: the
      // audit stayed green while the dashboard was rendering its venue photo
      // through NetworkImage, which cannot resolve a bundled asset:// path.
      const routes = <String>[
        '/merchant/dashboard',
        '/merchant/analytics',
        '/merchant/edit-venue',
        '/merchant/offers',
        '/merchant/photos',
        '/merchant/reviews',
        '/merchant/stories',
        '/merchant/notifications',
        '/merchant/venue/hours',
        '/merchant/venue/menu',
        '/merchant/wallet',
        '/merchant/invite',
      ];

      await pump(tester);
      router.go('/demo/merchant');
      await tester.pumpAndSettle();

      final failures = <String>[];
      for (final route in routes) {
        router.go(route);

        // Bounded pumps rather than pumpAndSettle: a loading indicator animates
        // forever, so requiring quiescence would hang on any surface that shows
        // one rather than reporting what it rendered.
        await tester.pump();
        for (var frame = 0; frame < 8; frame += 1) {
          await tester.pump(const Duration(milliseconds: 250));
        }

        Object? exception;
        while ((exception = tester.takeException()) != null) {
          failures.add('$route -> $exception');
        }
        expect(find.byType(LoginScreen), findsNothing, reason: route);
      }

      expect(failures, isEmpty);
    });
  });
}
