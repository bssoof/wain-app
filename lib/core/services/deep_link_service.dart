import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

/// Service for handling deep links and venue sharing.
///
/// Generates shareable URLs and listens for incoming deep links.
/// Link format: https://wain-app.web.app/venue/{venueId}
/// Custom scheme: wain://venue/{venueId}
class DeepLinkService {
  static const String _webHost = 'wain-app.web.app';
  static const String _customScheme = 'wain';

  final AppLinks _appLinks = AppLinks();
  GoRouter? _router;

  /// Initialize the service and start listening for incoming links
  Future<void> init(GoRouter router) async {
    _router = router;

    // Handle link that opened the app (cold start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('🔗 Initial deep link: $initialUri');
        _handleUri(initialUri);
      }
    } catch (e) {
      debugPrint('⚠️ No initial deep link: $e');
    }

    // Handle links when app is already running (warm start)
    _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('🔗 Incoming deep link: $uri');
        _handleUri(uri);
      },
      onError: (err) {
        debugPrint('❌ Deep link error: $err');
      },
    );
  }

  /// Parse the incoming URI and navigate accordingly
  void _handleUri(Uri uri) {
    final router = _router;
    if (router == null) return;

    String? venueId;

    // Parse https://wain-app.web.app/venue/{id}
    if (uri.host == _webHost && uri.pathSegments.length >= 2) {
      if (uri.pathSegments[0] == 'venue') {
        venueId = uri.pathSegments[1];
      }
    }

    // Parse wain://venue/{id}
    if (uri.scheme == _customScheme && uri.host == 'venue') {
      venueId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
    }

    if (venueId != null && venueId.isNotEmpty) {
      debugPrint('📍 Navigating to venue: $venueId');
      router.push('/venue/$venueId');
    }
  }

  /// Generate a shareable deep link for a venue
  static String generateVenueLink(String venueId) {
    return 'https://$_webHost/venue/$venueId';
  }

  /// Share venue via native share sheet
  static Future<void> shareVenue({
    required String venueId,
    required String venueName,
    required String city,
    required String shareMessage,
    double? rating,
    String? category,
  }) async {
    final link = generateVenueLink(venueId);

    final shareText = StringBuffer();
    shareText.writeln('🍽️ $venueName');
    shareText.writeln('📍 $city');
    if (rating != null && rating > 0) {
      shareText.writeln('⭐ $rating');
    }
    if (category != null && category.isNotEmpty) {
      shareText.writeln('🏷️ $category');
    }
    shareText.writeln();
    shareText.writeln(shareMessage);
    shareText.writeln(link);

    await Share.share(shareText.toString());
  }
}
