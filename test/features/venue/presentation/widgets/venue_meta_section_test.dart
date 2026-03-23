import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_meta_section.dart';
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
  String nameAr = 'مقهى اختبار',
  double rating = 4.5,
  List<String> categories = const ['cafe'],
}) {
  return Venue(
    id: 'v1',
    nameAr: nameAr,
    nameEn: 'Test Cafe',
    lat: 31.9,
    lng: 35.2,
    city: 'عمان',
    categories: categories,
    tags: const VenueTags(),
    minPrice: 10,
    maxPrice: 50,
    rating: rating,
    phone: '+962790000000',
  );
}

void main() {
  group('VenueMetaSection', () {
    testWidgets('renders venue name, rating, and category', (tester) async {
      final venue = _makeVenue(nameAr: 'قهوة الصباح', rating: 4.8);

      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: VenueMetaSection(
              venue: venue,
              displayTags: const ['رومانسي', 'عائلي'],
            ),
          ),
        ),
      );

      expect(find.text('قهوة الصباح'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.text('cafe'), findsOneWidget);
    });

    testWidgets('renders up to two display tags and collapses the rest', (
      tester,
    ) async {
      final venue = _makeVenue();

      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: VenueMetaSection(
              venue: venue,
              displayTags: const ['هادئ', 'لقاء أصدقاء', 'رومانسي'],
            ),
          ),
        ),
      );

      expect(find.text('هادئ'), findsOneWidget);
      expect(find.text('لقاء أصدقاء'), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);
      expect(find.text('رومانسي'), findsNothing);
    });

    testWidgets('renders no tag chips when list is empty', (tester) async {
      final venue = _makeVenue();

      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: VenueMetaSection(venue: venue, displayTags: const []),
          ),
        ),
      );

      expect(find.text('مقهى اختبار'), findsOneWidget);
      expect(find.text('+1'), findsNothing);
      expect(find.text('هادئ'), findsNothing);
    });

    testWidgets('shows general category when no categories', (tester) async {
      final venue = _makeVenue(categories: []);

      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: VenueMetaSection(venue: venue, displayTags: const []),
          ),
        ),
      );

      final context = tester.element(find.byType(VenueMetaSection));
      final l10n = AppLocalizations.of(context)!;
      expect(find.text(l10n.generalCategory), findsOneWidget);
    });
  });
}
