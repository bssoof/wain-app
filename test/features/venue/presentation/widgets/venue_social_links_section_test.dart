import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_social_links_section.dart';

Venue _makeVenue({
  String instagram = '',
  String facebook = '',
  String website = '',
  String whatsapp = '',
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
    instagram: instagram,
    facebook: facebook,
    website: website,
    whatsapp: whatsapp,
  );
}

void main() {
  group('VenueSocialLinksSection', () {
    testWidgets('renders all social chips when all links are provided',
        (tester) async {
      final venue = _makeVenue(
        instagram: 'testcafe',
        facebook: 'https://facebook.com/testcafe',
        website: 'https://testcafe.com',
        whatsapp: '+962790000000',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VenueSocialLinksSection(venue: venue),
            ),
          ),
        ),
      );

      // Section header
      expect(find.text('روابط التواصل'), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);

      // Social chips
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('Facebook'), findsOneWidget);
      expect(find.text('Website'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
    });

    testWidgets('renders only available social chips', (tester) async {
      final venue = _makeVenue(instagram: 'only_insta');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VenueSocialLinksSection(venue: venue),
            ),
          ),
        ),
      );

      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('Facebook'), findsNothing);
      expect(find.text('Website'), findsNothing);
      expect(find.text('WhatsApp'), findsNothing);
    });

    testWidgets('renders no chips when no links provided', (tester) async {
      final venue = _makeVenue();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VenueSocialLinksSection(venue: venue),
            ),
          ),
        ),
      );

      // Header still shows, but no ActionChips
      expect(find.text('روابط التواصل'), findsOneWidget);
      expect(find.byType(ActionChip), findsNothing);
    });
  });
}
