import 'package:wain_app/core/utils/hours_calculator.dart';

class MerchantVenueHoursSlot {
  final String open;
  final String close;
  final bool spansMidnight;

  const MerchantVenueHoursSlot({
    required this.open,
    required this.close,
    required this.spansMidnight,
  });
}

class MerchantVenue {
  final String id;
  final String nameAr;
  final String nameEn;
  final String city;
  final String phone;
  final List<String> photos;
  final List<String> categories;
  final List<String> moodLabels;
  final Map<String, List<MerchantVenueHoursSlot>> hours;
  final bool is24Hours;
  final String? activeMenuVersionId;
  final DateTime? lastStoryAt;
  final double rating;
  final int minPrice;
  final int maxPrice;
  final double lat;
  final double lng;

  const MerchantVenue({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.city,
    required this.phone,
    required this.photos,
    required this.categories,
    required this.moodLabels,
    required this.hours,
    required this.is24Hours,
    required this.activeMenuVersionId,
    required this.lastStoryAt,
    required this.rating,
    required this.minPrice,
    required this.maxPrice,
    required this.lat,
    required this.lng,
  });

  String get displayName {
    final primary = nameAr.trim();
    if (primary.isNotEmpty) {
      return primary;
    }
    final fallback = nameEn.trim();
    if (fallback.isNotEmpty) {
      return fallback;
    }
    return '';
  }

  String? get primaryPhoto => photos.isEmpty ? null : photos.first;

  bool? isOpenNow({DateTime? now}) {
    return isOpenNowFromSlots<MerchantVenueHoursSlot>(
      hours: hours,
      is24Hours: is24Hours,
      now: now,
      openOf: (slot) => slot.open,
      closeOf: (slot) => slot.close,
      spansMidnightOf: (slot) => slot.spansMidnight,
    );
  }
}

class MerchantActiveMenuSummary {
  final bool hasActiveMenu;
  final DateTime? publishedAt;

  const MerchantActiveMenuSummary({
    required this.hasActiveMenu,
    required this.publishedAt,
  });
}
