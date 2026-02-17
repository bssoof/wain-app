import 'package:flutter/material.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';

class VenueWorkingHoursSection extends StatelessWidget {
  final Venue venue;

  const VenueWorkingHoursSection({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    final todayText = venue.todayHoursText;
    if (todayText == null && venue.hours.isEmpty) {
      return const SizedBox.shrink();
    }

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
            const Text(
              'ساعات العمل',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            final dayName = _arabicDayName(entry.key);
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
                          ? 'مغلق'
                          : slots
                                .map((slot) => '${slot.open} - ${slot.close}')
                                .join('، '),
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

  String _arabicDayName(String key) {
    const names = {
      'monday': 'الإثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
      'saturday': 'السبت',
      'sunday': 'الأحد',
    };
    return names[key.toLowerCase()] ?? key;
  }
}
