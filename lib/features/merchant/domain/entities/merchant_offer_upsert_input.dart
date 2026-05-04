class MerchantOfferUpsertInput {
  final String? offerId;
  final String venueId;
  final String titleAr;
  final String descriptionAr;
  final String discountType;
  final double discountValue;
  final bool singleUsePerCustomer;
  final String termsAr;
  final bool isActive;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool applyServerStartAtWhenMissing;
  final bool clearStartAt;
  final bool clearEndAt;

  const MerchantOfferUpsertInput({
    required this.offerId,
    required this.venueId,
    required this.titleAr,
    required this.descriptionAr,
    required this.discountType,
    required this.discountValue,
    required this.singleUsePerCustomer,
    required this.termsAr,
    required this.isActive,
    required this.startAt,
    required this.endAt,
    required this.applyServerStartAtWhenMissing,
    required this.clearStartAt,
    required this.clearEndAt,
  });

  bool get isEditing => offerId != null && offerId!.isNotEmpty;
}
