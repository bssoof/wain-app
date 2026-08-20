import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/core/providers/location_provider.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/features/demo/data/demo_venue_catalog.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_hero_header.dart';
import 'package:wain_app/l10n/app_localizations.dart';

/// The channel share_plus actually talks to. Counting calls on it proves the
/// OS share sheet was never invoked, without inventing a production
/// abstraction that exists only for the test.
const MethodChannel _shareChannel = MethodChannel(
  'dev.fluttercommunity.plus/share',
);

class _CallLog {
  final List<String> calls = <String>[];
  Never record(String what) {
    calls.add(what);
    throw StateError('production $what reached from the demo');
  }
}

class _FailOnCallAnalytics implements AnalyticsService {
  _FailOnCallAnalytics(this.log);
  final _CallLog log;

  @override
  dynamic noSuchMethod(Invocation invocation) => log.record(
    'AnalyticsService.'
    '${invocation.memberName.toString().replaceAll(RegExp(r'Symbol\("|"\)'), '')}',
  );
}

Venue _realVenue() => buildDemoVenue().copyWith(id: 'real-venue-id');

Widget _hostHeroWithAnalytics(Venue venue, _CallLog log) {
  return ProviderScope(
    overrides: [
      analyticsServiceProvider.overrideWithValue(_FailOnCallAnalytics(log)),
    ],
    child: _heroScaffold(venue),
  );
}

Widget _hostHeroWithLocation(
  Venue venue,
  Stream<UserLocation> Function(Ref) create,
) {
  return ProviderScope(
    overrides: [userLocationProvider.overrideWith(create)],
    child: _heroScaffold(venue),
  );
}

Widget _heroScaffold(Venue venue) {
  return MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            VenueHeroHeader(
              venue: venue,
              isFavorite: false,
              displayTags: const <String>['هادئ', 'شغل'],
            ),
        ],
      ),
    ),
  );
}

void main() {
  late List<MethodCall> shareCalls;

  setUp(() {
    shareCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, (call) async {
          shareCalls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, null);
  });

  group('Share is inert for the demo venue', () {
    testWidgets('no share channel call, no analytics, clear message', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final log = _CallLog();
      await tester.pumpWidget(_hostHeroWithAnalytics(buildDemoVenue(), log));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.share_outlined));
      await tester.pumpAndSettle();

      expect(shareCalls, isEmpty, reason: 'share channel calls: $shareCalls');
      expect(log.calls, isEmpty, reason: 'analytics calls: ${log.calls}');
      expect(find.text('غير متاح في وضع العرض'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Location is never observed for the demo venue', () {
    testWidgets('the location provider is not built, distance still shows', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var locationBuilds = 0;
      await tester.pumpWidget(
        _hostHeroWithLocation(buildDemoVenue(), (ref) {
          locationBuilds += 1;
          throw StateError('userLocationProvider built for the demo');
        }),
      );
      await tester.pumpAndSettle();

      expect(locationBuilds, 0);
      expect(find.textContaining('1.2'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('control — a real venue does build the location provider', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var locationBuilds = 0;
      await tester.pumpWidget(
        _hostHeroWithLocation(_realVenue(), (ref) {
          locationBuilds += 1;
          return Stream<UserLocation>.value(
            const UserLocation(latitude: 31.9, longitude: 35.2),
          );
        }),
      );
      await tester.pumpAndSettle();

      expect(
        locationBuilds,
        1,
        reason: 'the override must be wired up, otherwise the demo test above '
            'would be green for the wrong reason',
      );
    });
  });

  group('demo id gate', () {
    test('only the demo venue id is treated as demo', () {
      expect(DemoMode.isDemoVenue(DemoMode.venueId), isTrue);
      expect(DemoMode.isDemoVenue('real-venue-id'), isFalse);
    });
  });
}
