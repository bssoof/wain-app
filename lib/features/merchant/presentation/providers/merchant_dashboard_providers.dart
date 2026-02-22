import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:wain_app/l10n/app_localizations.dart';

/// Check if current user is a merchant (has merchant_venue_id)
final merchantVenueIdProvider = FutureProvider<String?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    // We strictly read from the user document.
    // The 'merchants' document creation is now handled server-side by the redeemInviteCode function.
    return doc.data()?['merchant_venue_id'] as String?;
  } catch (e) {
    debugPrint('❌ Error checking merchant status: $e');
    return null;
  }
});

/// Get the merchant's venue data
final merchantVenueProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final venueId = await ref.watch(merchantVenueIdProvider.future);
  if (venueId == null) return null;

  try {
    final doc = await FirebaseFirestore.instance
        .collection('venues')
        .doc(venueId)
        .get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  } catch (e) {
    debugPrint('❌ Error fetching merchant venue: $e');
    return null;
  }
});

/// Get merchant venue stats (reviews, rating)
final merchantStatsProvider = FutureProvider<MerchantStats>((ref) async {
  final venueId = await ref.watch(merchantVenueIdProvider.future);
  if (venueId == null) return MerchantStats.empty();

  try {
    final venueDoc = await FirebaseFirestore.instance
        .collection('venues')
        .doc(venueId)
        .get();

    final reviewsSnap = await FirebaseFirestore.instance
        .collection('venues')
        .doc(venueId)
        .collection('reviews')
        .orderBy('created_at', descending: true)
        .limit(10)
        .get();

    final data = venueDoc.data() ?? {};
    return MerchantStats(
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (data['review_count'] as num?)?.toInt() ?? 0,
      recentReviews: reviewsSnap.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList(),
    );
  } catch (e) {
    debugPrint('❌ Error fetching merchant stats: $e');
    return MerchantStats.empty();
  }
});

/// Get all merchant reviews (for management screen)
final merchantReviewsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final venueId = await ref.watch(merchantVenueIdProvider.future);
  if (venueId == null) return [];

  try {
    final snap = await FirebaseFirestore.instance
        .collection('venues')
        .doc(venueId)
        .collection('reviews')
        .orderBy('created_at', descending: true)
        .limit(100)
        .get();

    return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  } catch (e) {
    debugPrint('❌ Error fetching merchant reviews: $e');
    return [];
  }
});

/// Get merchant's offers
final merchantOffersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final venueId = await ref.watch(merchantVenueIdProvider.future);
  if (venueId == null) return [];

  try {
    final snap = await FirebaseFirestore.instance
        .collection('offers')
        .where('venue_id', isEqualTo: venueId)
        .get();

    return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  } catch (e) {
    debugPrint('❌ Error fetching merchant offers: $e');
    return [];
  }
});

/// Analytics data from server-aggregated venue_analytics collection
final merchantAnalyticsProvider = FutureProvider<MerchantAnalytics>((
  ref,
) async {
  final venueId = await ref.watch(merchantVenueIdProvider.future);
  if (venueId == null) return MerchantAnalytics.empty();

  try {
    final doc = await FirebaseFirestore.instance
        .collection('venue_analytics')
        .doc(venueId)
        .get();

    if (!doc.exists) return MerchantAnalytics.empty();
    return MerchantAnalytics.fromMap(doc.data()!);
  } catch (e) {
    debugPrint('❌ Error fetching merchant analytics: $e');
    return MerchantAnalytics.empty();
  }
});

/// Selected range for the trends chart (7 or 30 days).
final trendRangeDaysProvider =
    NotifierProvider<TrendRangeDaysNotifier, int>(TrendRangeDaysNotifier.new);

class TrendRangeDaysNotifier extends Notifier<int> {
  @override
  int build() => 7;

  void setRange(int days) {
    state = days == 30 ? 30 : 7;
  }
}

