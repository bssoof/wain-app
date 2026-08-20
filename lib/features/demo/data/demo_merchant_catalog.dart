import 'dart:math' as math;

import 'package:wain_app/features/demo/data/demo_offers_catalog.dart';
import 'package:wain_app/features/demo/data/demo_reviews_catalog.dart';
import 'package:wain_app/features/demo/data/demo_stories_catalog.dart';
import 'package:wain_app/features/demo/data/demo_venue_catalog.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/menu/data/demo_menu_catalog.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_stories_repository.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_content_health.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_analytics_funnel.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_dashboard_metrics.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_review.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_story.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_topup_request.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_validation_result.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_venue.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet_entry.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet_report.dart';

// The merchant's own view of the same café the customer walkthrough shows.
//
// Everything here is derived from the customer-side catalogs rather than
// written a second time: a presenter switches between the two views in front of
// the audience, and a merchant dashboard reporting a different rating or a
// different set of offers than the venue page is the one thing that reads as
// fake immediately.

/// The demo's clock, anchored to the real one.
///
/// This was a fixed date, on the reasoning that fixed dates keep the numbers
/// identical in every run. They do — but the dashboard does not only *show*
/// timestamps, it derives judgements from how far they are from now: "البيانات
/// قديمة، آخر تحديث قبل ٢٤٣ ساعة". A fixed anchor made the walkthrough open on
/// a staleness warning that grew by a day every day.
///
/// So only the anchors move. The shape of the data — the weekly rhythm, the
/// per-metric trend, every ratio — is fixed, which is what determinism actually
/// needed; the timestamps hang off [demoMerchantNow] at fixed offsets, so the
/// freshness rules read the demo as current.
///
/// One consequence worth knowing: because the weekly rhythm keys off the
/// weekday, the chart rotates with the real calendar. The weekend lift lands on
/// the actual weekend, which is the point, but it means the exact totals depend
/// on which day the walkthrough runs.
DateTime demoMerchantNow() => DateTime.now();

/// Offsets chosen so every "is this stale?" rule in the dashboard reads healthy:
/// analytics refreshed this morning, menu published within the fortnight the
/// content-health rule allows, a story still inside its 24h window.
DateTime demoMerchantAnalyticsUpdatedAt() =>
    demoMerchantNow().subtract(const Duration(hours: 2));

/// Deferred to the menu catalog so the content-health rule and the dashboard's
/// "last published" line cannot disagree about the same menu version.
DateTime demoMerchantMenuPublishedAt() => demoMenuPublishedAt();

DateTime demoMerchantLastStoryAt() =>
    demoMerchantNow().subtract(const Duration(hours: 6));

DateTime demoMerchantWalletCreatedAt() =>
    demoMerchantNow().subtract(const Duration(days: 200));

DateTime demoMerchantWalletUpdatedAt() =>
    demoMerchantNow().subtract(const Duration(hours: 18));

DateTime demoMerchantLastTopUpAt() =>
    demoMerchantNow().subtract(const Duration(days: 8));

/// The venue record the merchant screens edit, mirroring [buildDemoVenue].
MerchantVenue buildDemoMerchantVenue() {
  final venue = buildDemoVenue();

  return MerchantVenue(
    id: DemoMode.venueId,
    nameAr: venue.nameAr,
    nameEn: venue.nameEn,
    city: venue.city,
    phone: venue.phone,
    photos: venue.photos,
    categories: venue.categories,
    moodLabels: demoVenueTags.mood,
    hours: <String, List<MerchantVenueHoursSlot>>{
      for (final entry in demoVenueHours.entries)
        entry.key: <MerchantVenueHoursSlot>[
          for (final slot in entry.value)
            MerchantVenueHoursSlot(
              open: slot.open,
              close: slot.close,
              spansMidnight: slot.spansMidnight,
            ),
        ],
    },
    is24Hours: false,
    activeMenuVersionId: demoMenuActiveVersionId,
    lastStoryAt: demoMerchantLastStoryAt(),
    rating: venue.rating,
    minPrice: venue.minPrice,
    maxPrice: venue.maxPrice,
    lat: venue.lat,
    lng: venue.lng,
  );
}

