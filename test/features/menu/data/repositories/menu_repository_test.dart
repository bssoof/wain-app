import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:wain_app/features/menu/data/repositories/menu_repository.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/domain/entities/menu_section.dart';

class FakeFirebaseStorage extends Fake implements FirebaseStorage {}
class FakeFirebaseFunctions extends Fake implements FirebaseFunctions {}

void main() {
  late MenuRepository repo;
  late FakeFirebaseFirestore fakeFirestore;
  late FakeFirebaseStorage fakeStorage;
  late FakeFirebaseFunctions fakeFunctions;

  const venueId = 'test_venue';
  const merchantUid = 'test_merchant';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fakeStorage = FakeFirebaseStorage();
    fakeFunctions = FakeFirebaseFunctions();
    repo = MenuRepository(
      firestore: fakeFirestore, 
      storage: fakeStorage, 
      functions: fakeFunctions
    );
  });

  group('MenuRepository - Phase 1 Fixes', () {
    test('publishDraftVersion validates items and publishes successfully', () async {
      final configRef = fakeFirestore.collection('venues').doc(venueId).collection('menu_config').doc('main');
      await configRef.set({'draft_version_id': 'draft_1'});

      final draftRef = fakeFirestore.collection('venues').doc(venueId).collection('menu_versions').doc('draft_1');
      await draftRef.set({'status': 'draft'});

      final categoryRef = draftRef.collection('categories').doc('category_1');
      await categoryRef.set({'name_ar': 'Category 1'});

      final itemRef = draftRef.collection('items').doc('item_1');
      await itemRef.set({
        'name_ar': 'Item 1',
        'price': 100.0,
        'category': 'category_1'
      });

      await repo.publishDraftVersion(venueId: venueId, merchantUid: merchantUid);

      final draftSnap = await draftRef.get();
      expect(draftSnap.data()?['status'], 'active');

      final venueSnap = await fakeFirestore.collection('venues').doc(venueId).get();
      expect(venueSnap.data()?['active_menu_version_id'], 'draft_1');
    });

    test('publishDraftVersion fails on invalid price', () async {
      final configRef = fakeFirestore.collection('venues').doc(venueId).collection('menu_config').doc('main');
      await configRef.set({'draft_version_id': 'draft_1'});

      final draftRef = fakeFirestore.collection('venues').doc(venueId).collection('menu_versions').doc('draft_1');
      await draftRef.set({'status': 'draft'});

      final categoryRef = draftRef.collection('categories').doc('category_1');
      await categoryRef.set({'name_ar': 'Category 1'});

      final itemRef = draftRef.collection('items').doc('item_1');
      await itemRef.set({
        'name_ar': 'Invalid Price Item',
        'price': -5.0, // Invalid price
        'category': 'category_1'
      });

      expect(
        () => repo.publishDraftVersion(venueId: venueId, merchantUid: merchantUid),
        throwsA(isA<StateError>()),
      );
    });

    test('publishDraftVersion fails on missing/invalid category', () async {
      final configRef = fakeFirestore.collection('venues').doc(venueId).collection('menu_config').doc('main');
      await configRef.set({'draft_version_id': 'draft_1'});

      final draftRef = fakeFirestore.collection('venues').doc(venueId).collection('menu_versions').doc('draft_1');
      await draftRef.set({'status': 'draft'});
      
      // We purposefully do not create the category_1 document

      final itemRef = draftRef.collection('items').doc('item_1');
      await itemRef.set({
        'name_ar': 'Orphan Item',
        'price': 100.0,
        'category': 'category_1' // Invalid category
      });

      expect(
        () => repo.publishDraftVersion(venueId: venueId, merchantUid: merchantUid),
        throwsA(isA<StateError>()),
      );
    });

    test('deleteMenuSection migrates items to fallback category', () async {
      final draftRef = fakeFirestore.collection('venues').doc(venueId).collection('menu_versions').doc('draft_1');
      
      final sourceCategoryRef = draftRef.collection('categories').doc('source_category');
      await sourceCategoryRef.set({'name_ar': 'Source'});

      final fallbackCategoryRef = draftRef.collection('categories').doc('fallback_category');
      await fallbackCategoryRef.set({'name_ar': 'Fallback'});

      final itemRef = draftRef.collection('items').doc('item_1');
      await itemRef.set({
        'name_ar': 'Item 1',
        'price': 10.0,
        'category': 'source_category'
      });

      await repo.deleteMenuSection(
        venueId: venueId, 
        versionId: 'draft_1', 
        sectionId: 'source_category', 
        fallbackSectionId: 'fallback_category'
      );

      // Verify category deleted
      final sourceSnap = await sourceCategoryRef.get();
      expect(sourceSnap.exists, isFalse);

      // Verify item migrated
      final itemSnap = await itemRef.get();
      expect(itemSnap.exists, isTrue);
      expect(itemSnap.data()?['category'], 'fallback_category');
    });

    test('reorderMenuSections updates sort_order in batch', () async {
      final draftRef = fakeFirestore.collection('venues').doc(venueId).collection('menu_versions').doc('draft_1');
      
      final cat1Ref = draftRef.collection('categories').doc('cat_1');
      await cat1Ref.set({'name_ar': 'Category 1', 'sort_order': 0});

      final cat2Ref = draftRef.collection('categories').doc('cat_2');
      await cat2Ref.set({'name_ar': 'Category 2', 'sort_order': 1});

      final List<MenuSection> sections = [
        MenuSection(id: 'cat_2', nameAr: 'Category 2', sortOrder: 1),
        MenuSection(id: 'cat_1', nameAr: 'Category 1', sortOrder: 0),
      ];

      await repo.reorderMenuSections(
        venueId: venueId,
        versionId: 'draft_1',
        orderedSections: sections,
      );

      final cat1Snap = await cat1Ref.get();
      final cat2Snap = await cat2Ref.get();

      expect(cat1Snap.data()?['sort_order'], 1);
      expect(cat2Snap.data()?['sort_order'], 0);
    });

    test('reorderMenuItems updates sort_order in batch', () async {
      final draftRef = fakeFirestore.collection('venues').doc(venueId).collection('menu_versions').doc('draft_1');
      
      final item1Ref = draftRef.collection('items').doc('item_1');
      await item1Ref.set({'name_ar': 'Item 1', 'category': 'cat_1', 'sort_order': 0, 'price': 10.0});

      final item2Ref = draftRef.collection('items').doc('item_2');
      await item2Ref.set({'name_ar': 'Item 2', 'category': 'cat_1', 'sort_order': 1, 'price': 20.0});

      final List<MenuItem> items = [
        MenuItem(id: 'item_2', nameAr: 'Item 2', category: 'cat_1', sortOrder: 1, price: 20.0),
        MenuItem(id: 'item_1', nameAr: 'Item 1', category: 'cat_1', sortOrder: 0, price: 10.0),
      ];

      await repo.reorderMenuItems(
        venueId: venueId,
        versionId: 'draft_1',
        orderedItems: items,
      );

      final item1Snap = await item1Ref.get();
      final item2Snap = await item2Ref.get();

      expect(item1Snap.data()?['sort_order'], 1);
      expect(item2Snap.data()?['sort_order'], 0);
    });
  });
}
