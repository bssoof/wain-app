import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/routing/go_router_refresh_stream.dart';
import 'package:wain_app/core/routing/main_navigation_shell.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/features/merchant/presentation/widgets/merchant_access_gate.dart';
import 'package:wain_app/l10n/app_localizations.dart';

import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/providers/onboarding_providers.dart';
import '../../core/services/notification_service.dart';

// Screens
import '../../features/discovery/presentation/screens/splash_screen.dart';
import '../../features/discovery/presentation/screens/question_flow_screen.dart';
import '../../features/discovery/presentation/screens/home_screen.dart';
import '../../features/discovery/presentation/screens/results_screen.dart';
import '../../features/venue/presentation/screens/venue_details_screen.dart';
import '../../features/venue/presentation/screens/venue_menu_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/about_screen.dart';
import '../../features/profile/presentation/screens/privacy_screen.dart';
import '../../features/profile/presentation/screens/help_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/offers/presentation/screens/offer_details_screen.dart';
import '../../features/offers/presentation/screens/my_claims_screen.dart';
import '../../features/offers/presentation/screens/saved_offers_screen.dart';
import '../../features/merchant/presentation/screens/merchant_scan_screen.dart';
import '../../features/merchant/presentation/screens/merchant_invite_screen.dart';
import '../../features/merchant/presentation/screens/merchant_dashboard_screen.dart';
import '../../features/merchant/presentation/screens/merchant_analytics_screen.dart';
import '../../features/merchant/presentation/screens/merchant_edit_venue_screen.dart';
import '../../features/merchant/presentation/screens/merchant_offers_screen.dart';
import '../../features/merchant/presentation/screens/merchant_photos_screen.dart';
import '../../features/merchant/presentation/screens/merchant_reviews_screen.dart';
import '../../features/merchant/presentation/screens/merchant_stories_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/profile/presentation/screens/user_stats_screen.dart';
import '../../features/try_list/presentation/screens/try_list_screen.dart';
import '../../features/notifications/presentation/screens/notification_screen.dart';
import '../../features/merchant/presentation/screens/merchant_hours_screen.dart';
import '../../features/merchant/presentation/screens/merchant_menu_screen.dart';
import '../../features/merchant/presentation/screens/merchant_wallet_screen.dart';
import '../../features/admin/presentation/screens/admin_topup_review_screen.dart';
import '../../features/admin/presentation/screens/admin_wallet_audit_screen.dart';

/// App Router Constants
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String questionFlow = '/question-flow';
  static const String results = '/results';
  static const String venueDetails = '/venue/:id';
  static const String venueMenu = '/venue/:id/menu';
  static const String favorites = '/favorites';
  static const String profile = '/profile';
  static const String about = '/about';
  static const String privacy = '/privacy';
  static const String help = '/help';
  static const String map = '/map';
  static const String offerDetails = '/offer/:id';
  static const String myClaims = '/my-claims';
  static const String merchantScan = '/merchant/scan';
  static const String login = '/login';
  static const String editProfile = '/edit-profile';
  static const String savedOffers = '/saved-offers';
  static const String otp = '/otp';
  static const String signup = '/signup';
  static const String stats = '/stats';
  static const String tryList = '/try-list';
  static const String merchantInvite = '/merchant/invite';
  static const String merchantDashboard = '/merchant/dashboard';
  static const String merchantAnalytics = '/merchant/analytics';
  static const String merchantEditVenue = '/merchant/edit-venue';
  static const String merchantOffers = '/merchant/offers';
  static const String merchantPhotos = '/merchant/photos';
  static const String merchantReviews = '/merchant/reviews';
  static const String merchantStories = '/merchant/stories';
  static const String merchantNotifications = '/merchant/notifications';
  static const String merchantHours = '/merchant/venue/hours';
  static const String merchantMenu = '/merchant/venue/menu';
  static const String merchantWallet = '/merchant/wallet';
  static const String adminTopUps = '/admin/topups';
  static const String adminWalletAudit = '/admin/wallet-audit';
}

