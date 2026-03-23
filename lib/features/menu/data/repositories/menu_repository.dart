import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
      'name_ar': '',
      'name_en': '',
      'icon': 'coffee',
      'sort_order': 1,
    },
    {
      'id': 'cold_drinks',
      'name_ar': '',
      'name_en': '',
      'icon': 'local_drink',
      'sort_order': 2,
    },
    {
      'id': 'juices',
      'name_ar': '',
      'name_en': '',
      'icon': 'local_bar',
      'sort_order': 3,
    },
    {
      'id': 'hookah',
      'name_ar': '',
      'name_en': '',
      'icon': 'smoking_rooms',
      'sort_order': 4,
    },
    {
      'id': 'desserts',
      'name_ar': '',
      'name_en': '',
      'icon': 'cake',
      'sort_order': 5,
    },
    {
      'id': 'snacks',
      'name_ar': '',
      'name_en': '',
      'icon': 'fastfood',
      'sort_order': 6,
    },
  ],
  'restaurant': [
    {
      'id': 'appetizers',
      'name_ar': '',
      'name_en': '',
      'icon': 'restaurant',
      'sort_order': 1,
    },
    {
      'id': 'main_courses',
      'name_ar': '',
      'name_en': '',
      'icon': 'dinner_dining',
      'sort_order': 2,
    },
    {
      'id': 'grills',
      'name_ar': '',
      'name_en': '',
      'icon': 'outdoor_grill',
      'sort_order': 3,
    },
    {
      'id': 'soups',
      'name_ar': '',
      'name_en': '',
      'icon': 'soup_kitchen',
      'sort_order': 4,
    },
    {
      'id': 'desserts',
      'name_ar': '',
      'name_en': '',
      'icon': 'cake',
      'sort_order': 5,
    },
    {
      'id': 'drinks',
      'name_ar': '',
      'name_en': '',
      'icon': 'local_drink',
      'sort_order': 6,
    },
  ],
  'fast_food': [
    {
      'id': 'burgers',
      'name_ar': '',
      'name_en': '',
      'icon': 'lunch_dining',
      'sort_order': 1,
    },
    {
      'id': 'shawarma',
      'name_ar': '',
      'name_en': '',
      'icon': 'kebab_dining',
      'sort_order': 2,
    },
    {
      'id': 'pizza',
      'name_ar': '',
      'name_en': '',
      'icon': 'local_pizza',
      'sort_order': 3,
    },
    {
      'id': 'sandwiches',
      'name_ar': '',
      'name_en': '',
      'icon': 'fastfood',
      'sort_order': 4,
    },
    {
      'id': 'sides',
      'name_ar': '',
      'name_en': '',
      'icon': 'tapas',
      'sort_order': 5,
    },
    {
      'id': 'drinks',
      'name_ar': '',
      'name_en': '',
      'icon': 'local_drink',
      'sort_order': 6,
    },
  ],
  'sweets': [
    {
      'id': 'eastern_sweets',
      'name_ar': '',
      'name_en': '',
      'icon': 'bakery_dining',
      'sort_order': 1,
    },
    {
      'id': 'western_sweets',
      'name_ar': '',
      'name_en': '',
      'icon': 'cake',
      'sort_order': 2,
    },
    {
      'id': 'ice_cream',
      'name_ar': '',
      'name_en': '',
      'icon': 'icecream',
      'sort_order': 3,
    },
    {
      'id': 'drinks',
      'name_ar': '',
      'name_en': '',
      'icon': 'local_drink',
      'sort_order': 4,
    },
  ],
  'juice_bar': [
    {
      'id': 'fresh_juices',
      'name_ar': '',
      'name_en': '',
      'icon': 'local_drink',
      'sort_order': 1,
    },
    {
      'id': 'smoothies',
      'name_ar': '',
      'name_en': '',
      'icon': 'blender',
      'sort_order': 2,
    },
    {
      'id': 'cocktails',
      'name_ar': '',
      'name_en': '',
      'icon': 'local_bar',
      'sort_order': 3,
    },
    {
      'id': 'milkshakes',
      'name_ar': '',
      'name_en': '',
      'icon': 'coffee',
      'sort_order': 4,
    },
  ],
};