/// Daily analytics points for dashboard charts.
/// Reads from: venue_analytics_daily/{venueId}/days/{dateKey}
/// Returns a contiguous series with zero-filled gaps.
final merchantAnalyticsDailyProvider =
    FutureProvider.family<List<MerchantDailyPoint>, int>((
      ref,
      rangeDays,
    ) async {
      final venueId = await ref.watch(merchantVenueIdProvider.future);
      if (venueId == null) return [];

      final safeRange = rangeDays <= 0 ? 7 : rangeDays;
      try {
        final snap = await FirebaseFirestore.instance
            .collection('venue_analytics_daily')
            .doc(venueId)
            .collection('days')
            .orderBy('date_key', descending: true)
            .limit(safeRange)
            .get();

        final fetched = <String, MerchantDailyPoint>{};
        for (final doc in snap.docs) {
          final point =
              MerchantDailyPoint.fromMap({'id': doc.id, ...doc.data()});
          fetched[point.dateKey] = point;
        }

        return buildZeroFilledSeries(
          rangeDays: safeRange,
          fetched: fetched,
        );
      } catch (e) {
        debugPrint('❌ Error fetching merchant daily analytics: $e');
        return [];
      }
    });

/// Builds a contiguous list of [MerchantDailyPoint] for the last
/// [rangeDays] days, inserting zero-value points for any missing day.
List<MerchantDailyPoint> buildZeroFilledSeries({
  required int rangeDays,
  required Map<String, MerchantDailyPoint> fetched,
  DateTime? today,
}) {
  final anchorDay = today ?? DateTime.now();
  final result = <MerchantDailyPoint>[];

  for (var i = rangeDays - 1; i >= 0; i--) {
    final day = anchorDay.subtract(Duration(days: i));
    final key =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    result.add(
      fetched[key] ??
          MerchantDailyPoint(
            dateKey: key,
            views: 0,
            calls: 0,
            navs: 0,
            storyViews: 0,
          ),
    );
  }

  return result;
}

int sumDailyMetric(
  List<MerchantDailyPoint> points,
  int Function(MerchantDailyPoint point) selector,
) {
  var total = 0;
  for (final point in points) {
    total += selector(point);
  }
  return total;
}

double? calculateWoWPercent(int current, int previous) {
  if (previous == 0) return current > 0 ? 100.0 : null;
  return ((current - previous) / previous) * 100;
}

double? calculateDailyWoW(
  List<MerchantDailyPoint> points,
  int Function(MerchantDailyPoint point) selector,
) {
  if (points.isEmpty) return null;

  final last7 = points.length > 7 ? points.sublist(points.length - 7) : points;
  final prev7 = points.length > 14
      ? points.sublist(points.length - 14, points.length - 7)
      : <MerchantDailyPoint>[];

  return calculateWoWPercent(
    sumDailyMetric(last7, selector),
    sumDailyMetric(prev7, selector),
  );
}

/// Redeem an invite code via Cloud Function
Future<InviteResult> redeemInviteCode(String code, AppLocalizations l10n) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return InviteResult(success: false, message: l10n.inviteLoginRequired);
  }

  try {
    debugPrint('🚀 Calling redeemInviteCode Cloud Function...');

    final result = await FirebaseFunctions.instance
        .httpsCallable('redeemInviteCode')
        .call({'code': code.trim().toUpperCase()});

    final data = result.data as Map<dynamic, dynamic>;

    if (data['success'] == true) {
      return InviteResult(
        success: true,
        message: l10n.inviteSuccess,
        venueId: data['venueId'] as String?,
      );
    } else {
      return InviteResult(success: false, message: l10n.inviteActivationFailed);
    }
  } on FirebaseFunctionsException catch (e) {
    debugPrint('❌ Cloud Function Error: ${e.code} - ${e.message}');

    String message = l10n.inviteUnexpectedError;
    switch (e.code) {
      case 'not-found':
        message = l10n.inviteInvalidCode;
        break;
      case 'failed-precondition':
        if (e.message?.toLowerCase().contains('app check') == true) {
          message = l10n.inviteAppCheckFailed;
        } else if (e.message?.contains('expired') == true) {
          message = l10n.inviteCodeExpired;
        } else if (e.message?.contains('used') == true) {
          message = l10n.inviteCodeUsed;
        } else {
          message = l10n.inviteCodeUnavailable;
        }
        break;
      case 'resource-exhausted':
        message = l10n.inviteRateLimited;
        break;
      case 'aborted':
        message = l10n.inviteAborted;
        break;
      case 'unauthenticated':
        message = l10n.inviteUnauthenticated;
        break;
      default:
        message = e.message ?? l10n.inviteConnectionError;
    }

    return InviteResult(success: false, message: message);
  } catch (e) {
    debugPrint('❌ Error redeeming invite: $e');
    return InviteResult(success: false, message: l10n.inviteRetryError);
  }
}

