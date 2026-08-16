// Exports the demo café as Firestore-shaped JSON, for the publisher script.
//
//   flutter test --no-pub test/tools/export_demo_seed_test.dart
//   -> writes .tmp/demo_seed.json
//
// It lives under test/ rather than tool/ because the entities it serialises
// import Flutter, and `dart run` compiles against the Dart SDK alone. Running
// it through the test runner also lets it assert the seed is coherent before
// anything is published, which is worth more than a bare script.
//
// Why this exists rather than the values being written into the publisher: the
// demo catalogs in lib/features/demo are the source of truth, and the merchant
// dashboard keeps reading them after the venue is published. If the published
// documents were typed a second time in JavaScript, the venue page and the
// merchant dashboard would describe the same café differently the first time
// either side changed — which is exactly how the header came to claim 4.6 while
// the reviews card said 3.8, and how the weekly analytics figures drifted from
// the chart they were supposed to summarise.
//
// Every document here is produced by the same code the app reads back, through
// each entity's own serialiser where it has one.

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wain_app/features/demo/data/demo_offers_catalog.dart';
import 'package:wain_app/features/demo/data/demo_reviews_catalog.dart';
import 'package:wain_app/features/demo/data/demo_stories_catalog.dart';
import 'package:wain_app/features/demo/data/demo_venue_catalog.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/demo/data/demo_merchant_catalog.dart';
import 'package:wain_app/features/menu/data/demo_menu_catalog.dart';

/// Firestore timestamps are emitted as ISO-8601 strings and converted back by
/// the publisher, so this file stays plain JSON and diffable.
String? _iso(DateTime? value) => value?.toUtc().toIso8601String();

/// The entities' own serialisers hand back `Timestamp` objects, which JSON
/// cannot encode. Walking the tree is deliberate: a field-by-field conversion
/// would silently miss whatever gets added to an entity later.
Object? _jsonSafe(Object? value) {
  if (value is Timestamp) return _iso(value.toDate());
  if (value is DateTime) return _iso(value);
  if (value is Map) {
    return <String, dynamic>{
      for (final entry in value.entries)
        entry.key.toString(): _jsonSafe(entry.value),
    };
  }
  if (value is List) return value.map(_jsonSafe).toList();
  return value;
}

Map<String, dynamic> _venue() {
  final venue = buildDemoVenue();
  // The entity's own serialiser, so the published document is by construction
  // the shape `Venue.fromJson` reads back.
  final json = Map<String, dynamic>.from(venue.toJson())..remove('id');

  return <String, dynamic>{
    ...json,
    // Written by the publisher as real server timestamps.
    'created_at': null,
    'updated_at': null,
  };
}

List<Map<String, dynamic>> _offers() {
  return <Map<String, dynamic>>[
    for (final offer in buildDemoOffers())
      <String, dynamic>{
        'id': offer.id,
        'venue_id': DemoMode.venueId,
        'title_ar': offer.titleAr,
        'title_en': offer.titleEn,
        'description_ar': offer.descriptionAr,
        'description_en': offer.descriptionEn,
        'discount_type': switch (offer.discountType.name) {
          'freeItem' => 'free_item',
          final other => other,
        },
        'discount_value': offer.discountValue,
        'currency': offer.currency,
        'start_at': _iso(offer.startAt),
        'end_at': _iso(offer.endAt),
        'is_active': offer.isActive,
        'terms_ar': offer.termsAr,
        'image_url': offer.imageUrl,
        'is_partner': offer.isPartner,
        'claims_count': offer.claimsCount,
        'redeemed_count': offer.redeemedCount,
        'single_use_per_customer': offer.singleUsePerCustomer,
      },
  ];
}

List<Map<String, dynamic>> _stories() {
  return <Map<String, dynamic>>[
    for (final story in buildDemoStories())
      <String, dynamic>{
        'id': story.id,
        'venue_id': story.venueId,
        'venue_name': story.venueName,
        'venue_photo_url': story.venuePhotoUrl,
        'type': story.type,
        'image_url': story.imageUrl,
        'video_url': story.videoUrl,
        'text': story.text,
        'offer_ref': story.offerRef,
        'created_at': _iso(story.createdAt),
        'expires_at': _iso(story.expiresAt),
        'promoted_until': _iso(story.promotedUntil),
        'view_count': story.viewCount,
        'duration_seconds': story.durationSeconds,
      },
  ];
}

