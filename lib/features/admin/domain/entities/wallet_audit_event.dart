import 'package:cloud_firestore/cloud_firestore.dart';

class WalletAuditEvent {
  final String id;
  final String eventType;
  final String? category;
  final String? venueId;
  final String? requestId;
  final String? linkedEntryId;
  final String? entryId;
  final String? type;
  final String? featureKey;
  final String? reviewedByUid;
  final String? decision;
  final String? reversalEntryId;
  final String? reversalOfEntryId;
  final String? reversalReason;
  final String? proofImageUrl;
  final DateTime? proofRetentionUntil;
  final DateTime? proofDeletedAt;
  final bool? proofStorageDeleted;
  final double? amount;
  final DateTime createdAt;

  const WalletAuditEvent({
    required this.id,
    required this.eventType,
    required this.createdAt,
    this.category,
    this.venueId,
    this.requestId,
    this.linkedEntryId,
    this.entryId,
    this.type,
    this.featureKey,
    this.reviewedByUid,
    this.decision,
    this.reversalEntryId,
    this.reversalOfEntryId,
    this.reversalReason,
    this.proofImageUrl,
    this.proofRetentionUntil,
    this.proofDeletedAt,
    this.proofStorageDeleted,
    this.amount,
  });

  factory WalletAuditEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletAuditEvent(
      id: doc.id,
      eventType: data['event_type'] as String? ?? 'unknown',
      category: data['category'] as String?,
      venueId: data['venue_id'] as String?,
      requestId: data['request_id'] as String?,
      linkedEntryId:
          data['linked_entry_id'] as String? ?? data['entry_id'] as String?,
      entryId: data['entry_id'] as String?,
      type: data['type'] as String?,
      featureKey: data['feature_key'] as String?,
      reviewedByUid: data['reviewed_by_uid'] as String?,
      decision: data['decision'] as String?,
      reversalEntryId: data['reversal_entry_id'] as String?,
      reversalOfEntryId: data['reversal_of_entry_id'] as String?,
      reversalReason: data['reversal_reason'] as String?,
      proofImageUrl: data['proof_image_url'] as String?,
      proofRetentionUntil: (data['proof_retention_until'] as Timestamp?)
          ?.toDate(),
      proofDeletedAt: (data['proof_deleted_at'] as Timestamp?)?.toDate(),
      proofStorageDeleted: data['proof_storage_deleted'] as bool?,
      amount: (data['amount'] as num?)?.toDouble(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
