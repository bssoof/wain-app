const _hoursDayKeys = <int, String>{
  1: 'monday',
  2: 'tuesday',
  3: 'wednesday',
  4: 'thursday',
  5: 'friday',
  6: 'saturday',
  7: 'sunday',
};

bool? isOpenNowFromSlots<T>({
  required Map<String, List<T>> hours,
  required bool is24Hours,
  DateTime? now,
  required String Function(T slot) openOf,
  required String Function(T slot) closeOf,
  required bool Function(T slot) spansMidnightOf,
}) {
  if (is24Hours) return true;
  if (hours.isEmpty) return null;

  final dateTime = now ?? DateTime.now();
  final dayKey = _hoursDayKeys[dateTime.weekday];
  if (dayKey == null) return null;

  final currentMinutes = dateTime.hour * 60 + dateTime.minute;

  final todaySlots = hours[dayKey];
  if (todaySlots != null) {
    for (final slot in todaySlots) {
      final openMinutes = _parseHoursTime(openOf(slot));
      final closeMinutes = _parseHoursTime(closeOf(slot));
      if (openMinutes == null || closeMinutes == null) {
        continue;
      }

      if (spansMidnightOf(slot)) {
        if (currentMinutes >= openMinutes) {
          return true;
        }
      } else if (currentMinutes >= openMinutes &&
          currentMinutes < closeMinutes) {
        return true;
      }
    }
  }

  final previousDayKey =
      _hoursDayKeys[dateTime.weekday == 1 ? 7 : dateTime.weekday - 1];
  if (previousDayKey != null) {
    final previousDaySlots = hours[previousDayKey];
    if (previousDaySlots != null) {
      for (final slot in previousDaySlots) {
        if (!spansMidnightOf(slot)) {
          continue;
        }
        final closeMinutes = _parseHoursTime(closeOf(slot));
        if (closeMinutes == null) {
          continue;
        }
        if (currentMinutes < closeMinutes) {
          return true;
        }
      }
    }
  }

  if (todaySlots == null || todaySlots.isEmpty) {
    return false;
  }

  return false;
}

int? _parseHoursTime(String time) {
  final parts = time.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return hour * 60 + minute;
}
