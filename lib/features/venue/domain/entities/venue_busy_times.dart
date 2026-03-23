enum BusyTimesConfidence { insufficient, low, medium, high }

enum BusyTimesCurrentLabel { quiet, medium, busy }

class BestVisitWindow {
  final int startHour;
  final int endHour;

  const BestVisitWindow({required this.startHour, required this.endHour});
}

class VenueBusyTimes {
  final String venueId;
  final String? timezone;
  final String? resolvedTimezone;
  final BusyTimesConfidence confidence;
  final String? insufficientReason;
  final Map<String, List<double>>? histogram;
  final BusyTimesCurrentLabel? currentTypicalLabel;
  final Map<String, List<BestVisitWindow>>? bestVisitWindowsByDay;
  final DateTime? computedFrom;
  final DateTime? computedTo;
  final DateTime? lastComputedAt;

  const VenueBusyTimes({
    required this.venueId,
    required this.timezone,
    required this.resolvedTimezone,
    required this.confidence,
    required this.insufficientReason,
    required this.histogram,
    required this.currentTypicalLabel,
    required this.bestVisitWindowsByDay,
    required this.computedFrom,
    required this.computedTo,
    required this.lastComputedAt,
  });

  bool get isUsable => confidence != BusyTimesConfidence.insufficient;
}
