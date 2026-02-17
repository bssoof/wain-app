import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/offers/domain/entities/offer.dart';
import 'package:wain_app/features/offers/presentation/providers/offers_providers.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_offers_section.dart';
import 'package:wain_app/l10n/app_localizations.dart';

Widget _app(Widget child) {
  return MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

Venue _makeVenue() {
  return const Venue(
    id: 'venue-1',
    nameAr: 'Cafe',
    nameEn: 'Cafe',
    lat: 31.9,
    lng: 35.2,
    city: 'Amman',
    categories: ['cafe'],
    tags: VenueTags(),
    minPrice: 10,
    maxPrice: 50,
    rating: 4.4,
    phone: '+962790000000',
  );
}

Offer _makeOffer() {
  return Offer(
    id: 'offer-1',
    venueId: 'venue-1',
    titleAr: 'Free Cookie',
    descriptionAr: 'Any coffee + free cookie',
    discountType: DiscountType.freeItem,
    discountValue: 0,
    isActive: true,
  );
}

void main() {
  group('VenueOffersSection', () {
    testWidgets('renders offers and triggers claim callback', (tester) async {
      final venue = _makeVenue();
      final offer = _makeOffer();
      Offer? claimedOffer;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offersByVenueProvider(
              venueId: venue.id,
            ).overrideWith((ref) async => [offer]),
          ],
          child: _app(
            VenueOffersSection(
              venue: venue,
              onClaimOffer: (value) => claimedOffer = value,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(VenueOffersSection), findsOneWidget);
      expect(find.text('Free Cookie'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();

      expect(claimedOffer?.id, 'offer-1');
    });

    testWidgets('shows empty state when there are no offers', (tester) async {
      final venue = _makeVenue();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offersByVenueProvider(
              venueId: venue.id,
            ).overrideWith((ref) async => <Offer>[]),
          ],
          child: _app(VenueOffersSection(venue: venue, onClaimOffer: (_) {})),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.card_giftcard_outlined), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });
}
