import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'package:wain_app/features/merchant/domain/entities/merchant_analytics_funnel.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_dashboard_metrics.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_dashboard_refresh.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_review.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_venue.dart';

class MerchantDashboardRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  MerchantDashboardRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  Future<String?> getLinkedVenueId(String userId, {Source? source}) async {
    final options = source != null ? GetOptions(source: source) : null;
    final merchantDoc = options != null
        ? await _firestore.collection('merchants').doc(userId).get(options)
        : await _firestore.collection('merchants').doc(userId).get();
    final merchantVenueId = _stringOrNull(merchantDoc.data()?['venue_id']);
    if (merchantVenueId != null) {
      return merchantVenueId;
    }

    // Legacy fallback for accounts that were linked before merchants/{uid}
    // became the authoritative merchant-to-venue source.
    final userDoc = options != null
        ? await _firestore.collection('users').doc(userId).get(options)
        : await _firestore.collection('users').doc(userId).get();
    return _stringOrNull(userDoc.data()?['merchant_venue_id']);
  }

  Future<bool> venueExists(String venueId, {Source? source}) async {
    final options = source != null ? GetOptions(source: source) : null;
    final doc = options != null
        ? await _firestore.collection('venues').doc(venueId).get(options)
        : await _firestore.collection('venues').doc(venueId).get();
    return doc.exists;
  }

  Future<MerchantVenue?> getVenue(String venueId, {Source? source}) async {
    final options = source != null ? GetOptions(source: source) : null;
    final doc = options != null
        ? await _firestore.collection('venues').doc(venueId).get(options)
        : await _firestore.collection('venues').doc(venueId).get();
    if (!doc.exists) {
      return null;
    }
    return mapMerchantVenueData({'id': doc.id, ...doc.data()!});
  }

  Future<MerchantStats> getStats(String venueId, {Source? source}) async {
    final options = source != null ? GetOptions(source: source) : null;
    final venueDoc = options != null
        ? await _firestore.collection('venues').doc(venueId).get(options)
        : await _firestore.collection('venues').doc(venueId).get();
    final reviewsSnap = options != null
        ? await _firestore
              .collection('venues')
              .doc(venueId)
              .collection('reviews')
              .orderBy('created_at', descending: true)
              .limit(10)
              .get(options)
        : await _firestore
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
          .map((doc) => mapMerchantReviewData({'id': doc.id, ...doc.data()}))
          .toList(),
    );
  }

  Future<List<MerchantReview>> getReviews(
    String venueId, {
    int limit = 100,
    Source? source,
  }) async {
    final options = source != null ? GetOptions(source: source) : null;
    final snap = options != null
        ? await _firestore
              .collection('venues')
              .doc(venueId)
              .collection('reviews')
              .orderBy('created_at', descending: true)
              .limit(limit)
              .get(options)
        : await _firestore
              .collection('venues')
              .doc(venueId)
              .collection('reviews')
              .orderBy('created_at', descending: true)
              .limit(limit)
              .get();

    return snap.docs
        .map((doc) => mapMerchantReviewData({'id': doc.id, ...doc.data()}))
        .toList();
  }

  Future<List<MerchantOffer>> getOffers(
    String venueId, {
    Source? source,
  }) async {
    final options = source != null ? GetOptions(source: source) : null;
    final snap = options != null
        ? await _firestore
              .collection('offers')
              .where('venue_id', isEqualTo: venueId)
              .get(options)
        : await _firestore
              .collection('offers')
              .where('venue_id', isEqualTo: venueId)
              .get();

    return snap.docs
        .map((doc) => mapMerchantOfferData({'id': doc.id, ...doc.data()}))
        .toList();
  }

  Future<MerchantAnalytics> getAnalytics(
    String venueId, {
    Source? source,
  }) async {
    final options = source != null ? GetOptions(source: source) : null;
    final doc = options != null
        ? await _firestore
              .collection('venue_analytics')
              .doc(venueId)
              .get(options)
        : await _firestore.collection('venue_analytics').doc(venueId).get();
    if (!doc.exists) {
      return MerchantAnalytics.empty();
    }
    return mapMerchantAnalyticsData(doc.data()!);
  }

  Future<List<MerchantDailyPoint>> getAnalyticsDaily({
    required String venueId,
    required int rangeDays,
    Source? source,
  }) async {
    final safeRange = rangeDays <= 0 ? 7 : rangeDays;
    final options = source != null ? GetOptions(source: source) : null;
    final snap = options != null
        ? await _firestore
              .collection('venue_analytics_daily')
              .doc(venueId)
              .collection('days')
              .orderBy('date_key', descending: true)
              .limit(safeRange)
              .get(options)
        : await _firestore
              .collection('venue_analytics_daily')
              .doc(venueId)
              .collection('days')
              .orderBy('date_key', descending: true)
              .limit(safeRange)
              .get();

    final fetched = <String, MerchantDailyPoint>{};
    for (final doc in snap.docs) {
      final point = mapMerchantDailyPointData({'id': doc.id, ...doc.data()});
      fetched[point.dateKey] = point;
    }

    return buildZeroFilledSeries(rangeDays: safeRange, fetched: fetched);
  }

  Future<List<MerchantOfferAnalyticsSummary>> getOfferAnalytics({
    required String venueId,
    int limit = 50,
    Source? source,
  }) async {
    final safeLimit = limit <= 0 ? 10 : limit;
    final options = source != null ? GetOptions(source: source) : null;
    final snap = options != null
        ? await _firestore
              .collection('venue_offer_analytics')
              .doc(venueId)
              .collection('offers')
              .orderBy('updated_at', descending: true)
              .limit(safeLimit)
              .get(options)
        : await _firestore
              .collection('venue_offer_analytics')
              .doc(venueId)
              .collection('offers')
              .orderBy('updated_at', descending: true)
              .limit(safeLimit)
              .get();

    return snap.docs
        .map(
          (doc) => mapMerchantOfferAnalyticsSummaryData({
            'id': doc.id,
            ...doc.data(),
          }),
        )
        .toList();
  }

  Future<MerchantAnalyticsDrilldownPayload> getAnalyticsDrilldown({
    required String venueId,
    required int periodDays,
    Source? source,
  }) async {
    final normalizedPeriodDays = periodDays == 30 ? 30 : 7;
    final analytics = await getAnalytics(venueId, source: source);
    final comparisonPoints = await getAnalyticsDaily(
      venueId: venueId,
      rangeDays: normalizedPeriodDays * 2,
      source: source,
    );
    final offers = await getOfferAnalytics(venueId: venueId, source: source);

    final currentPoints = comparisonPoints.length <= normalizedPeriodDays
        ? comparisonPoints
        : comparisonPoints.sublist(
            comparisonPoints.length - normalizedPeriodDays,
          );
    final previousPoints = comparisonPoints.length <= normalizedPeriodDays
        ? const <MerchantDailyPoint>[]
        : comparisonPoints.sublist(
            0,
            comparisonPoints.length - normalizedPeriodDays,
          );

    return buildMerchantAnalyticsDrilldownPayload(
      analytics: analytics,
      currentPoints: currentPoints,
      previousPoints: previousPoints,
      periodDays: normalizedPeriodDays,
      offers: offers,
    );
  }

  Future<DashboardRefreshResult> refreshDashboard({
    required bool debugMode,
    int analyticsDays = 30,
  }) async {
    try {
      final analyticsResult = await _functions
          .httpsCallable('backfillMerchantAnalytics')
          .call({'days': analyticsDays});
      final busyTimesResult = await _functions
          .httpsCallable('backfillVenueBusyTimes')
          .call({'demoMode': debugMode});

      final analyticsData = _asStringMap(analyticsResult.data);
      final summary = _asStringMap(analyticsData?['summary']);

      return DashboardRefreshResult(
        views: (summary?['views_total'] as num?)?.toInt() ?? 0,
        calls: (summary?['calls_total'] as num?)?.toInt() ?? 0,
        navs: (summary?['navs_total'] as num?)?.toInt() ?? 0,
        busyTimesStatus: parseBusyTimesRefreshStatus(
          busyTimesResult.data as Map<dynamic, dynamic>?,
        ),
      );
    } on FirebaseFunctionsException catch (error) {
      throw DashboardRefreshException(
        type: classifyDashboardRefreshFailure(
          code: error.code,
          message: error.message,
        ),
        debugMessage: error.message ?? error.code,
      );
    } catch (error) {
      throw DashboardRefreshException(
        type: DashboardRefreshFailureType.unknown,
        debugMessage: error.toString(),
      );
    }
  }
}

