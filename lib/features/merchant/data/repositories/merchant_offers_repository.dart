import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer_upsert_input.dart';

abstract class MerchantOffersRepository {
  Future<void> setOfferStatus({
    required String offerId,
    required MerchantOfferStatus status,
  });

  Future<void> deleteOffer(String offerId);

  Future<void> saveOffer(MerchantOfferUpsertInput input);
  Future<Map<int, double>> fetchOfferPinPricing();
  Future<void> pinOffer({
    required String offerId,
    required int durationDays,
    required String requestId,
  });
}

class FirestoreMerchantOffersRepository implements MerchantOffersRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FirestoreMerchantOffersRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  CollectionReference<Map<String, dynamic>> get _offersRef =>
      _firestore.collection('offers');

  @override
  Future<void> setOfferStatus({
    required String offerId,
    required MerchantOfferStatus status,
  }) {
    final persistedStatus = switch (status) {
      MerchantOfferStatus.active => MerchantOfferStatus.active,
      MerchantOfferStatus.paused => MerchantOfferStatus.paused,
      MerchantOfferStatus.expired => throw ArgumentError(
        'Expired status is derived and cannot be persisted directly.',
      ),
    };

    return _offersRef.doc(offerId).update({
      'status': persistedStatus.storageValue,
      'is_active': persistedStatus == MerchantOfferStatus.active,
    });
  }

  @override
  Future<void> deleteOffer(String offerId) {
    return _offersRef.doc(offerId).delete();
  }

  @override
  Future<void> saveOffer(MerchantOfferUpsertInput input) async {
    final data = <String, dynamic>{
      'venue_id': input.venueId,
      'title_ar': input.titleAr,
      'description_ar': input.descriptionAr,
      'discount_type': input.discountType,
      'discount_value': input.discountValue,
      'single_use_per_customer': input.singleUsePerCustomer,
      'terms_ar': input.termsAr,
      'status': input.isActive ? 'active' : 'paused',
      'is_active': input.isActive,
    };

    if (input.startAt != null) {
      data['start_at'] = Timestamp.fromDate(input.startAt!);
    } else if (input.applyServerStartAtWhenMissing) {
      data['start_at'] = FieldValue.serverTimestamp();
    } else if (input.clearStartAt) {
      data['start_at'] = FieldValue.delete();
    }

    if (input.endAt != null) {
      data['end_at'] = Timestamp.fromDate(input.endAt!);
    } else if (input.clearEndAt) {
      data['end_at'] = FieldValue.delete();
    }

    if (input.isEditing) {
      await _offersRef.doc(input.offerId!).update(data);
      return;
    }

    await _offersRef.add(data);
  }

  @override
  Future<Map<int, double>> fetchOfferPinPricing() async {
    final doc = await _firestore
        .collection('wallet_feature_pricing')
        .doc('default')
        .get();
    final data = doc.data() ?? const <String, dynamic>{};
    return {
      1: (data['offer_pin_1d'] as num?)?.toDouble() ?? 0,
      3: (data['offer_pin_3d'] as num?)?.toDouble() ?? 0,
      7: (data['offer_pin_7d'] as num?)?.toDouble() ?? 0,
    };
  }

  @override
  Future<void> pinOffer({
    required String offerId,
    required int durationDays,
    required String requestId,
  }) async {
    final callable = _functions.httpsCallable('pinOffer');
    await callable.call({
      'offerId': offerId,
      'durationDays': durationDays,
      'requestId': requestId,
    });
  }
}
