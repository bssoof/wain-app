import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/demo/application/demo_session_store.dart';
import 'package:wain_app/features/demo/data/demo_offers_catalog.dart';
import 'package:wain_app/features/demo/data/demo_reviews_catalog.dart';
import 'package:wain_app/features/demo/data/demo_stories_catalog.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/offers/data/repositories/offers_repository.dart';
import 'package:wain_app/features/offers/domain/entities/offer.dart';
import 'package:wain_app/features/offers/presentation/providers/offers_providers.dart';
import 'package:wain_app/features/reviews/presentation/providers/reviews_provider.dart';
import 'package:wain_app/features/stories/presentation/providers/stories_provider.dart'
    as stories_provider;

/// Fails if any production repository behind offers or reviews is touched.
class _FailOnCall {
  final List<String> calls = <String>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName
        .toString()
        .replaceAll(RegExp(r'Symbol\("|"\)'), '');
    calls.add(name);
    throw StateError('production call $name reached from the demo');
  }
}

class _FailOnCallOffersRepository extends _FailOnCall
    implements OffersRepository {}

void main() {
  group('demo offers catalog', () {
    test('covers percent, amount, free-item and a used offer', () {
      final offers = buildDemoOffers();
      expect(offers, hasLength(4));
      expect(
        offers.map((o) => o.discountType).toSet(),
        containsAll(<DiscountType>{
          DiscountType.percent,
          DiscountType.amount,
          DiscountType.freeItem,
        }),
      );
      expect(demoUsedOfferIds, isNotEmpty);
      final used = offers.firstWhere((o) => demoUsedOfferIds.contains(o.id));
      expect(used.redeemedCount, greaterThan(0));
    });

    test('every offer is complete and locally illustrated', () {
      for (final offer in buildDemoOffers()) {
        expect(offer.venueId, DemoMode.venueId, reason: offer.id);
        expect(offer.titleAr.trim(), isNotEmpty, reason: offer.id);
        expect(offer.titleEn?.trim(), isNotEmpty, reason: offer.id);
        expect(offer.descriptionAr.trim(), isNotEmpty, reason: offer.id);
        expect(offer.termsAr?.trim(), isNotEmpty, reason: offer.id);
        expect(offer.endAt, isNotNull, reason: offer.id);
        expect(offer.imageUrl, startsWith('asset://'), reason: offer.id);
        expect(offer.singleUsePerCustomer, isTrue, reason: offer.id);
        final assetPath = offer.imageUrl!.substring('asset://'.length);
        expect(File(assetPath).existsSync(), isTrue, reason: assetPath);
      }
    });

    test('offer ids are unique', () {
      final ids = buildDemoOffers().map((o) => o.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('the demo QR is inert and says so', () {
      final payload = demoQrPayload('demo_offer_percent_coffee');
      expect(payload, startsWith('WAIN-DEMO://'));
      expect(payload, contains('valid=false'));
      expect(payload, contains('NOT_REDEEMABLE'));
      // It must not look like a claim token to anything downstream.
      expect(payload, isNot(matches(RegExp(r'^[A-Za-z0-9_\-]{20,}$'))));
      expect(demoQrNoticeAr, contains('غير صالح'));
      expect(demoQrNoticeEn, contains('not valid'));
    });

    test('validity windows are fixed, not wall-clock derived', () {
      final first = buildDemoOffers();
      final second = buildDemoOffers();
      expect(first.first.endAt, second.first.endAt);
      expect(demoOffersEpoch, DateTime.utc(2026, 7, 1));
    });
  });

  group('demo stories catalog', () {
    test('has three stories including one bound to an offer', () {
      final stories = buildDemoStories();
      expect(stories, hasLength(3));
      expect(stories.map((s) => s.type).toSet(), containsAll(<String>{'image', 'offer', 'text'}));

      final offerStory = stories.firstWhere((s) => s.type == 'offer');
      expect(offerStory.offerRef, isNotNull);
      expect(
        buildDemoOffers().map((o) => o.id),
        contains(offerStory.offerRef),
        reason: 'the story must point at a real demo offer',
      );
      expect(stories.any((s) => s.promotedUntil != null), isTrue);
    });

    test('none are expired and expiry does not depend on the wall clock', () {
      for (final story in buildDemoStories()) {
        expect(story.isExpired, isFalse, reason: story.id);
        expect(story.durationSeconds, greaterThan(0), reason: story.id);
      }
      expect(buildDemoStories().first.expiresAt, DateTime.utc(2099, 1, 1));
    });

    test('thumbnails resolve to bundled assets', () {
      for (final story in buildDemoStories()) {
        expect(story.imageUrl, startsWith('asset://'), reason: story.id);
        final path = story.imageUrl!.substring('asset://'.length);
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });
  });

  group('demo reviews catalog', () {
    test('has six reviews with a spread of ratings', () {
      final reviews = buildDemoReviews();
      expect(reviews, hasLength(6));
      expect(reviews.map((r) => r.rating).toSet().length, greaterThan(2));
      expect(reviews.every((r) => r.venueId == DemoMode.venueId), isTrue);
      expect(reviews.every((r) => r.text.trim().isNotEmpty), isTrue);
    });

    test('exactly two carry a merchant reply, two carry an avatar', () {
      final reviews = buildDemoReviews();
      expect(reviews.where((r) => r.hasReply), hasLength(2));
      expect(reviews.where((r) => r.userPhotoUrl != null), hasLength(2));
    });

    test('summary and distribution agree with the reviews', () {
      final reviews = buildDemoReviews();
      final distribution = demoReviewsDistribution();
      expect(distribution.keys.toSet(), <int>{1, 2, 3, 4, 5});
      expect(
        distribution.values.fold<int>(0, (a, b) => a + b),
        reviews.length,
      );
      final expectedAverage =
          reviews.fold<double>(0, (sum, r) => sum + r.rating) / reviews.length;
      expect(demoReviewsAverage(), closeTo(expectedAverage, 0.001));
    });
  });

  group('review submission never reaches the repository', () {
    setUp(clearDemoSubmittedReview);
    tearDown(clearDemoSubmittedReview);

    test('submitting a demo review stays in memory', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(demoSubmittedReview, isNull);

      await container.read(
        submitReviewProvider((
          venueId: DemoMode.venueId,
          userId: 'demo_local_user',
          userName: 'مقدّم العرض',
          userPhotoUrl: null,
          rating: 5.0,
          text: 'مراجعة مكتوبة أثناء العرض',
        )).future,
      );

      expect(demoSubmittedReview, isNotNull);
      expect(demoSubmittedReview!.venueId, DemoMode.venueId);
      expect(demoSubmittedReview!.rating, 5.0);
      // reviewsRepositoryProvider was never read: constructing
      // ReviewsRepositoryImpl needs Firebase, which is absent here, so any
      // attempt to reach it would have thrown before this line.
    });

    test('the demo reset clears the submitted review', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      recordDemoSubmittedReview(
        rating: 4,
        text: 'مؤقتة',
        userName: 'مقدّم العرض',
      );
      expect(demoSubmittedReview, isNotNull);

      container.read(demoSessionStoreProvider.notifier).reset();
      expect(demoSubmittedReview, isNull);
    });

    test('userReviewProvider serves the in-memory review', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      recordDemoSubmittedReview(
        rating: 3,
        text: 'مراجعة محلية',
        userName: 'مقدّم العرض',
      );
      final review = await container.read(
        userReviewProvider((
          venueId: DemoMode.venueId,
          userId: 'demo_local_user',
        )).future,
      );
      expect(review, isNotNull);
      expect(review!.text, 'مراجعة محلية');
    });
  });

  group('M2 provider isolation — behavioural', () {
    test('offers resolve without touching the offers repository', () async {
      final repository = _FailOnCallOffersRepository();
      final container = ProviderContainer(
        overrides: [offersRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final offers = await container.read(
        offersByVenueProvider(venueId: DemoMode.venueId).future,
      );
      expect(offers, hasLength(4));
      expect(repository.calls, isEmpty);
    });

    test('control — a real venue does reach the offers repository', () async {
      final repository = _FailOnCallOffersRepository();
      final container = ProviderContainer(
        overrides: [offersRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      // The real path fails here because the offline wrapper's dependencies are
      // unavailable in a bare container — but that failure is itself the proof
      // that the demo branch was not taken and real offers were never returned.
      await expectLater(
        container.read(offersByVenueProvider(venueId: 'real-venue').future),
        throwsA(isA<Object>()),
      );
    });

    // This one leaked past the fakes: VenueOffersSection watches
    // offerRedeemedStatusProvider once per card, and that provider reaches
    // FirebaseFirestore.instance directly rather than through an injected
    // repository, so no fail-on-call fake could see it.
    //
    // The assertion works because FirebaseFirestore.instance throws without an
    // initialised Firebase app: resolving cleanly is itself proof that no
    // Firestore call was made, and the control below shows the failure is real.
    test('redemption status resolves for every demo offer, no Firestore',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      for (final offer in buildDemoOffers()) {
        container.listen(
          offerRedeemedStatusProvider(offer.id),
          (_, _) {},
          fireImmediately: true,
        );
        final redeemed = await container
            .read(offerRedeemedStatusProvider(offer.id).future)
            .timeout(const Duration(seconds: 5));
        expect(
          redeemed,
          demoUsedOfferIds.contains(offer.id),
          reason: offer.id,
        );
      }
    });

    test('control — a non-demo offer id still goes to Firestore', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(
        offerRedeemedStatusProvider('real-offer-id'),
        (_, _) {},
        fireImmediately: true,
      );
      await expectLater(
        container
            .read(offerRedeemedStatusProvider('real-offer-id').future)
            .timeout(const Duration(seconds: 5)),
        throwsA(isA<Object>()),
        reason: 'without this the test above would pass even if the guard '
            'swallowed every offer id',
      );
    });

    // `venueStoriesProvider` used to name two different providers — a
    // List<Story> one here and a raw-map one on the venue side, which was the
    // one VenueStoriesSection actually watched. Asserting only the first left
    // the second reaching Firestore for the demo venue while the suite stayed
    // green. There is now one provider, and this is it.
    test('stories resolve from the local catalog', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // A StreamProvider only starts once something is listening.
      container.listen(
        stories_provider.venueStoriesProvider(DemoMode.venueId),
        (_, _) {},
        fireImmediately: true,
      );
      final stories = await container
          .read(stories_provider.venueStoriesProvider(DemoMode.venueId).future)
          .timeout(const Duration(seconds: 5));

      expect(stories, hasLength(3));
      expect(stories.first.text, buildDemoStories().first.text);
      expect(stories.map((s) => s.venueId), everyElement(DemoMode.venueId));
      expect(
        stories.map((s) => s.id).toList(),
        buildDemoStories().map((s) => s.id).toList(),
      );
    });

    test('reviews and the rating summary resolve from the local catalog', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(
        venueReviewsProvider(DemoMode.venueId),
        (_, _) {},
        fireImmediately: true,
      );

      final reviews = await container
          .read(venueReviewsProvider(DemoMode.venueId).future)
          .timeout(const Duration(seconds: 5));
      expect(reviews, hasLength(6));

      final summary = await container
          .read(venueRatingSummaryProvider(DemoMode.venueId).future)
          .timeout(const Duration(seconds: 5));
      expect(summary.reviewCount, 6);
      expect(summary.avgRating, closeTo(demoReviewsAverage(), 0.001));
    });
  });
}
