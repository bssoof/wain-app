import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

/// Current persistence scope for user-specific local preferences.
///
/// Returns the signed-in Firebase UID when available. A null value means local
/// device scope, used before authentication and for legacy guest-only sessions.
final userPreferenceScopeProvider = Provider<String?>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  final uid = user?.uid.trim();
  return uid == null || uid.isEmpty ? null : uid;
});