/// Fallback sections for unknown venue categories.
const List<Map<String, dynamic>> _genericSections = [
  {
    'id': 'food',
    'name_ar': '',
    'name_en': '',
    'icon': 'restaurant',
    'sort_order': 1,
  },
  {
    'id': 'drinks',
    'name_ar': '',
    'name_en': '',
    'icon': 'local_drink',
    'sort_order': 2,
  },
  {
    'id': 'other',
    'name_ar': '',
    'name_en': '',
    'icon': 'more_horiz',
    'sort_order': 3,
  },
];

const String _menuImportPipelineVersion = 'v2';

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

class MenuImportJobResult {
  final String venueId;
  final String jobId;
  final String status;
  final bool idempotent;
  final bool done;

  const MenuImportJobResult({
    required this.venueId,
    required this.jobId,
    required this.status,
    required this.idempotent,
    required this.done,
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
  final FirebaseFunctions _functions;

  MenuRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  // ------- Sections -------

  /// Get menu sections for a given venue category (e.g. "cafe", "restaurant").
  List<MenuSection> getSectionsForCategory(String venueCategory) {
    final cat = venueCategory.toLowerCase();
    final rawSections = defaultMenuSections[cat] ?? _genericSections;
    return rawSections.map((m) {
      final section = MenuSection.fromJson(m);
      final fallbackName = _humanizeCategoryKey(section.id);
      return section.copyWith(
        nameAr: section.nameAr.trim().isEmpty ? fallbackName : section.nameAr,
        nameEn: section.nameEn.trim().isEmpty ? fallbackName : section.nameEn,
      );
    }).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Streams menu sections from a specific menu version categories collection.
  /// Falls back to template sections when the version has no category docs yet.
  Stream<List<MenuSection>> watchMenuSectionsForVersion(
    String venueId,
    String versionId, {
    String? venueCategory,
  }) {
    final fallback = (venueCategory == null || venueCategory.trim().isEmpty)
        ? const <MenuSection>[]
        : getSectionsForCategory(venueCategory);

    return _versionCategoriesRef(
      venueId,
      versionId,
    ).orderBy('sort_order').snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return fallback;
      }

      final sections = snap.docs.map((doc) {
        final data = doc.data();
        final rawSort = data['sort_order'];
        final sortOrder = rawSort is num
            ? rawSort.toInt()
            : int.tryParse(rawSort?.toString() ?? '') ?? 0;
        final key = _asString(data['key']);
        var nameAr = _asString(data['name_ar']) ?? key ?? doc.id;

        // Phase 0 Hotfix: Normalize section names to avoid mismatch
        nameAr = nameAr.trim().replaceAll(RegExp(r'\s+'), ' ');

        var nameEn = _asString(data['name_en']) ?? nameAr;
        nameEn = nameEn.trim().replaceAll(RegExp(r'\s+'), ' ');

        final icon = _asString(data['icon']) ?? 'restaurant_menu';

        return MenuSection(
          id: doc.id,
          nameAr: nameAr,
          nameEn: nameEn,
          icon: icon,
          sortOrder: sortOrder,
        );
      }).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final filtered = sections
          .where((section) => _isLikelyValidMenuSectionName(section.nameAr))
          .toList();

      if (filtered.isEmpty) {
        return fallback;
      }
      return filtered;
    });
  }

