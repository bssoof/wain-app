import '../../data/models/navigation_click.dart';

/// Abstract interface for Navigation Repository
/// Handles logging navigation clicks for analytics and commission tracking
abstract class NavigationRepository {
  /// Log a navigation click event
  Future<String> logNavigationClick({
    required String venueId,
    String? userId,
    required String navApp,
  });

  /// Get device ID (generates one if not exists)
  Future<String> getDeviceId();

  /// Get all clicks for a venue (admin use)
  Future<List<NavigationClick>> getClicksForVenue(String venueId);

  /// Get all clicks for a user (profile stats)
  Future<List<NavigationClick>> getClicksForUser(String userId);
}
