import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/services/device_service.dart';
import 'package:wain_app/features/transport/data/repositories/transport_repository.dart';

final transportRepositoryProvider = Provider<TransportRepository>((ref) {
  return TransportRepositoryImpl(
    functions: FirebaseFunctions.instance,
    auth: FirebaseAuth.instance,
    deviceService: ref.read(deviceServiceProvider),
  );
});
