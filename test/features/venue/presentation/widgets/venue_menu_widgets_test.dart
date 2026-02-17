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
  group('VenueMenuItemTile', () {
    testWidgets('renders item name, description, and price', (tester) async {
      const item = MenuItem(
        id: 'item1',
        nameAr: 'قهوة عربية',
        descriptionAr: 'قهوة طازجة محمصة يدوياً',
        price: 12.0,
        currency: 'ILS',
        category: 'hot_drinks',
      );

      await tester.pumpWidget(
        _app(const SingleChildScrollView(child: VenueMenuItemTile(item: item))),
      );

      expect(find.text('قهوة عربية'), findsOneWidget);
      expect(find.text('قهوة طازجة محمصة يدوياً'), findsOneWidget);
      expect(find.text('12.0 ILS'), findsOneWidget);
    });

    testWidgets('hides description when empty', (tester) async {
      const item = MenuItem(
        id: 'item2',
        nameAr: 'شاي أخضر',
        descriptionAr: '',
        price: 8.0,
        currency: 'ILS',
        category: 'hot_drinks',
      );

      await tester.pumpWidget(
        _app(const SingleChildScrollView(child: VenueMenuItemTile(item: item))),
      );

      expect(find.text('شاي أخضر'), findsOneWidget);
      expect(find.text('8.0 ILS'), findsOneWidget);
      final textWidgets = tester.widgetList<Text>(find.byType(Text)).toList();
      expect(textWidgets.any((t) => t.data == ''), isFalse);
    });
  });

  group('VenueMenuSectionBlock', () {
    testWidgets('renders section header and all items', (tester) async {
      const section = MenuSection(
        id: 'hot_drinks',
        nameAr: 'مشروبات ساخنة',
        icon: 'coffee',
      );
      const items = [
        MenuItem(
          id: 'i1',
          nameAr: 'قهوة تركية',
          price: 10.0,
          currency: 'ILS',
          category: 'hot_drinks',
        ),
        MenuItem(
          id: 'i2',
          nameAr: 'لاتيه',
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

      expect(find.byIcon(Icons.coffee), findsOneWidget);
      expect(find.textContaining('مشروبات ساخنة'), findsOneWidget);
      expect(find.text('قهوة تركية'), findsOneWidget);
      expect(find.text('لاتيه'), findsOneWidget);
    });
  });

  group('VenueMenuEmptyState', () {
    testWidgets('renders message text and icon', (tester) async {
      await tester.pumpWidget(
        _app(
          const VenueMenuEmptyState(message: 'لا توجد نتائج مطابقة في المنيو'),
        ),
      );

      expect(find.text('لا توجد نتائج مطابقة في المنيو'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });

  group('VenueMenuHeader', () {
    testWidgets('renders header with item count', (tester) async {
      await tester.pumpWidget(_app(const VenueMenuHeader(itemCount: 42)));

      expect(find.text('المنيو'), findsOneWidget);
      expect(find.text('42 صنف'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
    });

    testWidgets('renders custom counter label', (tester) async {
      await tester.pumpWidget(
        _app(const VenueMenuHeader(itemCount: 3, counterLabel: 'صور')),
      );

      expect(find.text('3 صور'), findsOneWidget);
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
