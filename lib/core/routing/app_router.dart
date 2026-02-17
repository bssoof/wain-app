import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/providers/onboarding_providers.dart';
import '../../core/services/notification_service.dart';

// Screens
import '../../features/discovery/presentation/screens/splash_screen.dart';
import '../../features/discovery/presentation/screens/question_flow_screen.dart';
import '../../features/discovery/presentation/screens/home_screen.dart';
import '../../features/discovery/presentation/screens/results_screen.dart';
import '../../features/venue/presentation/screens/venue_details_screen.dart';
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


/// App Router Constants
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String questionFlow = '/question-flow';
  static const String results = '/results';
  static const String venueDetails = '/venue/:id';
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
  static const String merchantEditVenue = '/merchant/edit-venue';
  static const String merchantOffers = '/merchant/offers';
  static const String merchantPhotos = '/merchant/photos';
  static const String merchantReviews = '/merchant/reviews';
  static const String merchantStories = '/merchant/stories';
  static const String merchantNotifications = '/merchant/notifications';
  static const String merchantHours = '/merchant/venue/hours';
  static const String merchantMenu = '/merchant/venue/menu';
}

final appRouterProvider = Provider<GoRouter>((ref) {

  final seenOnboarding = ref.watch(seenOnboardingProvider);

  return GoRouter(
    navigatorKey: NotificationService.navigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
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

      // Map Screen (Main Discovery)
      GoRoute(
        path: AppRoutes.map,
        name: 'map',
        builder: (context, state) => const MapScreen(),
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
      GoRoute(
        path: AppRoutes.results,
        name: 'results',
        builder: (context, state) => const ResultsScreen(),
      ),
      
      // Venue Details
      GoRoute(
        path: AppRoutes.venueDetails,
        name: 'venue-details',
        builder: (context, state) {
          final venueId = state.pathParameters['id'] ?? '';
          return VenueDetailsScreen(venueId: venueId);
        },
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

      // Favorites
      GoRoute(
        path: AppRoutes.favorites,
        name: 'favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),

      // Try List
      GoRoute(
        path: AppRoutes.tryList,
        name: 'try-list',
        builder: (context, state) => const TryListScreen(),
      ),
      
      // Profile
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
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
      
      // Merchant Scan
      GoRoute(
        path: AppRoutes.merchantScan,
        name: 'merchant-scan',
        builder: (context, state) => const MerchantScanScreen(),
      ),

      // Merchant Invite
      GoRoute(
        path: AppRoutes.merchantInvite,
        name: 'merchant-invite',
        builder: (context, state) => const MerchantInviteScreen(),
      ),

      // Merchant Dashboard
      GoRoute(
        path: AppRoutes.merchantDashboard,
        name: 'merchant-dashboard',
        builder: (context, state) => const MerchantDashboardScreen(),
      ),

      // Merchant Edit Venue
      GoRoute(
        path: AppRoutes.merchantEditVenue,
        name: 'merchant-edit-venue',
        builder: (context, state) => const MerchantEditVenueScreen(),
      ),

      // Merchant Offers
      GoRoute(
        path: AppRoutes.merchantOffers,
        name: 'merchant-offers',
        builder: (context, state) => const MerchantOffersScreen(),
      ),

      // Merchant Hours
      GoRoute(
        path: AppRoutes.merchantHours,
        name: 'merchant-hours',
        builder: (context, state) => const MerchantHoursScreen(),
      ),

      // Merchant Menu
      GoRoute(
        path: AppRoutes.merchantMenu,
        name: 'merchant-menu',
        builder: (context, state) => const MerchantMenuScreen(),
      ),

      // Merchant Photos
      GoRoute(
        path: AppRoutes.merchantPhotos,
        name: 'merchant-photos',
        builder: (context, state) => const MerchantPhotosScreen(),
      ),

      // Merchant Reviews
      GoRoute(
        path: AppRoutes.merchantReviews,
        name: 'merchant-reviews',
        builder: (context, state) => const MerchantReviewsScreen(),
      ),

      // Merchant Stories
      GoRoute(
        path: AppRoutes.merchantStories,
        name: 'merchant-stories',
        builder: (context, state) => const MerchantStoriesScreen(),
      ),
      
      // Login
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
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
          );
        },
      ),
      
      // Sign Up
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // User Stats
      GoRoute(
        path: AppRoutes.stats,
        name: 'stats',
        builder: (context, state) => const UserStatsScreen(),
      ),

      // Notifications
      GoRoute(
        path: AppRoutes.merchantNotifications,
        name: 'merchant-notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
    ],
    
    // Error Page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'الصفحة غير موجودة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    ),
  );
});

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