final authRouterRefreshProvider = Provider<GoRouterRefreshStream>((ref) {
  final refresh = GoRouterRefreshStream(
    ref.watch(authRepositoryProvider).authStateChanges,
  );
  ref.onDispose(refresh.dispose);
  return refresh;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final seenOnboarding = ref.watch(seenOnboardingProvider);
  final authState = ref.watch(authStateProvider);
  final authRefresh = ref.watch(authRouterRefreshProvider);

  return GoRouter(
    navigatorKey: NotificationService.navigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: authRefresh,
    redirect: (context, state) async {
      final location = state.uri.path;
      final isMerchantRoute = _isMerchantLocation(location);
      final isAdminRoute = _isAdminLocation(location);

      if ((isMerchantRoute || isAdminRoute) && authState.isLoading) {
        return null;
      }

      final isAuthenticated = authState.asData?.value != null;
      if ((isMerchantRoute || isAdminRoute) && !isAuthenticated) {
        return _loginRedirectLocation(state.uri.toString());
      }

      if (isAdminRoute && isAuthenticated) {
        if (!await _currentUserHasAdminAccess()) {
          return AppRoutes.profile;
        }
      }

      // Check if we are in onboarding or splash
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;

      // If not seen onboarding and not on splash (let splash finish?)
      // Actually, if we use splash screen as simple loader,
      // we can redirect immediately if logic dictates.
      // But usually Splash has a timer.
      // Let's assume Splash Screen navigates to /map or /question manually.
      // BUT if we want to FORCE onboarding:
      if (!seenOnboarding && !isOnboarding && !isSplash) {
        return AppRoutes.onboarding;
      }
      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const _SplashWrapper(),
      ),

      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Discovery Flow
      GoRoute(
        path: AppRoutes.questionFlow,
        name: 'question-flow',
        builder: (context, state) => const QuestionFlowScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            MainNavigationShell(currentLocation: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.map,
            name: 'map',
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: AppRoutes.stats,
            name: 'stats',
            builder: (context, state) => const UserStatsScreen(),
          ),
          GoRoute(
            path: AppRoutes.results,
            name: 'results',
            builder: (context, state) => const ResultsScreen(),
          ),
          GoRoute(
            path: AppRoutes.favorites,
            name: 'favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Venue Details
      GoRoute(
        path: AppRoutes.venueMenu,
        name: 'venue-menu',
        builder: (context, state) {
          final venueId = state.pathParameters['id'] ?? '';
          return VenueMenuScreen(venueId: venueId);
        },
      ),
      GoRoute(
        path: AppRoutes.venueDetails,
        name: 'venue-details',
        builder: (context, state) {
          final venueId = state.pathParameters['id'] ?? '';
          return VenueDetailsScreen(venueId: venueId);
        },
      ),

      // Debug-only shortcut into the demo venue. Guarded by DemoMode.isEnabled
      // (kDebugMode), so the route simply does not exist in a release build and
      // no production query has to change to reach it.
      if (DemoMode.isEnabled)
        GoRoute(
          path: '/demo',
          name: 'demo-venue',
          redirect: (context, state) => '/venue/${DemoMode.venueId}',
        ),

      // Offer Details
      GoRoute(
        path: AppRoutes.offerDetails,
        name: 'offer-details',
        builder: (context, state) {
          final offerId = state.pathParameters['id'] ?? '';
          return OfferDetailsScreen(offerId: offerId);
        },
      ),

      // My Claims
      GoRoute(
        path: AppRoutes.myClaims,
        name: 'my-claims',
        builder: (context, state) => const MyClaimsScreen(),
      ),

      // Saved Offers
      GoRoute(
        path: AppRoutes.savedOffers,
        name: 'saved-offers',
        builder: (context, state) => const SavedOffersScreen(),
      ),

      // Try List
      GoRoute(
        path: AppRoutes.tryList,
        name: 'try-list',
        builder: (context, state) => const TryListScreen(),
      ),

      // Edit Profile
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),

      // About
      GoRoute(
        path: AppRoutes.about,
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),

      // Privacy
      GoRoute(
        path: AppRoutes.privacy,
        name: 'privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),

      // Help
      GoRoute(
        path: AppRoutes.help,
        name: 'help',
        builder: (context, state) => const HelpScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) =>
            MerchantAccessGate(currentLocation: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.merchantInvite,
            name: 'merchant-invite',
            builder: (context, state) => const MerchantInviteScreen(),
          ),
          GoRoute(
            path: AppRoutes.merchantDashboard,
            name: 'merchant-dashboard',
            builder: (context, state) => const MerchantDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.merchantAnalytics,
            name: 'merchant-analytics',
            builder: (context, state) => const MerchantAnalyticsScreen(),
          ),
          GoRoute(
            path: AppRoutes.merchantScan,
            name: 'merchant-scan',
            builder: (context, state) => const MerchantScanScreen(),
          ),
          GoRoute(
            path: AppRoutes.merchantEditVenue,
            name: 'merchant-edit-venue',
            builder: (context, state) => const MerchantEditVenueScreen(),
          ),
          GoRoute(
            path: AppRoutes.merchantOffers,
            name: 'merchant-offers',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return MerchantOffersScreen(
                highlightOfferId: extra?['highlight'] as String?,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.merchantHours,
            name: 'merchant-hours',
            builder: (context, state) => const MerchantHoursScreen(),
          ),
          GoRoute(
            path: AppRoutes.merchantMenu,
            name: 'merchant-menu',
            builder: (context, state) => const MerchantMenuScreen(),
          ),
          GoRoute(
            path: AppRoutes.merchantWallet,
            name: 'merchant-wallet',
            builder: (context, state) => const MerchantWalletScreen(),
          ),
          GoRoute(
            path: AppRoutes.merchantPhotos,
            name: 'merchant-photos',
            builder: (context, state) => const MerchantPhotosScreen(),
          ),
          GoRoute(
            path: AppRoutes.merchantReviews,
            name: 'merchant-reviews',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return MerchantReviewsScreen(
                initialFilter: extra?['filter'] as int?,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.merchantStories,
            name: 'merchant-stories',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return MerchantStoriesScreen(
                highlightStoryId: extra?['highlight'] as String?,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.merchantNotifications,
            name: 'merchant-notifications',
            builder: (context, state) => const NotificationScreen(),
          ),
        ],
      ),

      // Login
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) =>
            LoginScreen(redirectTo: state.uri.queryParameters['redirectTo']),
      ),

      // OTP Verification
      GoRoute(
        path: AppRoutes.otp,
        name: 'otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OtpScreen(
            phoneNumber: extra['phoneNumber'] ?? '',
            verificationId: extra['verificationId'] ?? '',
            redirectTo: state.uri.queryParameters['redirectTo'],
          );
        },
      ),

      // Sign Up
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) =>
            SignupScreen(redirectTo: state.uri.queryParameters['redirectTo']),
      ),

      GoRoute(
        path: AppRoutes.adminTopUps,
        name: 'admin-topups',
        builder: (context, state) => const AdminTopUpReviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminWalletAudit,
        name: 'admin-wallet-audit',
        builder: (context, state) => const AdminWalletAuditScreen(),
      ),
    ],

    // Error Page
    errorBuilder: (context, state) {
      final landing = ref.read(discoveryCompletedProvider)
          ? AppRoutes.results
          : AppRoutes.home;
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.errorPageNotFound,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => context.go(landing),
                child: Text(AppLocalizations.of(context)!.errorGoHome),
              ),
            ],
          ),
        ),
      );
    },
  );
});

bool _isMerchantLocation(String location) => location.startsWith('/merchant/');
bool _isAdminLocation(String location) => location.startsWith('/admin/');

Future<bool> _currentUserHasAdminAccess() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final tokenResult = await user.getIdTokenResult();
  final claims = tokenResult.claims ?? const <String, dynamic>{};
  if (claims['admin'] == true || claims['role'] == 'admin') {
    return true;
  }

  final adminDoc = await FirebaseFirestore.instance
      .collection('admins')
      .doc(user.uid)
      .get();
  return adminDoc.exists && adminDoc.data()?['active'] != false;
}

String _loginRedirectLocation(String redirectTo) {
  return Uri(
    path: AppRoutes.login,
    queryParameters: {'redirectTo': redirectTo},
  ).toString();
}

/// Wrapper to handle Splash logic with Onboarding awareness
/// (Since Splash calls context.go, we want to make sure it goes to the right place)
class _SplashWrapper extends ConsumerWidget {
  const _SplashWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We can inject custom logic here if needed,
    // or just return SplashScreen and let it navigate to /map or /question.
    // The router redirect will intercept if needed.
    return const SplashScreen();
  }
}
