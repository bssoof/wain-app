import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wain_app/l10n/app_localizations.dart';

/// Helper to convert Timestamp to DateTime
DateTime? timestampToDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

enum DiscountType { percent, amount, freeItem }

/// Offer entity - aligned with Phase 2A Spec
class Offer {
  final String id;
  final String venueId;
  final String titleAr;
  final String? titleEn;
  final String descriptionAr;
  final String? descriptionEn;
  final DiscountType discountType;
  final double discountValue;
  final String? currency;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool isActive;
  final String? termsAr;
  final String? imageUrl;
  final bool isPartner;
  final int claimsCount;
  final int redeemedCount;
  final bool singleUsePerCustomer;

  const Offer({
    required this.id,
    required this.venueId,
    required this.titleAr,
    this.titleEn,
    required this.descriptionAr,
    this.descriptionEn,
    required this.discountType,
    required this.discountValue,
    this.currency,
    this.startAt,
    this.endAt,
    this.isActive = true,
    this.termsAr,
    this.imageUrl,
    this.isPartner = false,
    this.claimsCount = 0,
    this.redeemedCount = 0,
    this.singleUsePerCustomer = true,
  });

  /// Create from Firestore document
  factory Offer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse discount type
    DiscountType type = DiscountType.percent;
    final typeStr = data['discount_type'] as String?;
    if (typeStr == 'amount') type = DiscountType.amount;
    if (typeStr == 'free_item') type = DiscountType.freeItem;

    return Offer(
      id: doc.id,
      venueId: data['venue_id'] ?? '',
      titleAr: data['title_ar'] ?? '',
      titleEn: data['title_en'],
      descriptionAr: data['description_ar'] ?? '',
      descriptionEn: data['description_en'],
      discountType: type,
      discountValue: (data['discount_value'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'],
      startAt: timestampToDateTime(data['start_at']),
      endAt: timestampToDateTime(data['end_at']),
      isActive: data['is_active'] ?? true,
      termsAr: data['terms_ar'],
      imageUrl: data['image_url'],
      isPartner: data['partner_tier'] != null || (data['is_partner'] ?? false),
      claimsCount: (data['claims_count'] as num?)?.toInt() ?? 0,
      redeemedCount: (data['redeemed_count'] as num?)?.toInt() ?? 0,
      singleUsePerCustomer: data['single_use_per_customer'] as bool? ?? true,
    );
  }

  /// Get display title (Arabic primary)
  String get title => titleAr;

  /// Get display description
  String get description => descriptionAr;

  /// Get display text for discount
  String getDiscountText(AppLocalizations l10n) {
    switch (discountType) {
      case DiscountType.percent:
        return l10n.offerDiscountPercent(discountValue.toStringAsFixed(0));
      case DiscountType.amount:
        return l10n.offerDiscountCurrency(
          discountValue.toStringAsFixed(0),
          currency ?? "ILS",
        );
      case DiscountType.freeItem:
        return l10n.offerDiscountFree;
    }
  }

  /// Check if offer is currently valid
  bool get isValid {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startAt != null && now.isBefore(startAt!)) return false;
    if (endAt != null && now.isAfter(endAt!)) return false;
    return true;
  }

  bool get isExpired {
    if (endAt == null) return false;
    return DateTime.now().isAfter(endAt!);
  }

  bool get isUpcoming {
    if (startAt == null) return false;
    return DateTime.now().isBefore(startAt!);
  }

  /// Formatted validity period
  String getValidityText(AppLocalizations l10n) {
    if (endAt == null) return l10n.offerValidityAlways;
    final remaining = endAt!.difference(DateTime.now());
    if (remaining.isNegative) return l10n.offerValidityExpired;
    if (remaining.inDays > 0) return l10n.offerValidityDays(remaining.inDays);
    if (remaining.inHours > 0) {
      return l10n.offerValidityHours(remaining.inHours);
    }
    return l10n.offerValiditySoon;
  }
}

/// Offer Claim entity
class OfferClaim {
  final String? id;
  final String offerId;
  final String venueId;
  final String? userId; // Nullable for guest
  final String deviceId;
  final String status; // pending, cancelled, redeemed
  final DateTime? timestamp;
  final String source;
  final String city;
  final double? appliedSavings;
  final DiscountType? appliedDiscountType;
  final double? appliedDiscountValue;
  final String? appliedCurrency;
  final String? appliedOfferTitleAr;

  const OfferClaim({
    this.id,
    required this.offerId,
    required this.venueId,
    this.userId,
    required this.deviceId,
    this.status = 'pending',
    this.timestamp,
    required this.source,
    required this.city,
    this.appliedSavings,
    this.appliedDiscountType,
    this.appliedDiscountValue,
    this.appliedCurrency,
    this.appliedOfferTitleAr,
  });

  /// Convert to Firestore-ready map
  Map<String, dynamic> toFirestoreMap() {
    return {
      'offer_id': offerId,
      'venue_id': venueId,
      'user_id': userId,
      'device_id': deviceId,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
      'source': source,
      'city': city,
    };
  }

  /// Create from Firestore document
  factory OfferClaim.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OfferClaim(
      id: doc.id,
      offerId: data['offer_id'] ?? '',
      venueId: data['venue_id'] ?? '',
      userId: data['user_id'],
      deviceId: data['device_id'] ?? '',
      status: data['status'] ?? 'pending',
      timestamp:
          timestampToDateTime(data['redeemed_at']) ??
          timestampToDateTime(data['timestamp']) ??
          timestampToDateTime(data['created_at']),
      source: data['source'] ?? '',
      city: data['city'] ?? '',
      appliedSavings: (data['applied_savings'] as num?)?.toDouble(),
      appliedDiscountType: _discountTypeFromString(
        data['applied_discount_type'] as String?,
      ),
      appliedDiscountValue: (data['applied_discount_value'] as num?)
          ?.toDouble(),
      appliedCurrency: data['applied_currency'] as String?,
      appliedOfferTitleAr: data['applied_offer_title_ar'] as String?,
    );
  }
}

DiscountType? _discountTypeFromString(String? type) {
  switch (type) {
    case 'amount':
      return DiscountType.amount;
    case 'free_item':
      return DiscountType.freeItem;
    case 'percent':
      return DiscountType.percent;
    default:
      return null;
  }
}

/// Result of a successful claim creation (via Cloud Function)
class ClaimResult {
  final String claimId;
  final String token; // The raw one-time token (QR data)
  final DateTime expiresAt;

  const ClaimResult({
    required this.claimId,
    required this.token,
    required this.expiresAt,
  });
}
