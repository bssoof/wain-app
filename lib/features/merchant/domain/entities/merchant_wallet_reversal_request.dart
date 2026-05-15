import 'package:cloud_firestore/cloud_firestore.dart';

enum ReversalRequestStatus {
  pendingReview,
  pendingSecondApproval,
  approvedAndExecuted,
  rejected,
  expired,
  unknown,
}

enum ReversalRequestSource { merchant, admin, unknown }

class MerchantWalletReversalRequest {
  final String requestId;
  final ReversalRequestSource source;
  final ReversalRequestStatus status;
  final String venueId;
  final String entryId;
  final double originalAmount;
  final String currency;
  final String originalFeatureKey;
  final String requestedByUid;
  final String reason;
  final String? merchantNote;
  final String? adminNote;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MerchantWalletReversalRequest({
    required this.requestId,
    required this.source,
    required this.status,
    required this.venueId,
    required this.entryId,
    required this.originalAmount,
    required this.currency,
    required this.originalFeatureKey,
    required this.requestedByUid,
    required this.reason,
    this.merchantNote,
    this.adminNote,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MerchantWalletReversalRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? const {};
    return MerchantWalletReversalRequest(
      requestId: _string(data['request_id']) ?? doc.id,
      source: reversalRequestSourceFromWire(_string(data['source'])),
      status: reversalRequestStatusFromWire(_string(data['status'])),
      venueId: _string(data['venue_id']) ?? '',
      entryId: _string(data['entry_id']) ?? '',
      originalAmount: (data['original_amount'] as num?)?.toDouble() ?? 0,
      currency: _string(data['currency']) ?? 'ILS',
      originalFeatureKey: _string(data['original_feature_key']) ?? '',
      requestedByUid: _string(data['requested_by_uid']) ?? '',
      reason: _string(data['reason']) ?? '',
      merchantNote: _string(data['merchant_note']),
      adminNote: _string(data['admin_note']),
      rejectionReason: _string(data['rejection_reason']),
      createdAt: _timestampToDate(data['created_at']),
      updatedAt: _timestampToDate(data['updated_at']),
    );
  }
}

ReversalRequestStatus reversalRequestStatusFromWire(String? value) {
  switch (value) {
    case 'pending_review':
      return ReversalRequestStatus.pendingReview;
    case 'pending_second_approval':
      return ReversalRequestStatus.pendingSecondApproval;
    case 'approved_and_executed':
      return ReversalRequestStatus.approvedAndExecuted;
    case 'rejected':
      return ReversalRequestStatus.rejected;
    case 'expired':
      return ReversalRequestStatus.expired;
    default:
      return ReversalRequestStatus.unknown;
  }
}

ReversalRequestSource reversalRequestSourceFromWire(String? value) {
  switch (value) {
    case 'merchant':
      return ReversalRequestSource.merchant;
    case 'admin':
      return ReversalRequestSource.admin;
    default:
      return ReversalRequestSource.unknown;
  }
}

String? _string(Object? value) {
  if (value is! String) return null;
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

DateTime _timestampToDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  return DateTime.fromMillisecondsSinceEpoch(0);
}
