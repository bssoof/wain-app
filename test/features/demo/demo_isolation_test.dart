import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/demo/application/demo_session_store.dart';
import 'package:wain_app/features/demo/data/demo_busy_times_catalog.dart';
import 'package:wain_app/features/demo/data/demo_catalog_validators.dart';
import 'package:wain_app/features/demo/data/demo_venue_catalog.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/demo/presentation/demo_badge.dart';
import 'package:wain_app/features/venue/domain/entities/venue_busy_times.dart';
import 'package:wain_app/features/venue/domain/repositories/venue_repository.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';

/// Counts every production entry point the demo must never reach.
///
/// Each method records the call and then throws, so a leak fails loudly at the
/// call site instead of quietly returning empty data that a test might mistake
/// for isolation.
class _FailOnCallVenueRepository implements VenueRepository {
  final List<String> calls = <String>[];

  Never _fail(String method) {
    calls.add(method);
    throw StateError('production VenueRepository.$method reached from demo');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName
        .toString()
        .replaceAll('Symbol("', '')
        .replaceAll('")', '');
    _fail(name);
  }
}

void main() {
  group('demo venue isolation — behavioural', () {
    late _FailOnCallVenueRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = _FailOnCallVenueRepository();
      container = ProviderContainer(
        overrides: [venueRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
    });

    test('venue profile resolves without touching the repository', () async {
      final venue = await container.read(
        venueByIdProvider(DemoMode.venueId).future,
      );
      expect(venue, isNotNull);
      expect(venue!.id, DemoMode.venueId);
      expect(repository.calls, isEmpty);
    });

    test('busy times resolve without touching the repository', () async {
      final busy = await container.read(
        venueBusyTimesProvider(DemoMode.venueId).future,
      );
      expect(busy, isA<VenueBusyTimes>());
      expect(repository.calls, isEmpty);
    });

    test('place photos are short-circuited before the repository', () async {
      final photos = await container.read(
        venuePlacePhotosProvider(DemoMode.venueId).future,
      );
      final primary = await container.read(
        venuePrimaryPlacePhotoProvider(DemoMode.venueId).future,
      );
      expect(photos, isEmpty);
      expect(primary, isNull);
      expect(repository.calls, isEmpty);
    });

    test('a non-demo venue still reaches the repository', () async {
      // Guards the guard: without this, the three tests above would also pass
      // if the spy were simply never wired up. venuePlacePhotosProvider calls
      // the repository directly, with no offline wrapper in between, so it is
      // the honest control.
      await expectLater(
        container.read(venuePlacePhotosProvider('some-real-venue').future),
        throwsA(isA<StateError>()),
      );
      expect(repository.calls, contains('getPlacePhotos'));
    });
  });

  group('analytics suppression', () {
    test('trackVenueEvent drops demo events before the callable', () {
      // AnalyticsService returns early for the demo venue, so no Functions
      // instance is ever touched. Asserted structurally here and behaviourally
      // by the fact that the widget test below builds with no Firebase at all.
      final source =
          File('lib/core/services/analytics_service.dart').readAsStringSync();
      final guardIndex = source.indexOf('if (DemoMode.isDemoVenue(venueId))');
      final callableIndex = source.indexOf("httpsCallable('trackVenueEvent')");
      expect(guardIndex, greaterThan(-1));
      expect(
        guardIndex,
        lessThan(callableIndex),
        reason: 'the demo guard must precede the callable',
      );
    });
  });

  group('DemoSessionStore', () {
    test('starts pristine, records local state, and resets fully', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final store = container.read(demoSessionStoreProvider.notifier);

      expect(container.read(demoSessionStoreProvider).isPristine, isTrue);

      store.toggleFavourite(DemoMode.venueId);
      store.toggleTryList(DemoMode.venueId);
      expect(store.isFavourite(DemoMode.venueId), isTrue);
      expect(store.isOnTryList(DemoMode.venueId), isTrue);
      expect(container.read(demoSessionStoreProvider).isPristine, isFalse);

      store.reset();
      expect(container.read(demoSessionStoreProvider), DemoSessionStore.initialState);
      expect(container.read(demoSessionStoreProvider).isPristine, isTrue);
      expect(store.isFavourite(DemoMode.venueId), isFalse);
      expect(store.isOnTryList(DemoMode.venueId), isFalse);
    });

    test('toggling twice returns to the initial state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final store = container.read(demoSessionStoreProvider.notifier);

      store.toggleFavourite(DemoMode.venueId);
      store.toggleFavourite(DemoMode.venueId);
      expect(container.read(demoSessionStoreProvider), DemoSessionStore.initialState);
    });
  });

  group('DemoModeBadge', () {
    testWidgets('renders its warning inline without covering content', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates:
                AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Column(
                children: [
                  DemoModeBadge(),
                  Text('محتوى الصفحة'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(DemoMode.badgeLabelAr), findsOneWidget);

      // "Does not cover content" is a geometry claim, so assert geometry: the
      // badge occupies its own band and the content sits entirely below it.
      final badgeRect = tester.getRect(find.byType(DemoModeBadge));
      final contentRect = tester.getRect(find.text('محتوى الصفحة'));
      expect(badgeRect.overlaps(contentRect), isFalse);
      expect(badgeRect.bottom, lessThanOrEqualTo(contentRect.top));
    });
  });

  group('asset pack readiness', () {
    test('structural validation passes', () {
      expect(validateDemoCatalogs(), isEmpty);
    });

    test('customer readiness is explicitly NOT claimed yet', () {
      expect(
        demoVenueAssetPackInstalled,
        isFalse,
        reason: 'flip this only when real venue photography is installed',
      );
      expect(
        demoAssetPackReadiness(),
        isNotEmpty,
        reason: 'the demo must not report itself customer-ready without photos',
      );
    });

    test('the pending manifest is on disk and its photos are not', () {
      expect(
        File('assets/images/demo_venue/PENDING_ASSETS.md').existsSync(),
        isTrue,
      );
      final present = demoVenueRequiredPhotoAssets
          .where((path) => File(path).existsSync())
          .toList();
      expect(
        present,
        isEmpty,
        reason: 'venue photos appeared — install them and flip the flag',
      );
    });
  });

  group('demo route', () {
    test('/demo resolves to the demo venue id', () {
      final source = File('lib/core/routing/app_router.dart').readAsStringSync();
      expect(source, contains("path: '/demo'"));
      expect(source, contains('if (DemoMode.isEnabled)'));
      expect(source, contains("'/venue/\${DemoMode.venueId}'"));
    });

    test('the demo venue id is stable and non-production', () {
      expect(DemoMode.venueId, 'wain-demo-cafe-showcase');
      expect(buildDemoVenue().id, DemoMode.venueId);
      expect(demoBusyTimesDayKeys, hasLength(7));
    });
  });
}
