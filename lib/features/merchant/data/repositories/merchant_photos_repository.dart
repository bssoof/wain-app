import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

abstract class MerchantPhotosRepository {
  Future<List<String>> uploadPhotos({
    required String venueId,
    required List<XFile> files,
  });

  Future<void> deletePhoto({required String venueId, required String photoUrl});

  Future<void> setPrimaryPhoto({
    required String venueId,
    required List<String> currentPhotos,
    required String targetUrl,
  });
}

class FirebaseMerchantPhotosRepository implements MerchantPhotosRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseMerchantPhotosRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<List<String>> uploadPhotos({
    required String venueId,
    required List<XFile> files,
  }) async {
    final newUrls = <String>[];
    for (final picked in files) {
      final file = File(picked.path);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final storageRef = _storage.ref().child(
        'venues/$venueId/photos/$fileName',
      );

      await storageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      newUrls.add(await storageRef.getDownloadURL());
    }

    await _firestore.collection('venues').doc(venueId).update({
      'photos': FieldValue.arrayUnion(newUrls),
    });

    return newUrls;
  }

  @override
  Future<void> deletePhoto({
    required String venueId,
    required String photoUrl,
  }) async {
    await _firestore.collection('venues').doc(venueId).update({
      'photos': FieldValue.arrayRemove([photoUrl]),
    });

    try {
      await _storage.refFromURL(photoUrl).delete();
    } catch (_) {}
  }

  @override
  Future<void> setPrimaryPhoto({
    required String venueId,
    required List<String> currentPhotos,
    required String targetUrl,
  }) async {
    final newOrder = List<String>.from(currentPhotos);
    newOrder.remove(targetUrl);
    newOrder.insert(0, targetUrl);

    await _firestore.collection('venues').doc(venueId).update({
      'photos': newOrder,
    });
  }
}
