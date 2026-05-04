import 'package:cloud_functions/cloud_functions.dart';

import 'package:wain_app/features/merchant/domain/entities/merchant_invite_result.dart';

abstract class MerchantInviteRepository {
  Future<MerchantInviteResult> redeemInviteCode(String code);
}

class FirebaseMerchantInviteRepository implements MerchantInviteRepository {
  final FirebaseFunctions _functions;

  FirebaseMerchantInviteRepository({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  @override
  Future<MerchantInviteResult> redeemInviteCode(String code) async {
    try {
      final result = await _functions.httpsCallable('redeemInviteCode').call({
        'code': code.trim().toUpperCase(),
      });

      final data = _asStringMap(result.data);
      if (data?['success'] == true) {
        return MerchantInviteResult(
          type: MerchantInviteResultType.success,
          venueId: data?['venueId'] as String?,
        );
      }

      return const MerchantInviteResult(
        type: MerchantInviteResultType.activationFailed,
      );
    } on FirebaseFunctionsException catch (error) {
      return MerchantInviteResult(
        type: classifyMerchantInviteFailure(
          code: error.code,
          message: error.message,
        ),
      );
    } catch (_) {
      return const MerchantInviteResult(
        type: MerchantInviteResultType.retryError,
      );
    }
  }
}

Map<String, dynamic>? _asStringMap(dynamic value) {
  if (value is! Map) {
    return null;
  }

  return value.map((key, entryValue) => MapEntry(key.toString(), entryValue));
}
