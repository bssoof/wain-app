import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/domain/entities/menu_section.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_item_details_sheet.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_section.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_ui_constants.dart';
import 'package:wain_app/l10n/app_localizations.dart';

import '../../../../helpers/test_image_http_overrides.dart';

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
  const coffeeName = '\u0642\u0647\u0648\u0629 \u0639\u0631\u0628\u064a\u0629';
  const coffeeDesc =
      '\u0642\u0647\u0648\u0629 \u0637\u0627\u0632\u062c\u0629 \u0645\u062d\u0645\u0635\u0629 \u064a\u062f\u0648\u064a\u0627\u064b';
  const teaName = '\u0634\u0627\u064a \u0623\u062e\u0636\u0631';
  const sectionName =
      '\u0645\u0634\u0631\u0648\u0628\u0627\u062a \u0633\u0627\u062e\u0646\u0629';
  const emptyMessage =
      '\u0644\u0627 \u062a\u0648\u062c\u062f \u0646\u062a\u0627\u0626\u062c \u0645\u0637\u0627\u0628\u0642\u0629 \u0641\u064a \u0627\u0644\u0645\u0646\u064a\u0648';

  group('venue menu helpers', () {
    test('formats supported and unknown currencies for Arabic menu UI', () {
      expect(formatVenueMenuPriceWithCurrency(15, 'ILS'), '15 ₪');
      expect(formatVenueMenuPriceWithCurrency(15, 'JOD'), '15 د.أ');
      expect(formatVenueMenuPriceWithCurrency(15, 'USD'), r'15 US$');
      expect(formatVenueMenuPriceWithCurrency(15, 'EUR'), '15 EUR');
      expect(
        formatVenueMenuPriceWithCurrency(15, 'USD', languageCode: 'en'),
        r'$15',
      );
      expect(
        formatVenueMenuPriceWithCurrency(15, 'LONGCURRENCY'),
        '15 LONGCURR',
      );
    });

    test('maps section icon strings through safe defaults', () {
      expect(venueMenuSectionIcon('coffee'), Icons.coffee_rounded);
      expect(venueMenuSectionIcon('local_cafe'), Icons.coffee_rounded);
      expect(venueMenuSectionIcon('hot_drinks'), Icons.coffee_rounded);
      expect(venueMenuSectionIcon('cake'), Icons.cake_rounded);
      expect(venueMenuSectionIcon('desserts'), Icons.cake_rounded);
      expect(venueMenuSectionIcon('main_courses'), Icons.lunch_dining_rounded);
      expect(
        venueMenuSectionIcon('unknown-custom-icon'),
        Icons.restaurant_menu_rounded,
      );
    });

    test('selects available featured items in deterministic capped order', () {
      const items = [
        MenuItem(
          id: 'z-featured',
          nameAr: 'Z',
          price: 1,
          category: 'hot_drinks',
          isFeatured: true,
          sortOrder: 2,
        ),
        MenuItem(
          id: 'b-featured',
          nameAr: 'B',
          price: 1,
          category: 'hot_drinks',
          isFeatured: true,
          sortOrder: 1,
        ),
        MenuItem(
          id: 'a-featured',
          nameAr: 'A',
          price: 1,
          category: 'hot_drinks',
          isFeatured: true,
          sortOrder: 1,
        ),
        MenuItem(
          id: 'unavailable',
          nameAr: 'Unavailable',
          price: 1,
          category: 'hot_drinks',
          isAvailable: false,
          isFeatured: true,
        ),
        MenuItem(
          id: 'normal',
          nameAr: 'Normal',
          price: 1,
          category: 'hot_drinks',
        ),
      ];

      final selected = selectVenueFeaturedMenuItems(items, limit: 2);

      expect(selected.map((item) => item.id), ['a-featured', 'b-featured']);
    });
  });

  group('VenueMenuItemTile', () {
    testWidgets('renders item name, description, and localized price', (
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
      expect(find.text('12 ₪'), findsOneWidget);
      expect(find.text(coffeeDesc), findsOneWidget);
      expect(find.text('مميز'), findsNothing);
    });

    testWidgets(
      'hides description when empty and shows category placeholder thumbnail',
      (tester) async {
        const item = MenuItem(
          id: 'item2',
          nameAr: teaName,
          descriptionAr: '',
          price: 8.0,
          currency: 'ILS',
          category: 'hot_drinks',
        );

        await tester.pumpWidget(
          _app(
            const SingleChildScrollView(child: VenueMenuItemTile(item: item)),
          ),
        );

        expect(find.text(teaName), findsOneWidget);
        expect(find.text('8 ₪'), findsOneWidget);
        expect(find.text(coffeeDesc), findsNothing);
        expect(find.byIcon(Icons.coffee_rounded), findsOneWidget);
      },
    );

    testWidgets('renders a network image through deterministic test override', (
      tester,
    ) async {
      const item = MenuItem(
        id: 'item-photo',
        nameAr: coffeeName,
        descriptionAr: coffeeDesc,
        price: 12.0,
        currency: 'ILS',
        category: 'hot_drinks',
        photoUrl: 'https://example.test/menu-item.png',
      );

      await runWithTestImageHttpOverrides(() async {
        await tester.pumpWidget(
          _app(
            const SingleChildScrollView(child: VenueMenuItemTile(item: item)),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      });

      expect(find.text(coffeeName), findsOneWidget);
      expect(find.byIcon(Icons.fastfood_rounded), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows featured badge only for featured items', (tester) async {
      const featuredItem = MenuItem(
        id: 'item-featured',
        nameAr: coffeeName,
        descriptionAr: coffeeDesc,
        price: 12.0,
        currency: 'ILS',
        category: 'hot_drinks',
        isFeatured: true,
      );

      await tester.pumpWidget(
        _app(
          const SingleChildScrollView(
            child: VenueMenuItemTile(item: featuredItem),
          ),
        ),
      );

      expect(find.text('مميز'), findsOneWidget);
      expect(find.text('12 ₪'), findsOneWidget);
    });

    testWidgets('supports known and unknown currency display contracts', (
      tester,
    ) async {
      const items = [
        MenuItem(
          id: 'item-jod',
          nameAr: 'ماء',
          price: 2.5,
          currency: 'JOD',
          category: 'drinks',
        ),
        MenuItem(
          id: 'item-usd',
          nameAr: 'حلوى',
          price: 3,
          currency: 'USD',
          category: 'desserts',
        ),
        MenuItem(
          id: 'item-unknown',
          nameAr: 'طبق خاص',
          price: 5,
          currency: 'LONGCURRENCY',
          category: 'main_courses',
        ),
      ];

      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: Column(
              children: [
                for (final item in items) VenueMenuItemTile(item: item),
              ],
            ),
          ),
        ),
      );

      expect(find.text('2.5 د.أ'), findsOneWidget);
      expect(find.text(r'3 US$'), findsOneWidget);
      expect(find.text('5 LONGCURR'), findsOneWidget);
    });

    testWidgets(
      'keeps current tile stable in RTL for mixed Arabic and English',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const item = MenuItem(
          id: 'item-mixed',
          nameAr: 'Cappuccino كابتشينو كبير مع إضافة Extra Shot',
          descriptionAr: 'قهوة عربية Arabic coffee blend محمصة يدوياً',
          price: 12.0,
          currency: 'ILS',
          category: 'hot_drinks',
        );

        await tester.pumpWidget(
          _app(
            const SingleChildScrollView(child: VenueMenuItemTile(item: item)),
          ),
        );
        await tester.pump();

        expect(
          Directionality.of(tester.element(find.byType(VenueMenuItemTile))),
          TextDirection.rtl,
        );
        expect(find.textContaining('Cappuccino'), findsOneWidget);
        expect(find.text('12 ₪'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('VenueMenuItemDetailsSheet', () {
    testWidgets('renders sheet content without a photo using category icon', (
      tester,
    ) async {
      const item = MenuItem(
        id: 'details-item',
        nameAr: coffeeName,
        nameEn: 'Arabic coffee',
        descriptionAr: coffeeDesc,
        price: 12.0,
        currency: 'ILS',
        category: 'hot_drinks',
      );

      await tester.pumpWidget(
        _app(const VenueMenuItemDetailsSheet(item: item)),
      );

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      expect(find.text(coffeeName), findsOneWidget);
      expect(find.text('Arabic coffee'), findsOneWidget);
      expect(find.text(coffeeDesc), findsOneWidget);
      expect(find.text(l10n.priceLabel), findsOneWidget);
      expect(find.text('12 ₪'), findsOneWidget);
      expect(find.byIcon(Icons.coffee_rounded), findsOneWidget);
    });

    testWidgets('renders sheet with image and no overflow', (tester) async {
      const item = MenuItem(
        id: 'details-photo',
        nameAr: coffeeName,
        nameEn: 'Arabic coffee',
        descriptionAr: coffeeDesc,
        price: 15.5,
        currency: 'ILS',
        category: 'hot_drinks',
        photoUrl: 'https://example.test/item.png',
      );

      await runWithTestImageHttpOverrides(() async {
        await tester.pumpWidget(
          _app(const VenueMenuItemDetailsSheet(item: item)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      });

      expect(find.text(coffeeName), findsOneWidget);
      expect(find.text('15.5 ₪'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows featured badge when item is featured', (tester) async {
      const item = MenuItem(
        id: 'details-featured',
        nameAr: coffeeName,
        price: 12.0,
        currency: 'ILS',
        category: 'hot_drinks',
        isFeatured: true,
      );

      await tester.pumpWidget(
        _app(const VenueMenuItemDetailsSheet(item: item)),
      );

      expect(find.text('\u0645\u0645\u064a\u0632'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('hides featured badge when item is not featured', (
      tester,
    ) async {
      const item = MenuItem(
        id: 'details-normal',
        nameAr: coffeeName,
        price: 12.0,
        currency: 'ILS',
        category: 'hot_drinks',
      );

      await tester.pumpWidget(
        _app(const VenueMenuItemDetailsSheet(item: item)),
      );

      expect(find.text('\u0645\u0645\u064a\u0632'), findsNothing);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('uses localized currency formatting for JOD', (tester) async {
      const item = MenuItem(
        id: 'details-jod',
        nameAr: coffeeName,
        price: 5.0,
        currency: 'JOD',
        category: 'desserts',
      );

      await tester.pumpWidget(
        _app(const VenueMenuItemDetailsSheet(item: item)),
      );

      expect(find.text('5 د.أ'), findsOneWidget);
      expect(find.byIcon(Icons.cake_rounded), findsOneWidget);
    });

    testWidgets('handles long Arabic text without overflow in RTL', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const item = MenuItem(
        id: 'details-long',
        nameAr:
            'كابتشينو كبير مع إضافة حليب الشوفان والكراميل المحمص والشوكولاتة',
        nameEn: 'Large Cappuccino with Oat Milk Caramel and Roasted Chocolate',
        descriptionAr:
            'مشروب ساخن مميز محضر من حبوب البن العربي المحمصة يدوياً مع حليب الشوفان الطازج وصوص الكراميل المنزلي والشوكولاتة البلجيكية الداكنة',
        price: 28.0,
        currency: 'ILS',
        category: 'hot_drinks',
      );

      await tester.pumpWidget(
        _app(const VenueMenuItemDetailsSheet(item: item)),
      );
      await tester.pump();

      expect(
        Directionality.of(
          tester.element(find.byType(VenueMenuItemDetailsSheet)),
        ),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('sheet remains draggable via DraggableScrollableSheet', (
      tester,
    ) async {
      const item = MenuItem(
        id: 'details-drag',
        nameAr: coffeeName,
        price: 12.0,
        currency: 'ILS',
        category: 'hot_drinks',
      );

      await tester.pumpWidget(
        _app(const VenueMenuItemDetailsSheet(item: item)),
      );

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });
  });

  group('VenueMenuSectionBlock', () {
    testWidgets('renders section header icon from configured section icon', (
      tester,
    ) async {
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
          category: 'main_courses',
        ),
        MenuItem(
          id: 'i2',
          nameAr: '\u0644\u0627\u062a\u064a\u0647',
          price: 15.0,
          currency: 'ILS',
          category: 'main_courses',
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
      expect(find.byIcon(Icons.coffee_rounded), findsOneWidget);
      expect(find.text(sectionName), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(
        find.text('\u0642\u0647\u0648\u0629 \u062a\u0631\u0643\u064a\u0629'),
        findsOneWidget,
      );
      expect(find.text('\u0644\u0627\u062a\u064a\u0647'), findsOneWidget);
    });

    testWidgets('uses section id for icon when section icon is default', (
      tester,
    ) async {
      const section = MenuSection(id: 'desserts', nameAr: 'حلويات');

      await tester.pumpWidget(
        _app(
          const SingleChildScrollView(
            child: VenueMenuSectionBlock(section: section, items: []),
          ),
        ),
      );

      expect(find.byIcon(Icons.cake_rounded), findsOneWidget);
    });

    testWidgets('falls back safely for unknown section icons', (tester) async {
      const section = MenuSection(
        id: 'chef_specials',
        nameAr: 'اختيارات الشيف',
        icon: 'unknown-custom-icon',
      );

      await tester.pumpWidget(
        _app(
          const SingleChildScrollView(
            child: VenueMenuSectionBlock(section: section, items: []),
          ),
        ),
      );

      expect(find.byIcon(Icons.restaurant_menu_rounded), findsOneWidget);
    });

    testWidgets('preserves expand and collapse behavior', (tester) async {
      const section = MenuSection(
        id: 'hot_drinks',
        nameAr: sectionName,
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
        MenuItem(
          id: 'i3',
          nameAr: 'كابتشينو',
          price: 16.0,
          currency: 'ILS',
          category: 'hot_drinks',
        ),
      ];
      final expansionChanges = <bool>[];

      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: VenueMenuSectionBlock(
              section: section,
              items: items,
              previewLimit: 1,
              onExpansionChanged: expansionChanges.add,
            ),
          ),
        ),
      );

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      expect(find.text('قهوة تركية'), findsOneWidget);
      expect(find.text('لاتيه'), findsNothing);
      expect(find.text('1/3'), findsOneWidget);
      expect(find.text(l10n.menuShowAll(2)), findsOneWidget);

      await tester.tap(find.text(l10n.menuShowAll(2)));
      await tester.pumpAndSettle();

      expect(find.text('لاتيه'), findsOneWidget);
      expect(find.text('كابتشينو'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text(l10n.menuShowLess), findsOneWidget);
      expect(expansionChanges, [true]);

      await tester.tap(find.text(l10n.menuShowLess));
      await tester.pumpAndSettle();

      expect(find.text('لاتيه'), findsNothing);
      expect(find.text('1/3'), findsOneWidget);
      expect(expansionChanges, [true, false]);

      await tester.tap(find.text(sectionName));
      await tester.pumpAndSettle();

      expect(find.text('لاتيه'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(expansionChanges, [true, false, true]);

      await tester.tap(find.text(sectionName));
      await tester.pumpAndSettle();

      expect(find.text('لاتيه'), findsNothing);
      expect(find.text('1/3'), findsOneWidget);
      expect(expansionChanges, [true, false, true, false]);
    });

    testWidgets('keeps long section header stable in RTL phone viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const longSectionName =
          'Cappuccino كابتشينو ومشروبات ساخنة عربية وإنجليزية طويلة جداً';
      const section = MenuSection(
        id: 'hot_drinks',
        nameAr: longSectionName,
        icon: 'coffee',
      );

      await tester.pumpWidget(
        _app(
          const SingleChildScrollView(
            child: VenueMenuSectionBlock(section: section, items: []),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(longSectionName), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not auto-expand oversized sections from category sync', (
      tester,
    ) async {
      const section = MenuSection(
        id: 'hot_drinks',
        nameAr: sectionName,
        icon: 'coffee',
      );
      final items = List<MenuItem>.generate(
        121,
        (index) => MenuItem(
          id: 'large-$index',
          nameAr: 'Large Item $index',
          price: 10.0,
          currency: 'ILS',
          category: 'hot_drinks',
          sortOrder: index,
        ),
      );

      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: VenueMenuSectionBlock(
              section: section,
              items: items,
              shouldExpand: true,
            ),
          ),
        ),
      );
      await tester.pump();

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      expect(find.text('Large Item 0'), findsOneWidget);
      expect(find.text('Large Item 3'), findsOneWidget);
      expect(find.text('Large Item 4'), findsNothing);
      expect(find.text('4/121'), findsOneWidget);
      expect(find.text(l10n.menuShowAll(117)), findsOneWidget);
      expect(tester.takeException(), isNull);
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
    testWidgets('renders compact header with item count and icon badge', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_app(const VenueMenuHeader(itemCount: 42)));

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      expect(find.text(l10n.menuTitle), findsOneWidget);
      expect(find.text('42 ${l10n.menuItemCounter}'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
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

  group('VenueMenuFeaturedCard', () {
    testWidgets('renders localized price and category placeholder icon', (
      tester,
    ) async {
      const item = MenuItem(
        id: 'featured-dessert',
        nameAr: 'كنافة',
        price: 12,
        currency: 'ILS',
        category: 'desserts',
        isFeatured: true,
      );

      await tester.pumpWidget(
        _app(
          const SingleChildScrollView(child: VenueMenuFeaturedCard(item: item)),
        ),
      );

      expect(find.text('كنافة'), findsOneWidget);
      expect(find.text('12 ₪'), findsOneWidget);
      expect(find.byIcon(Icons.cake_rounded), findsOneWidget);
      expect(
        (tester.getTopLeft(find.text('كنافة')).dy -
                tester.getTopLeft(find.text('12 ₪')).dy)
            .abs(),
        lessThan(6),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('VenueMenuImageGallery', () {
    testWidgets('renders named menu photos section and opens preview dialog', (
      tester,
    ) async {
      await runWithTestImageHttpOverrides(() async {
        await tester.pumpWidget(
          _app(
            const SingleChildScrollView(
              child: VenueMenuImageGallery(
                images: [
                  'https://example.test/menu-photo-1.png',
                  'https://example.test/menu-photo-2.png',
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final l10n = AppLocalizations.of(
          tester.element(find.byType(Scaffold)),
        )!;
        expect(find.text(l10n.menuPhotosTitle), findsOneWidget);
        expect(find.text('2 ${l10n.photoPlural}'), findsOneWidget);
        expect(find.byIcon(Icons.photo_library_rounded), findsOneWidget);

        await tester.tap(find.byType(InkWell).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(Dialog), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
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
