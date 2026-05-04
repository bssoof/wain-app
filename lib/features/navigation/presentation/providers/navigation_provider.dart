import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/repositories/navigation_repository.dart';
import '../../data/repositories/navigation_repository_impl.dart';
import '../../../../core/services/device_service.dart';

part 'navigation_provider.g.dart';

// ============ REPOSITORY PROVIDER ============

/// Provides NavigationRepository instance
@Riverpod(keepAlive: true)
NavigationRepository navigationRepository(Ref ref) {
  return NavigationRepositoryImpl(
    firestore: FirebaseFirestore.instance,
    deviceService: ref.watch(deviceServiceProvider),
  );
}

// ============ NAVIGATION ACTIONS ============

/// Log a navigation click and return the click ID
@riverpod
Future<String> logNavigationClick(
  Ref ref, {
  required String venueId,
  String? userId,
  required String navApp,
}) {
  return ref
      .read(navigationRepositoryProvider)
      .logNavigationClick(venueId: venueId, userId: userId, navApp: navApp);
}

/// Get device ID
@riverpod
Future<String> deviceId(Ref ref) {
  return ref.watch(navigationRepositoryProvider).getDeviceId();
}
