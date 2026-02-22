import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
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
  const coffeeName = '\u0642\u0647\u0648\u0629 \u0639\u0631\u0628\u064a\u0629';
  const coffeeDesc =
      '\u0642\u0647\u0648\u0629 \u0637\u0627\u0632\u062c\u0629 \u0645\u062d\u0645\u0635\u0629 \u064a\u062f\u0648\u064a\u0627\u064b';
  const teaName = '\u0634\u0627\u064a \u0623\u062e\u0636\u0631';
  const sectionName =
      '\u0645\u0634\u0631\u0648\u0628\u0627\u062a \u0633\u0627\u062e\u0646\u0629';
  const emptyMessage =
      '\u0644\u0627 \u062a\u0648\u062c\u062f \u0646\u062a\u0627\u0626\u062c \u0645\u0637\u0627\u0628\u0642\u0629 \u0641\u064a \u0627\u0644\u0645\u0646\u064a\u0648';

  group('VenueMenuItemTile', () {
    testWidgets('renders item name, description, and formatted price', (
      tester,
    ) async {
      const item = MenuItem(
        id: 'item1',
        nameAr: coffeeName,
        descriptionAr: coffeeDesc,
        price: 12.0,
        currency: 'ILS',
        category: 'hot_drinks',
      );

      await tester.pumpWidget(
        _app(const SingleChildScrollView(child: VenueMenuItemTile(item: item))),
      );

      expect(find.text(coffeeName), findsOneWidget);
      expect(find.text('12 ILS'), findsOneWidget);
      expect(find.text(coffeeDesc), findsOneWidget);
    });

    testWidgets('hides description when empty', (tester) async {
      const item = MenuItem(
        id: 'item2',
        nameAr: teaName,
        descriptionAr: '',
        price: 8.0,
        currency: 'ILS',
        category: 'hot_drinks',
      );

      await tester.pumpWidget(
        _app(const SingleChildScrollView(child: VenueMenuItemTile(item: item))),
      );

      expect(find.text(teaName), findsOneWidget);
      expect(find.text('8 ILS'), findsOneWidget);
      expect(find.text(coffeeDesc), findsNothing);
    });
  });

  group('VenueMenuSectionBlock', () {
    testWidgets('renders section header and all items', (tester) async {
      const section = MenuSection(
        id: 'hot_drinks',
        nameAr: sectionName,
        icon: 'coffee',
      );
      const items = [
        MenuItem(
          id: 'i1',
          nameAr: '\u0642\u0647\u0648\u0629 \u062a\u0631\u0643\u064a\u0629',
          price: 10.0,
          currency: 'ILS',
          category: 'hot_drinks',
        ),
        MenuItem(
          id: 'i2',
          nameAr: '\u0644\u0627\u062a\u064a\u0647',
          price: 15.0,
          currency: 'ILS',
          category: 'hot_drinks',
        ),
      ];

      await tester.pumpWidget(
        _app(
          const SingleChildScrollView(
            child: VenueMenuSectionBlock(section: section, items: items),
          ),
        ),
      );

      expect(find.byIcon(Icons.coffee), findsNothing);
      expect(find.text(sectionName), findsOneWidget);
      expect(
        find.text('\u0642\u0647\u0648\u0629 \u062a\u0631\u0643\u064a\u0629'),
        findsOneWidget,
      );
      expect(find.text('\u0644\u0627\u062a\u064a\u0647'), findsOneWidget);
    });
  });

  group('VenueMenuEmptyState', () {
    testWidgets('renders message text and icon', (tester) async {
      await tester.pumpWidget(
        _app(const VenueMenuEmptyState(message: emptyMessage)),
      );

      expect(find.text(emptyMessage), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });

  group('VenueMenuHeader', () {
    testWidgets('renders header with item count', (tester) async {
      await tester.pumpWidget(_app(const VenueMenuHeader(itemCount: 42)));

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      expect(find.text(l10n.menuTitle), findsOneWidget);
      expect(find.text('42 ${l10n.menuItemCounter}'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
    });

    testWidgets('renders custom counter label', (tester) async {
      await tester.pumpWidget(
        _app(
          const VenueMenuHeader(
            itemCount: 3,
            counterLabel: '\u0635\u0648\u0631',
          ),
        ),
      );

      expect(find.text('3 \u0635\u0648\u0631'), findsOneWidget);
    });
  });

  group('VenueMenuLoadingSkeleton', () {
    testWidgets('renders without overflow', (tester) async {
      await tester.pumpWidget(
        _app(const SingleChildScrollView(child: VenueMenuLoadingSkeleton())),
      );

      expect(find.byType(Container), findsAtLeastNWidgets(3));
    });
  });

  group('PinnedMenuHeaderDelegate', () {
    test('maxExtent and minExtent equal the provided height', () {
      final delegate = PinnedMenuHeaderDelegate(
        height: 60,
        child: const SizedBox(),
      );

      expect(delegate.maxExtent, 60.0);
      expect(delegate.minExtent, 60.0);
    });

    test('shouldRebuild returns true when child or height changes', () {
      final child1 = const SizedBox(key: ValueKey('a'));
      final child2 = const SizedBox(key: ValueKey('b'));

      final d1 = PinnedMenuHeaderDelegate(height: 60, child: child1);
      final d2 = PinnedMenuHeaderDelegate(height: 60, child: child2);
      final d3 = PinnedMenuHeaderDelegate(height: 70, child: child1);

      expect(d1.shouldRebuild(d2), isTrue);
      expect(d1.shouldRebuild(d3), isTrue);
      expect(d1.shouldRebuild(d1), isFalse);
    });
  });
}
