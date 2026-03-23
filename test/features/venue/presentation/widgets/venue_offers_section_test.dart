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
  return _makeCustomOffer(
    id: 'offer-1',
    title: 'Free Cookie',
    discountType: DiscountType.freeItem,
    discountValue: 0,
  );
}

Offer _makeCustomOffer({
  required String id,
  required String title,
  DiscountType discountType = DiscountType.amount,
  double discountValue = 20,
  bool isActive = true,
  DateTime? endAt,
  bool isPartner = false,
}) {
  return Offer(
    id: id,
    venueId: 'venue-1',
    titleAr: title,
    descriptionAr: 'Offer for $title',
    discountType: discountType,
    discountValue: discountValue,
    isActive: isActive,
    endAt: endAt,
    isPartner: isPartner,
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
            offerRedeemedStatusProvider(
              offer.id,
            ).overrideWith((ref) => Stream.value(false)),
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

      expect(find.byIcon(Icons.card_giftcard_rounded), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('shows only top two offers inline and opens all offers sheet', (
      tester,
    ) async {
      final venue = _makeVenue();
      final offers = [
        _makeCustomOffer(id: 'offer-1', title: 'Offer 10', discountValue: 10),
        _makeCustomOffer(id: 'offer-2', title: 'Offer 20', discountValue: 20),
        _makeCustomOffer(id: 'offer-3', title: 'Offer 30', discountValue: 30),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offersByVenueProvider(
              venueId: venue.id,
            ).overrideWith((ref) async => offers),
            offerRedeemedStatusProvider(
              'offer-1',
            ).overrideWith((ref) => Stream.value(false)),
            offerRedeemedStatusProvider(
              'offer-2',
            ).overrideWith((ref) => Stream.value(false)),
            offerRedeemedStatusProvider(
              'offer-3',
            ).overrideWith((ref) => Stream.value(false)),
          ],
          child: _app(VenueOffersSection(venue: venue, onClaimOffer: (_) {})),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Offer 30'), findsOneWidget);
      expect(find.text('Offer 20'), findsOneWidget);
      expect(find.text('Offer 10'), findsNothing);
      expect(find.textContaining('عرض كل العروض'), findsOneWidget);

      await tester.tap(find.textContaining('عرض كل العروض'));
      await tester.pumpAndSettle();

      expect(find.text('كل العروض'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Offer 10'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Offer 10'), findsOneWidget);
    });

    testWidgets('filters expired offers out of the inline preview', (
      tester,
    ) async {
      final venue = _makeVenue();
      final activeOffer = _makeCustomOffer(
        id: 'offer-active',
        title: 'Active Offer',
        discountValue: 25,
      );
      final expiredOffer = _makeCustomOffer(
        id: 'offer-expired',
        title: 'Expired Offer',
        discountValue: 50,
        endAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offersByVenueProvider(
              venueId: venue.id,
            ).overrideWith((ref) async => [activeOffer, expiredOffer]),
            offerRedeemedStatusProvider(
              activeOffer.id,
            ).overrideWith((ref) => Stream.value(false)),
            offerRedeemedStatusProvider(
              expiredOffer.id,
            ).overrideWith((ref) => Stream.value(false)),
          ],
          child: _app(VenueOffersSection(venue: venue, onClaimOffer: (_) {})),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Active Offer'), findsOneWidget);
      expect(find.text('Expired Offer'), findsNothing);
    });
  });
}
