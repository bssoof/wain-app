import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';

class MerchantOfferPerformanceSummary {
  final int totalClaims;
  final int totalRedeemed;
  final double overallConversionPercent;
  final MerchantOffer? topPerformer;

  const MerchantOfferPerformanceSummary({
    required this.totalClaims,
    required this.totalRedeemed,
    required this.overallConversionPercent,
    required this.topPerformer,
  });

  bool get hasAnyActivity => topPerformer != null;
}

MerchantOfferPerformanceSummary buildOfferPerformanceSummary(
  List<MerchantOffer> offers,
  DateTime now,
) {
  var totalClaims = 0;
  var totalRedeemed = 0;
  final rankedOffers = <MerchantOffer>[];

  for (final offer in offers) {
    totalClaims += offer.claimsCount;
    totalRedeemed += offer.redeemedCount;
    if (offer.claimsCount > 0 || offer.redeemedCount > 0) {
      rankedOffers.add(offer);
    }
  }

  rankedOffers.sort((left, right) {
    final leftActive = left.effectiveStatusAt(now) == MerchantOfferStatus.active
        ? 0
        : 1;
    final rightActive =
        right.effectiveStatusAt(now) == MerchantOfferStatus.active ? 0 : 1;
    if (leftActive != rightActive) {
      return leftActive.compareTo(rightActive);
    }

    final redeemedOrder = right.redeemedCount.compareTo(left.redeemedCount);
    if (redeemedOrder != 0) {
      return redeemedOrder;
    }

    final conversionOrder = right.conversionPercent.compareTo(
      left.conversionPercent,
    );
    if (conversionOrder != 0) {
      return conversionOrder;
    }

    final claimsOrder = right.claimsCount.compareTo(left.claimsCount);
    if (claimsOrder != 0) {
      return claimsOrder;
    }

    return left.primaryTitle.compareTo(right.primaryTitle);
  });

  final overallConversionPercent = totalClaims <= 0
      ? 0.0
      : (totalRedeemed / totalClaims) * 100;

  return MerchantOfferPerformanceSummary(
    totalClaims: totalClaims,
    totalRedeemed: totalRedeemed,
    overallConversionPercent: overallConversionPercent,
    topPerformer: rankedOffers.isEmpty ? null : rankedOffers.first,
  );
}
