import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/menu/data/demo_menu_catalog.dart';

void main() {
  test('demo menu provides a complete editable cafe catalog', () {
    final available = demoMenuItems.where((item) => item.isAvailable).toList();

    expect(demoMenuSections, hasLength(6));
    expect(available, hasLength(24));
    expect(demoMenuItems.map((item) => item.id).toSet(),
        hasLength(demoMenuItems.length));
    expect(
      demoMenuSections.map((section) => section.id).toSet(),
      demoMenuItems.map((item) => item.category).toSet(),
    );
    expect(
      demoMenuSections.map((section) => section.id).toSet(),
      containsAll(<String>{
        'hot_drinks',
        'specialty_coffee',
        'cold_drinks',
        'juices',
        'desserts',
        'breakfast',
      }),
    );
    expect(demoMenuItems.every((item) => item.price > 0), isTrue);
    expect(
      demoMenuItems.every(
        (item) => item.photoUrl.startsWith('asset://assets/images/demo_menu/'),
      ),
      isTrue,
    );
    expect(demoMenuItems.any((item) => item.isFeatured), isTrue);
    expect(demoMenuItems.any((item) => !item.isAvailable), isTrue);
  });
}