List<Map<String, dynamic>> _reviews() {
  return <Map<String, dynamic>>[
    for (final review in buildDemoReviews())
      <String, dynamic>{
        ...review.toJson(),
        'id': review.id,
        'created_at': _iso(review.createdAt),
      },
  ];
}

Map<String, dynamic> _menu() {
  return <String, dynamic>{
    'sections': <Map<String, dynamic>>[
      for (final section in demoMenuSections) section.toJson(),
    ],
    'items': <Map<String, dynamic>>[
      for (final item in demoMenuItems) item.toJson()..['id'] = item.id,
    ],
  };
}

/// The merchant side, for when the dashboard is reached through a linked
/// account rather than /demo/merchant.
///
/// These are discovery snapshots. The debug app recognizes the linked demo
/// venue after the account lookup and switches the dashboard to the rolling
/// local catalog, so a walkthrough does not depend on this frozen timestamp.
/// Republish only when the catalog itself changes and Firestore discovery must
/// be brought back in sync.
Map<String, dynamic> _merchant() {
  final wallet = buildDemoMerchantWallet();
  final report = buildDemoMerchantWalletReport();
  final a = buildDemoMerchantAnalytics();

  return <String, dynamic>{
    'wallet': <String, dynamic>{
      'venue_id': wallet.venueId,
      'currency': wallet.currency,
      'status': wallet.status.name,
      'available_balance': wallet.availableBalance,
      'low_balance_threshold': wallet.lowBalanceThreshold,
      'last_entry_at': _iso(wallet.lastEntryAt),
      'last_top_up_at': _iso(wallet.lastTopUpAt),
      'created_at': _iso(wallet.createdAt),
      'updated_at': _iso(wallet.updatedAt),
    },
    'wallet_entries': <Map<String, dynamic>>[
      for (final e in buildDemoMerchantWalletEntries())
        <String, dynamic>{
          'id': e.id,
          'type': e.type,
          'amount': e.amount,
          'currency': e.currency,
          'balance_after': e.balanceAfter,
          'feature_key': e.featureKey,
          'reference_type': e.referenceType,
          'reference_id': e.referenceId,
          'note': e.note,
          'metadata': e.metadata,
          'created_at': _iso(e.createdAt),
        },
    ],
    'wallet_report': <String, dynamic>{
      'venue_id': report.venueId,
      'currency': report.currency,
      'total_credited': report.totalCredited,
      'topup_total_credited': report.topupTotalCredited,
      'total_debited': report.totalDebited,
      'last_30d_debited': report.last30dDebited,
      'debit_by_feature': report.debitByFeature,
      'most_used_debit_feature': report.mostUsedDebitFeature,
      'last_top_up_amount': report.lastTopUpAmount,
      'last_entry_at': _iso(report.lastEntryAt),
      'updated_at': _iso(report.updatedAt),
    },
    'topup_requests': <Map<String, dynamic>>[
      for (final r in buildDemoMerchantTopUpRequests())
        <String, dynamic>{
          'id': r.id,
          'venue_id': r.venueId,
          'requested_by_uid': r.requestedByUid,
          'amount': r.amount,
          'currency': r.currency,
          'proof_image_url': r.proofImageUrl,
          'transfer_reference': r.transferReference,
          'note': r.note,
          'status': r.status.name,
          'admin_note': r.adminNote,
          'linked_entry_id': r.linkedEntryId,
          'reviewed_at': _iso(r.reviewedAt),
          'created_at': _iso(r.createdAt),
          'updated_at': _iso(r.updatedAt),
        },
    ],
    'analytics': <String, dynamic>{
      'views_total': a.viewsTotal,
      'views_this_week': a.viewsThisWeek,
      'views_last_week': a.viewsLastWeek,
      'calls_total': a.callsTotal,
      'calls_this_week': a.callsThisWeek,
      'calls_last_week': a.callsLastWeek,
      'navs_total': a.navsTotal,
      'navs_this_week': a.navsThisWeek,
      'navs_last_week': a.navsLastWeek,
      'story_views_total': a.storyViewsTotal,
      'story_views_this_week': a.storyViewsThisWeek,
      'offer_detail_views_total': a.offerDetailViewsTotal,
      'offer_detail_views_7d': a.offerDetailViews7d,
      'offer_detail_views_prev_7d': a.offerDetailViewsPrev7d,
      'claim_clicks_total': a.claimClicksTotal,
      'claim_clicks_7d': a.claimClicks7d,
      'claim_clicks_prev_7d': a.claimClicksPrev7d,
      'claims_created_total': a.claimsCreatedTotal,
      'claims_created_7d': a.claimsCreated7d,
      'claims_created_prev_7d': a.claimsCreatedPrev7d,
      'redemptions_total': a.redemptionsTotal,
      'redemptions_7d': a.redemptions7d,
      'redemptions_prev_7d': a.redemptionsPrev7d,
      'contact_intent_7d': a.contactIntent7d,
      'contact_intent_prev_7d': a.contactIntentPrev7d,
      'contact_rate_7d': a.contactRate7d,
      'detail_to_claim_click_rate_7d': a.detailToClaimClickRate7d,
      'view_to_claim_rate_7d': a.viewToClaimRate7d,
      'claim_to_redemption_rate_7d': a.claimToRedemptionRate7d,
      'updated_at': _iso(a.updatedAt),
    },
    'analytics_daily': <Map<String, dynamic>>[
      for (final p in buildDemoMerchantDailySeries(30))
        <String, dynamic>{
          'id': p.dateKey,
          'date_key': p.dateKey,
          'views': p.views,
          'calls': p.calls,
          'navs': p.navs,
          'story_views': p.storyViews,
          'offer_detail_views': p.offerDetailViews,
          'claim_clicks': p.claimClicks,
          'claims_created': p.claimsCreated,
          'redemptions': p.redemptions,
        },
    ],
    'offer_analytics': <Map<String, dynamic>>[
      for (final r in buildDemoMerchantOfferAnalytics())
        <String, dynamic>{
          'id': r.offerId,
          'offer_id': r.offerId,
          'offer_title_ar': r.offerTitleAr,
          'status': r.status?.storageValue,
          'detail_views_7d': r.detailViews7d,
          'detail_views_30d': r.detailViews30d,
          'claim_clicks_7d': r.claimClicks7d,
          'claim_clicks_30d': r.claimClicks30d,
          'claims_created_7d': r.claimsCreated7d,
          'claims_created_30d': r.claimsCreated30d,
          'redemptions_7d': r.redemptions7d,
          'redemptions_30d': r.redemptions30d,
          'claim_to_redemption_rate_7d': r.claimToRedemptionRate7d,
          'claim_to_redemption_rate_30d': r.claimToRedemptionRate30d,
          'updated_at': _iso(r.updatedAt),
        },
    ],
  };
}

