import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_hours_section.dart';
import 'package:wain_app/l10n/app_localizations.dart';

Widget _app(Widget child) {
  return MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

Venue _makeVenue({
  Map<String, List<VenueHours>> hours = const {},
  bool is24h = false,
}) {
  return Venue(
    id: 'v1',
    nameAr: 'مقهى تجريبي',
    nameEn: 'Test Cafe',
    lat: 31.9,
    lng: 35.2,
    city: 'عمان',
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
    testWidgets('renders header and day rows when hours are provided', (
      tester,
    ) async {
      final venue = _makeVenue(
        hours: {
          'monday': [const VenueHours(open: '09:00', close: '22:00')],
          'tuesday': [const VenueHours(open: '09:00', close: '22:00')],
          'friday': [const VenueHours(open: '10:00', close: '23:00')],
        },
      );

      await tester.pumpWidget(
        _app(
          SingleChildScrollView(child: VenueWorkingHoursSection(venue: venue)),
        ),
      );

      final context = tester.element(find.byType(VenueWorkingHoursSection));
      final l10n = AppLocalizations.of(context)!;

      expect(find.text(l10n.hoursTitle), findsOneWidget);
      expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);
      expect(find.text(l10n.dayMonday), findsOneWidget);
      expect(find.text(l10n.dayTuesday), findsOneWidget);
      expect(find.text(l10n.dayFriday), findsOneWidget);
      expect(find.text('09:00 - 22:00'), findsAtLeastNWidgets(1));
      expect(find.text('10:00 - 23:00'), findsAtLeastNWidgets(1));
    });

    testWidgets('returns SizedBox.shrink when no hours and not 24h', (
      tester,
    ) async {
      final venue = _makeVenue(hours: {}, is24h: false);

      await tester.pumpWidget(_app(VenueWorkingHoursSection(venue: venue)));

      final context = tester.element(find.byType(VenueWorkingHoursSection));
      final l10n = AppLocalizations.of(context)!;
      expect(find.text(l10n.hoursTitle), findsNothing);
    });

    testWidgets('shows open 24 hours badge for 24h venues', (tester) async {
      final venue = _makeVenue(is24h: true);

      await tester.pumpWidget(
        _app(
          SingleChildScrollView(child: VenueWorkingHoursSection(venue: venue)),
        ),
      );

      final context = tester.element(find.byType(VenueWorkingHoursSection));
      final l10n = AppLocalizations.of(context)!;
      expect(find.text(l10n.hoursTitle), findsOneWidget);
      expect(find.text(l10n.open24Hours), findsOneWidget);
    });
  });
}
