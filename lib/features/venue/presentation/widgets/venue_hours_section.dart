import 'package:flutter/material.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class VenueWorkingHoursSection extends StatelessWidget {
  final Venue venue;

  const VenueWorkingHoursSection({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final todayText = venue.todayHoursText;
    if (todayText == null && venue.hours.isEmpty) {
      return const SizedBox.shrink();
    }

    final separator = l10n.localeName.startsWith('ar') ? '، ' : ', ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.access_time,
                color: Colors.blue.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.hoursTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (todayText != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  todayText,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        if (venue.hours.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...venue.hours.entries.map((entry) {
            final dayName = _localizedDayName(l10n, entry.key);
            final slots = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      slots.isEmpty
                          ? l10n.closed
                          : slots
                                .map((slot) => '${slot.open} - ${slot.close}')
                                .join(separator),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  String _localizedDayName(AppLocalizations l10n, String key) {
    switch (key.toLowerCase()) {
      case 'monday':
        return l10n.dayMonday;
      case 'tuesday':
        return l10n.dayTuesday;
      case 'wednesday':
        return l10n.dayWednesday;
      case 'thursday':
        return l10n.dayThursday;
      case 'friday':
        return l10n.dayFriday;
      case 'saturday':
        return l10n.daySaturday;
      case 'sunday':
        return l10n.daySunday;
      default:
        return key;
    }
  }
}