  /// Watches visible menu sections for customers.
  /// Source precedence:
  /// 1) venues/{venueId}.active_menu_version_id -> menu_versions/{id}/categories
  /// 2) template sections for the venue category
  Stream<List<MenuSection>> watchMenuSections(
    String venueId, {
    required String venueCategory,
  }) {
    final controller = StreamController<List<MenuSection>>.broadcast();

    final fallback = getSectionsForCategory(venueCategory);
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? venueSub;
    StreamSubscription<List<MenuSection>>? sectionsSub;
    String? attachedSource;

    void bindSectionsStream(String? activeVersionId) {
      final source = (activeVersionId != null && activeVersionId.isNotEmpty)
          ? 'version:$activeVersionId'
          : 'template';

      if (source == attachedSource) {
        return;
      }
      attachedSource = source;

      sectionsSub?.cancel();

      if (source == 'template') {
        controller.add(fallback);
        return;
      }

      sectionsSub = watchMenuSectionsForVersion(
        venueId,
        activeVersionId!,
        venueCategory: venueCategory,
      ).listen(controller.add, onError: controller.addError);
    }

    controller.onListen = () {
      if (venueSub != null) {
        return;
      }
      venueSub = _venueRef(venueId).snapshots().listen((venueSnap) {
        final activeVersionId = _asString(
          venueSnap.data()?['active_menu_version_id'],
        );
        bindSectionsStream(activeVersionId);
      }, onError: controller.addError);
    };

    controller.onCancel = () async {
      if (controller.hasListener) {
        return;
      }
      await sectionsSub?.cancel();
      await venueSub?.cancel();
      sectionsSub = null;
      venueSub = null;
      attachedSource = null;
    };

    return controller.stream;
  }

