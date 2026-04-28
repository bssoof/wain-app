import 'package:cloud_firestore/cloud_firestore.dart';

class MerchantWalletReport {
  final String venueId;
  final String currency;
  final double totalCredited;
  final double topupTotalCredited;
  final double totalDebited;
  final double last30dDebited;
  final Map<String, double> debitByFeature;
  final String? mostUsedDebitFeature;
  final double? lastTopUpAmount;
  final DateTime? lastEntryAt;
  final DateTime updatedAt;

  const MerchantWalletReport({
    required this.venueId,
    required this.currency,
    required this.totalCredited,
    required this.topupTotalCredited,
    required this.totalDebited,
    required this.last30dDebited,
    required this.debitByFeature,
    required this.mostUsedDebitFeature,
    required this.lastTopUpAmount,
    required this.lastEntryAt,
    required this.updatedAt,
  });

  factory MerchantWalletReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawDebitByFeature =
        (data['debit_by_feature'] as Map<String, dynamic>?) ?? const {};
    final debitByFeature = <String, double>{};
    for (final entry in rawDebitByFeature.entries) {
      final value = entry.value;
      if (value is num) {
        debitByFeature[entry.key] = value.toDouble();
      }
    }

    return MerchantWalletReport(
      venueId: data['venue_id'] as String? ?? doc.id,
      currency: data['currency'] as String? ?? 'ILS',
      totalCredited: (data['total_credited'] as num?)?.toDouble() ?? 0,
      topupTotalCredited:
          (data['topup_total_credited'] as num?)?.toDouble() ?? 0,
      totalDebited: (data['total_debited'] as num?)?.toDouble() ?? 0,
      last30dDebited: (data['last_30d_debited'] as num?)?.toDouble() ?? 0,
      debitByFeature: debitByFeature,
      mostUsedDebitFeature: data['most_used_debit_feature'] as String?,
      lastTopUpAmount: (data['last_top_up_amount'] as num?)?.toDouble(),
      lastEntryAt: (data['last_entry_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
