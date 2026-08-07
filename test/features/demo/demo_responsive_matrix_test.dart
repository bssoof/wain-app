import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/features/demo/data/demo_venue_catalog.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/demo/presentation/demo_badge.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/domain/repositories/venue_repository.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/features/venue/presentation/screens/venue_details_screen.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_hero_header.dart';
import 'package:wain_app/l10n/app_localizations.dart';

/// Names long enough to wrap on the narrowest supported width.
const String _longAr =
    'مقهى وين التجريبي للعرض التقديمي في مدينة رام الله والبيرة';
const String _longEn =
    'WAIN Demo Café — Presentation Showcase Branch, Ramallah and Al-Bireh';

const List<String> _nineTags = <String>[
  'هادئ',
  'عائلي',
  'رومانسي',
  'شغل',
  'لقاء أصدقاء',
  'صباحي',
  'سهرة',
  'فطور',
  'حلويات',
];

typedef _Size = ({String label, double width, double height});

const List<_Size> _sizes = <_Size>[
  (label: '320x800', width: 320, height: 800),
  (label: '360x800', width: 360, height: 800),
  (label: '390x844', width: 390, height: 844),
];

Venue _venue({required bool longNames}) {
  final base = buildDemoVenue();
  if (!longNames) return base;
  return base.copyWith(nameAr: _longAr, nameEn: _longEn);
}

/// Drains every exception the binding has buffered since the last drain.
///
/// `takeException` returns one at a time, so a single call can leave a second
/// overflow sitting in the queue and make the case look clean.
List<Object> _drain(WidgetTester tester) {
  final errors = <Object>[];
  Object? exception;
  while ((exception = tester.takeException()) != null) {
    errors.add(exception!);
  }
  return errors;
}

