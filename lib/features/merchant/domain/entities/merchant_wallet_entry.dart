import 'package:cloud_firestore/cloud_firestore.dart';

class MerchantWalletEntry {
  final String id;
  final String type;
  final double amount;
  final String currency;
  final double balanceAfter;
  final String? featureKey;
  final String? referenceType;
  final String? referenceId;
  final String? reversalEntryId;
  final String? note;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const MerchantWalletEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.balanceAfter,
    this.featureKey,
    this.referenceType,
    this.referenceId,
    this.reversalEntryId,
    this.note,
    this.metadata = const {},
    required this.createdAt,
  });

  bool get isCredit => type == 'credit';

  factory MerchantWalletEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MerchantWalletEntry(
      id: doc.id,
      type: data['type'] as String? ?? 'debit',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'ILS',
      balanceAfter: (data['balance_after'] as num?)?.toDouble() ?? 0.0,
      featureKey: data['feature_key'] as String?,
      referenceType: data['reference_type'] as String?,
      referenceId: data['reference_id'] as String?,
      reversalEntryId: data['reversal_entry_id'] as String?,
      note: data['note'] as String?,
      metadata: (data['metadata'] as Map<String, dynamic>?) ?? const {},
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
