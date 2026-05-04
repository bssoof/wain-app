enum MerchantOfferStatus {
  active,
  paused,
  expired;

  static MerchantOfferStatus? tryParse(String? raw) {
    final value = raw?.trim().toLowerCase();
    switch (value) {
      case 'active':
        return MerchantOfferStatus.active;
      case 'paused':
        return MerchantOfferStatus.paused;
      default:
        return null;
    }
  }

  String get storageValue {
    return switch (this) {
      MerchantOfferStatus.active => 'active',
      MerchantOfferStatus.paused => 'paused',
      MerchantOfferStatus.expired => 'expired',
    };
  }
}

class MerchantOffer {
  final String id;
  final String venueId;
  final String titleAr;
  final String title;
  final String descriptionAr;
  final String description;
  final String termsAr;
  final String discountType;
  final double discountValue;
  final bool singleUsePerCustomer;
  final bool isActive;
  final DateTime? startAt;
  final DateTime? endAt;
  final MerchantOfferStatus? status;
  final int claimsCount;
  final int redeemedCount;
  final double? conversionRate;
  final bool isFeatured;
  final DateTime? featuredUntil;

  const MerchantOffer({
    required this.id,
    required this.venueId,
    required this.titleAr,
    required this.title,
    required this.descriptionAr,
    required this.description,
    required this.termsAr,
    required this.discountType,
    required this.discountValue,
    required this.singleUsePerCustomer,
    required this.isActive,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.claimsCount,
    required this.redeemedCount,
    required this.conversionRate,
    required this.isFeatured,
    required this.featuredUntil,
  });

  String get primaryTitle {
    final arabic = titleAr.trim();
    if (arabic.isNotEmpty) {
      return arabic;
    }
    return title.trim();
  }

  String get primaryDescription {
    final arabic = descriptionAr.trim();
    if (arabic.isNotEmpty) {
      return arabic;
    }
    return description.trim();
  }

  bool get hasDescription => primaryDescription.isNotEmpty;

  double get conversionPercent {
    final fromDb = conversionRate;
    if (fromDb != null) {
      return fromDb * 100;
    }
    if (claimsCount <= 0) {
      return 0;
    }
    return (redeemedCount / claimsCount) * 100;
  }

  bool isExpiredAt(DateTime now) {
    final deadline = endAt;
    return deadline != null && deadline.isBefore(now);
  }

  MerchantOfferStatus effectiveStatusAt(DateTime now) {
    if (isExpiredAt(now)) {
      return MerchantOfferStatus.expired;
    }

    final persistedStatus = status;
    if (persistedStatus != null &&
        persistedStatus != MerchantOfferStatus.expired) {
      return persistedStatus;
    }

    return isActive ? MerchantOfferStatus.active : MerchantOfferStatus.paused;
  }

  bool isEndingSoonAt(
    DateTime now, {
    Duration within = const Duration(hours: 48),
  }) {
    final deadline = endAt;
    if (deadline == null || deadline.isBefore(now)) {
      return false;
    }
    return deadline.isBefore(now.add(within));
  }

  bool isCurrentlyActiveAt(DateTime now) {
    return effectiveStatusAt(now) == MerchantOfferStatus.active;
  }

  bool isFeaturedAt(DateTime now) {
    final until = featuredUntil;
    if (!isFeatured || until == null) return false;
    return until.isAfter(now);
  }
}
