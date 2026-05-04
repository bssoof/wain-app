import 'package:cloud_firestore/cloud_firestore.dart';

abstract class MerchantVenueProfileRepository {
  Future<void> updateVenueProfile({
    required String venueId,
    required String nameAr,
    required String nameEn,
    required String phone,
    required String city,
  });
}

class FirebaseMerchantVenueProfileRepository
    implements MerchantVenueProfileRepository {
  final FirebaseFirestore _firestore;

  FirebaseMerchantVenueProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> updateVenueProfile({
    required String venueId,
    required String nameAr,
    required String nameEn,
    required String phone,
    required String city,
  }) {
    return _firestore.collection('venues').doc(venueId).update({
      'name_ar': nameAr.trim(),
      'name_en': nameEn.trim(),
      'phone': phone.trim(),
      'city': city.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
