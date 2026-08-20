import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wain_app/features/auth/domain/entities/app_user.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/features/demo/application/demo_merchant_session.dart';
import 'package:wain_app/features/demo/application/demo_merchant_store.dart';
import 'package:wain_app/features/demo/application/demo_session_store.dart';
import 'package:wain_app/features/demo/data/demo_merchant_catalog.dart';
import 'package:wain_app/features/demo/data/demo_merchant_repositories.dart';
import 'package:wain_app/features/demo/data/demo_offers_catalog.dart';
import 'package:wain_app/features/demo/data/demo_reviews_catalog.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_dashboard_repository.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer_upsert_input.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_providers.dart';

class _LinkedDemoVenueRepository extends MerchantDashboardRepository {
  @override
  Future<String?> getLinkedVenueId(String userId, {Source? source}) async =>
      DemoMode.venueId;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    container.read(demoMerchantSessionProvider.notifier).enter();
    addTearDown(container.dispose);
  });

  test('rating is derived from the six reviews and stays consistent', () {
    final reviews = buildDemoReviews();
    final derived =
        reviews.fold<double>(0, (total, item) => total + item.rating) /
        reviews.length;

    expect(derived, 4.5);
    expect(demoReviewsAverage(), derived);
    expect(buildDemoMerchantVenue().rating, derived);
    expect(buildDemoMerchantReviews(), hasLength(reviews.length));
  });

  test(
    'offer and review writes change only the local merchant store',
    () async {
      final store = container.read(demoMerchantStoreProvider);
      final offers = container.read(merchantOffersRepositoryProvider);
      final reviews = container.read(merchantReviewsRepositoryProvider);
      final initialBalance =
          (await store.watchWallet().first)!.availableBalance;

      await offers.saveOffer(
        MerchantOfferUpsertInput(
          offerId: null,
          venueId: DemoMode.venueId,
          titleAr: 'عرض جلسة الديمو',
          descriptionAr: 'وصف محلي',
          discountType: 'percent',
          discountValue: 15,
          singleUsePerCustomer: true,
          termsAr: 'للعرض فقط',
          isActive: true,
          startAt: null,
          endAt: null,
          applyServerStartAtWhenMissing: false,
          clearStartAt: false,
          clearEndAt: false,
        ),
      );
      final created = store.offers.first;
      expect(created.titleAr, 'عرض جلسة الديمو');

      await offers.setOfferStatus(
        offerId: created.id,
        status: MerchantOfferStatus.paused,
      );
      expect(store.offers.first.status, MerchantOfferStatus.paused);

      await offers.pinOffer(
        offerId: created.id,
        durationDays: 1,
        requestId: 'local-request',
      );
      expect(store.offers.first.isFeatured, isTrue);
      expect(
        (await store.watchWallet().first)!.availableBalance,
        initialBalance - demoMerchantOfferPinPricing[1]!,
      );

      final review = store.reviews.first;
      await reviews.submitReply(
        venueId: DemoMode.venueId,
        reviewId: review.id,
        replyText: 'رد محلي ظاهر',
        authorIdentifier: 'demo-owner',
      );
      expect(store.reviews.first.merchantReply, 'رد محلي ظاهر');
      await reviews.deleteReply(venueId: DemoMode.venueId, reviewId: review.id);
      expect(store.reviews.first.merchantReply, isNull);

      await offers.deleteOffer(created.id);
      expect(store.offers.any((offer) => offer.id == created.id), isFalse);
    },
  );

  test('content, wallet and QR writes persist for this walkthrough', () async {
    final store = container.read(demoMerchantStoreProvider);
    final stories = container.read(merchantStoriesRepositoryProvider);
    final photos = container.read(merchantPhotosRepositoryProvider);
    final hours = container.read(merchantHoursRepositoryProvider);
    final profile = container.read(merchantVenueProfileRepositoryProvider);
    final wallet = DemoMerchantWalletRepository(store);
    final claims = container.read(merchantRepositoryProvider);

    await stories.createStory(
      venueId: DemoMode.venueId,
      text: 'قصة أضيفت أثناء العرض',
      expiryHours: 24,
      createdBy: 'demo-owner',
    );
    final story =
        (await stories.watchStories(venueId: DemoMode.venueId).first).first;
    expect(story.text, 'قصة أضيفت أثناء العرض');
    await stories.promoteStory(
      storyId: story.id,
      durationDays: 1,
      requestId: 'local-story-request',
    );
    expect(
      (await stories.watchStories(venueId: DemoMode.venueId).first)
          .first
          .isPromotedFlag,
      isTrue,
    );

    final demoPhotoPath =
        '${Directory.systemTemp.path}${Platform.pathSeparator}new-photo.jpg';
    final uploaded = await photos.uploadPhotos(
      venueId: DemoMode.venueId,
      files: <XFile>[XFile(demoPhotoPath)],
    );
    expect(uploaded.single, startsWith('file:'));
    expect(store.venue.photos, contains(uploaded.single));
    await photos.setPrimaryPhoto(
      venueId: DemoMode.venueId,
      currentPhotos: store.venue.photos,
      targetUrl: uploaded.single,
    );
    expect(store.venue.photos.first, uploaded.single);

    await hours.saveHours(
      venueId: DemoMode.venueId,
      is24Hours: true,
      hours: const <String, List<Map<String, String>>>{},
    );
    await profile.updateVenueProfile(
      venueId: DemoMode.venueId,
      nameAr: 'وين كافيه — نسخة العرض',
      nameEn: 'WAIN Cafe Demo',
      phone: '0599000000',
      city: 'رام الله',
    );
    expect(store.venue.is24Hours, isTrue);
    expect(store.venue.nameAr, contains('نسخة العرض'));

    await wallet.createTopUpRequest(amount: 75, note: 'طلب محلي');
    expect(
      await wallet.streamTopUpRequests(DemoMode.venueId).first,
      isNotEmpty,
    );
    expect(
      await wallet.uploadTopUpProof(
        venueId: DemoMode.venueId,
        file: File('C:\\demo-assets\\proof.jpg'),
        fileName: 'proof.jpg',
      ),
      startsWith('file:'),
    );

    final offer = store.offers.firstWhere((candidate) => candidate.isActive);
    final token = demoQrPayload(offer.id);
    expect(await claims.redeemToken(token), isTrue);
    expect(await claims.redeemToken(token), isFalse);
    expect(
      store.offers
          .firstWhere((candidate) => candidate.id == offer.id)
          .redeemedCount,
      offer.redeemedCount + 1,
    );
  });

  test('Reset Demo discards every merchant mutation', () async {
    final subscription = container.listen(
      demoMerchantStoreProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    final originalName = buildDemoMerchantVenue().nameAr;
    container
        .read(demoMerchantStoreProvider)
        .updateVenueProfile(
          nameAr: 'اسم مؤقت',
          nameEn: 'Temporary',
          phone: '',
          city: 'رام الله',
        );

    container.read(demoSessionStoreProvider.notifier).reset();

    expect(
      container.read(demoMerchantStoreProvider).venue.nameAr,
      originalName,
    );
  });

  test(
    'the real account link activates local demo adapters automatically',
    () async {
      final signedIn = AppUser(
        uid: 'owner-uid',
        phoneNumber: '',
        createdAt: DateTime(2026),
      );
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      final linked = ProviderContainer(
        overrides: [
          authStateProvider.overrideWithValue(AsyncValue.data(signedIn)),
          sharedPreferencesProvider.overrideWithValue(preferences),
          merchantDashboardRepositoryProvider.overrideWithValue(
            _LinkedDemoVenueRepository(),
          ),
        ],
      );
      addTearDown(linked.dispose);

      expect(
        await linked
            .read(merchantVenueIdProvider.future)
            .timeout(const Duration(seconds: 5)),
        DemoMode.venueId,
      );
      await Future<void>.delayed(Duration.zero);

      expect(linked.read(demoMerchantActiveProvider), isTrue);
      expect(
        linked.read(merchantOffersRepositoryProvider),
        isA<DemoMerchantOffersRepository>(),
      );
    },
  );
}
