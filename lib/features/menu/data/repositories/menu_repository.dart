import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/menu_item.dart';
import '../../domain/entities/menu_section.dart';

/// Predefined menu sections per venue category.
/// Stored client-side to avoid an extra Firestore read on every page load.
const Map<String, List<Map<String, dynamic>>> defaultMenuSections = {
  'cafe': [
    {
      'id': 'hot_drinks',
      'name_ar': 'مشروبات ساخنة',
      'name_en': 'Hot Drinks',
      'icon': 'coffee',
      'sort_order': 1,
    },
    {
      'id': 'cold_drinks',
      'name_ar': 'مشروبات باردة',
      'name_en': 'Cold Drinks',
      'icon': 'local_drink',
      'sort_order': 2,
    },
    {
      'id': 'juices',
      'name_ar': 'عصائر وسموذي',
      'name_en': 'Juices & Smoothies',
      'icon': 'local_bar',
      'sort_order': 3,
    },
    {
      'id': 'hookah',
      'name_ar': 'أراجيل',
      'name_en': 'Hookah',
      'icon': 'smoking_rooms',
      'sort_order': 4,
    },
    {
      'id': 'desserts',
      'name_ar': 'حلويات',
      'name_en': 'Desserts',
      'icon': 'cake',
      'sort_order': 5,
    },
    {
      'id': 'snacks',
      'name_ar': 'سناكات',
      'name_en': 'Snacks',
      'icon': 'fastfood',
      'sort_order': 6,
    },
  ],
  'restaurant': [
    {
      'id': 'appetizers',
      'name_ar': 'مقبلات',
      'name_en': 'Appetizers',
      'icon': 'restaurant',
      'sort_order': 1,
    },
    {
      'id': 'main_courses',
      'name_ar': 'أطباق رئيسية',
      'name_en': 'Main Courses',
      'icon': 'dinner_dining',
      'sort_order': 2,
    },
    {
      'id': 'grills',
      'name_ar': 'مشاوي',
      'name_en': 'Grills',
      'icon': 'outdoor_grill',
      'sort_order': 3,
    },
    {
      'id': 'soups',
      'name_ar': 'شوربات',
      'name_en': 'Soups',
      'icon': 'soup_kitchen',
      'sort_order': 4,
    },
    {
      'id': 'desserts',
      'name_ar': 'حلويات',
      'name_en': 'Desserts',
      'icon': 'cake',
      'sort_order': 5,
    },
    {
      'id': 'drinks',
      'name_ar': 'مشروبات',
      'name_en': 'Drinks',
      'icon': 'local_drink',
      'sort_order': 6,
    },
  ],
  'fast_food': [
    {
      'id': 'burgers',
      'name_ar': 'برغر',
      'name_en': 'Burgers',
      'icon': 'lunch_dining',
      'sort_order': 1,
    },
    {
      'id': 'shawarma',
      'name_ar': 'شاورما',
      'name_en': 'Shawarma',
      'icon': 'kebab_dining',
      'sort_order': 2,
    },
    {
      'id': 'pizza',
      'name_ar': 'بيتزا',
      'name_en': 'Pizza',
      'icon': 'local_pizza',
      'sort_order': 3,
    },
    {
      'id': 'sandwiches',
      'name_ar': 'ساندويتشات',
      'name_en': 'Sandwiches',
      'icon': 'fastfood',
      'sort_order': 4,
    },
    {
      'id': 'sides',
      'name_ar': 'مقالي وإضافات',
      'name_en': 'Sides & Fries',
      'icon': 'tapas',
      'sort_order': 5,
    },
    {
      'id': 'drinks',
      'name_ar': 'مشروبات',
      'name_en': 'Drinks',
      'icon': 'local_drink',
      'sort_order': 6,
    },
  ],
  'sweets': [
    {
      'id': 'eastern_sweets',
      'name_ar': 'حلويات شرقية',
      'name_en': 'Eastern Sweets',
      'icon': 'bakery_dining',
      'sort_order': 1,
    },
    {
      'id': 'western_sweets',
      'name_ar': 'حلويات غربية',
      'name_en': 'Western Sweets',
      'icon': 'cake',
      'sort_order': 2,
    },
    {
      'id': 'ice_cream',
      'name_ar': 'آيس كريم',
      'name_en': 'Ice Cream',
      'icon': 'icecream',
      'sort_order': 3,
    },
    {
      'id': 'drinks',
      'name_ar': 'مشروبات',
      'name_en': 'Drinks',
      'icon': 'local_drink',
      'sort_order': 4,
    },
  ],
  'juice_bar': [
    {
      'id': 'fresh_juices',
      'name_ar': 'عصائر طبيعية',
      'name_en': 'Fresh Juices',
      'icon': 'local_drink',
      'sort_order': 1,
    },
    {
      'id': 'smoothies',
      'name_ar': 'سموذي',
      'name_en': 'Smoothies',
      'icon': 'blender',
      'sort_order': 2,
    },
    {
      'id': 'cocktails',
      'name_ar': 'كوكتيلات',
      'name_en': 'Cocktails',
      'icon': 'local_bar',
      'sort_order': 3,
    },
    {
      'id': 'milkshakes',
      'name_ar': 'ميلك شيك',
      'name_en': 'Milkshakes',
      'icon': 'coffee',
      'sort_order': 4,
    },
  ],
};

