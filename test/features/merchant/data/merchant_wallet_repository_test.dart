import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_wallet_repository.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet_reversal_request.dart';

class _FakeUser extends Fake implements User {
  @override
  final String uid;

  _FakeUser(this.uid);
}

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {
  @override
  final User? currentUser;

  _FakeFirebaseAuth(String? uid)
    : currentUser = uid == null ? null : _FakeUser(uid);
}

class _RecordingFirebaseFunctions extends Fake implements FirebaseFunctions {
  String? callableName;
  Object? parameters;
  FirebaseFunctionsException? exception;

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    callableName = name;
    return _RecordingHttpsCallable(this);
  }
}

class _RecordingHttpsCallable extends Fake implements HttpsCallable {
  final _RecordingFirebaseFunctions owner;

  _RecordingHttpsCallable(this.owner);

  @override
  Future<HttpsCallableResult<T>> call<T>([Object? parameters]) async {
    owner.parameters = parameters;
    final exception = owner.exception;
    if (exception != null) throw exception;
    return _FakeHttpsCallableResult<T>();
  }
}

class _FakeHttpsCallableResult<T> extends Fake
    implements HttpsCallableResult<T> {}

class _FakeFirebaseStorage extends Fake implements FirebaseStorage {}

void main() {
  group('FirebaseMerchantWalletRepository', () {
    test(
      'streams wallet entries sorted newest first without Firestore orderBy',
      () async {
        final firestore = FakeFirebaseFirestore();
        final repository = FirebaseMerchantWalletRepository(
          firestore: firestore,
          auth: _FakeFirebaseAuth('merchant-1'),
          functions: _RecordingFirebaseFunctions(),
          storage: _FakeFirebaseStorage(),
        );

        await firestore
            .collection('merchant_wallets')
            .doc('venue-1')
            .collection('entries')
            .doc('older')
            .set({
              'venue_id': 'venue-1',
              'type': 'credit',
              'amount': 10,
              'currency': 'ILS',
              'balance_after': 10,
              'reference_type': 'topup_request',
              'created_at': Timestamp.fromDate(DateTime(2026, 5, 10, 10)),
            });
        await firestore
            .collection('merchant_wallets')
            .doc('venue-1')
            .collection('entries')
            .doc('newer')
            .set({
              'venue_id': 'venue-1',
              'type': 'debit',
              'amount': 4,
              'currency': 'ILS',
              'balance_after': 6,
              'feature_key': 'story_promotion',
              'created_at': Timestamp.fromDate(DateTime(2026, 5, 12, 10)),
            });

        final entries = await repository.streamWalletEntries('venue-1').first;

        expect(entries.map((entry) => entry.id), ['newer', 'older']);
      },
    );

    test('maps wallet reversal request documents to entities', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = FirebaseMerchantWalletRepository(
        firestore: firestore,
        auth: _FakeFirebaseAuth('merchant-1'),
        functions: _RecordingFirebaseFunctions(),
        storage: _FakeFirebaseStorage(),
      );

      await firestore.collection('merchants').doc('merchant-1').set({
        'venue_id': 'venue-1',
      });
      await firestore
          .collection('wallet_reversal_requests')
          .doc('request-1')
          .set({
            'request_id': 'request-1',
            'source': 'merchant',
            'status': 'pending_review',
            'venue_id': 'venue-1',
            'entry_id': 'entry-1',
            'original_amount': 12,
            'currency': 'ILS',
            'original_feature_key': 'story_promotion',
            'requested_by_uid': 'merchant-1',
            'reason': 'duplicate debit',
            'created_at': Timestamp.fromDate(DateTime(2026, 5, 12, 10)),
            'updated_at': Timestamp.fromDate(DateTime(2026, 5, 12, 11)),
          });

      final requests = await repository
          .watchReversalRequestsForVenue('venue-1')
          .first;

      expect(requests, hasLength(1));
      expect(requests.single.requestId, 'request-1');
      expect(requests.single.status, ReversalRequestStatus.pendingReview);
      expect(requests.single.source, ReversalRequestSource.merchant);
      expect(requests.single.entryId, 'entry-1');
    });

    test(
      'createReversalRequest calls callable with expected parameters',
      () async {
        final firestore = FakeFirebaseFirestore();
        final functions = _RecordingFirebaseFunctions();
        final repository = FirebaseMerchantWalletRepository(
          firestore: firestore,
          auth: _FakeFirebaseAuth('merchant-1'),
          functions: functions,
          storage: _FakeFirebaseStorage(),
        );

        await firestore.collection('merchants').doc('merchant-1').set({
          'venue_id': 'venue-1',
        });

        await repository.createReversalRequest(
          venueId: 'venue-1',
          entryId: 'entry-1',
          reason: 'duplicate debit',
          note: 'please check',
        );

        expect(functions.callableName, 'createMerchantWalletReversalRequest');
        expect(functions.parameters, {
          'venueId': 'venue-1',
          'entryId': 'entry-1',
          'reason': 'duplicate debit',
          'merchantNote': 'please check',
        });
      },
    );

    test('createTopUpRequest sends client request id to callable', () async {
      final functions = _RecordingFirebaseFunctions();
      final repository = FirebaseMerchantWalletRepository(
        firestore: FakeFirebaseFirestore(),
        auth: _FakeFirebaseAuth('merchant-1'),
        functions: functions,
        storage: _FakeFirebaseStorage(),
      );

      await repository.createTopUpRequest(
        amount: 150,
        requestId: 'topup_test_1',
        proofImageUrl: 'venues/venue-1/wallet_topups/proof.jpg',
        transferReference: 'BANK-123',
        note: 'manual transfer',
      );

      expect(functions.callableName, 'createMerchantTopUpRequest');
      expect(functions.parameters, {
        'amount': 150.0,
        'requestId': 'topup_test_1',
        'proof_image_url': 'venues/venue-1/wallet_topups/proof.jpg',
        'transfer_reference': 'BANK-123',
        'note': 'manual transfer',
      });
    });

    test('maps merchant reversal errors to Arabic messages', () async {
      expect(
        mapMerchantReversalErrorCode('merchant_review_already_open'),
        'يوجد طلب مراجعة مفتوح لهذه العملية',
      );
    });
  });
}