void main() {
  test('exports a coherent demo seed to .tmp/demo_seed.json', () {
    final seed = buildDemoSeed();

    // Checked before anything reaches Firestore: a published venue whose
    // header rating disagrees with its own reviews is the failure this whole
    // pipeline exists to prevent.
    expect(seed['venue_id'], DemoMode.venueId);
    expect((seed['venue'] as Map)['rating'], demoReviewsAverage());
    expect(seed['offers'], hasLength(4));
    expect(seed['stories'], hasLength(3));
    expect(seed['reviews'], hasLength(6));
    expect((seed['menu'] as Map)['items'], hasLength(demoMenuItems.length));

    final m = seed['merchant'] as Map;
    expect((m['wallet'] as Map)['available_balance'], 240);
    expect(m['wallet_entries'], hasLength(5));
    expect(m['analytics_daily'], hasLength(30));
    expect(m['offer_analytics'], hasLength(4));
    expect(m['topup_requests'], hasLength(2));
    expect((m['analytics'] as Map)['views_this_week'], greaterThan(0));

    for (final offer in seed['offers'] as List) {
      expect((offer as Map)['venue_id'], DemoMode.venueId);
    }

    final out = File('.tmp/demo_seed.json');
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(seed));
    // ignore: avoid_print
    print('wrote ${out.path}');
  });
}

Map<String, dynamic> buildDemoSeed() {
  return _jsonSafe(<String, dynamic>{
        'venue_id': DemoMode.venueId,
        'venue': _venue(),
        'offers': _offers(),
        'stories': _stories(),
        'reviews': _reviews(),
        'menu': _menu(),
        'merchant': _merchant(),
        'rating_note':
            'rating is derived from the reviews below; do not hand-edit it in '
            'Firestore or the venue header and the reviews card will disagree',
      })!
      as Map<String, dynamic>;
}
