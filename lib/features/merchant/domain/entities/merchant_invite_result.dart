enum MerchantInviteResultType {
  success,
  invalidCode,
  appCheckFailed,
  codeExpired,
  codeUsed,
  codeUnavailable,
  rateLimited,
  aborted,
  unauthenticated,
  activationFailed,
  connectionError,
  retryError,
}

class MerchantInviteResult {
  final MerchantInviteResultType type;
  final String? venueId;

  const MerchantInviteResult({required this.type, this.venueId});

  bool get isSuccess => type == MerchantInviteResultType.success;
}

MerchantInviteResultType classifyMerchantInviteFailure({
  required String code,
  String? message,
}) {
  final normalizedMessage = message?.toLowerCase() ?? '';
  switch (code) {
    case 'not-found':
      return MerchantInviteResultType.invalidCode;
    case 'failed-precondition':
      if (normalizedMessage.contains('app check')) {
        return MerchantInviteResultType.appCheckFailed;
      }
      if (normalizedMessage.contains('expired')) {
        return MerchantInviteResultType.codeExpired;
      }
      if (normalizedMessage.contains('used')) {
        return MerchantInviteResultType.codeUsed;
      }
      return MerchantInviteResultType.codeUnavailable;
    case 'resource-exhausted':
      return MerchantInviteResultType.rateLimited;
    case 'aborted':
      return MerchantInviteResultType.aborted;
    case 'unauthenticated':
      return MerchantInviteResultType.unauthenticated;
    default:
      return MerchantInviteResultType.connectionError;
  }
}
