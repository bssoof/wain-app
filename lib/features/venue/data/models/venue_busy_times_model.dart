import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wain_app/features/venue/domain/entities/venue_busy_times.dart';

class VenueBusyTimesModel extends VenueBusyTimes {
  const VenueBusyTimesModel({
    required super.venueId,
    required super.timezone,
    required super.resolvedTimezone,
    required super.confidence,
    required super.insufficientReason,
    required super.histogram,
    required super.currentTypicalLabel,
    required super.bestVisitWindowsByDay,
    required super.computedFrom,
    required super.computedTo,
    required super.lastComputedAt,
  });

  static VenueBusyTimes? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists) {
      return null;
    }

    final data = doc.data();
    if (data == null) {
      return null;
    }

    return VenueBusyTimesModel(
      venueId: (data['venue_id'] as String?) ?? doc.id,
      timezone: data['timezone'] as String?,
      resolvedTimezone: data['resolved_timezone'] as String?,
      confidence: _confidenceFromString(data['confidence'] as String?),
      insufficientReason: data['insufficient_reason'] as String?,
      histogram: _parseHistogram(data['histogram']),
      currentTypicalLabel: _labelFromString(
        data['current_typical_label'] as String?,
      ),
      bestVisitWindowsByDay: _parseBestVisitWindowsByDay(
        data['best_visit_windows_by_day'],
      ),
      computedFrom: _timestampToDateTime(data['computed_from']),
      computedTo: _timestampToDateTime(data['computed_to']),
      lastComputedAt: _timestampToDateTime(data['last_computed_at']),
    );
  }

  static DateTime? _timestampToDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static BusyTimesConfidence _confidenceFromString(String? value) {
    switch (value) {
      case 'low':
        return BusyTimesConfidence.low;
      case 'medium':
        return BusyTimesConfidence.medium;
      case 'high':
        return BusyTimesConfidence.high;
      case 'insufficient':
      default:
        return BusyTimesConfidence.insufficient;
    }
  }

  static BusyTimesCurrentLabel? _labelFromString(String? value) {
    switch (value) {
      case 'quiet':
        return BusyTimesCurrentLabel.quiet;
      case 'medium':
        return BusyTimesCurrentLabel.medium;
      case 'busy':
        return BusyTimesCurrentLabel.busy;
      default:
        return null;
    }
  }

  static Map<String, List<double>>? _parseHistogram(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    final histogram = <String, List<double>>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is! List) {
        continue;
      }

      histogram[entry.key.toString()] = value
          .map((item) => item is num ? item.toDouble() : 0.0)
          .toList(growable: false);
    }

    return histogram.isEmpty ? null : histogram;
  }

  static Map<String, List<BestVisitWindow>>? _parseBestVisitWindowsByDay(
    Object? raw,
  ) {
    if (raw is! Map) {
      return null;
    }

    final windows = <String, List<BestVisitWindow>>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is! List) {
        continue;
      }

      final parsed = value
          .whereType<Map>()
          .map(
            (window) => BestVisitWindow(
              startHour: (window['start_hour'] as num?)?.toInt() ?? 0,
              endHour: (window['end_hour'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList(growable: false);
      windows[entry.key.toString()] = parsed;
    }

    return windows.isEmpty ? null : windows;
  }
}
