class MerchantValidationOfferPreview {
  final String titleAr;
  final String discountType;
  final double discountValue;
  final String currency;

  const MerchantValidationOfferPreview({
    required this.titleAr,
    required this.discountType,
    required this.discountValue,
    required this.currency,
  });
}

class MerchantValidationVenuePreview {
  final String nameAr;

  const MerchantValidationVenuePreview({required this.nameAr});
}

class MerchantValidationResult {
  final bool valid;
  final String? reason;
  final String? claimId;
  final MerchantValidationOfferPreview? offer;
  final MerchantValidationVenuePreview? venue;
  final bool canRedeem;

  const MerchantValidationResult({
    required this.valid,
    this.reason,
    this.claimId,
    this.offer,
    this.venue,
    this.canRedeem = false,
  });
}
