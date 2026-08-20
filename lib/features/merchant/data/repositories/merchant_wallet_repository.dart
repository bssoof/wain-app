import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/features/demo/application/demo_merchant_session.dart';
import 'package:wain_app/features/demo/data/demo_merchant_repositories.dart';

import '../../domain/entities/merchant_wallet.dart';
import '../../domain/entities/merchant_wallet_entry.dart';
import '../../domain/entities/merchant_wallet_report.dart';
import '../../domain/entities/merchant_topup_request.dart';
import '../../domain/entities/merchant_wallet_reversal_request.dart';

final merchantWalletRepositoryProvider = Provider<MerchantWalletRepository>((
  ref,
) {
  // The demo adapter is chosen before the Firebase handles are read, so the
  // walkthrough never constructs a Firestore, Functions or Storage client.
  if (isDemoMerchantSession(ref)) {
    return DemoMerchantWalletRepository(ref.watch(demoMerchantStoreProvider));
  }

  return FirebaseMerchantWalletRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    functions: FirebaseFunctions.instance,
    storage: FirebaseStorage.instance,
  );
});

class MerchantReversalException implements Exception {
  final String message;

  const MerchantReversalException(this.message);

  @override
  String toString() => message;
}

abstract class MerchantWalletRepository {
  Future<String?> getCurrentMerchantVenueId();
  Stream<MerchantWallet?> streamWallet(String venueId);
  Stream<List<MerchantTopUpRequest>> streamTopUpRequests(String venueId);
  Stream<List<MerchantWalletEntry>> streamWalletEntries(String venueId);
  Stream<MerchantWalletReport?> streamWalletReport(String venueId);
  Stream<List<MerchantWalletReversalRequest>> watchReversalRequestsForVenue(
    String venueId,
  );
  Future<void> createTopUpRequest({
    required double amount,
    String? requestId,
    String? proofImageUrl,
    String? transferReference,
    String? note,
  });
  Future<void> createReversalRequest({
    required String venueId,
    required String entryId,
    required String reason,
    String? note,
  });
  Future<String> uploadTopUpProof({
    required String venueId,
    required File file,
    required String fileName,
  });
}

