enum BusyTimesRefreshStatus {
  ready,
  readyDemo,
  pendingHours,
  pendingTimezone,
  pendingSignals,
  pendingActiveDays,
  pendingGeneric,
}

enum DashboardRefreshFailureType {
  appCheckFailed,
  permissionDenied,
  missingIndex,
  noVenue,
  unauthenticated,
  unknown,
}

class DashboardRefreshResult {
  final int views;
  final int calls;
  final int navs;
  final BusyTimesRefreshStatus busyTimesStatus;

  const DashboardRefreshResult({
    required this.views,
    required this.calls,
    required this.navs,
    required this.busyTimesStatus,
  });
}

class DashboardRefreshException implements Exception {
  final DashboardRefreshFailureType type;
  final String? debugMessage;

  const DashboardRefreshException({required this.type, this.debugMessage});

  @override
  String toString() => debugMessage ?? type.name;
}

BusyTimesRefreshStatus parseBusyTimesRefreshStatus(
  Map<dynamic, dynamic>? result,
) {
  final busyTimes = result?['busyTimes'];
  if (busyTimes is! Map) {
    return BusyTimesRefreshStatus.pendingGeneric;
  }

  if (busyTimes['demo_override_active'] == true) {
    return BusyTimesRefreshStatus.readyDemo;
  }

  final confidence = busyTimes['confidence'] as String?;
  if (confidence != 'insufficient') {
    return BusyTimesRefreshStatus.ready;
  }

  switch (busyTimes['insufficient_reason'] as String?) {
    case 'missing_opening_hours':
      return BusyTimesRefreshStatus.pendingHours;
    case 'missing_timezone':
      return BusyTimesRefreshStatus.pendingTimezone;
    case 'not_enough_signals':
      return BusyTimesRefreshStatus.pendingSignals;
    case 'not_enough_active_days':
      return BusyTimesRefreshStatus.pendingActiveDays;
    default:
      return BusyTimesRefreshStatus.pendingGeneric;
  }
}

DashboardRefreshFailureType classifyDashboardRefreshFailure({
  required String code,
  String? message,
}) {
  final normalizedMessage = (message ?? '').toLowerCase();

  switch (code) {
    case 'permission-denied':
      return DashboardRefreshFailureType.permissionDenied;
    case 'failed-precondition':
      if (normalizedMessage.contains('app check')) {
        return DashboardRefreshFailureType.appCheckFailed;
      }
      if (normalizedMessage.contains('index')) {
        return DashboardRefreshFailureType.missingIndex;
      }
      return DashboardRefreshFailureType.noVenue;
    case 'unauthenticated':
      return DashboardRefreshFailureType.unauthenticated;
    default:
      return DashboardRefreshFailureType.unknown;
  }
}
