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
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('VenueMenuCategoryChips', () {
    testWidgets('renders text-only section tabs and returns selected id', (
      tester,
    ) async {
      String? selectedId;
      const hotDrinks = 'مشروبات ساخنة';
      const desserts = 'حلويات';
      final sections = [
        const MenuSection(id: 'hot_drinks', nameAr: hotDrinks, icon: 'coffee'),
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
      expect(find.text(l10n.all), findsOneWidget);
      expect(find.text(hotDrinks), findsOneWidget);
      expect(find.text(desserts), findsOneWidget);
      expect(find.textContaining('(7)'), findsNothing);
      expect(find.textContaining('(4)'), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.byIcon(Icons.apps_rounded), findsNothing);
      expect(find.byIcon(Icons.coffee_rounded), findsNothing);
      expect(find.byIcon(Icons.cake_rounded), findsNothing);

      await tester.tap(find.text(desserts));
      await tester.pumpAndSettle();

      expect(selectedId, 'desserts');
    });

    testWidgets('does not render icons for text-only category tabs', (
      tester,
    ) async {
      const section = MenuSection(
        id: 'chef_specials',
        nameAr: 'اختيارات الشيف',
        icon: 'unknown-custom-icon',
      );

      await tester.pumpWidget(
        _app(
          VenueMenuCategoryChips(
            sections: const [section],
            selectedSectionId: 'all',
            onSelected: (_) {},
            totalCount: 1,
            sectionItemCounts: const {'chef_specials': 1},
          ),
        ),
      );

      expect(find.text('اختيارات الشيف'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu_rounded), findsNothing);
    });

    testWidgets('updates selected section without breaking auto scroll', (
      tester,
    ) async {
      const sections = [
        MenuSection(id: 'hot_drinks', nameAr: 'مشروبات ساخنة'),
        MenuSection(id: 'desserts', nameAr: 'حلويات'),
        MenuSection(id: 'main_courses', nameAr: 'أطباق رئيسية'),
      ];

      await tester.pumpWidget(
        _app(
          VenueMenuCategoryChips(
            sections: sections,
            selectedSectionId: 'all',
            onSelected: (_) {},
            totalCount: 9,
            sectionItemCounts: const {
              'hot_drinks': 3,
              'desserts': 2,
              'main_courses': 4,
            },
          ),
        ),
      );

      await tester.pumpWidget(
        _app(
          VenueMenuCategoryChips(
            sections: sections,
            selectedSectionId: 'main_courses',
            onSelected: (_) {},
            totalCount: 9,
            sectionItemCounts: const {
              'hot_drinks': 3,
              'desserts': 2,
              'main_courses': 4,
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text('أطباق رئيسية'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps long mixed labels stable in RTL phone viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const longName = 'Cappuccino كابتشينو ومشروبات ساخنة طويلة جداً';

      await tester.pumpWidget(
        _app(
          VenueMenuCategoryChips(
            sections: const [
              MenuSection(id: 'hot_drinks', nameAr: longName),
              MenuSection(id: 'desserts', nameAr: 'حلويات'),
            ],
            selectedSectionId: 'hot_drinks',
            onSelected: (_) {},
            totalCount: 7,
            sectionItemCounts: const {'hot_drinks': 4, 'desserts': 3},
          ),
        ),
      );
      await tester.pump();

      expect(
        Directionality.of(tester.element(find.byType(VenueMenuCategoryChips))),
        TextDirection.rtl,
      );
      expect(find.text(longName), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('VenueMenuSearchField', () {
    testWidgets('shows count label and invokes onChanged and onClear', (
      tester,
    ) async {
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
            countLabel: '64 صنف',
          ),
        ),
      );

      expect(find.text('64 صنف'), findsOneWidget);

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
