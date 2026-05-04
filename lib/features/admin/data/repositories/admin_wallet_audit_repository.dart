import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/features/admin/domain/entities/wallet_audit_event.dart';

final adminWalletAuditRepositoryProvider = Provider<AdminWalletAuditRepository>(
  (ref) {
    return FirebaseAdminWalletAuditRepository(
      firestore: FirebaseFirestore.instance,
      functions: FirebaseFunctions.instance,
    );
  },
);

abstract class AdminWalletAuditRepository {
  Stream<List<WalletAuditEvent>> streamAuditEvents({
    String? venueId,
    String? eventType,
  });

  Future<void> reverseWalletEntry({
    required String entryId,
    required String venueId,
    required String reason,
    String? adminNote,
  });
}

class FirebaseAdminWalletAuditRepository implements AdminWalletAuditRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FirebaseAdminWalletAuditRepository({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  }) : _firestore = firestore,
       _functions = functions;

  @override
  Stream<List<WalletAuditEvent>> streamAuditEvents({
    String? venueId,
    String? eventType,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('wallet_audit_events')
        .orderBy('created_at', descending: true)
        .limit(120);
    if (venueId != null && venueId.trim().isNotEmpty) {
      query = query.where('venue_id', isEqualTo: venueId.trim());
    }
    if (eventType != null && eventType.trim().isNotEmpty) {
      query = query.where('event_type', isEqualTo: eventType.trim());
    }
    return query.snapshots().map(
      (snap) => snap.docs.map(WalletAuditEvent.fromFirestore).toList(),
    );
  }

  @override
  Future<void> reverseWalletEntry({
    required String entryId,
    required String venueId,
    required String reason,
    String? adminNote,
  }) async {
    final callable = _functions.httpsCallable('reverseWalletEntry');
    await callable.call({
      'entryId': entryId,
      'venueId': venueId,
      'reason': reason,
      if (adminNote != null && adminNote.trim().isNotEmpty)
        'adminNote': adminNote.trim(),
    });
  }
}
