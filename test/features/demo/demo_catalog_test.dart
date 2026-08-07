import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/demo/data/demo_busy_times_catalog.dart';
import 'package:wain_app/features/demo/data/demo_catalog_validators.dart';
import 'package:wain_app/features/demo/data/demo_venue_catalog.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/menu/data/demo_menu_catalog.dart';

/// The published venue the demo used to borrow. Nothing may point at it again.
const String _productionVenueId = 'ramallah-cafe-8c061a8cca7fb2c8e16b';

void main() {
  group('demo catalog contracts', () {
    test('all catalog invariants hold', () {
      expect(validateDemoCatalogs(), isEmpty);
    });

    test('every declared asset exists on disk', () {
      final missing = demoAssetPaths()
          .where((path) => !File(path).existsSync())
          .toList();
      expect(missing, isEmpty, reason: 'missing demo assets: $missing');
    });

    test('menu covers 6 sections and 24 customer-visible items', () {
      expect(demoMenuSections, hasLength(6));
      expect(demoMenuItems.where((i) => i.isAvailable), hasLength(24));
    });

    test('the unavailable item is hidden from customers', () {
      final unavailable =
          demoMenuItems.where((item) => !item.isAvailable).toList();
      expect(unavailable, isNotEmpty);
      for (final item in unavailable) {
        expect(
          demoMenuItems
              .where((i) => i.isAvailable)
              .map((i) => i.id)
              .contains(item.id),
          isFalse,
          reason: '"${item.id}" must not reach the customer menu',
        );
      }
    });
  });

  group('demo isolation from production', () {
    test('the demo venue is not a published venue', () {
      expect(DemoMode.venueId, isNot(_productionVenueId));
      expect(demoMenuVenueId, DemoMode.venueId);
      expect(buildDemoVenue().id, DemoMode.venueId);
    });

    test('shouldUseDemoMenu rejects every other venue id', () {
      expect(shouldUseDemoMenu(_productionVenueId), isFalse);
      expect(shouldUseDemoMenu('some-other-venue'), isFalse);
      expect(shouldUseDemoMenu(''), isFalse);
      // kDebugMode is true under `flutter test`, so the positive case is the
      // meaningful one to assert here; the release gate is covered below.
      expect(shouldUseDemoMenu(DemoMode.venueId), isTrue);
    });

    test('the demo module never reaches Firestore or Functions', () {
      // The merchant adapters override production repository methods, and two
      // of those signatures carry Firestore's `Source` enum — a cache
      // preference that performs nothing. That single type-only import is
      // named here rather than the rule being relaxed, so a new demo file
      // cannot inherit the allowance by accident. Every other banned token,
      // including anything that could actually issue a call, still applies to
      // the whole module.
      const typeOnlyFirestoreImport = <String>{
        'demo_merchant_repositories.dart',
      };

      final offenders = <String>[];
      final demoDir = Directory('lib/features/demo');
      expect(demoDir.existsSync(), isTrue);

      for (final entity in demoDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        final fileName = entity.uri.pathSegments.last;

        for (final banned in const <String>[
          'FirebaseFirestore',
          'FirebaseFunctions',
          'FirebaseStorage',
          'httpsCallable',
          'cloud_firestore',
          'cloud_functions',
          'package:http',
        ]) {
          if (banned == 'cloud_firestore' &&
              typeOnlyFirestoreImport.contains(fileName)) {
            continue;
          }
          if (source.contains(banned)) {
            offenders.add('${entity.path} -> $banned');
          }
        }
      }
      expect(offenders, isEmpty, reason: 'demo data must stay local');
    });

    test('the type-only Firestore allowance stays type-only', () {
      // The allowance above is only defensible while the file imports the
      // enum and nothing else: no instance, no collection, no query.
      final source = File(
        'lib/features/demo/data/demo_merchant_repositories.dart',
      ).readAsStringSync();

      for (final banned in const <String>[
        '.instance',
        '.collection(',
        '.doc(',
        '.snapshots(',
        'GetOptions',
      ]) {
        expect(
          source.contains(banned),
          isFalse,
          reason: 'demo merchant adapters must not perform "$banned"',
        );
      }
    });

    test('release builds cannot reach the demo', () {
      // DemoMode.isEnabled is the single gate; it is wired to kDebugMode, which
      // is a const false in release, so the whole module is tree-shaken.
      final source = File('lib/features/demo/demo_mode.dart').readAsStringSync();
      expect(source, contains('static bool get isEnabled => kDebugMode;'));
      expect(
        source,
        contains('isDemoVenue(String? id) => isEnabled && id == venueId'),
      );
    });
  });

  group('demo busy times', () {
    test('is a full 7 x 24 histogram', () {
      final busyTimes = buildDemoBusyTimes();
      final histogram = busyTimes.histogram!;
      expect(histogram.keys.toSet(), demoBusyTimesDayKeys.toSet());
      for (final entry in histogram.entries) {
        expect(entry.value, hasLength(24), reason: 'day ${entry.key}');
        for (final value in entry.value) {
          expect(value, inInclusiveRange(0.0, 1.0));
        }
      }
    });

    test('is usable and carries a current label and best-visit windows', () {
      final busyTimes = buildDemoBusyTimes();
      expect(busyTimes.isUsable, isTrue);
      expect(busyTimes.currentTypicalLabel, isNotNull);
      expect(busyTimes.bestVisitWindowsByDay!.keys.toSet(),
          demoBusyTimesDayKeys.toSet());
    });

    test('timestamps are fixed, not wall-clock derived', () {
      final first = buildDemoBusyTimes();
      final second = buildDemoBusyTimes();
      expect(first.lastComputedAt, second.lastComputedAt);
      expect(first.computedFrom, DateTime.utc(2026, 7, 1));
    });
  });
}
