import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/core/widgets/search_clear_button.dart';
import 'package:wain_app/l10n/app_localizations.dart';

void main() {
  testWidgets('renders an accessible x button and clears on tap', (
    tester,
  ) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SearchClearButton(onPressed: () => tapCount++)),
      ),
    );

    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byTooltip('مسح البحث'), findsOneWidget);

    await tester.tap(find.byType(SearchClearButton));
    expect(tapCount, 1);
  });
}
