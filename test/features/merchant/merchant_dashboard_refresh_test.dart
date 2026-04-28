import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_dashboard_refresh.dart';

void main() {
  group('parseBusyTimesRefreshStatus', () {
    test('returns readyDemo when demo override is active', () {
      final status = parseBusyTimesRefreshStatus({
        'busyTimes': {'demo_override_active': true, 'confidence': 'sufficient'},
      });

      expect(status, BusyTimesRefreshStatus.readyDemo);
    });

    test('returns ready when confidence is sufficient', () {
      final status = parseBusyTimesRefreshStatus({
        'busyTimes': {'confidence': 'sufficient'},
      });

      expect(status, BusyTimesRefreshStatus.ready);
    });

    test('maps insufficient reasons to typed statuses', () {
      expect(
        parseBusyTimesRefreshStatus({
          'busyTimes': {
            'confidence': 'insufficient',
            'insufficient_reason': 'missing_opening_hours',
          },
        }),
        BusyTimesRefreshStatus.pendingHours,
      );
      expect(
        parseBusyTimesRefreshStatus({
          'busyTimes': {
            'confidence': 'insufficient',
            'insufficient_reason': 'missing_timezone',
          },
        }),
        BusyTimesRefreshStatus.pendingTimezone,
      );
      expect(
        parseBusyTimesRefreshStatus({
          'busyTimes': {
            'confidence': 'insufficient',
            'insufficient_reason': 'not_enough_signals',
          },
        }),
        BusyTimesRefreshStatus.pendingSignals,
      );
      expect(
        parseBusyTimesRefreshStatus({
          'busyTimes': {
            'confidence': 'insufficient',
            'insufficient_reason': 'not_enough_active_days',
          },
        }),
        BusyTimesRefreshStatus.pendingActiveDays,
      );
    });

    test('falls back to pendingGeneric for unknown payloads', () {
      expect(
        parseBusyTimesRefreshStatus(null),
        BusyTimesRefreshStatus.pendingGeneric,
      );
      expect(
        parseBusyTimesRefreshStatus({
          'busyTimes': {
            'confidence': 'insufficient',
            'insufficient_reason': 'other',
          },
        }),
        BusyTimesRefreshStatus.pendingGeneric,
      );
    });
  });

  group('classifyDashboardRefreshFailure', () {
    test('maps permission denied', () {
      final type = classifyDashboardRefreshFailure(
        code: 'permission-denied',
        message: 'blocked',
      );

      expect(type, DashboardRefreshFailureType.permissionDenied);
    });

    test('maps failed precondition with index message', () {
      final type = classifyDashboardRefreshFailure(
        code: 'failed-precondition',
        message: 'Missing composite index',
      );

      expect(type, DashboardRefreshFailureType.missingIndex);
    });

    test('maps failed precondition without index to noVenue', () {
      final type = classifyDashboardRefreshFailure(
        code: 'failed-precondition',
        message: 'Merchant has no venue',
      );

      expect(type, DashboardRefreshFailureType.noVenue);
    });

    test('maps unauthenticated and unknown', () {
      expect(
        classifyDashboardRefreshFailure(
          code: 'unauthenticated',
          message: 'no auth',
        ),
        DashboardRefreshFailureType.unauthenticated,
      );
      expect(
        classifyDashboardRefreshFailure(code: 'internal', message: 'boom'),
        DashboardRefreshFailureType.unknown,
      );
    });
  });
}
