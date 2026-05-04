import 'package:cloud_firestore/cloud_firestore.dart';

enum TopUpRequestStatus {
  pending,
  credited,
  rejected,
  cancelled;

  static TopUpRequestStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return TopUpRequestStatus.pending;
      case 'credited':
        return TopUpRequestStatus.credited;
      case 'rejected':
        return TopUpRequestStatus.rejected;
      case 'cancelled':
        return TopUpRequestStatus.cancelled;
      default:
        return TopUpRequestStatus.pending;
    }
  }
}

class MerchantTopUpRequest {
  final String id;
  final String venueId;
  final String requestedByUid;
  final double amount;
  final String currency;
  final String? proofImageUrl;
  final String? transferReference;
  final String? note;
  final TopUpRequestStatus status;
  final String? adminNote;
  final String? linkedEntryId;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MerchantTopUpRequest({
    required this.id,
    required this.venueId,
    required this.requestedByUid,
    required this.amount,
    required this.currency,
    this.proofImageUrl,
    this.transferReference,
    this.note,
    required this.status,
    this.adminNote,
    this.linkedEntryId,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MerchantTopUpRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MerchantTopUpRequest(
      id: doc.id,
      venueId: data['venue_id'] as String,
      requestedByUid: data['requested_by_uid'] as String,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'ILS',
      proofImageUrl: data['proof_image_url'] as String?,
      transferReference: data['transfer_reference'] as String?,
      note: data['note'] as String?,
      status: TopUpRequestStatus.fromString(
        data['status'] as String? ?? 'pending',
      ),
      adminNote: data['admin_note'] as String?,
      linkedEntryId: data['linked_entry_id'] as String?,
      reviewedAt: (data['reviewed_at'] as Timestamp?)?.toDate(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