/// Reviews as the merchant sees them: two already answered, four not.
///
/// The unanswered ones are what makes the "reply" surface worth showing, so the
/// split is deliberate rather than incidental.
List<MerchantReview> buildDemoMerchantReviews() {
  const repliedTo = <String, String>{
    'demo_review_1':
        'شكرًا لك! سعداء أن الأجواء عجبتك، بنستناك مرة ثانية ☕',
    'demo_review_4':
        'نعتذر عن الانتظار وقت الذروة — زدنا فريق الباريستا من الأسبوع الماضي.',
  };

  return <MerchantReview>[
    for (final review in buildDemoReviews())
      MerchantReview(
        id: review.id,
        userName: review.userName,
        userPhotoUrl: review.userPhotoUrl,
        rating: review.rating,
        text: review.text,
        createdAt: review.createdAt,
        merchantReply: repliedTo[review.id],
        merchantReplyAt: repliedTo.containsKey(review.id)
            ? review.createdAt.add(const Duration(hours: 6))
            : null,
        merchantReplyBy: repliedTo.containsKey(review.id)
            ? DemoMode.venueNameAr
            : null,
      ),
  ];
}

MerchantStats buildDemoMerchantStats() {
  final reviews = buildDemoMerchantReviews();
  return MerchantStats(
    rating: demoReviewsAverage(),
    reviewCount: reviews.length,
    recentReviews: reviews.take(3).toList(),
  );
}

/// The offers list in merchant shape, carrying the claim and redemption counts
/// the customer side has no reason to know about.
List<MerchantOffer> buildDemoMerchantOffers() {
  const performance = <String, ({int claims, int redeemed})>{
    'demo_offer_breakfast': (claims: 214, redeemed: 168),
    'demo_offer_free_juice': (claims: 96, redeemed: 61),
    'demo_offer_used_dessert': (claims: 143, redeemed: 139),
    'demo_offer_expired_evening': (claims: 58, redeemed: 22),
  };

  return <MerchantOffer>[
    for (final offer in buildDemoOffers())
      MerchantOffer(
        id: offer.id,
        venueId: DemoMode.venueId,
        titleAr: offer.titleAr,
        title: offer.titleEn ?? offer.titleAr,
        descriptionAr: offer.descriptionAr,
        description: offer.descriptionEn ?? offer.descriptionAr,
        termsAr: offer.termsAr ?? '',
        discountType: offer.discountType.name,
        discountValue: offer.discountValue,
        singleUsePerCustomer: offer.singleUsePerCustomer,
        isActive: offer.isActive,
        startAt: offer.startAt ?? demoOffersEpoch,
        endAt: offer.endAt,
        status: offer.isActive
            ? MerchantOfferStatus.active
            : MerchantOfferStatus.paused,
        claimsCount: performance[offer.id]?.claims ?? offer.claimsCount,
        redeemedCount: performance[offer.id]?.redeemed ?? offer.redeemedCount,
        conversionRate: null,
        isFeatured: offer.id == 'demo_offer_breakfast',
        featuredUntil: offer.id == 'demo_offer_breakfast'
            ? demoOffersValidUntil
            : null,
      ),
  ];
}

List<MerchantStory> buildDemoMerchantStories() {
  return <MerchantStory>[
    for (final story in buildDemoStories())
      MerchantStory(
        id: story.id,
        type: story.type,
        text: story.text,
        imageUrl: story.imageUrl,
        videoUrl: story.videoUrl,
        createdAt: story.createdAt,
        expiresAt: story.expiresAt,
        promotedUntil: story.promotedUntil,
        isPromotedFlag: story.promotedUntil != null,
      ),
  ];
}

