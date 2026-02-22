import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppBootstrapStatus {
  final bool firebaseReady;
  final bool notificationsReady;
  final String? warningMessage;

  const AppBootstrapStatus({
    required this.firebaseReady,
    required this.notificationsReady,
    this.warningMessage,
  });
}

final appBootstrapStatusProvider = Provider<AppBootstrapStatus>(
  (ref) => const AppBootstrapStatus(
    firebaseReady: true,
    notificationsReady: true,
    warningMessage: null,
  ),
);
