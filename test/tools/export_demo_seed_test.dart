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

    for (final offer in seed['offers'] as List) {
      expect((offer as Map)['venue_id'], DemoMode.venueId);
    }

    final out = File('.tmp/demo_seed.json');
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(seed),
    );
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
    'rating_note':
        'rating is derived from the reviews below; do not hand-edit it in '
        'Firestore or the venue header and the reviews card will disagree',
  })! as Map<String, dynamic>;
}