  Future<String> addMenuSection({
    required String venueId,
    required String versionId,
    required String nameAr,
    String? nameEn,
    String icon = 'restaurant_menu',
  }) async {
    final trimmedNameAr = nameAr.trim();
    if (trimmedNameAr.isEmpty) {
      throw StateError('Section name is required.');
    }

    final categoriesRef = _versionCategoriesRef(venueId, versionId);
    final existingSnap = await categoriesRef.get();

    final duplicate = existingSnap.docs.any((doc) {
      final existingName = _asString(doc.data()['name_ar'])?.toLowerCase();
      return existingName == trimmedNameAr.toLowerCase();
    });
    if (duplicate) {
      throw StateError('Section already exists.');
    }

    var maxSortOrder = 0;
    for (final doc in existingSnap.docs) {
      final rawSort = doc.data()['sort_order'];
      final sortOrder = rawSort is num
          ? rawSort.toInt()
          : int.tryParse(rawSort?.toString() ?? '') ?? 0;
      if (sortOrder > maxSortOrder) {
        maxSortOrder = sortOrder;
      }
    }

    final normalizedEn = nameEn?.trim();
    final sectionKey = _normalizeCategoryKey(normalizedEn ?? trimmedNameAr);
    final docRef = categoriesRef.doc();

    await docRef.set({
      'key': sectionKey.isEmpty ? docRef.id : sectionKey,
      'name_ar': trimmedNameAr,
      'name_en': normalizedEn?.isNotEmpty == true
          ? normalizedEn
          : trimmedNameAr,
      'icon': icon,
      'sort_order': maxSortOrder + 1,
      'is_custom': true,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    await _menuVersionRef(venueId, versionId).set({
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return docRef.id;
  }

  Future<void> updateMenuSection({
    required String venueId,
    required String versionId,
    required String sectionId,
    required String nameAr,
    String? nameEn,
    String? icon,
  }) async {
    final trimmedNameAr = nameAr.trim();
    if (trimmedNameAr.isEmpty) {
      throw StateError('Section name is required.');
    }

    final updateData = <String, dynamic>{
      'name_ar': trimmedNameAr,
      'name_en': nameEn?.trim().isNotEmpty == true
          ? nameEn!.trim()
          : trimmedNameAr,
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (icon != null && icon.trim().isNotEmpty) {
      updateData['icon'] = icon.trim();
    }

    await _versionCategoriesRef(
      venueId,
      versionId,
    ).doc(sectionId).update(updateData);

    await _menuVersionRef(venueId, versionId).set({
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteMenuSection({
    required String venueId,
    required String versionId,
    required String sectionId,
    required String fallbackSectionId,
  }) async {
    if (sectionId == fallbackSectionId) {
      throw StateError(
        'Fallback section must be different from deleted section.',
      );
    }

    final categoriesRef = _versionCategoriesRef(venueId, versionId);
    final sourceRef = categoriesRef.doc(sectionId);
    final fallbackRef = categoriesRef.doc(fallbackSectionId);

    final sourceSnap = await sourceRef.get();
    if (!sourceSnap.exists) {
      return;
    }
    final fallbackSnap = await fallbackRef.get();
    if (!fallbackSnap.exists) {
      throw StateError('Fallback section does not exist.');
    }

    final affectedItems = await _versionItemsRef(
      venueId,
      versionId,
    ).where('category', isEqualTo: sectionId).get();

    const chunkSize = 400;
    var index = 0;
    while (index < affectedItems.docs.length) {
      final end = (index + chunkSize).clamp(0, affectedItems.docs.length);
      final chunk = affectedItems.docs.sublist(index, end);
      final batch = _firestore.batch();
      for (final itemDoc in chunk) {
        batch.update(itemDoc.reference, {
          'category': fallbackSectionId,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      index = end;
    }

    await sourceRef.delete();

    await _menuVersionRef(venueId, versionId).set({
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> reorderMenuSections({
    required String venueId,
    required String versionId,
    required List<MenuSection> orderedSections,
  }) async {
    const batchSize = 499; // Firestore limit is 500
    for (var i = 0; i < orderedSections.length; i += batchSize) {
      final batch = _firestore.batch();
      final end = (i + batchSize < orderedSections.length)
          ? i + batchSize
          : orderedSections.length;

      for (var j = i; j < end; j++) {
        final section = orderedSections[j];
        final ref = _versionCategoriesRef(venueId, versionId).doc(section.id);
        batch.set(ref, <String, dynamic>{
          'sort_order': j,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
    }
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

  CollectionReference<Map<String, dynamic>> _menuImportJobsRef(
    String venueId,
  ) => _venueRef(venueId).collection('menu_import_jobs');

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
        final items = snap.docs
            .map((d) => MenuItem.fromDoc(d))
            .where(_isLikelyValidMenuItem)
            .toList();
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
      final safeCategoryData = Map<String, dynamic>.from(category.data);
      // Phase 1: Trim categories locally before saving them to the draft
      final nameAr = _asString(safeCategoryData['name_ar']) ?? category.id;
      final nameEn = _asString(safeCategoryData['name_en']) ?? nameAr;
      safeCategoryData['name_ar'] = nameAr.trim();
      safeCategoryData['name_en'] = nameEn.trim();

      batch.set(
        _versionCategoriesRef(venueId, newDraftId).doc(category.id),
        safeCategoryData,
      );
    }

    for (final item in seed.items) {
      final safeItemData = Map<String, dynamic>.from(item.data);
      final rawNameAr = _asString(safeItemData['name_ar']) ?? 'Untitled';
      final rawNameEn = _asString(safeItemData['name_en']) ?? rawNameAr;
      final rawDescAr = _asString(safeItemData['description_ar']) ?? '';
      final rawDescEn = _asString(safeItemData['description_en']) ?? '';

      safeItemData['name_ar'] = rawNameAr.trim();
      safeItemData['name_en'] = rawNameEn.trim();
      safeItemData['description_ar'] = rawDescAr.trim();
      safeItemData['description_en'] = rawDescEn.trim();

      batch.set(
        _versionItemsRef(venueId, newDraftId).doc(item.id),
        safeItemData,
      );
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

    // Preflight counts and validations (outside transaction due to Firestore limits).
    final draftCategoriesSnap = await _versionCategoriesRef(
      venueId,
      draftVersionId,
    ).get();

    final categoryCount = draftCategoriesSnap.size;
    final validCategoryIds = draftCategoriesSnap.docs.map((d) => d.id).toSet();

    final draftItemsSnap = await _versionItemsRef(
      venueId,
      draftVersionId,
    ).get();

    final itemCount = draftItemsSnap.size;
    if (itemCount <= 0) {
      throw StateError('Cannot publish an empty menu draft.');
    }

    // Phase 1 Validate Draft Items
    for (final doc in draftItemsSnap.docs) {
      final data = doc.data();
      final itemName = _asString(data['name_ar']) ?? 'Unknown';

      final price = data['price'];
      final numPrice = price is num
          ? price
          : double.tryParse(price?.toString() ?? '');
      if (numPrice == null || numPrice < 0) {
        throw StateError(
          'Item "$itemName" has an invalid price. Please fix it before publishing.',
        );
      }

      final categoryId = _asString(data['category']);
      if (categoryId == null ||
          categoryId.isEmpty ||
          !validCategoryIds.contains(categoryId)) {
        throw StateError(
          'Item "$itemName" belongs to an invalid or deleted category. Please assign it to an existing section.',
        );
      }
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

  Future<void> reorderMenuItems({
    required String venueId,
    String? versionId,
    required List<MenuItem> orderedItems,
  }) async {
    const batchSize = 499;
    for (var i = 0; i < orderedItems.length; i += batchSize) {
      final batch = _firestore.batch();
      final end = (i + batchSize < orderedItems.length)
          ? i + batchSize
          : orderedItems.length;

      for (var j = i; j < end; j++) {
        final item = orderedItems[j];
        final ref = _itemsRefForWrite(
          venueId,
          versionId: versionId,
        ).doc(item.id);
        batch.set(ref, <String, dynamic>{
          'sort_order': j,
          'category': item.category,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
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

  /// Upload a menu import image and return a gs:// URI for pipeline input.
  Future<String> uploadMenuImportImage(String venueId, File file) async {
    final extension = _normalizedExtension(file.path);
    final allowedExtensions = <String>{'.jpg', '.jpeg', '.png', '.webp'};
    if (!allowedExtensions.contains(extension)) {
      throw StateError('Menu import currently supports image files only.');
    }

    final fileName =
        'menu_import_${DateTime.now().millisecondsSinceEpoch}$extension';
    // Uses `/photos` path to stay aligned with current Storage rules.
    final ref = _storage.ref().child('venues/$venueId/photos/$fileName');
    final metadata = SettableMetadata(
      contentType: _contentTypeFromExtension(extension),
    );
    await ref.putFile(file, metadata);
    return _toGsUri(ref);
  }

  /// Creates an import job and enqueues background processing.
  Future<MenuImportJobResult> importMenuFromImage({
    required String venueId,
    required String versionId,
    required File imageFile,
  }) async {
    final inputFileUri = await uploadMenuImportImage(venueId, imageFile);
    final idempotencyKey = await _buildImportIdempotencyKey(
      versionId: versionId,
      file: imageFile,
    );

    final created = await createMenuImportJob(
      venueId: venueId,
      versionId: versionId,
      inputFiles: [inputFileUri],
      idempotencyKey: idempotencyKey,
    );

    try {
      return enqueueMenuImport(venueId: venueId, jobId: created.jobId);
    } catch (_) {
      // Backward-compatible fallback if async callable is unavailable or transiently failing.
      return processMenuImport(venueId: venueId, jobId: created.jobId);
    }
  }

  Future<MenuImportJobResult> createMenuImportJob({
    required String venueId,
    required String versionId,
    required List<String> inputFiles,
    required String idempotencyKey,
  }) async {
    final callable = _functions.httpsCallable('createMenuImportJob');
    final result = await callable.call({
      'venueId': venueId,
      'versionId': versionId,
      'inputFiles': inputFiles,
      'idempotencyKey': idempotencyKey,
    });

    return _menuImportResultFromCallableData(
      result.data,
      fallbackVenueId: venueId,
      fallbackStatus: 'uploaded',
    );
  }

  Future<MenuImportJobResult> processMenuImport({
    required String venueId,
    required String jobId,
  }) async {
    final callable = _functions.httpsCallable('processMenuImport');
    final result = await callable.call({'venueId': venueId, 'jobId': jobId});

    return _menuImportResultFromCallableData(
      result.data,
      fallbackVenueId: venueId,
      fallbackJobId: jobId,
      fallbackStatus: 'uploaded',
    );
  }

  Future<MenuImportJobResult> enqueueMenuImport({
    required String venueId,
    required String jobId,
  }) async {
    final callable = _functions.httpsCallable('enqueueMenuImport');
    final result = await callable.call({'venueId': venueId, 'jobId': jobId});

    return _menuImportResultFromCallableData(
      result.data,
      fallbackVenueId: venueId,
      fallbackJobId: jobId,
      fallbackStatus: 'queued',
    );
  }

  Future<MenuImportJobResult?> getLatestImportJob(String venueId) async {
    final snap = await _menuImportJobsRef(
      venueId,
    ).orderBy('created_at', descending: true).limit(1).get();
    if (snap.docs.isEmpty) {
      return null;
    }

    final doc = snap.docs.first;
    final data = doc.data();
    final status = _asString(data['status']) ?? 'uploaded';
    return MenuImportJobResult(
      venueId: _asString(data['venue_id']) ?? venueId,
      jobId: doc.id,
      status: status,
      idempotent: false,
      done: status == 'review_required' || status == 'published',
    );
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

  String _normalizedExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '';
    return path.substring(dot).toLowerCase();
  }

  String _contentTypeFromExtension(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  Future<String> _buildImportIdempotencyKey({
    required String versionId,
    required File file,
  }) async {
    final stat = await file.stat();
    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'menu';
    return '$_menuImportPipelineVersion|$versionId|$fileName|${stat.size}|${stat.modified.toUtc().millisecondsSinceEpoch}';
  }

  String _toGsUri(Reference ref) => 'gs://${ref.bucket}/${ref.fullPath}';

  MenuImportJobResult _menuImportResultFromCallableData(
    Object? data, {
    required String fallbackVenueId,
    required String fallbackStatus,
    String? fallbackJobId,
  }) {
    final map = _asStringMap(data);
    final jobId = _asString(map['jobId']) ?? fallbackJobId;
    if (jobId == null || jobId.isEmpty) {
      throw StateError('Menu import function returned no jobId.');
    }

    final status = _asString(map['status']) ?? fallbackStatus;
    return MenuImportJobResult(
      venueId: _asString(map['venueId']) ?? fallbackVenueId,
      jobId: jobId,
      status: status,
      idempotent: _asBool(map['idempotent']),
      done:
          _asBool(map['done']) ||
          status == 'review_required' ||
          status == 'published',
    );
  }

  Map<String, dynamic> _asStringMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map<Object?, Object?>) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return const <String, dynamic>{};
  }

  String? _asString(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return trimmed;
    }
    return null;
  }

  bool _asBool(Object? value) => value == true;

  bool _isLikelyValidMenuSectionName(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return false;
    if (text.length > 60) return false;

    final lower = text.toLowerCase();
    const noisyTokens = <String>[
      'http',
      'www.',
      'googleapis.com',
      'type.googleapis.com',
      'cloud vision api',
      'enable it by visiting',
      'permission_denied',
      'service_disabled',
      'contact us',
      '"error"',
      '"status"',
      '"details"',
    ];
    if (noisyTokens.any(lower.contains)) return false;
    if (RegExp(r'[{}\[\]]').hasMatch(text)) return false;
    if (RegExp(r'^[:/]+').hasMatch(text)) return false;

    return true;
  }

  bool _isLikelyValidMenuItem(MenuItem item) {
    if (item.nameAr.trim().isEmpty) return false;
    if (item.nameAr.length > 80) return false;

    // Filter noise like error messages and links
    if (!_isLikelyValidMenuSectionName(item.nameAr)) return false;
    if (!_isLikelyValidMenuSectionName(item.category)) return false;

    // Filter out mojibake and corrupt characters (Phase 0 Hotfix)
    if (item.nameAr.contains('\uFFFD') || item.category.contains('\uFFFD')) {
      return false;
    }

    // Filter missing/invalid prices if we want to be overly strict
    // but the prompt said "No price -> block publish", not block view entirely,
    // although blocking view of invalid items is also good. We'll leave price out for now
    // to not break items that were intentionally set with price=0 or something valid.

    return true;
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
