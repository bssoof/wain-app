import 'package:cloud_firestore/cloud_firestore.dart';

abstract class MerchantHoursRepository {
  Future<void> saveHours({
    required String venueId,
    required bool is24Hours,
    required Map<String, List<Map<String, String>>> hours,
  });
}

class FirebaseMerchantHoursRepository implements MerchantHoursRepository {
  final FirebaseFirestore _firestore;

  FirebaseMerchantHoursRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveHours({
    required String venueId,
    required bool is24Hours,
    required Map<String, List<Map<String, String>>> hours,
  }) async {
    final hoursToSave = <String, dynamic>{};
    if (!is24Hours) {
      hours.forEach((day, shifts) {
        if (shifts.isEmpty) {
          return;
        }
        hoursToSave[day] = shifts.map((shift) {
          final open = shift['open']!;
          final close = shift['close']!;
          return {
            'open': open,
            'close': close,
            'spans_midnight': close.compareTo(open) < 0,
          };
        }).toList();
      });
    }

    await _firestore.collection('venues').doc(venueId).update({
      'is_24h': is24Hours,
      'hours': is24Hours ? null : hoursToSave,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