// ============ DATA CLASSES ============

class MerchantStats {
  final double rating;
  final int reviewCount;
  final List<Map<String, dynamic>> recentReviews;

  MerchantStats({
    required this.rating,
    required this.reviewCount,
    required this.recentReviews,
  });

  factory MerchantStats.empty() =>
      MerchantStats(rating: 0.0, reviewCount: 0, recentReviews: []);
}

/// Server-aggregated analytics — read-only from client
class MerchantAnalytics {
  final int viewsTotal;
  final int viewsThisWeek;
  final int viewsLastWeek;
  final int callsTotal;
  final int callsThisWeek;
  final int callsLastWeek;
  final int navsTotal;
  final int navsThisWeek;
  final int navsLastWeek;
  final int storyViewsTotal;
  final int storyViewsThisWeek;

  MerchantAnalytics({
    required this.viewsTotal,
    required this.viewsThisWeek,
    required this.viewsLastWeek,
    required this.callsTotal,
    required this.callsThisWeek,
    required this.callsLastWeek,
    required this.navsTotal,
    required this.navsThisWeek,
    required this.navsLastWeek,
    required this.storyViewsTotal,
    required this.storyViewsThisWeek,
  });

  factory MerchantAnalytics.empty() => MerchantAnalytics(
    viewsTotal: 0,
    viewsThisWeek: 0,
    viewsLastWeek: 0,
    callsTotal: 0,
    callsThisWeek: 0,
    callsLastWeek: 0,
    navsTotal: 0,
    navsThisWeek: 0,
    navsLastWeek: 0,
    storyViewsTotal: 0,
    storyViewsThisWeek: 0,
  );

  factory MerchantAnalytics.fromMap(Map<String, dynamic> data) {
    return MerchantAnalytics(
      viewsTotal: (data['views_total'] as num?)?.toInt() ?? 0,
      viewsThisWeek: (data['views_this_week'] as num?)?.toInt() ?? 0,
      viewsLastWeek: (data['views_last_week'] as num?)?.toInt() ?? 0,
      callsTotal: (data['calls_total'] as num?)?.toInt() ?? 0,
      callsThisWeek: (data['calls_this_week'] as num?)?.toInt() ?? 0,
      callsLastWeek: (data['calls_last_week'] as num?)?.toInt() ?? 0,
      navsTotal: (data['navs_total'] as num?)?.toInt() ?? 0,
      navsThisWeek: (data['navs_this_week'] as num?)?.toInt() ?? 0,
      navsLastWeek: (data['navs_last_week'] as num?)?.toInt() ?? 0,
      storyViewsTotal: (data['story_views_total'] as num?)?.toInt() ?? 0,
      storyViewsThisWeek: (data['story_views_this_week'] as num?)?.toInt() ?? 0,
    );
  }

  /// Week-over-week percentage change. Returns null if no previous data.
  double? get viewsWoW => _wow(viewsThisWeek, viewsLastWeek);
  double? get callsWoW => _wow(callsThisWeek, callsLastWeek);
  double? get navsWoW => _wow(navsThisWeek, navsLastWeek);

  double? _wow(int current, int previous) {
    if (previous == 0) return current > 0 ? 100.0 : null;
    return ((current - previous) / previous * 100);
  }
}

class InviteResult {
  final bool success;
  final String message;
  final String? venueId;

  InviteResult({required this.success, required this.message, this.venueId});
}

class MerchantDailyPoint {
  final String dateKey; // YYYY-MM-DD
  final int views;
  final int calls;
  final int navs;
  final int storyViews;

  MerchantDailyPoint({
    required this.dateKey,
    required this.views,
    required this.calls,
    required this.navs,
    required this.storyViews,
  });

  factory MerchantDailyPoint.fromMap(Map<String, dynamic> data) {
    return MerchantDailyPoint(
      dateKey: data['date_key'] as String? ?? '',
      views: (data['views'] as num?)?.toInt() ?? 0,
      calls: (data['calls'] as num?)?.toInt() ?? 0,
      navs: (data['navs'] as num?)?.toInt() ?? 0,
      storyViews: (data['story_views'] as num?)?.toInt() ?? 0,
    );
  }
}
