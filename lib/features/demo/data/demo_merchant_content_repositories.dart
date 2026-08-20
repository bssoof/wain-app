import 'package:image_picker/image_picker.dart';
import 'package:wain_app/features/demo/application/demo_merchant_store.dart';
import 'package:wain_app/features/demo/data/demo_merchant_catalog.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_hours_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_photos_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_stories_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_venue_profile_repository.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_story.dart';

class DemoMerchantStoriesRepository implements MerchantStoriesRepository {
  DemoMerchantStoriesRepository(this._store);

  final DemoMerchantStore _store;

  @override
  Stream<List<MerchantStory>> watchStories({
    required String venueId,
    int limit = 20,
  }) => _store.watchStories().map((stories) => stories.take(limit).toList());

  @override
  Future<StoryPromotionPricing> getStoryPromotionPricing() async =>
      demoMerchantStoryPromotionPricing;

  @override
  Future<void> promoteStory({
    required String storyId,
    required int durationDays,
    required String requestId,
  }) async => _store.promoteStory(storyId, durationDays);

  @override
  Future<void> deleteStory({
    required String storyId,
    String? imageUrl,
    String? videoUrl,
  }) async => _store.deleteStory(storyId);

  @override
  Future<void> createStory({
    required String venueId,
    required String text,
    required int expiryHours,
    required String? createdBy,
    XFile? image,
    XFile? video,
  }) async => _store.createStory(
    text: text,
    expiryHours: expiryHours,
    image: image,
    video: video,
  );

  @override
  Future<bool> hasActiveStory({required String venueId, DateTime? now}) async =>
      true;
}

class DemoMerchantPhotosRepository implements MerchantPhotosRepository {
  DemoMerchantPhotosRepository(this._store);

  final DemoMerchantStore _store;

  @override
  Future<List<String>> uploadPhotos({
    required String venueId,
    required List<XFile> files,
  }) async => _store.uploadPhotos(files);

  @override
  Future<void> deletePhoto({
    required String venueId,
    required String photoUrl,
  }) async => _store.deletePhoto(photoUrl);

  @override
  Future<void> setPrimaryPhoto({
    required String venueId,
    required List<String> currentPhotos,
    required String targetUrl,
  }) async => _store.setPrimaryPhoto(targetUrl);
}

class DemoMerchantHoursRepository implements MerchantHoursRepository {
  DemoMerchantHoursRepository(this._store);

  final DemoMerchantStore _store;

  @override
  Future<void> saveHours({
    required String venueId,
    required bool is24Hours,
    required Map<String, List<Map<String, String>>> hours,
  }) async => _store.saveHours(is24Hours, hours);
}

class DemoMerchantVenueProfileRepository
    implements MerchantVenueProfileRepository {
  DemoMerchantVenueProfileRepository(this._store);

  final DemoMerchantStore _store;

  @override
  Future<void> updateVenueProfile({
    required String venueId,
    required String nameAr,
    required String nameEn,
    required String phone,
    required String city,
  }) async => _store.updateVenueProfile(
    nameAr: nameAr,
    nameEn: nameEn,
    phone: phone,
    city: city,
  );
}
