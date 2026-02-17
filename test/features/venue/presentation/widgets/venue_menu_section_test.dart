import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/menu/domain/entities/menu_section.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_section.dart';
import 'package:wain_app/l10n/app_localizations.dart';

Widget _app(Widget child) {
  return MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('VenueMenuCategoryChips', () {
    testWidgets('renders section names and returns selected id', (
      tester,
    ) async {
      String? selectedId;
      final sections = [
        const MenuSection(id: 'hot_drinks', nameAr: 'مشروبات ساخنة'),
        const MenuSection(id: 'desserts', nameAr: 'حلويات'),
      ];

      await tester.pumpWidget(
        _app(
          VenueMenuCategoryChips(
            sections: sections,
            selectedSectionId: 'all',
            onSelected: (value) => selectedId = value,
          ),
        ),
      );

      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('مشروبات ساخنة'), findsOneWidget);
      expect(find.text('حلويات'), findsOneWidget);

      await tester.tap(find.text('حلويات'));
      await tester.pumpAndSettle();

      expect(selectedId, 'desserts');
    });
  });

  group('VenueMenuSearchField', () {
    testWidgets('invokes onChanged and onClear', (tester) async {
      final controller = TextEditingController();
      String latestValue = '';
      var cleared = false;

      await tester.pumpWidget(
        _app(
          VenueMenuSearchField(
            controller: controller,
            onChanged: (value) => latestValue = value,
            onClear: () {
              controller.clear();
              cleared = true;
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'قهوة');
      await tester.pumpAndSettle();

      expect(latestValue, 'قهوة');

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(cleared, isTrue);
      expect(controller.text, isEmpty);
    });
  });
}
