import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Result of token validation
class ValidationResult {
  final bool valid;
  final String? reason;
  final String? claimId;
  final Map<String, dynamic>? offer;
  final Map<String, dynamic>? venue;
  final bool canRedeem;

  ValidationResult({
    required this.valid,
    this.reason,
    this.claimId,
    this.offer,
    this.venue,
    this.canRedeem = false,
  });

  factory ValidationResult.fromMap(Map<String, dynamic> map) {
    return ValidationResult(
      valid: map['valid'] as bool,
      reason: map['reason'] as String?,
      claimId: map['claimId'] as String?,
      offer: map['offer'] != null ? Map<String, dynamic>.from(map['offer']) : null,
      venue: map['venue'] != null ? Map<String, dynamic>.from(map['venue']) : null,
      canRedeem: map['canRedeem'] as bool? ?? false,
    );
  }
}

class MerchantRepository {
  final FirebaseFunctions _functions;

  MerchantRepository({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// Validate a token (scan preview)
  Future<ValidationResult> validateToken(String token) async {
    try {
      final callable = _functions.httpsCallable('validateToken');
      final result = await callable.call({'token': token});
      
      final data = result.data as Map<Object?, Object?>;
      return ValidationResult.fromMap(data.cast<String, dynamic>());
    } catch (e) {
      debugPrint('❌ Validation Error: $e');
      if (e is FirebaseFunctionsException) {
        return ValidationResult(valid: false, reason: e.message);
      }
      return ValidationResult(valid: false, reason: 'unknown_error');
    }
  }

  /// Redeem a token (finalize)
  Future<bool> redeemToken(String token) async {
    try {
      final callable = _functions.httpsCallable('redeemToken');
      await callable.call({'token': token});
      return true;
    } catch (e) {
      debugPrint('❌ Redemption Error: $e');
      return false;
    }
  }
}
