import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_meta_section.dart';

Venue _makeVenue({
  String nameAr = 'مقهى اختبار',
  double rating = 4.5,
  List<String> categories = const ['cafe'],
  List<String> mood = const [],
  List<String> occasion = const [],
}) {
  return Venue(
    id: 'v1',
    nameAr: nameAr,
    nameEn: 'Test Cafe',
    lat: 31.9,
    lng: 35.2,
    city: 'عمّان',
    categories: categories,
    tags: VenueTags(mood: mood, occasion: occasion),
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
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VenueMetaSection(
                venue: venue,
                displayTags: const ['رومانسي', 'عائلي'],
              ),
            ),
          ),
        ),
      );

      // Name
      expect(find.text('قهوة الصباح'), findsOneWidget);

      // Rating
      expect(find.text('4.8'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);

      // Category (first category displayed)
      expect(find.text('cafe'), findsOneWidget);
    });

    testWidgets('renders display tags', (tester) async {
      final venue = _makeVenue();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VenueMetaSection(
                venue: venue,
                displayTags: const ['هادئ', 'لقاء أصدقاء', 'رومانسي'],
              ),
            ),
          ),
        ),
      );

      expect(find.text('هادئ'), findsOneWidget);
      expect(find.text('لقاء أصدقاء'), findsOneWidget);
      expect(find.text('رومانسي'), findsOneWidget);
    });

    testWidgets('renders no tags when list is empty', (tester) async {
      final venue = _makeVenue();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VenueMetaSection(
                venue: venue,
                displayTags: const [],
              ),
            ),
          ),
        ),
      );

      // Name always present
      expect(find.text('مقهى اختبار'), findsOneWidget);
      // Wrap is conditionally omitted when displayTags is empty
      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets('shows "عام" when no categories', (tester) async {
      final venue = _makeVenue(categories: []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VenueMetaSection(
                venue: venue,
                displayTags: const [],
              ),
            ),
          ),
        ),
      );

      expect(find.text('عام'), findsOneWidget);
    });
  });
}
