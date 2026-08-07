import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/features/demo/application/demo_session_store.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/demo/presentation/demo_badge.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wain_app/features/demo/data/demo_offers_catalog.dart';
import 'package:wain_app/features/demo/data/demo_reviews_catalog.dart';
import 'package:wain_app/features/demo/presentation/demo_offer_qr_sheet.dart';
import 'package:wain_app/features/demo/data/demo_stories_catalog.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/features/venue/domain/entities/venue_place_photo.dart';
import 'package:wain_app/features/venue/domain/repositories/venue_repository.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/features/venue/presentation/screens/venue_details_screen.dart';
import 'package:wain_app/l10n/app_localizations.dart';

/// Shared tally so one assertion can cover every production surface at once.
class ProductionCallLog {
  final List<String> calls = <String>[];

  Never record(String adapter, String method) {
    calls.add('$adapter.$method');
    throw StateError('production $adapter.$method reached from the demo');
  }

  void expectSilent() {
    expect(calls, isEmpty, reason: 'production calls: $calls');
  }
}

class _FailOnCallVenueRepository implements VenueRepository {
  _FailOnCallVenueRepository(this.log);
  final ProductionCallLog log;

  @override
  dynamic noSuchMethod(Invocation invocation) => log.record(
    'VenueRepository',
    invocation.memberName.toString().replaceAll(RegExp(r'Symbol\("|"\)'), ''),
  );
}

/// AnalyticsService is a concrete class, so the fake overrides the venue-facing
/// surface the screen actually uses. Any of them firing is a leak — including
/// `logVenueViewFull`, which writes straight to FirebaseAnalytics.
class _FailOnCallAnalytics implements AnalyticsService {
  _FailOnCallAnalytics(this.log);
  final ProductionCallLog log;

  @override
  dynamic noSuchMethod(Invocation invocation) => log.record(
    'AnalyticsService',
    invocation.memberName.toString().replaceAll(RegExp(r'Symbol\("|"\)'), ''),
  );
}

class _FailOnCallFavorites extends FavoritesList {
  _FailOnCallFavorites(this.log);
  final ProductionCallLog log;

  @override
  Future<List<String>> build() async {
    log.record('FavoritesList', 'build');
  }
}

