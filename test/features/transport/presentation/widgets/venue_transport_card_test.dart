import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/core/providers/location_provider.dart';
import 'package:wain_app/features/transport/presentation/widgets/venue_transport_card.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class _FakeLocationAccessService extends LocationAccessService {
  int requestCount = 0;

  @override
  Future<LocationAccessResult> requestAccess() async {
    requestCount++;
    return LocationAccessResult.denied;
  }
}

Venue _venue() {
  return const Venue(
    id: 'venue-1',
    nameAr: 'محل اختبار',
    nameEn: 'Test venue',
    lat: 31.9,
    lng: 35.2,
    city: 'ramallah',
    categories: ['restaurant'],
    tags: VenueTags(),
    minPrice: 10,
    maxPrice: 40,
    rating: 4.5,
    phone: '',
    transportEnabled: true,
    transportPartnerIds: ['partner-1'],
  );
}

Widget _app({
  required UserLocation location,
  required LocationAccessService accessService,
}) {
  return ProviderScope(
    overrides: [
      userLocationProvider.overrideWith((ref) => Stream.value(location)),
      locationAccessServiceProvider.overrideWithValue(accessService),
    ],
    child: MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: VenueTransportCard(venue: _venue(), onOpenNavigation: () {}),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('asks for location instead of showing a city estimate', (
    tester,
  ) async {
    final accessService = _FakeLocationAccessService();

    await tester.pumpWidget(
      _app(
        location: const UserLocation(
          latitude: 31.9,
          longitude: 35.2,
          isRealLocation: false,
        ),
        accessService: accessService,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('حدد موقعك الحالي لعرض خيارات وصلني والأسعار بدقة.'),
      findsOneWidget,
    );
    expect(find.text('تحديد موقعي'), findsOneWidget);
    expect(find.text('تقدير من مركز المدينة'), findsNothing);

    await tester.tap(find.text('تحديد موقعي'));
    await tester.pump();

    expect(accessService.requestCount, 1);
    expect(
      find.text('اسمح لوين بالوصول إلى موقعك ثم حاول مرة أخرى.'),
      findsOneWidget,
    );
  });

  testWidgets('shows transport options when a real location is available', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        location: const UserLocation(latitude: 31.9, longitude: 35.2),
        accessService: _FakeLocationAccessService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('موقعك الحالي'), findsOneWidget);
    expect(find.text('عرض خيارات التوصيل'), findsOneWidget);
    expect(find.text('تحديد موقعي'), findsNothing);
  });
}
