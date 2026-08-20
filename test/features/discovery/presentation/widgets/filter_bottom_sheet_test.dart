import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/discovery/presentation/widgets/filter_bottom_sheet.dart';
import 'package:wain_app/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'filter sheet keeps its primary actions visible on a short phone',
    (tester) async {
      tester.view.physicalSize = const Size(606, 870);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: _FilterSheetTestHost(),
          ),
        ),
      );

      await tester.tap(find.text('افتح الفلاتر'));
      await tester.pumpAndSettle();

      expect(find.text('تصفية وترتيب'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.text('شوف الاقتراحات'), findsOneWidget);
      expect(find.text('التقييم'), findsOneWidget);
      expect(find.text('المسافة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _FilterSheetTestHost extends StatelessWidget {
  const _FilterSheetTestHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => showFilterBottomSheet(context, preResultsFlow: true),
          child: const Text('افتح الفلاتر'),
        ),
      ),
    );
  }
}