/// Fallback sections for unknown venue categories.
const List<Map<String, dynamic>> _genericSections = [
  {
    'id': 'food',
    'name_ar': 'أكل',
    'name_en': 'Food',
    'icon': 'restaurant',
    'sort_order': 1,
  },
  {
    'id': 'drinks',
    'name_ar': 'مشروبات',
    'name_en': 'Drinks',
    'icon': 'local_drink',
    'sort_order': 2,
  },
  {
    'id': 'other',
    'name_ar': 'أخرى',
    'name_en': 'Other',
    'icon': 'more_horiz',
    'sort_order': 3,
  },
];

class MenuDraftContext {
  final String venueId;
  final String draftVersionId;
  final String? activeVersionId;

  const MenuDraftContext({
    required this.venueId,
    required this.draftVersionId,
    required this.activeVersionId,
  });
}

class MenuVersionSummary {
  final String versionId;
  final String status;
  final String source;
  final Timestamp? createdAt;
  final Timestamp? publishedAt;

  const MenuVersionSummary({
    required this.versionId,
    required this.status,
    required this.source,
    required this.createdAt,
    required this.publishedAt,
  });
}

class _SeedCategory {
  final String id;
  final Map<String, dynamic> data;

  const _SeedCategory({required this.id, required this.data});
}

class _SeedItem {
  final String id;
  final Map<String, dynamic> data;

  const _SeedItem({required this.id, required this.data});
}

class _DraftSeedResult {
  final String source;
  final List<_SeedCategory> categories;
  final List<_SeedItem> items;

  const _DraftSeedResult({
    required this.source,
    required this.categories,
    required this.items,
  });
}

class MenuRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  MenuRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  // ------- Sections -------

  /// Get menu sections for a given venue category (e.g. "cafe", "restaurant").
  List<MenuSection> getSectionsForCategory(String venueCategory) {
    final cat = venueCategory.toLowerCase();
    final rawSections = defaultMenuSections[cat] ?? _genericSections;
    return rawSections.map((m) => MenuSection.fromJson(m)).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  // ------- Paths -------

  DocumentReference<Map<String, dynamic>> _venueRef(String venueId) =>
      _firestore.collection('venues').doc(venueId);

  DocumentReference<Map<String, dynamic>> _menuConfigRef(String venueId) =>
      _venueRef(venueId).collection('menu_config').doc('main');

  CollectionReference<Map<String, dynamic>> _menuVersionsRef(String venueId) =>
      _venueRef(venueId).collection('menu_versions');

  DocumentReference<Map<String, dynamic>> _menuVersionRef(
    String venueId,
    String versionId,
  ) => _menuVersionsRef(venueId).doc(versionId);

  CollectionReference<Map<String, dynamic>> _versionItemsRef(
    String venueId,
    String versionId,
  ) => _menuVersionRef(venueId, versionId).collection('items');

  CollectionReference<Map<String, dynamic>> _versionCategoriesRef(
    String venueId,
    String versionId,
  ) => _menuVersionRef(venueId, versionId).collection('categories');

  CollectionReference<Map<String, dynamic>> _legacyItemsRef(String venueId) =>
      _venueRef(venueId).collection('menu_items');

  CollectionReference<Map<String, dynamic>> _itemsRefForWrite(
    String venueId, {
    String? versionId,
  }) {
    if (versionId != null && versionId.isNotEmpty) {
      return _versionItemsRef(venueId, versionId);
    }
    return _legacyItemsRef(venueId);
  }

  // ------- Read path (customer): active version -> legacy fallback -------

  /// Watches visible menu items for customers.
  /// Source precedence:
  /// 1) venues/{venueId}.active_menu_version_id -> menu_versions/{id}/items
  /// 2) legacy venues/{venueId}/menu_items fallback
  Stream<List<MenuItem>> watchMenuItems(String venueId) {
    final controller = StreamController<List<MenuItem>>.broadcast();

    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? venueSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? itemsSub;
    String? attachedSource;

    void bindItemsStream(String? activeVersionId) {
      final source = (activeVersionId != null && activeVersionId.isNotEmpty)
          ? 'version:$activeVersionId'
          : 'legacy';

      if (source == attachedSource) {
        return;
      }
      attachedSource = source;

      itemsSub?.cancel();

      final query = source == 'legacy'
          ? _legacyItemsRef(venueId).orderBy('sort_order')
          : _versionItemsRef(venueId, activeVersionId!).orderBy('sort_order');

      itemsSub = query.snapshots().listen((snap) {
        final items = snap.docs.map((d) => MenuItem.fromDoc(d)).toList();
        controller.add(items);
      }, onError: controller.addError);
    }

    controller.onListen = () {
      if (venueSub != null) {
        return;
      }
      venueSub = _venueRef(venueId).snapshots().listen((venueSnap) {
        final activeVersionId = _asString(
          venueSnap.data()?['active_menu_version_id'],
        );
        bindItemsStream(activeVersionId);
      }, onError: controller.addError);
    };

    controller.onCancel = () async {
      if (controller.hasListener) {
        return;
      }
      await itemsSub?.cancel();
      await venueSub?.cancel();
      itemsSub = null;
      venueSub = null;
      attachedSource = null;
    };

    return controller.stream;
  }

  /// Stream menu items for a specific version (merchant draft/editor use).
  Stream<List<MenuItem>> watchMenuItemsForVersion(
    String venueId,
    String versionId,
  ) {
    return _versionItemsRef(venueId, versionId)
        .orderBy('sort_order')
        .snapshots()
        .map((snap) => snap.docs.map((d) => MenuItem.fromDoc(d)).toList());
  }

  Future<List<MenuItem>> getMenuItems(String venueId) async {
    final venueDoc = await _venueRef(venueId).get();
    final activeVersionId = _asString(
      venueDoc.data()?['active_menu_version_id'],
    );

    final snap = (activeVersionId != null && activeVersionId.isNotEmpty)
        ? await _versionItemsRef(
            venueId,
            activeVersionId,
          ).orderBy('sort_order').get()
        : await _legacyItemsRef(venueId).orderBy('sort_order').get();

    return snap.docs.map((d) => MenuItem.fromDoc(d)).toList();
  }

  Future<List<MenuItem>> getMenuItemsForVersion(
    String venueId,
    String versionId,
  ) async {
    final snap = await _versionItemsRef(
      venueId,
      versionId,
    ).orderBy('sort_order').get();
    return snap.docs.map((d) => MenuItem.fromDoc(d)).toList();
  }

  // ------- Draft lifecycle -------

  /// Ensures there is an editable draft for merchant menu management.
  /// If no draft exists, creates one by cloning active menu or legacy menu fallback.
  Future<MenuDraftContext> ensureDraftVersion({
    required String venueId,
    required String venueCategory,
    required String merchantUid,
  }) async {
    if (merchantUid.isEmpty) {
      throw StateError('Merchant user is not authenticated.');
    }

    final venueDoc = await _venueRef(venueId).get();
    if (!venueDoc.exists) {
      throw StateError('Venue not found.');
    }

    final venueData = venueDoc.data() ?? <String, dynamic>{};
    final activeVersionId = _asString(venueData['active_menu_version_id']);

    final configRef = _menuConfigRef(venueId);
    final configDoc = await configRef.get();
    final configData = configDoc.data() ?? <String, dynamic>{};

    final existingDraftId = _asString(configData['draft_version_id']);
    if (existingDraftId != null && existingDraftId.isNotEmpty) {
      final draftDoc = await _menuVersionRef(venueId, existingDraftId).get();
      if (draftDoc.exists) {
        final status = _asString(draftDoc.data()?['status']) ?? 'draft';
        if (status == 'draft') {
          return MenuDraftContext(
            venueId: venueId,
            draftVersionId: existingDraftId,
            activeVersionId: activeVersionId,
          );
        }
      }
    }

    final newDraftId = 'draft_${DateTime.now().millisecondsSinceEpoch}';
    final seed = await _buildDraftSeed(
      venueId: venueId,
      venueCategory: venueCategory,
      activeVersionId: activeVersionId,
    );

    // Firestore batch limit guard.
    final opCount = seed.categories.length + seed.items.length + 2;
    if (opCount > 450) {
      throw StateError(
        'Draft clone is too large for single batch (items: ${seed.items.length}).',
      );
    }

    final batch = _firestore.batch();
    final draftRef = _menuVersionRef(venueId, newDraftId);
    final now = FieldValue.serverTimestamp();

    batch.set(draftRef, {
      'status': 'draft',
      'source': seed.source,
      'created_by': merchantUid,
      'created_at': now,
      'published_at': null,
      'item_count': seed.items.length,
      'category_count': seed.categories.length,
      'last_counted_at': null,
    });

    for (final category in seed.categories) {
      batch.set(_versionCategoriesRef(venueId, newDraftId).doc(category.id), {
        ...category.data,
      });
    }

    for (final item in seed.items) {
      batch.set(_versionItemsRef(venueId, newDraftId).doc(item.id), {
        ...item.data,
      });
    }

    batch.set(configRef, {
      'draft_version_id': newDraftId,
      'venue_type': venueCategory,
      'currency': _asString(configData['currency']) ?? 'ILS',
      'migration_status':
          _asString(configData['migration_status']) ?? 'not_started',
      'updated_at': now,
    }, SetOptions(merge: true));

    await batch.commit();

    return MenuDraftContext(
      venueId: venueId,
      draftVersionId: newDraftId,
      activeVersionId: activeVersionId,
    );
  }

  Future<void> publishDraftVersion({
    required String venueId,
    required String merchantUid,
  }) async {
    if (merchantUid.isEmpty) {
      throw StateError('Merchant user is not authenticated.');
    }

    final configDoc = await _menuConfigRef(venueId).get();
    final draftVersionId = _asString(configDoc.data()?['draft_version_id']);
    if (draftVersionId == null || draftVersionId.isEmpty) {
      throw StateError('No draft version to publish.');
    }

    // Preflight counts (outside transaction).
    final categoryCount = (await _versionCategoriesRef(
      venueId,
      draftVersionId,
    ).get()).size;
    final itemCount = (await _versionItemsRef(
      venueId,
      draftVersionId,
    ).get()).size;
    if (itemCount <= 0) {
      throw StateError('Cannot publish an empty menu draft.');
    }

    await _runTransactionWithRetry(() {
      return _firestore.runTransaction((tx) async {
        final venueRef = _venueRef(venueId);
        final configRef = _menuConfigRef(venueId);

        final venueSnap = await tx.get(venueRef);
        final configSnap = await tx.get(configRef);

        final txDraftId = _asString(configSnap.data()?['draft_version_id']);
        if (txDraftId == null || txDraftId != draftVersionId) {
          throw StateError('Draft changed. Please refresh and try again.');
        }

        final draftRef = _menuVersionRef(venueId, txDraftId);
        final draftSnap = await tx.get(draftRef);
        if (!draftSnap.exists) {
          throw StateError('Draft version does not exist.');
        }

        final draftStatus = _asString(draftSnap.data()?['status']) ?? 'draft';
        if (draftStatus != 'draft') {
          throw StateError('Only draft versions can be published.');
        }

        final oldActiveId = _asString(
          venueSnap.data()?['active_menu_version_id'],
        );
        DocumentReference<Map<String, dynamic>>? oldActiveRef;
        DocumentSnapshot<Map<String, dynamic>>? oldActiveSnap;
        if (oldActiveId != null &&
            oldActiveId.isNotEmpty &&
            oldActiveId != txDraftId) {
          oldActiveRef = _menuVersionRef(venueId, oldActiveId);
          oldActiveSnap = await tx.get(oldActiveRef);
        }

        tx.set(venueRef, {
          'active_menu_version_id': txDraftId,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        tx.set(draftRef, {
          'status': 'active',
          'published_at': FieldValue.serverTimestamp(),
          'item_count': itemCount,
          'category_count': categoryCount,
          'last_counted_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (oldActiveRef != null &&
            oldActiveSnap != null &&
            oldActiveSnap.exists) {
          tx.set(oldActiveRef, {'status': 'archived'}, SetOptions(merge: true));
        }

        tx.set(configRef, {
          'draft_version_id': null,
          'last_published_by': merchantUid,
          'last_published_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    });
  }

  Future<void> rollbackToVersion({
    required String venueId,
    required String targetVersionId,
    required String merchantUid,
  }) async {
    if (merchantUid.isEmpty) {
      throw StateError('Merchant user is not authenticated.');
    }

    await _runTransactionWithRetry(() {
      return _firestore.runTransaction((tx) async {
        final venueRef = _venueRef(venueId);
        final configRef = _menuConfigRef(venueId);
        final targetRef = _menuVersionRef(venueId, targetVersionId);

        final venueSnap = await tx.get(venueRef);
        final targetSnap = await tx.get(targetRef);

        if (!targetSnap.exists) {
          throw StateError('Target version not found.');
        }

        final targetStatus = _asString(targetSnap.data()?['status']) ?? '';
        if (targetStatus != 'archived' && targetStatus != 'active') {
          throw StateError('Target version is not eligible for rollback.');
        }

        final currentActiveId = _asString(
          venueSnap.data()?['active_menu_version_id'],
        );

        if (currentActiveId != null &&
            currentActiveId.isNotEmpty &&
            currentActiveId != targetVersionId) {
          final currentActiveRef = _menuVersionRef(venueId, currentActiveId);
          final currentActiveSnap = await tx.get(currentActiveRef);
          if (currentActiveSnap.exists) {
            tx.set(currentActiveRef, {
              'status': 'archived',
            }, SetOptions(merge: true));
          }
        }

        tx.set(targetRef, {
          'status': 'active',
          'published_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        tx.set(venueRef, {
          'active_menu_version_id': targetVersionId,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        tx.set(configRef, {
          'last_rollback_by': merchantUid,
          'last_rollback_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    });
  }

  Future<List<MenuVersionSummary>> listMenuVersions(String venueId) async {
    final snap = await _menuVersionsRef(
      venueId,
    ).orderBy('created_at', descending: true).limit(50).get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return MenuVersionSummary(
        versionId: doc.id,
        status: _asString(data['status']) ?? 'draft',
        source: _asString(data['source']) ?? 'manual',
        createdAt: data['created_at'] as Timestamp?,
        publishedAt: data['published_at'] as Timestamp?,
      );
    }).toList();
  }

  // ------- Menu item CRUD (draft-aware writes) -------

  Future<String> addMenuItem(
    String venueId,
    MenuItem item, {
    String? versionId,
  }) async {
    final data = item.toJson();
    data['created_at'] = FieldValue.serverTimestamp();
    data['updated_at'] = FieldValue.serverTimestamp();
    data['source'] = data['source'] ?? 'manual';
    final docRef = await _itemsRefForWrite(
      venueId,
      versionId: versionId,
    ).add(data);
    return docRef.id;
  }

  Future<void> updateMenuItem(
    String venueId,
    MenuItem item, {
    String? versionId,
  }) async {
    final data = item.toJson();
    data['updated_at'] = FieldValue.serverTimestamp();
    await _itemsRefForWrite(
      venueId,
      versionId: versionId,
    ).doc(item.id).update(data);
  }

  Future<void> deleteMenuItem(
    String venueId,
    MenuItem item, {
    String? versionId,
  }) async {
    await _itemsRefForWrite(
      venueId,
      versionId: versionId,
    ).doc(item.id).delete();

    // Clean up photo from Storage
    if (item.photoUrl.isNotEmpty) {
      try {
        await _storage.refFromURL(item.photoUrl).delete();
      } catch (e) {
        debugPrint('Could not delete menu item photo: $e');
      }
    }
  }

  Future<void> toggleAvailability(
    String venueId,
    String itemId,
    bool available, {
    String? versionId,
  }) async {
    await _itemsRefForWrite(venueId, versionId: versionId).doc(itemId).update({
      'is_available': available,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ------- Photo Upload -------

  /// Upload a menu item photo and return the download URL.
  Future<String> uploadMenuItemPhoto(String venueId, File file) async {
    final fileName = 'item_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('venues/$venueId/menu_items/$fileName');
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    await ref.putFile(file, metadata);
    return ref.getDownloadURL();
  }

  // ------- Internal helpers -------

  Future<_DraftSeedResult> _buildDraftSeed({
    required String venueId,
    required String venueCategory,
    required String? activeVersionId,
  }) async {
    if (activeVersionId != null && activeVersionId.isNotEmpty) {
      final activeCategories = await _versionCategoriesRef(
        venueId,
        activeVersionId,
      ).get();
      final activeItems = await _versionItemsRef(
        venueId,
        activeVersionId,
      ).orderBy('sort_order').get();

      if (activeCategories.docs.isNotEmpty || activeItems.docs.isNotEmpty) {
        final categories = <_SeedCategory>[];
        for (final doc in activeCategories.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          data['sort_order'] = (data['sort_order'] as num?)?.toInt() ?? 0;
          categories.add(_SeedCategory(id: doc.id, data: data));
        }

        final items = <_SeedItem>[];
        for (final doc in activeItems.docs) {
          items.add(
            _SeedItem(id: doc.id, data: Map<String, dynamic>.from(doc.data())),
          );
        }

        if (categories.isEmpty) {
          categories.addAll(_templateSeedCategories(venueCategory));
        }

        return _DraftSeedResult(
          source: 'manual',
          categories: categories,
          items: items,
        );
      }
    }

    final legacyItems = await _legacyItemsRef(
      venueId,
    ).orderBy('sort_order').get();

    final categories = _templateSeedCategories(venueCategory);
    final categoriesById = {for (final c in categories) c.id: c};

    final items = <_SeedItem>[];
    for (final doc in legacyItems.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      final rawCategory = _asString(data['category']) ?? 'other';
      final normalizedCategory = _normalizeCategoryKey(rawCategory);

      if (!categoriesById.containsKey(normalizedCategory)) {
        final nextSort = categoriesById.length + 1;
        final customCategory = _SeedCategory(
          id: normalizedCategory,
          data: {
            'key': normalizedCategory,
            'name_ar': _humanizeCategoryKey(normalizedCategory),
            'name_en': _humanizeCategoryKey(normalizedCategory),
            'sort_order': nextSort,
            'is_custom': true,
          },
        );
        categoriesById[normalizedCategory] = customCategory;
      }

      data['category'] = normalizedCategory;
      items.add(_SeedItem(id: doc.id, data: data));
    }

    return _DraftSeedResult(
      source: legacyItems.docs.isNotEmpty ? 'migration' : 'manual',
      categories: categoriesById.values.toList()
        ..sort(
          (a, b) => ((a.data['sort_order'] as num?)?.toInt() ?? 0).compareTo(
            (b.data['sort_order'] as num?)?.toInt() ?? 0,
          ),
        ),
      items: items,
    );
  }

  List<_SeedCategory> _templateSeedCategories(String venueCategory) {
    final sections = getSectionsForCategory(venueCategory);
    return sections
        .map(
          (section) => _SeedCategory(
            id: section.id,
            data: {
              'key': section.id,
              'name_ar': section.nameAr,
              'name_en': section.nameEn,
              'sort_order': section.sortOrder,
              'is_custom': false,
            },
          ),
        )
        .toList();
  }

  String _normalizeCategoryKey(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return 'other';
    final safe = trimmed.replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
    return safe.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
  }

  String _humanizeCategoryKey(String value) {
    final text = value.replaceAll('_', ' ').trim();
    if (text.isEmpty) return 'Other';
    return text[0].toUpperCase() + text.substring(1);
  }

  String? _asString(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return trimmed;
    }
    return null;
  }

  Future<T> _runTransactionWithRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
  }) async {
    final delays = <Duration>[
      const Duration(milliseconds: 150),
      const Duration(milliseconds: 500),
      const Duration(milliseconds: 1200),
    ];

    Object? lastError;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await operation();
      } on FirebaseException catch (e) {
        lastError = e;
        final isRetryable =
            e.code == 'aborted' || e.code == 'deadline-exceeded';
        if (!isRetryable || attempt == maxAttempts - 1) {
          rethrow;
        }
      }
      await Future<void>.delayed(delays[attempt.clamp(0, delays.length - 1)]);
    }

    throw StateError('Transaction failed: $lastError');
  }
}