/// Derived through the real [buildMerchantContentHealth] rather than
/// hand-written, so the card shows what the production rules would say about a
/// venue in this shape instead of a picture of a healthy venue.
MerchantContentHealth buildDemoMerchantContentHealth() {
  final venue = buildDemoMerchantVenue();

  return buildMerchantContentHealth(
    hasActiveMenu: true,
    menuPublishedAt: demoMerchantMenuPublishedAt(),
    photoCount: venue.photos.length,
    hasActiveStory: true,
    lastStoryAt: venue.lastStoryAt,
    is24Hours: venue.is24Hours,
    validHoursDays: venue.hours.values
        .where((slots) => slots.isNotEmpty)
        .length,
    hasName: venue.displayName.isNotEmpty,
    hasCity: venue.city.isNotEmpty,
    hasPhone: venue.phone.isNotEmpty,
    hasCategory: venue.categories.isNotEmpty,
    hasPhoto: venue.photos.isNotEmpty,
    now: demoMerchantNow(),
  );
}

/// A wallet with a real balance and a visible history — not zeroed, and not so
/// full that the low-balance affordance can never be demonstrated.
MerchantWallet buildDemoMerchantWallet() {
  return MerchantWallet(
    venueId: DemoMode.venueId,
    currency: 'ILS',
    status: MerchantWalletStatus.active,
    availableBalance: 240,
    lowBalanceThreshold: 50,
    lastEntryAt: demoMerchantWalletUpdatedAt(),
    lastTopUpAt: demoMerchantLastTopUpAt(),
    createdAt: demoMerchantWalletCreatedAt(),
    updatedAt: demoMerchantWalletUpdatedAt(),
  );
}

List<MerchantWalletEntry> buildDemoMerchantWalletEntries() {
  return <MerchantWalletEntry>[
    MerchantWalletEntry(
      id: 'demo_wallet_entry_5',
      type: 'debit',
      amount: 20,
      currency: 'ILS',
      balanceAfter: 240,
      featureKey: 'story_promotion',
      referenceType: 'story',
      referenceId: 'demo_story_offer',
      note: 'ترويج قصة العصير المجاني',
      metadata: const <String, dynamic>{},
      createdAt: demoMerchantWalletUpdatedAt(),
    ),
    MerchantWalletEntry(
      id: 'demo_wallet_entry_4',
      type: 'debit',
      amount: 35,
      currency: 'ILS',
      balanceAfter: 260,
      featureKey: 'offer_feature',
      referenceType: 'offer',
      referenceId: 'demo_offer_breakfast',
      note: 'تمييز عرض الفطور',
      metadata: const <String, dynamic>{},
      createdAt: demoMerchantNow().subtract(const Duration(days: 3)),
    ),
    MerchantWalletEntry(
      id: 'demo_wallet_entry_3',
      type: 'credit',
      amount: 200,
      currency: 'ILS',
      balanceAfter: 295,
      featureKey: null,
      referenceType: 'topup',
      referenceId: 'demo_topup_july',
      note: 'شحن رصيد — تحويل بنكي',
      metadata: const <String, dynamic>{},
      createdAt: demoMerchantLastTopUpAt(),
    ),
    MerchantWalletEntry(
      id: 'demo_wallet_entry_2',
      type: 'debit',
      amount: 15,
      currency: 'ILS',
      balanceAfter: 95,
      featureKey: 'story_promotion',
      referenceType: 'story',
      referenceId: 'demo_story_morning',
      note: 'ترويج قصة الصباح',
      metadata: const <String, dynamic>{},
      createdAt: demoMerchantNow().subtract(const Duration(days: 16)),
    ),
    MerchantWalletEntry(
      id: 'demo_wallet_entry_1',
      type: 'credit',
      amount: 110,
      currency: 'ILS',
      balanceAfter: 110,
      featureKey: null,
      referenceType: 'topup',
      referenceId: 'demo_topup_june',
      note: 'شحن رصيد — تحويل بنكي',
      metadata: const <String, dynamic>{},
      createdAt: demoMerchantNow().subtract(const Duration(days: 30)),
    ),
  ];
}