class FirebaseMerchantWalletRepository implements MerchantWalletRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  FirebaseMerchantWalletRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required FirebaseFunctions functions,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _auth = auth,
       _functions = functions,
       _storage = storage;

  /// Authoritative merchant->venue link source.
  /// Functions also use merchants/{uid}.venue_id; do NOT use
  /// users/{uid}.merchant_venue_id here to avoid divergence on permission checks.
  @override
  Future<String?> getCurrentMerchantVenueId() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('merchants').doc(uid).get();
    if (!doc.exists) return null;
    final venueId = doc.data()?['venue_id'] as String?;
    final normalized = venueId?.trim();
    return normalized != null && normalized.isNotEmpty ? normalized : null;
  }

  String? get _currentUid => _auth.currentUser?.uid;

  @override
  Stream<MerchantWallet?> streamWallet(String venueId) {
    return _firestore
        .collection('merchant_wallets')
        .doc(venueId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) return null;
          return MerchantWallet.fromFirestore(snapshot);
        });
  }

  @override
  Stream<List<MerchantTopUpRequest>> streamTopUpRequests(String venueId) {
    return _firestore
        .collection('merchant_topup_requests')
        .where('venue_id', isEqualTo: venueId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MerchantTopUpRequest.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Stream<List<MerchantWalletEntry>> streamWalletEntries(String venueId) {
    return _firestore
        .collection('merchant_wallets')
        .doc(venueId)
        .collection('entries')
        .snapshots()
        .map((snapshot) {
          final entries = snapshot.docs
              .map((doc) => MerchantWalletEntry.fromFirestore(doc))
              .toList();
          entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return entries;
        });
  }

  @override
  Stream<List<MerchantWalletReversalRequest>> watchReversalRequestsForVenue(
    String venueId,
  ) {
    final uid = _currentUid;
    if (uid == null) return Stream.value(const []);

    return _firestore.collection('merchants').doc(uid).snapshots().asyncExpand((
      merchantDoc,
    ) {
      final merchantVenueId = (merchantDoc.data()?['venue_id'] as String?)
          ?.trim();
      if (!merchantDoc.exists ||
          merchantVenueId == null ||
          merchantVenueId.isEmpty ||
          merchantVenueId != venueId) {
        return Stream.value(const <MerchantWalletReversalRequest>[]);
      }

      return _firestore
          .collection('wallet_reversal_requests')
          .where('venue_id', isEqualTo: venueId)
          .where('requested_by_uid', isEqualTo: uid)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(MerchantWalletReversalRequest.fromFirestore)
                .toList(),
          );
    });
  }

  @override
  Stream<MerchantWalletReport?> streamWalletReport(String venueId) {
    return _firestore
        .collection('merchant_wallet_reports')
        .doc(venueId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) return null;
          return MerchantWalletReport.fromFirestore(snapshot);
        });
  }

  @override
  Future<void> createTopUpRequest({
    required double amount,
    String? requestId,
    String? proofImageUrl,
    String? transferReference,
    String? note,
  }) async {
    final callable = _functions.httpsCallable('createMerchantTopUpRequest');
    final data = <String, dynamic>{'amount': amount};
    final normalizedRequestId = requestId?.trim();
    if (normalizedRequestId != null && normalizedRequestId.isNotEmpty) {
      data['requestId'] = normalizedRequestId;
    }
    if (proofImageUrl != null) {
      data['proof_image_url'] = proofImageUrl;
    }
    if (transferReference != null) {
      data['transfer_reference'] = transferReference;
    }
    if (note != null) {
      data['note'] = note;
    }
    await callable.call(data);
  }

  @override
  Future<void> createReversalRequest({
    required String venueId,
    required String entryId,
    required String reason,
    String? note,
  }) async {
    final merchantVenueId = await getCurrentMerchantVenueId();
    if (merchantVenueId == null || merchantVenueId != venueId) {
      throw MerchantReversalException(
        mapMerchantReversalErrorCode('merchant_venue_mismatch'),
      );
    }

    try {
      final callable = _functions.httpsCallable(
        'createMerchantWalletReversalRequest',
      );
      final data = <String, dynamic>{
        'venueId': venueId,
        'entryId': entryId,
        'reason': reason,
      };
      final normalizedNote = note?.trim();
      if (normalizedNote != null && normalizedNote.isNotEmpty) {
        data['merchantNote'] = normalizedNote;
      }
      await callable.call(data);
    } on FirebaseFunctionsException catch (error) {
      throw MerchantReversalException(
        mapMerchantReversalErrorCode(error.message ?? error.code),
      );
    }
  }

  @override
  Future<String> uploadTopUpProof({
    required String venueId,
    required File file,
    required String fileName,
  }) async {
    final ref = _storage.ref().child('venues/$venueId/wallet_topups/$fileName');
    await ref.putFile(file);
    return ref.fullPath;
  }
}

String mapMerchantReversalErrorCode(String code) {
  switch (code) {
    case 'merchant_review_already_open':
      return 'يوجد طلب مراجعة مفتوح لهذه العملية';
    case 'entry_already_reversed':
      return 'تم تصحيح هذه العملية مسبقًا';
    case 'reversal_only_for_debit':
      return 'لا يمكن طلب مراجعة لعملية إضافة';
    case 'unsupported_reversal_feature':
      return 'هذه العملية غير مدعومة للمراجعة';
    case 'entry_not_found':
      return 'العملية غير موجودة';
    case 'merchant_venue_mismatch':
    case 'not_a_merchant':
    case 'merchant_venue_not_assigned':
      return 'ليس لديك صلاحية على هذه العملية';
    case 'invalid_merchant_review_arguments':
      return 'البيانات المرسلة غير مكتملة';
    default:
      return 'تعذّر إرسال الطلب. حاول لاحقًا';
  }
}