Future<List<Object>> _pumpHero(
  WidgetTester tester, {
  required _Size size,
  required TextDirection direction,
  required double textScale,
  required List<String> tags,
  required bool longNames,
}) async {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: Locale(direction == TextDirection.rtl ? 'ar' : 'en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(size.width, size.height),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: CustomScrollView(
                // Logical pixels. Generous enough that the hero, the badge, and
                // the next block are all built on every surface in the matrix,
                // so geometry can be measured at rest instead of scrolled to.
                cacheExtent: size.height * 3,
                slivers: [
                  VenueHeroHeader(
                    venue: _venue(longNames: longNames),
                    isFavorite: false,
                    displayTags: tags,
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: DemoModeBadge(),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: SizedBox(
                        key: Key('next_section'),
                        height: 80,
                        child: ColoredBox(color: Color(0xFFEEEEEE)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  final errors = <Object>[..._drain(tester)];
  await tester.pump();
  errors.addAll(_drain(tester));
  await tester.pumpAndSettle();
  errors.addAll(_drain(tester));
  return errors;
}

/// Stubs that keep the screen off Firebase without asserting anything: this
/// file is about layout, and `demo_screen_isolation_test` already owns the
/// question of whether production is reached.
class _InertVenueRepository implements VenueRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('production VenueRepository reached from the demo');
}

class _InertAnalytics implements AnalyticsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _InertFavorites extends FavoritesList {
  @override
  Future<List<String>> build() async => <String>[];
}

/// Pumps the whole demo venue screen at [size], not just the hero.
///
/// The hero matrix above covers one sliver. Three "Row of fixed-width children"
/// overflows have already been found by scrolling the real screen on a narrow
/// device, so the sweep below walks every section of every tab at the narrowest
/// supported widths and the largest text scale users can pick, and fails on any
/// exception the binding buffers along the way.
Future<List<Object>> _sweepDemoScreen(
  WidgetTester tester, {
  required _Size size,
  required double textScale,
}) async {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        venueRepositoryProvider.overrideWithValue(_InertVenueRepository()),
        analyticsServiceProvider.overrideWithValue(_InertAnalytics()),
        favoritesListProvider.overrideWith(_InertFavorites.new),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(size.width, size.height),
            textScaler: TextScaler.linear(textScale),
          ),
          child: const VenueDetailsScreen(venueId: DemoMode.venueId),
        ),
      ),
    ),
  );

  final errors = <Object>[];
  await tester.pump();
  await tester.pumpAndSettle();
  errors.addAll(_drain(tester));

  for (var index = 0; index < 3; index += 1) {
    await tester.drag(find.byType(NestedScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    errors.addAll(_drain(tester));

    final tabs = find.byType(Tab);
    if (tabs.evaluate().length == 3) {
      await tester.tap(tabs.at(index), warnIfMissed: false);
      await tester.pumpAndSettle();
      errors.addAll(_drain(tester));
    }

    // Walk the tab body: a section only overflows once it has been laid out,
    // and the tallest tabs are several screens long.
    for (var step = 0; step < 8; step += 1) {
      await tester.drag(find.byType(NestedScrollView), const Offset(0, -320));
      await tester.pumpAndSettle();
      errors.addAll(_drain(tester));
    }

    await tester.drag(find.byType(NestedScrollView), const Offset(0, 4000));
    await tester.pumpAndSettle();
    errors.addAll(_drain(tester));
  }

  return errors;
}

void main() {
  group('demo hero — responsive matrix', () {
    for (final size in _sizes) {
      for (final direction in TextDirection.values) {
        for (final textScale in const <double>[1.0, 1.3]) {
          for (final tagCase in const <({String label, int count})>[
            (label: 'tags:0', count: 0),
            (label: 'tags:2', count: 2),
            (label: 'tags:9', count: 9),
          ]) {
            final name =
                '${size.label} ${direction.name} scale$textScale '
                '${tagCase.label}';

            testWidgets('$name lays out without overflow', (tester) async {
              final errors = await _pumpHero(
                tester,
                size: size,
                direction: direction,
                textScale: textScale,
                tags: _nineTags.take(tagCase.count).toList(),
                longNames: true,
              );

              expect(errors, isEmpty, reason: name);

              final panel = tester.getRect(
                find.byKey(const ValueKey('venue-hero-info-panel')),
              );
              final badge = tester.getRect(find.byType(DemoModeBadge));

              // The panel took its intrinsic height rather than being squeezed.
              expect(panel.height, greaterThan(0), reason: name);
              // The image band ends where the panel starts: no overlap.
              expect(panel.top, greaterThanOrEqualTo(249.5), reason: name);
              // The badge sits strictly between the panel and the next block.
              expect(badge.overlaps(panel), isFalse, reason: name);
              expect(badge.top, greaterThanOrEqualTo(panel.bottom - 0.5),
                  reason: name);
              final nextFinder = find.byKey(const Key('next_section'));
              expect(nextFinder, findsOneWidget, reason: name);

              final next = tester.getRect(nextFinder);
              expect(badge.overlaps(next), isFalse, reason: name);
              expect(
                badge.bottom,
                lessThanOrEqualTo(next.top + 0.5),
                reason: name,
              );
              // Nothing is clipped sideways.
              expect(panel.left, greaterThanOrEqualTo(-0.5), reason: name);
              expect(panel.right, lessThanOrEqualTo(size.width + 0.5),
                  reason: name);
            });
          }
        }
      }
    }

    testWidgets('the +N control appears only when tags overflow', (
      tester,
    ) async {
      // Two tags fit, so no overflow affordance is offered.
      await _pumpHero(
        tester,
        size: _sizes[1],
        direction: TextDirection.rtl,
        textScale: 1.0,
        tags: _nineTags.take(2).toList(),
        longNames: false,
      );
      expect(find.textContaining('+'), findsNothing);

      // Nine tags do not, so it is.
      await _pumpHero(
        tester,
        size: _sizes[1],
        direction: TextDirection.rtl,
        textScale: 1.0,
        tags: _nineTags,
        longNames: false,
      );
      final overflowChip = find.textContaining('+');
      expect(overflowChip, findsWidgets);

      await tester.tap(overflowChip.first);
      await tester.pumpAndSettle();
      expect(_drain(tester), isEmpty, reason: 'opening the +N sheet');
      // Every tag becomes reachable once the sheet is open.
      for (final tag in _nineTags) {
        expect(find.text(tag), findsWidgets, reason: 'tag "$tag" missing');
      }
    });
  });

  group('demo screen — every section, every tab', () {
    for (final size in _sizes) {
      for (final textScale in const <double>[1.0, 1.3]) {
        final name = '${size.label} scale$textScale';

        testWidgets('$name scrolls end to end without overflow', (tester) async {
          final errors = await _sweepDemoScreen(
            tester,
            size: size,
            textScale: textScale,
          );

          expect(errors, isEmpty, reason: name);
        });
      }
    }
  });
}