MerchantWalletReport buildDemoMerchantWalletReport() {
  final entries = buildDemoMerchantWalletEntries();
  final credited = entries
      .where((entry) => entry.isCredit)
      .fold<double>(0, (sum, entry) => sum + entry.amount);
  final debited = entries
      .where((entry) => !entry.isCredit)
      .fold<double>(0, (sum, entry) => sum + entry.amount);

  return MerchantWalletReport(
    venueId: DemoMode.venueId,
    currency: 'ILS',
    totalCredited: credited,
    topupTotalCredited: credited,
    totalDebited: debited,
    last30dDebited: debited,
    debitByFeature: const <String, double>{
      'story_promotion': 35,
      'offer_feature': 35,
    },
    mostUsedDebitFeature: 'story_promotion',
    lastTopUpAmount: 200,
    lastEntryAt: demoMerchantWalletUpdatedAt(),
    updatedAt: demoMerchantWalletUpdatedAt(),
  );
}

/// One settled request and one still pending, so the wallet screen can show
/// both states without the presenter having to submit anything.
List<MerchantTopUpRequest> buildDemoMerchantTopUpRequests() {
  return <MerchantTopUpRequest>[
    MerchantTopUpRequest(
      id: 'demo_topup_pending',
      venueId: DemoMode.venueId,
      requestedByUid: 'demo_merchant',
      amount: 150,
      currency: 'ILS',
      proofImageUrl: null,
      transferReference: 'DEMO-TRANSFER-0042',
      note: 'شحن رصيد لتمييز عروض آب',
      status: TopUpRequestStatus.pending,
      adminNote: null,
      linkedEntryId: null,
      reviewedAt: null,
      createdAt: demoMerchantNow().subtract(const Duration(days: 1)),
      updatedAt: demoMerchantNow().subtract(const Duration(days: 1)),
    ),
    MerchantTopUpRequest(
      id: 'demo_topup_approved',
      venueId: DemoMode.venueId,
      requestedByUid: 'demo_merchant',
      amount: 200,
      currency: 'ILS',
      proofImageUrl: null,
      transferReference: 'DEMO-TRANSFER-0038',
      note: null,
      status: TopUpRequestStatus.credited,
      adminNote: 'تم التحقق من الحوالة',
      linkedEntryId: 'demo_wallet_entry_3',
      reviewedAt: demoMerchantLastTopUpAt(),
      createdAt: demoMerchantNow().subtract(const Duration(days: 9)),
      updatedAt: demoMerchantLastTopUpAt(),
    ),
  ];
}

const Map<int, double> demoMerchantOfferPinPricing = <int, double>{
  1: 10,
  3: 25,
  7: 50,
};

const StoryPromotionPricing demoMerchantStoryPromotionPricing =
    StoryPromotionPricing(
      currency: 'ILS',
      oneDayPrice: 8,
      threeDayPrice: 20,
      sevenDayPrice: 40,
    );

