import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/features/demo/application/demo_merchant_session.dart';
import 'package:wain_app/features/demo/data/demo_merchant_repositories.dart';

import '../../domain/entities/merchant_wallet.dart';
import '../../domain/entities/merchant_wallet_entry.dart';
import '../../domain/entities/merchant_wallet_report.dart';
import '../../domain/entities/merchant_topup_request.dart';

final merchantWalletRepositoryProvider = Provider<MerchantWalletRepository>((
  ref,
) {
  // The demo adapter is chosen before the Firebase handles are read, so the
  // walkthrough never constructs a Firestore, Functions or Storage client.
  if (isDemoMerchantSession(ref)) {
    return DemoMerchantWalletRepository();
  }

  return FirebaseMerchantWalletRepository(
    firestore: FirebaseFirestore.instance,
    functions: FirebaseFunctions.instance,
    storage: FirebaseStorage.instance,
  );
});

abstract class MerchantWalletRepository {
  Stream<MerchantWallet?> streamWallet(String venueId);
  Stream<List<MerchantTopUpRequest>> streamTopUpRequests(String venueId);
  Stream<List<MerchantWalletEntry>> streamWalletEntries(String venueId);
  Stream<MerchantWalletReport?> streamWalletReport(String venueId);
  Future<void> createTopUpRequest({
    required double amount,
    String? proofImageUrl,
    String? transferReference,
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
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  FirebaseMerchantWalletRepository({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _functions = functions,
       _storage = storage;

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
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MerchantWalletEntry.fromFirestore(doc))
              .toList();
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
    String? proofImageUrl,
    String? transferReference,
    String? note,
  }) async {
    final callable = _functions.httpsCallable('createMerchantTopUpRequest');
    final data = <String, dynamic>{'amount': amount};
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