Map<String, dynamic>? _asStringMap(dynamic value) {
  if (value is! Map) {
    return null;
  }

  return value.map((key, entryValue) => MapEntry(key.toString(), entryValue));
}

String? _stringOrNull(dynamic value) {
  final normalized = (value as String?)?.trim();
  return normalized != null && normalized.isNotEmpty ? normalized : null;
}

@visibleForTesting
MerchantVenue mapMerchantVenueData(Map<String, dynamic> data) {
  final tags = _asStringMap(data['tags']) ?? const <String, dynamic>{};
  final moodLabels =
      (tags['mood'] as List?)
          ?.map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty)
          .toList() ??
      const <String>[];

  final hours = <String, List<MerchantVenueHoursSlot>>{};
  final rawHours = _asStringMap(data['hours']) ?? const <String, dynamic>{};
  rawHours.forEach((day, rawSlots) {
    if (rawSlots is! List) {
      hours[day] = const <MerchantVenueHoursSlot>[];
      return;
    }
    hours[day] = rawSlots.whereType<Map>().map((slot) {
      final slotData = _asStringMap(slot) ?? const <String, dynamic>{};
      return MerchantVenueHoursSlot(
        open: (slotData['open'] as String? ?? '').trim(),
        close: (slotData['close'] as String? ?? '').trim(),
        spansMidnight: slotData['spans_midnight'] == true,
      );
    }).toList();
  });

  return MerchantVenue(
    id: (data['id'] as String? ?? '').trim(),
    nameAr: (data['name_ar'] as String? ?? '').trim(),
    nameEn: (data['name_en'] as String? ?? '').trim(),
    city: (data['city'] as String? ?? '').trim(),
    phone: (data['phone'] as String? ?? '').trim(),
    photos:
        (data['photos'] as List?)
            ?.map((item) => '$item'.trim())
            .where((item) => item.isNotEmpty)
            .toList() ??
        const <String>[],
    categories:
        (data['categories'] as List?)
            ?.map((item) => '$item'.trim())
            .where((item) => item.isNotEmpty)
            .toList() ??
        const <String>[],
    moodLabels: moodLabels,
    hours: hours,
    is24Hours: data['is_24h'] == true,
    activeMenuVersionId: (data['active_menu_version_id'] as String?)?.trim(),
    lastStoryAt: _parseDateTime(data['last_story_at']),
    rating: (data['rating'] as num?)?.toDouble() ?? 0,
    minPrice: (data['min_price'] as num?)?.toInt() ?? 0,
    maxPrice: (data['max_price'] as num?)?.toInt() ?? 0,
    lat: (data['lat'] as num?)?.toDouble() ?? 0,
    lng: (data['lng'] as num?)?.toDouble() ?? 0,
  );
}