/// Aggregate counters.
///
/// The weekly figures are summed out of [buildDemoMerchantDailySeries] rather
/// than written again here. They used to be a second, independent set of
/// numbers — and the dashboard reads the series, not these, so the two could
/// disagree without anything noticing. Only the lifetime totals are still
/// standalone, because nothing on screen compares them to the chart.
MerchantAnalytics buildDemoMerchantAnalytics() {
  final fortnight = buildDemoMerchantDailySeries(14);
  final previous = fortnight.take(7).toList();
  final current = fortnight.skip(7).toList();

  int total(List<MerchantDailyPoint> points, int Function(MerchantDailyPoint) f) =>
      points.fold<int>(0, (sum, point) => sum + f(point));

  double rate(int part, int whole) => whole == 0 ? 0 : part / whole;

  final views = total(current, (p) => p.views);
  final calls = total(current, (p) => p.calls);
  final navs = total(current, (p) => p.navs);
  final offerDetailViews = total(current, (p) => p.offerDetailViews);
  final claimClicks = total(current, (p) => p.claimClicks);
  final claimsCreated = total(current, (p) => p.claimsCreated);
  final redemptions = total(current, (p) => p.redemptions);
  final contactIntent = calls + navs;

  return MerchantAnalytics(
    viewsTotal: 18420,
    viewsThisWeek: views,
    viewsLastWeek: total(previous, (p) => p.views),
    callsTotal: 742,
    callsThisWeek: calls,
    callsLastWeek: total(previous, (p) => p.calls),
    navsTotal: 1180,
    navsThisWeek: navs,
    navsLastWeek: total(previous, (p) => p.navs),
    storyViewsTotal: 5560,
    storyViewsThisWeek: total(current, (p) => p.storyViews),
    offerDetailViewsTotal: 4310,
    offerDetailViews7d: offerDetailViews,
    offerDetailViewsPrev7d: total(previous, (p) => p.offerDetailViews),
    claimClicksTotal: 1620,
    claimClicks7d: claimClicks,
    claimClicksPrev7d: total(previous, (p) => p.claimClicks),
    claimsCreatedTotal: 511,
    claimsCreated7d: claimsCreated,
    claimsCreatedPrev7d: total(previous, (p) => p.claimsCreated),
    redemptionsTotal: 390,
    redemptions7d: redemptions,
    redemptionsPrev7d: total(previous, (p) => p.redemptions),
    contactIntent7d: contactIntent,
    contactIntentPrev7d:
        total(previous, (p) => p.calls) + total(previous, (p) => p.navs),
    contactRate7d: rate(contactIntent, views),
    detailToClaimClickRate7d: rate(claimClicks, offerDetailViews),
    viewToClaimRate7d: rate(claimsCreated, views),
    claimToRedemptionRate7d: rate(redemptions, claimsCreated),
    updatedAt: demoMerchantAnalyticsUpdatedAt(),
  );
}

/// Week-on-week growth per metric.
///
/// The series used to carry a weekly rhythm and nothing else, so a 7-day window
/// and the 7 days before it contained the same seven weekdays and summed to the
/// same number. Every tile on the dashboard read `+0%` — not a plausible week,
/// a mathematically impossible one, and the clearest tell that the data was
/// generated.
///
/// Deliberately not uniform, and navigation is deliberately *down*: a dashboard
/// where every number moves together, in the same direction, by the same
/// amount, is the same tell wearing a different hat. A real week has something
/// falling in it, and the insight engine has something to say about it.
const ({
  double views,
  double calls,
  double navs,
  double storyViews,
  double offerDetailViews,
  double claimClicks,
  double claimsCreated,
  double redemptions,
})
demoMerchantWeeklyGrowth = (
  views: 1.21,
  calls: 1.09,
  navs: 0.85,
  storyViews: 1.31,
  offerDetailViews: 1.27,
  claimClicks: 1.20,
  claimsCreated: 1.21,
  redemptions: 1.13,
);

/// Scales a metric by how long ago [offset] days it was.
///
/// Today is 1.0 and each step back divides by the weekly growth spread over
/// seven days, so summing any seven consecutive days and the seven before them
/// reproduces that growth. A factor below 1 makes the metric decline.
double _demoTrend(double weeklyGrowth, int offset) =>
    math.pow(weeklyGrowth, -offset / 7).toDouble();

/// A daily series ending today, shaped by a fixed weekly rhythm and a fixed
/// per-metric trend rather than random noise: the same chart every run, with a
/// weekend lift and a week-on-week movement the presenter can point at.
List<MerchantDailyPoint> buildDemoMerchantDailySeries(int rangeDays) {
  final safeRange = rangeDays <= 0 ? 7 : rangeDays;
  const weeklyShape = <double>[0.92, 0.88, 0.95, 1.04, 1.22, 1.30, 0.78];
  const growth = demoMerchantWeeklyGrowth;

  return <MerchantDailyPoint>[
    for (var offset = safeRange - 1; offset >= 0; offset -= 1)
      () {
        final day = demoMerchantNow().subtract(Duration(days: offset));
        // The baseline every metric is a fixed proportion of, before its own
        // trend is applied. Metrics are not derived from `views` itself, or
        // they would all inherit the same movement.
        final base = 170 * weeklyShape[day.weekday % 7];
        final views = (base * _demoTrend(growth.views, offset)).round();

        return MerchantDailyPoint(
          dateKey:
              '${day.year.toString().padLeft(4, '0')}-'
              '${day.month.toString().padLeft(2, '0')}-'
              '${day.day.toString().padLeft(2, '0')}',
          views: views,
          calls: (base * 0.050 * _demoTrend(growth.calls, offset)).round(),
          navs: (base * 0.075 * _demoTrend(growth.navs, offset)).round(),
          storyViews: (base * 0.44 * _demoTrend(growth.storyViews, offset))
              .round(),
          offerDetailViews:
              (base * 0.31 * _demoTrend(growth.offerDetailViews, offset))
                  .round(),
          claimClicks: (base * 0.113 * _demoTrend(growth.claimClicks, offset))
              .round(),
          claimsCreated:
              (base * 0.037 * _demoTrend(growth.claimsCreated, offset)).round(),
          redemptions: (base * 0.027 * _demoTrend(growth.redemptions, offset))
              .round(),
        );
      }(),
  ];
}