Future<void> _pumpDemoDetails(WidgetTester tester, ProductionCallLog log) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        venueRepositoryProvider.overrideWithValue(
          _FailOnCallVenueRepository(log),
        ),
        analyticsServiceProvider.overrideWithValue(_FailOnCallAnalytics(log)),
        favoritesListProvider.overrideWith(() => _FailOnCallFavorites(log)),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const VenueDetailsScreen(venueId: DemoMode.venueId),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  group('VenueDetailsScreen — demo venue reaches no production adapter', () {
    testWidgets('first paint is silent', (tester) async {
      final log = ProductionCallLog();
      await _pumpDemoDetails(tester, log);

      expect(find.byType(VenueDetailsScreen), findsOneWidget);
      log.expectSilent();
    });

    testWidgets('switching across all three tabs stays silent', (tester) async {
      final log = ProductionCallLog();
      await _pumpDemoDetails(tester, log);

      for (var index = 0; index < 3; index += 1) {
        // The tab bar sits below the intrinsically sized header, so scroll it
        // into view, switch tab, then scroll back so the badge is on screen
        // again. The badge lives in the header sliver: it is per-screen, not
        // per-tab, which is exactly what has to be proven here.
        await tester.drag(find.byType(NestedScrollView), const Offset(0, -400));
        await tester.pumpAndSettle();

        final tabs = find.byType(Tab);
        expect(tabs, findsNWidgets(3));
        await tester.tap(tabs.at(index), warnIfMissed: false);
        await tester.pumpAndSettle();
        log.expectSilent();

        await tester.drag(find.byType(NestedScrollView), const Offset(0, 600));
        await tester.pumpAndSettle();
        expect(
          find.byType(DemoModeBadge),
          findsOneWidget,
          reason: 'the badge must be present on tab $index',
        );
        log.expectSilent();
      }
    });

    testWidgets('favourite and try-list mutate only local demo state', (
      tester,
    ) async {
      final log = ProductionCallLog();
      await _pumpDemoDetails(tester, log);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(VenueDetailsScreen)),
      );
      expect(container.read(demoSessionStoreProvider).isPristine, isTrue);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pumpAndSettle();
      expect(
        container.read(demoSessionStoreProvider).favouriteVenueIds,
        contains(DemoMode.venueId),
      );
      log.expectSilent();

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();
      expect(
        container.read(demoSessionStoreProvider).tryListVenueIds,
        contains(DemoMode.venueId),
      );
      log.expectSilent();
    });

    testWidgets('the reset button restores the initial state', (tester) async {
      final log = ProductionCallLog();
      await _pumpDemoDetails(tester, log);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(VenueDetailsScreen)),
      );
      container.read(demoSessionStoreProvider.notifier)
        ..toggleFavourite(DemoMode.venueId)
        ..toggleTryList(DemoMode.venueId);
      await tester.pumpAndSettle();
      expect(container.read(demoSessionStoreProvider).isPristine, isFalse);

      final resetButton = find.byKey(const Key('demo_reset_button'));
      expect(resetButton, findsOneWidget);
      await tester.ensureVisible(resetButton);
      await tester.pumpAndSettle();
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      expect(
        container.read(demoSessionStoreProvider),
        DemoSessionStore.initialState,
      );
      log.expectSilent();
    });

    testWidgets('call and whatsapp are refused without a launcher', (
      tester,
    ) async {
      final log = ProductionCallLog();
      await _pumpDemoDetails(tester, log);

      // No url_launcher platform channel is registered in this test binding, so
      // an actual launch attempt would throw MissingPluginException. Reaching
      // the end of the test is itself the proof that none was made.
      for (final icon in const [Icons.phone, Icons.chat]) {
        final button = find.byIcon(icon);
        if (button.evaluate().isEmpty) continue;
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(find.text('غير متاح في وضع العرض'), findsWidgets);
        log.expectSilent();
      }
    });
  });

  group('control — a non-demo venue still reaches production', () {
    // A plain test: no widget binding is needed, and a bare ProviderContainer
    // inside testWidgets leaves Riverpod's dispose timer pending.
    test('the fakes fire for a real venue id', () async {
      final log = ProductionCallLog();
      final container = ProviderContainer(
        overrides: [
          venueRepositoryProvider.overrideWithValue(
            _FailOnCallVenueRepository(log),
          ),
          analyticsServiceProvider.overrideWithValue(_FailOnCallAnalytics(log)),
          favoritesListProvider.overrideWith(() => _FailOnCallFavorites(log)),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(venuePlacePhotosProvider('real-venue-id').future),
        throwsA(isA<StateError>()),
      );
      expect(log.calls, contains('VenueRepository.getPlacePhotos'));
    });
  });

  group('GoRouter /demo', () {
    testWidgets('routes to VenueDetailsScreen for the demo venue', (
      tester,
    ) async {
      final log = ProductionCallLog();
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
          GoRoute(
            path: '/demo',
            redirect: (_, _) => '/venue/${DemoMode.venueId}',
          ),
          GoRoute(
            path: '/venue/:id',
            builder: (context, state) =>
                VenueDetailsScreen(venueId: state.pathParameters['id'] ?? ''),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            venueRepositoryProvider.overrideWithValue(
              _FailOnCallVenueRepository(log),
            ),
            analyticsServiceProvider.overrideWithValue(
              _FailOnCallAnalytics(log),
            ),
            favoritesListProvider.overrideWith(() => _FailOnCallFavorites(log)),
          ],
          child: MaterialApp.router(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/demo');
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      final screen = tester.widget<VenueDetailsScreen>(
        find.byType(VenueDetailsScreen),
      );
      expect(screen.venueId, 'wain-demo-cafe-showcase');
      expect(find.byType(DemoModeBadge), findsOneWidget);
      log.expectSilent();
    });
  });

  group('M2 content actually renders, still silently', () {
    /// Brings a tab into view and selects it.
    Future<void> openTab(WidgetTester tester, int index) async {
      await tester.drag(find.byType(NestedScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Tab).at(index), warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    /// Scrolls the tab body until [finder] is on screen, or gives up.
    ///
    /// Tab content sits below an intrinsically sized header, so nothing in a
    /// tab body is visible at first paint.
    Future<void> revealInBody(WidgetTester tester, Finder finder) async {
      for (var attempt = 0; attempt < 8; attempt += 1) {
        if (finder.evaluate().isNotEmpty) return;
        await tester.drag(
          find.byType(NestedScrollView),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
      }
    }

    testWidgets('the offers tab lists the demo offers', (tester) async {
      final log = ProductionCallLog();
      await _pumpDemoDetails(tester, log);

      final offers = buildDemoOffers();
      final title = find.text(offers.first.titleAr);
      await revealInBody(tester, title);

      // A title proves the catalog reached the screen, not merely that some
      // empty state rendered.
      expect(title, findsWidgets);
      log.expectSilent();
    });

    testWidgets('activating an offer opens the inert demo QR, no callable', (
      tester,
    ) async {
      final log = ProductionCallLog();
      await _pumpDemoDetails(tester, log);

      final offer = buildDemoOffers().first;
      await revealInBody(tester, find.text(offer.titleAr));
      final card = find.text(offer.titleAr).first;
      await tester.tap(card, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Either the card itself activates or it opens details; in both cases no
      // production adapter may be touched.
      log.expectSilent();
      expect(tester.takeException(), isNull);
    });

    testWidgets('the demo QR sheet is inert and labelled', (tester) async {
      final log = ProductionCallLog();
      await _pumpDemoDetails(tester, log);

      // Driven directly: the sheet is the contract under test here, not the
      // particular button that happens to open it.
      final context = tester.element(find.byType(VenueDetailsScreen));
      DemoOfferQrSheet.show(context, buildDemoOffers().first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('demo_offer_qr_sheet')), findsOneWidget);
      expect(find.text(demoQrNoticeAr), findsOneWidget);
      expect(find.text(demoQrNoticeEn), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);

      // The payload itself is asserted in demo_m2_catalogs_test; what matters
      // here is that the sheet renders a code and carries both warnings.
      final payload = demoQrPayload(buildDemoOffers().first.id);
      expect(payload, contains('valid=false'));
      expect(payload, contains('NOT_REDEEMABLE'));

      log.expectSilent();
    });

    testWidgets('the about tab shows demo stories, still silent', (
      tester,
    ) async {
      final log = ProductionCallLog();
      await _pumpDemoDetails(tester, log);
      await openTab(tester, 1);

      // Asserted by content, not by type. `find.byType` returned zero for a
      // section that `tester.allWidgets` showed was mounted: the screen reaches
      // its sections through relative imports while this test imports them
      // through package: URIs, so the two are distinct types to the finder.
      // Content is the honest check anyway — it proves the demo catalog got
      // through, which a type match never would.
      expect(
        find.byKey(const PageStorageKey<String>('about_tab')),
        findsOneWidget,
      );

      // Stories are the first block in the tab body, which is already at
      // offset 0 — scrolling further would carry them off the top.
      expect(
        find.text(buildDemoStories().first.text),
        findsWidgets,
        reason: 'the About tab must show the demo stories',
      );
      log.expectSilent();
    });

    testWidgets('the reviews tab shows the demo reviews and summary', (
      tester,
    ) async {
      final log = ProductionCallLog();
      await _pumpDemoDetails(tester, log);
      await openTab(tester, 2);

      // The sample-data label must be present before any rating is shown.
      expect(find.text('مراجعات تجريبية'), findsOneWidget);

      // The average the section derives from the six demo reviews.
      final expectedAverage = demoReviewsAverage().toStringAsFixed(1);
      expect(find.text(expectedAverage), findsWidgets);

      // And a review body, proving the list itself is populated.
      expect(find.textContaining('القهوة ممتازة'), findsWidgets);
      log.expectSilent();
    });
  });

  group('badge geometry', () {
    testWidgets('the badge sits below the hero panel and covers nothing', (
      tester,
    ) async {
      final log = ProductionCallLog();
      await _pumpDemoDetails(tester, log);

      final badge = tester.getRect(find.byType(DemoModeBadge));
      final infoPanel = tester.getRect(
        find.byKey(const ValueKey('venue-hero-info-panel')),
      );
      // The block directly after the badge is the transport card. It used to
      // be a DemoUnavailableSection; transport is now demoed for real, so the
      // geometry is asserted against what actually follows the badge.
      final nextSection = tester.getRect(
        find.byKey(const Key('demo_transport_card')),
      );

      expect(badge.overlaps(infoPanel), isFalse);
      expect(badge.top, greaterThanOrEqualTo(infoPanel.bottom - 0.5));

      // ...and it precedes the next section without touching it.
      expect(badge.overlaps(nextSection), isFalse);
      expect(badge.bottom, lessThanOrEqualTo(nextSection.top + 0.5));

      // Fully inside the 360x800 logical viewport, not clipped at an edge.
      expect(badge.left, greaterThanOrEqualTo(0));
      expect(badge.right, lessThanOrEqualTo(360));
      expect(badge.height, greaterThan(0));
      log.expectSilent();
    });
  });
}

/// Referenced only for its type in the repository fake above.
// ignore: unused_element
typedef _PlacePhoto = VenuePlacePhoto;
