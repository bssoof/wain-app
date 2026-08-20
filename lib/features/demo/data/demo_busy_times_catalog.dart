import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/venue/domain/entities/venue_busy_times.dart';

/// Busy-times day keys are `day_0`..`day_6`, which is *not* the
/// `monday`..`sunday` convention the opening-hours map uses.
///
/// The two live side by side in the same About tab, and mixing them up is
/// silent: `VenueBusyTimesSection` looks the key up, gets null, and hides
/// itself with no error at all.
const List<String> demoBusyTimesDayKeys = <String>[
  'day_0',
  'day_1',
  'day_2',
  'day_3',
  'day_4',
  'day_5',
  'day_6',
];

/// Hourly occupancy, 0.0 - 1.0, one entry per hour of the day.
///
/// The shape is a plausible café day: dead overnight, a morning bump, a quiet
/// early afternoon, and a strong evening peak. Weekend curves run later and
/// higher, and Sunday — the closed day in the demo hours — stays flat.
const List<double> _weekdayCurve = <double>[
  0.02, 0.01, 0.01, 0.01, 0.01, 0.02, 0.06, 0.18, //
  0.34, 0.46, 0.42, 0.38, 0.44, 0.40, 0.32, 0.30, //
  0.38, 0.52, 0.68, 0.82, 0.88, 0.74, 0.48, 0.18, //
];

const List<double> _thursdayCurve = <double>[
  0.10, 0.04, 0.01, 0.01, 0.01, 0.02, 0.06, 0.16, //
  0.30, 0.44, 0.40, 0.36, 0.42, 0.40, 0.36, 0.34, //
  0.46, 0.62, 0.78, 0.90, 0.96, 0.92, 0.78, 0.46, //
];

const List<double> _fridayCurve = <double>[
  0.04, 0.02, 0.01, 0.01, 0.01, 0.02, 0.05, 0.14, //
  0.28, 0.38, 0.34, 0.10, 0.06, 0.06, 0.30, 0.44, //
  0.52, 0.66, 0.80, 0.92, 0.94, 0.80, 0.54, 0.22, //
];

const List<double> _saturdayCurve = <double>[
  0.03, 0.01, 0.01, 0.01, 0.01, 0.02, 0.05, 0.12, //
  0.22, 0.40, 0.50, 0.54, 0.58, 0.52, 0.44, 0.42, //
  0.50, 0.64, 0.76, 0.86, 0.90, 0.78, 0.52, 0.20, //
];

const List<double> _closedCurve = <double>[
  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, //
  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, //
  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, //
];

const Map<String, List<double>> demoBusyTimesHistogram = <String, List<double>>{
  'day_0': _weekdayCurve, // Monday
  'day_1': _weekdayCurve, // Tuesday
  'day_2': _weekdayCurve, // Wednesday
  'day_3': _thursdayCurve, // Thursday — runs past midnight
  'day_4': _fridayCurve, // Friday — split day
  'day_5': _saturdayCurve, // Saturday
  'day_6': _closedCurve, // Sunday — closed
};

const Map<String, List<BestVisitWindow>> demoBestVisitWindows =
    <String, List<BestVisitWindow>>{
      'day_0': [BestVisitWindow(startHour: 10, endHour: 12)],
      'day_1': [BestVisitWindow(startHour: 10, endHour: 12)],
      'day_2': [BestVisitWindow(startHour: 10, endHour: 12)],
      'day_3': [BestVisitWindow(startHour: 9, endHour: 11)],
      'day_4': [BestVisitWindow(startHour: 14, endHour: 16)],
      'day_5': [BestVisitWindow(startHour: 9, endHour: 11)],
      'day_6': <BestVisitWindow>[],
    };

/// Fixed timestamps: the demo must never drift with the wall clock, otherwise
/// its tests become flaky and a live demo can silently change shape mid-pitch.
final DateTime demoBusyTimesComputedFrom = DateTime.utc(2026, 7, 1);
final DateTime demoBusyTimesComputedTo = DateTime.utc(2026, 7, 28);
final DateTime demoBusyTimesLastComputedAt = DateTime.utc(2026, 7, 28, 3);

VenueBusyTimes buildDemoBusyTimes() {
  return VenueBusyTimes(
    venueId: DemoMode.venueId,
    timezone: 'Asia/Hebron',
    resolvedTimezone: 'Asia/Hebron',
    confidence: BusyTimesConfidence.high,
    insufficientReason: null,
    histogram: demoBusyTimesHistogram,
    currentTypicalLabel: BusyTimesCurrentLabel.medium,
    bestVisitWindowsByDay: demoBestVisitWindows,
    computedFrom: demoBusyTimesComputedFrom,
    computedTo: demoBusyTimesComputedTo,
    lastComputedAt: demoBusyTimesLastComputedAt,
  );
}