/// Per-offer analytics, keyed to the same four offers the customer side shows.
List<MerchantOfferAnalyticsSummary> buildDemoMerchantOfferAnalytics() {
  const perOffer = <String, ({int detail7, int click7, int claim7, int redeem7})>{
    'demo_offer_breakfast': (detail7: 186, click7: 74, claim7: 25, redeem7: 19),
    'demo_offer_free_juice': (detail7: 108, click7: 39, claim7: 13, redeem7: 9),
    'demo_offer_used_dessert': (detail7: 71, click7: 22, claim7: 7, redeem7: 5),
    'demo_offer_expired_evening': (detail7: 23, click7: 7, claim7: 2, redeem7: 1),
  };

  return <MerchantOfferAnalyticsSummary>[
    for (final offer in buildDemoMerchantOffers())
      () {
        final counts =
            perOffer[offer.id] ??
            (detail7: 0, click7: 0, claim7: 0, redeem7: 0);

        return MerchantOfferAnalyticsSummary(
          offerId: offer.id,
          offerTitleAr: offer.titleAr,
          status: offer.status,
          detailViews7d: counts.detail7,
          detailViews30d: counts.detail7 * 4,
          claimClicks7d: counts.click7,
          claimClicks30d: counts.click7 * 4,
          claimsCreated7d: counts.claim7,
          claimsCreated30d: counts.claim7 * 4,
          redemptions7d: counts.redeem7,
          redemptions30d: counts.redeem7 * 4,
          claimToRedemptionRate7d: counts.claim7 == 0
              ? 0
              : counts.redeem7 / counts.claim7,
          claimToRedemptionRate30d: counts.claim7 == 0
              ? 0
              : counts.redeem7 / counts.claim7,
          updatedAt: demoMerchantAnalyticsUpdatedAt(),
        );
      }(),
  ];
}

/// The scanner's answer for a demo QR payload.
///
/// Anything that is not one of this venue's own offer payloads comes back
/// invalid, so scanning a real customer's code during a walkthrough reports
/// "not one of ours" rather than inventing a claim.
MerchantValidationResult buildDemoMerchantValidation(String token) {
  final offer = buildDemoMerchantOffers()
      .where((candidate) => demoQrPayload(candidate.id) == token.trim())
      .firstOrNull;

  if (offer == null || !offer.isActive) {
    return const MerchantValidationResult(
      valid: false,
      reason: 'not_found',
      canRedeem: false,
    );
  }

  return MerchantValidationResult(
    valid: true,
    reason: null,
    claimId: 'demo_claim_${offer.id}',
    offer: MerchantValidationOfferPreview(
      titleAr: offer.titleAr,
      discountType: offer.discountType,
      discountValue: offer.discountValue,
      currency: 'ILS',
    ),
    venue: const MerchantValidationVenuePreview(nameAr: DemoMode.venueNameAr),
    canRedeem: true,
  );
}

/// Menu counts the merchant menu screen reports, taken from the same catalog
/// the customer menu tab renders.
int get demoMerchantMenuItemCount => demoMenuItems.length;

int get demoMerchantMenuSectionCount => demoMenuSections.length;
