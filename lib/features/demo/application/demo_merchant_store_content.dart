part of 'demo_merchant_store.dart';

extension DemoMerchantContentMutations on DemoMerchantStore {
  void promoteStory(String storyId, int durationDays) {
    final index = _stories.indexWhere((story) => story.id == storyId);
    if (index < 0) throw StateError('story_not_found');
    final price = switch (durationDays) {
      1 => 8.0,
      3 => 20.0,
      7 => 40.0,
      _ => 0.0,
    };
    _debit(price, featureKey: 'story_promotion', referenceId: storyId);
    _stories[index] = _copyStory(
      _stories[index],
      promotedUntil: demoMerchantNow().add(Duration(days: durationDays)),
      isPromotedFlag: true,
    );
    _notify();
  }

  void deleteStory(String storyId) {
    _stories.removeWhere((story) => story.id == storyId);
    _notify();
  }

  void createStory({
    required String text,
    required int expiryHours,
    XFile? image,
    XFile? video,
  }) {
    _localStorySerial += 1;
    final now = demoMerchantNow();
    _stories.insert(
      0,
      MerchantStory(
        id: 'demo_story_local_$_localStorySerial',
        type: video != null
            ? 'video'
            : image != null
            ? 'image'
            : 'text',
        text: text,
        imageUrl: image == null ? null : Uri.file(image.path).toString(),
        videoUrl: video == null ? null : Uri.file(video.path).toString(),
        createdAt: now,
        expiresAt: now.add(Duration(hours: expiryHours)),
        promotedUntil: null,
        isPromotedFlag: false,
      ),
    );
    _notify();
  }

  List<String> uploadPhotos(List<XFile> files) {
    final added = files.map((file) => Uri.file(file.path).toString()).toList();
    _venue = _copyVenue(_venue, photos: <String>[..._venue.photos, ...added]);
    _notify();
    return added;
  }

  void deletePhoto(String photoUrl) {
    _venue = _copyVenue(
      _venue,
      photos: _venue.photos.where((url) => url != photoUrl).toList(),
    );
    _notify();
  }

  void setPrimaryPhoto(String targetUrl) {
    if (!_venue.photos.contains(targetUrl)) throw StateError('photo_not_found');
    _venue = _copyVenue(
      _venue,
      photos: <String>[
        targetUrl,
        ..._venue.photos.where((url) => url != targetUrl),
      ],
    );
    _notify();
  }

  void saveHours(bool is24Hours, Map<String, List<Map<String, String>>> hours) {
    _venue = _copyVenue(
      _venue,
      is24Hours: is24Hours,
      hours: <String, List<MerchantVenueHoursSlot>>{
        for (final entry in hours.entries)
          entry.key: <MerchantVenueHoursSlot>[
            for (final slot in entry.value)
              MerchantVenueHoursSlot(
                open: slot['open'] ?? '',
                close: slot['close'] ?? '',
                spansMidnight:
                    (slot['close'] ?? '').compareTo(slot['open'] ?? '') < 0,
              ),
          ],
      },
    );
    _notify();
  }

  void updateVenueProfile({
    required String nameAr,
    required String nameEn,
    required String phone,
    required String city,
  }) {
    _venue = _copyVenue(
      _venue,
      nameAr: nameAr,
      nameEn: nameEn,
      phone: phone,
      city: city,
    );
    _notify();
  }
}
