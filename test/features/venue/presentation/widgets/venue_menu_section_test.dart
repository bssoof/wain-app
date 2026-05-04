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
    testWidgets('renders section names with counts and returns selected id', (
      tester,
    ) async {
      String? selectedId;
      const hotDrinks = 'مشروبات ساخنة';
      const desserts = 'حلويات';
      final sections = [
        const MenuSection(id: 'hot_drinks', nameAr: hotDrinks),
        const MenuSection(id: 'desserts', nameAr: desserts),
      ];

      await tester.pumpWidget(
        _app(
          VenueMenuCategoryChips(
            sections: sections,
            selectedSectionId: 'all',
            onSelected: (value) => selectedId = value,
            totalCount: 7,
            sectionItemCounts: const {'hot_drinks': 4, 'desserts': 3},
          ),
        ),
      );

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      expect(find.text('${l10n.all} (7)'), findsOneWidget);
      expect(find.text('$hotDrinks (4)'), findsOneWidget);
      expect(find.text('$desserts (3)'), findsOneWidget);

      await tester.tap(find.text('$desserts (3)'));
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
