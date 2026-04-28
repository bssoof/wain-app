import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/providers/offline_providers.dart';
import 'package:wain_app/core/widgets/offline_widgets.dart';
import 'package:wain_app/l10n/app_localizations.dart';

Widget _buildTestApp({required bool isOnline, required Widget child}) {
  return ProviderScope(
    overrides: [isOnlineProvider.overrideWithValue(isOnline)],
    child: MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('OfflineBanner', () {
    testWidgets('hides cached-copy age by default', (tester) async {
      final oldFetchedAt = DateTime.now().subtract(const Duration(hours: 8));

      await tester.pumpWidget(
        _buildTestApp(
          isOnline: false,
          child: OfflineBanner(fetchedAt: oldFetchedAt),
        ),
      );

      expect(find.textContaining('آخر نسخة محفوظة'), findsOneWidget);
      expect(find.textContaining('8'), findsNothing);
      expect(find.textContaining('ساعة'), findsNothing);
    });

    testWidgets('explains server update failure when cache is shown online', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          isOnline: true,
          child: const OfflineBanner(isVisible: true),
        ),
      );

      expect(find.textContaining('تعذر تحديث البيانات'), findsOneWidget);
      expect(find.textContaining('أنت غير متصل'), findsNothing);
    });

    testWidgets('can show cached-copy age when explicitly requested', (
      tester,
    ) async {
      final oldFetchedAt = DateTime.now().subtract(const Duration(hours: 8));

      await tester.pumpWidget(
        _buildTestApp(
          isOnline: false,
          child: OfflineBanner(fetchedAt: oldFetchedAt, showCacheAge: true),
        ),
      );

      expect(find.textContaining('منذ 8 ساعة'), findsOneWidget);
    });
  });
}
