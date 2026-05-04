import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_topup_request.dart';

final adminTopUpReviewRepositoryProvider = Provider<AdminTopUpReviewRepository>(
  (ref) {
    return FirebaseAdminTopUpReviewRepository(
      firestore: FirebaseFirestore.instance,
      functions: FirebaseFunctions.instance,
    );
  },
);

abstract class AdminTopUpReviewRepository {
  Stream<List<MerchantTopUpRequest>> streamPendingRequests();
  Future<void> reviewRequest({
    required String requestId,
    required String decision,
    String? adminNote,
  });
  Future<bool> isCurrentUserAdmin();
}

class FirebaseAdminTopUpReviewRepository implements AdminTopUpReviewRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FirebaseAdminTopUpReviewRepository({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  }) : _firestore = firestore,
       _functions = functions;

  @override
  Stream<List<MerchantTopUpRequest>> streamPendingRequests() {
    return _firestore
        .collection('merchant_topup_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => MerchantTopUpRequest.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Future<void> reviewRequest({
    required String requestId,
    required String decision,
    String? adminNote,
  }) async {
    final callable = _functions.httpsCallable('reviewMerchantTopUpRequest');
    await callable.call({
      'requestId': requestId,
      'decision': decision,
      if (adminNote != null && adminNote.trim().isNotEmpty)
        'adminNote': adminNote.trim(),
    });
  }

  @override
  Future<bool> isCurrentUserAdmin() async {
    final callable = _functions.httpsCallable('isCurrentUserAdmin');
    final res = await callable.call();
    return res.data is Map && (res.data['isAdmin'] == true);
  }
}