@visibleForTesting
MerchantOffer mapMerchantOfferData(Map<String, dynamic> data) {
  return MerchantOffer(
    id: (data['id'] as String? ?? '').trim(),
    venueId: (data['venue_id'] as String? ?? '').trim(),
    titleAr: (data['title_ar'] as String? ?? '').trim(),
    title: (data['title'] as String? ?? '').trim(),
    descriptionAr: (data['description_ar'] as String? ?? '').trim(),
    description: (data['description'] as String? ?? '').trim(),
    termsAr: (data['terms_ar'] as String? ?? '').trim(),
    discountType: (data['discount_type'] as String? ?? 'percent').trim(),
    discountValue: (data['discount_value'] as num?)?.toDouble() ?? 0,
    singleUsePerCustomer: data['single_use_per_customer'] as bool? ?? true,
    isActive: data['is_active'] as bool? ?? true,
    startAt: _parseDateTime(data['start_at']),
    endAt: _parseDateTime(data['end_at']),
    status: MerchantOfferStatus.tryParse(data['status'] as String?),
    claimsCount: (data['claims_count'] as num?)?.toInt() ?? 0,
    redeemedCount: (data['redeemed_count'] as num?)?.toInt() ?? 0,
    conversionRate: (data['conversion_rate'] as num?)?.toDouble(),
    isFeatured: data['is_featured'] as bool? ?? false,
    featuredUntil: _parseDateTime(data['featured_until']),
  );
}

@visibleForTesting
MerchantReview mapMerchantReviewData(Map<String, dynamic> data) {
  return MerchantReview(
    id: (data['id'] as String? ?? '').trim(),
    userName: (data['user_name'] as String? ?? '').trim(),
    userPhotoUrl: (data['user_photo_url'] as String?)?.trim(),
    rating: (data['rating'] as num?)?.toDouble() ?? 0,
    text: ((data['text'] as String?) ?? (data['comment'] as String?) ?? '')
        .trim(),
    createdAt: _parseDateTime(data['created_at']),
    merchantReply: (data['merchant_reply'] as String?)?.trim(),
    merchantReplyAt: _parseDateTime(data['merchant_reply_at']),
    merchantReplyBy: (data['merchant_reply_by'] as String?)?.trim(),
  );
}

