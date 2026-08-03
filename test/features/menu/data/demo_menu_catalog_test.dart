import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/menu/data/demo_menu_catalog.dart';

void main() {
  test('demo menu provides a complete editable cafe catalog', () {
    expect(demoMenuItems, hasLength(10));
    expect(demoMenuSections, hasLength(5));
    expect(demoMenuItems.map((item) => item.id).toSet(), hasLength(10));
    expect(
      demoMenuSections.map((section) => section.id).toSet(),
      demoMenuItems.map((item) => item.category).toSet(),
    );
    expect(
      demoMenuItems.map((item) => item.category).toSet(),
      containsAll(<String>{
        'hot_drinks',
        'cold_drinks',
        'juices',
        'desserts',
        'snacks',
      }),
    );
    expect(demoMenuItems.every((item) => item.price > 0), isTrue);
    expect(
      demoMenuItems.every(
        (item) => item.photoUrl.startsWith('asset://assets/images/demo_menu/'),
      ),
      isTrue,
    );
  });
}
