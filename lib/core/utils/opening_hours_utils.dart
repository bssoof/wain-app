import 'package:wain_app/features/venue/domain/entities/venue.dart';

/// Utility class for checking venue opening hours
class OpeningHoursUtils {
  OpeningHoursUtils._();

  /// Days mapping (English weekday names to Arabic)
  static const Map<int, String> _weekdayMap = {
    1: 'monday',
    2: 'tuesday',
    3: 'wednesday',
    4: 'thursday',
    5: 'friday',
    6: 'saturday',
    7: 'sunday',
  };

  /// Check if venue is currently open
  static bool isOpenNow(Map<String, List<VenueHours>> hours, bool is24h) {
    if (is24h) return true;
    if (hours.isEmpty) return false;

    final now = DateTime.now();
    final dayName = _weekdayMap[now.weekday];
    if (dayName == null) return false;

    final todayHours = hours[dayName];
    if (todayHours == null || todayHours.isEmpty) return false;

    for (final period in todayHours) {
      if (_isWithinPeriod(now, period, dayName, hours)) {
        return true;
      }
    }

    return false;
  }

  /// Check if current time is within a period
  static bool _isWithinPeriod(
    DateTime now,
    VenueHours period,
    String dayName,
    Map<String, List<VenueHours>> allHours,
  ) {
    final openTime = _parseTime(period.open);
    final closeTime = _parseTime(period.close);

    if (openTime == null || closeTime == null) return false;

    final nowMinutes = now.hour * 60 + now.minute;

    if (period.spansMidnight) {
      // Venue closes after midnight
      // Either: current time is after open today
      // Or: current time is before close (and yesterday was open)
      if (nowMinutes >= openTime) {
        return true;
      }
      // Check if yesterday's hours span into today
      if (nowMinutes < closeTime) {
        return true;
      }
      return false;
    } else {
      // Normal hours (same day)
      return nowMinutes >= openTime && nowMinutes < closeTime;
    }
  }

  /// Parse time string (HH:MM) to minutes since midnight
  static int? _parseTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return null;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return hour * 60 + minute;
    } catch (e) {
      return null;
    }
  }

  /// Get today's opening hours as formatted string
  static String getTodayHours(Map<String, List<VenueHours>> hours, bool is24h) {
    if (is24h) return 'مفتوح 24 ساعة';
    if (hours.isEmpty) return 'ساعات العمل غير متوفرة';

    final now = DateTime.now();
    final dayName = _weekdayMap[now.weekday];
    if (dayName == null) return 'غير معروف';

    final todayHours = hours[dayName];
    if (todayHours == null || todayHours.isEmpty) return 'مغلق اليوم';

    final formattedPeriods = todayHours.map((period) {
      final openFormatted = _formatTime(period.open);
      final closeFormatted = _formatTime(period.close);
      return '$openFormatted - $closeFormatted';
    }).join(' / ');

    return formattedPeriods;
  }

  /// Get open status message
  static OpenStatus getOpenStatus(Map<String, List<VenueHours>> hours, bool is24h) {
    if (is24h) {
      return OpenStatus(
        isOpen: true,
        message: 'مفتوح 24 ساعة',
        badge: 'مفتوح',
      );
    }

    final isOpen = isOpenNow(hours, is24h);
    
    if (isOpen) {
      final closingTime = _getNextClosingTime(hours);
      return OpenStatus(
        isOpen: true,
        message: closingTime != null ? 'مفتوح حتى $closingTime' : 'مفتوح الآن',
        badge: 'مفتوح',
      );
    } else {
      final openingTime = _getNextOpeningTime(hours);
      return OpenStatus(
        isOpen: false,
        message: openingTime != null ? 'يفتح الساعة $openingTime' : 'مغلق',
        badge: 'مغلق',
      );
    }
  }

  /// Get next closing time today
  static String? _getNextClosingTime(Map<String, List<VenueHours>> hours) {
    final now = DateTime.now();
    final dayName = _weekdayMap[now.weekday];
    if (dayName == null) return null;

    final todayHours = hours[dayName];
    if (todayHours == null || todayHours.isEmpty) return null;

    final nowMinutes = now.hour * 60 + now.minute;

    for (final period in todayHours) {
      final openTime = _parseTime(period.open);
      final closeTime = _parseTime(period.close);
      if (openTime == null || closeTime == null) continue;

      if (period.spansMidnight) {
        if (nowMinutes >= openTime) {
          return _formatTime(period.close);
        }
      } else {
        if (nowMinutes >= openTime && nowMinutes < closeTime) {
          return _formatTime(period.close);
        }
      }
    }

    return null;
  }

  /// Get next opening time
  static String? _getNextOpeningTime(Map<String, List<VenueHours>> hours) {
    final now = DateTime.now();
    final dayName = _weekdayMap[now.weekday];
    if (dayName == null) return null;

    final todayHours = hours[dayName];
    if (todayHours == null || todayHours.isEmpty) return null;

    final nowMinutes = now.hour * 60 + now.minute;

    for (final period in todayHours) {
      final openTime = _parseTime(period.open);
      if (openTime == null) continue;

      if (nowMinutes < openTime) {
        return _formatTime(period.open);
      }
    }

    return null;
  }

  /// Format time for display (24h to 12h)
  static String _formatTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return time;
      
      var hour = int.parse(parts[0]);
      final minute = parts[1];
      
      final period = hour >= 12 ? 'م' : 'ص';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      
      return '$hour:$minute $period';
    } catch (e) {
      return time;
    }
  }
}

/// Open status result
class OpenStatus {
  final bool isOpen;
  final String message;
  final String badge;

  const OpenStatus({
    required this.isOpen,
    required this.message,
    required this.badge,
  });
}