@visibleForTesting
MerchantAnalytics mapMerchantAnalyticsData(Map<String, dynamic> data) {
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
    storyToVenueViewsTotal:
        (data['story_to_venue_views_total'] as num?)?.toInt() ?? 0,
    storyToVenueViewsThisWeek:
        (data['story_to_venue_views_this_week'] as num?)?.toInt() ?? 0,
    storyToVenueViews7d:
        (data['story_to_venue_views_7d'] as num?)?.toInt() ?? 0,
    offerDetailViewsTotal:
        (data['offer_detail_views_total'] as num?)?.toInt() ?? 0,
    offerDetailViews7d: (data['offer_detail_views_7d'] as num?)?.toInt() ?? 0,
    offerDetailViewsPrev7d:
        (data['offer_detail_views_prev_7d'] as num?)?.toInt() ?? 0,
    claimClicksTotal: (data['claim_clicks_total'] as num?)?.toInt() ?? 0,
    claimClicks7d: (data['claim_clicks_7d'] as num?)?.toInt() ?? 0,
    claimClicksPrev7d: (data['claim_clicks_prev_7d'] as num?)?.toInt() ?? 0,
    claimsCreatedTotal: (data['claims_created_total'] as num?)?.toInt() ?? 0,
    claimsCreated7d: (data['claims_created_7d'] as num?)?.toInt() ?? 0,
    claimsCreatedPrev7d: (data['claims_created_prev_7d'] as num?)?.toInt() ?? 0,
    redemptionsTotal: (data['redemptions_total'] as num?)?.toInt() ?? 0,
    redemptions7d: (data['redemptions_7d'] as num?)?.toInt() ?? 0,
    redemptionsPrev7d: (data['redemptions_prev_7d'] as num?)?.toInt() ?? 0,
    contactIntent7d: (data['contact_intent_7d'] as num?)?.toInt() ?? 0,
    contactIntentPrev7d: (data['contact_intent_prev_7d'] as num?)?.toInt() ?? 0,
    contactRate7d: (data['contact_rate_7d'] as num?)?.toDouble() ?? 0,
    detailToClaimClickRate7d:
        (data['detail_to_claim_click_rate_7d'] as num?)?.toDouble() ?? 0,
    viewToClaimRate7d: (data['view_to_claim_rate_7d'] as num?)?.toDouble() ?? 0,
    claimToRedemptionRate7d:
        (data['claim_to_redemption_rate_7d'] as num?)?.toDouble() ?? 0,
    updatedAt: _parseDateTime(data['updated_at']),
  );
}

@visibleForTesting
MerchantDailyPoint mapMerchantDailyPointData(Map<String, dynamic> data) {
  return MerchantDailyPoint(
    dateKey: data['date_key'] as String? ?? '',
    views: (data['views'] as num?)?.toInt() ?? 0,
    calls: (data['calls'] as num?)?.toInt() ?? 0,
    navs: (data['navs'] as num?)?.toInt() ?? 0,
    storyViews: (data['story_views'] as num?)?.toInt() ?? 0,
    storyToVenueViews: (data['story_to_venue_views'] as num?)?.toInt() ?? 0,
    offerDetailViews: (data['offer_detail_views'] as num?)?.toInt() ?? 0,
    claimClicks: (data['claim_clicks'] as num?)?.toInt() ?? 0,
    claimsCreated: (data['claims_created'] as num?)?.toInt() ?? 0,
    redemptions: (data['redemptions'] as num?)?.toInt() ?? 0,
  );
}

@visibleForTesting
MerchantOfferAnalyticsSummary mapMerchantOfferAnalyticsSummaryData(
  Map<String, dynamic> data,
) {
  return MerchantOfferAnalyticsSummary(
    offerId: (data['offer_id'] as String? ?? data['id'] as String? ?? '')
        .trim(),
    offerTitleAr: (data['offer_title_ar'] as String? ?? '').trim(),
    status: MerchantOfferStatus.tryParse(data['status'] as String?),
    detailViews7d: (data['detail_views_7d'] as num?)?.toInt() ?? 0,
    detailViews30d: (data['detail_views_30d'] as num?)?.toInt() ?? 0,
    claimClicks7d: (data['claim_clicks_7d'] as num?)?.toInt() ?? 0,
    claimClicks30d: (data['claim_clicks_30d'] as num?)?.toInt() ?? 0,
    claimsCreated7d: (data['claims_created_7d'] as num?)?.toInt() ?? 0,
    claimsCreated30d: (data['claims_created_30d'] as num?)?.toInt() ?? 0,
    redemptions7d: (data['redemptions_7d'] as num?)?.toInt() ?? 0,
    redemptions30d: (data['redemptions_30d'] as num?)?.toInt() ?? 0,
    claimToRedemptionRate7d:
        (data['claim_to_redemption_rate_7d'] as num?)?.toDouble() ?? 0,
    claimToRedemptionRate30d:
        (data['claim_to_redemption_rate_30d'] as num?)?.toDouble() ?? 0,
    updatedAt: _parseDateTime(data['updated_at']),
  );
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

// Removed _getServerFirstDocument and _getServerFirstQuery.
// Offline fallback is now handled exclusively by fetchWithOfflineFallback
// in the provider layer. The repository is stateless and applies the
// Source parameter it receives directly.

/// Builds a contiguous list of [MerchantDailyPoint] for the last [rangeDays]
/// days, inserting zero-value points for missing days.
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
            offerDetailViews: 0,
            claimClicks: 0,
            claimsCreated: 0,
            redemptions: 0,
          ),
    );
  }

  return result;
}
