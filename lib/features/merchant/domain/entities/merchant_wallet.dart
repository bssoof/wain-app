import 'package:cloud_firestore/cloud_firestore.dart';

enum MerchantWalletStatus {
  active,
  suspended,
  closed;

  static MerchantWalletStatus fromString(String value) {
    switch (value) {
      case 'active':
        return MerchantWalletStatus.active;
      case 'suspended':
        return MerchantWalletStatus.suspended;
      case 'closed':
        return MerchantWalletStatus.closed;
      default:
        return MerchantWalletStatus.active;
    }
  }
}

class MerchantWallet {
  final String venueId;
  final String currency;
  final MerchantWalletStatus status;
  final double availableBalance;
  final double lowBalanceThreshold;
  final DateTime? lastEntryAt;
  final DateTime? lastTopUpAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MerchantWallet({
    required this.venueId,
    required this.currency,
    required this.status,
    required this.availableBalance,
    required this.lowBalanceThreshold,
    this.lastEntryAt,
    this.lastTopUpAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowBalance => availableBalance <= lowBalanceThreshold;

  factory MerchantWallet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MerchantWallet(
      venueId: data['venue_id'] as String,
      currency: data['currency'] as String? ?? 'ILS',
      status: MerchantWalletStatus.fromString(
        data['status'] as String? ?? 'active',
      ),
      availableBalance: (data['available_balance'] as num?)?.toDouble() ?? 0.0,
      lowBalanceThreshold:
          (data['low_balance_threshold'] as num?)?.toDouble() ?? 10.0,
      lastEntryAt: (data['last_entry_at'] as Timestamp?)?.toDate(),
      lastTopUpAt: (data['last_top_up_at'] as Timestamp?)?.toDate(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
