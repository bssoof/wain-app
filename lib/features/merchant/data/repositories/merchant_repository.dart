import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_validation_result.dart';

class MerchantRepository {
  MerchantRepository({FirebaseFunctions? functions})
    : _injectedFunctions = functions;

  final FirebaseFunctions? _injectedFunctions;

  // Lazy for the same reason as MerchantDashboardRepository: the demo adapter
  // subclasses this and overrides every call, so constructing it must not
  // reach FirebaseFunctions.
  late final FirebaseFunctions _functions =
      _injectedFunctions ?? FirebaseFunctions.instance;

  /// Validate a token (scan preview)
  Future<MerchantValidationResult> validateToken(String token) async {
    try {
      final callable = _functions.httpsCallable('validateToken');
      final result = await callable.call({'token': token});

      final data = result.data as Map<Object?, Object?>;
      return mapMerchantValidationResult(data.cast<String, dynamic>());
    } catch (e) {
      debugPrint('❌ Validation Error: $e');
      if (e is FirebaseFunctionsException) {
        return MerchantValidationResult(valid: false, reason: e.message);
      }
      return const MerchantValidationResult(
        valid: false,
        reason: 'unknown_error',
      );
    }
  }

  /// Redeem a token (finalize)
  Future<bool> redeemToken(String token, {double? billAmount}) async {
    try {
      final callable = _functions.httpsCallable('redeemToken');
      await callable.call({
        'token': token,
        ...?billAmount == null ? null : {'billAmount': billAmount},
      });
      return true;
    } catch (e) {
      debugPrint('❌ Redemption Error: $e');
      return false;
    }
  }
}

@visibleForTesting
MerchantValidationResult mapMerchantValidationResult(Map<String, dynamic> map) {
  final offerMap = _asStringMap(map['offer']);
  final venueMap = _asStringMap(map['venue']);
  return MerchantValidationResult(
    valid: map['valid'] == true,
    reason: map['reason'] as String?,
    claimId: map['claimId'] as String?,
    offer: offerMap == null
        ? null
        : mapMerchantValidationOfferPreview(offerMap),
    venue: venueMap == null
        ? null
        : mapMerchantValidationVenuePreview(venueMap),
    canRedeem: map['canRedeem'] as bool? ?? false,
  );
}

@visibleForTesting
MerchantValidationOfferPreview mapMerchantValidationOfferPreview(
  Map<String, dynamic> map,
) {
  final discountValue = map['discount_value'];
  return MerchantValidationOfferPreview(
    titleAr: (map['title_ar'] as String? ?? '').trim(),
    discountType: (map['discount_type'] as String? ?? 'percent').trim(),
    discountValue: discountValue is num
        ? discountValue.toDouble()
        : double.tryParse('$discountValue') ?? 0,
    currency: (map['currency'] as String? ?? 'ILS').trim().isEmpty
        ? 'ILS'
        : (map['currency'] as String).trim(),
  );
}

@visibleForTesting
MerchantValidationVenuePreview mapMerchantValidationVenuePreview(
  Map<String, dynamic> map,
) {
  return MerchantValidationVenuePreview(
    nameAr: (map['name_ar'] as String? ?? '').trim(),
  );
}

Map<String, dynamic>? _asStringMap(dynamic value) {
  if (value is! Map) {
    return null;
  }

  return value.map((key, entryValue) => MapEntry(key.toString(), entryValue));
}
