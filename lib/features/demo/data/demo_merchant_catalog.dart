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
/// So only the anchors move. Every count, ratio and weekly shape below is still
/// a constant, which is what determinism actually needed; the timestamps hang
/// off [demoMerchantNow] at fixed offsets, so the story on screen is the same
/// every run and the freshness rules read it as current.
DateTime demoMerchantNow() => DateTime.now();

/// Offsets chosen so every "is this stale?" rule in the dashboard reads healthy:
/// analytics refreshed this morning, menu published within the fortnight the
/// content-health rule allows, a story still inside its 24h window.
DateTime demoMerchantAnalyticsUpdatedAt() =>
    demoMerchantNow().subtract(const Duration(hours: 2));

DateTime demoMerchantMenuPublishedAt() =>
    demoMerchantNow().subtract(const Duration(days: 4));

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
    activeMenuVersionId: 'demo_menu_v3',
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

/// Aggregate counters, chosen so the funnel narrows realistically at every
/// step and the week-on-week deltas are visible rather than flat.
MerchantAnalytics buildDemoMerchantAnalytics() {
  return MerchantAnalytics(
    viewsTotal: 18420,
    viewsThisWeek: 1265,
    viewsLastWeek: 1042,
    callsTotal: 742,
    callsThisWeek: 63,
    callsLastWeek: 58,
    navsTotal: 1180,
    navsThisWeek: 94,
    navsLastWeek: 111,
    storyViewsTotal: 5560,
    storyViewsThisWeek: 556,
    offerDetailViewsTotal: 4310,
    offerDetailViews7d: 388,
    offerDetailViewsPrev7d: 305,
    claimClicksTotal: 1620,
    claimClicks7d: 142,
    claimClicksPrev7d: 118,
    claimsCreatedTotal: 511,
    claimsCreated7d: 47,
    claimsCreatedPrev7d: 39,
    redemptionsTotal: 390,
    redemptions7d: 34,
    redemptionsPrev7d: 30,
    contactIntent7d: 157,
    contactIntentPrev7d: 169,
    contactRate7d: 0.124,
    detailToClaimClickRate7d: 0.366,
    viewToClaimRate7d: 0.037,
    claimToRedemptionRate7d: 0.723,
    updatedAt: demoMerchantAnalyticsUpdatedAt(),
  );
}

/// A daily series ending on [demoMerchantNow], shaped by a fixed weekly rhythm
/// rather than random noise: the same chart every run, with a weekend lift the
/// presenter can point at.
List<MerchantDailyPoint> buildDemoMerchantDailySeries(int rangeDays) {
  final safeRange = rangeDays <= 0 ? 7 : rangeDays;
  const weeklyShape = <double>[0.92, 0.88, 0.95, 1.04, 1.22, 1.30, 0.78];

  return <MerchantDailyPoint>[
    for (var offset = safeRange - 1; offset >= 0; offset -= 1)
      () {
        final day = demoMerchantNow().subtract(Duration(days: offset));
        final shape = weeklyShape[day.weekday % 7];
        final views = (170 * shape).round();

        return MerchantDailyPoint(
          dateKey:
              '${day.year.toString().padLeft(4, '0')}-'
              '${day.month.toString().padLeft(2, '0')}-'
              '${day.day.toString().padLeft(2, '0')}',
          views: views,
          calls: (views * 0.05).round(),
          navs: (views * 0.075).round(),
          storyViews: (views * 0.44).round(),
          offerDetailViews: (views * 0.31).round(),
          claimClicks: (views * 0.113).round(),
          claimsCreated: (views * 0.037).round(),
          redemptions: (views * 0.027).round(),
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
