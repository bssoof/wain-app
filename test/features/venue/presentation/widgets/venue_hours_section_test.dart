import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_hours_section.dart';

/// Helper to create a minimal [Venue] for testing.
Venue _makeVenue({
  Map<String, List<VenueHours>> hours = const {},
  bool is24h = false,
}) {
  return Venue(
    id: 'v1',
    nameAr: 'مقهى تست',
    nameEn: 'Test Cafe',
    lat: 31.9,
    lng: 35.2,
    city: 'عمّان',
    categories: const ['cafe'],
    tags: const VenueTags(),
    minPrice: 10,
    maxPrice: 50,
    rating: 4.5,
    phone: '+962790000000',
    hours: hours,
    is24h: is24h,
  );
}

void main() {
  group('VenueWorkingHoursSection', () {
    testWidgets('renders header and day rows when hours are provided',
        (tester) async {
      final venue = _makeVenue(
        hours: {
          'monday': [const VenueHours(open: '09:00', close: '22:00')],
          'tuesday': [const VenueHours(open: '09:00', close: '22:00')],
          'friday': [const VenueHours(open: '10:00', close: '23:00')],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VenueWorkingHoursSection(venue: venue),
            ),
          ),
        ),
      );

      // Section header
      expect(find.text('ساعات العمل'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);

      // Day names translated
      expect(find.text('الإثنين'), findsOneWidget);
      expect(find.text('الثلاثاء'), findsOneWidget);
      expect(find.text('الجمعة'), findsOneWidget);

      // Time ranges
      expect(find.text('09:00 - 22:00'), findsAtLeastNWidgets(1));
      expect(find.text('10:00 - 23:00'), findsOneWidget);
    });

    testWidgets('returns SizedBox.shrink when no hours and not 24h',
        (tester) async {
      final venue = _makeVenue(hours: {}, is24h: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VenueWorkingHoursSection(venue: venue),
          ),
        ),
      );

      // Should render nothing visible
      expect(find.text('ساعات العمل'), findsNothing);
    });

    testWidgets('shows "مفتوح 24 ساعة" badge for 24h venues', (tester) async {
      final venue = _makeVenue(is24h: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VenueWorkingHoursSection(venue: venue),
            ),
          ),
        ),
      );

      expect(find.text('ساعات العمل'), findsOneWidget);
      expect(find.text('مفتوح 24 ساعة'), findsOneWidget);
    });
  });
}
