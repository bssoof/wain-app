import 'dart:io';

import 'package:wain_app/features/demo/application/demo_menu_store.dart';
import 'package:wain_app/features/menu/data/demo_menu_catalog.dart';
import 'package:wain_app/features/menu/data/repositories/menu_repository.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/domain/entities/menu_section.dart';

/// Firebase-free menu editor used only while the merchant demo session is on.
class DemoMenuRepository extends MenuRepository {
  DemoMenuRepository(this._store) : super.detached();

  final DemoMenuStore _store;

  @override
  Stream<List<MenuSection>> watchMenuSectionsForVersion(
    String venueId,
    String versionId, {
    String? venueCategory,
  }) => _store.watchSections();

  @override
  Stream<List<MenuSection>> watchMenuSections(
    String venueId, {
    required String venueCategory,
  }) => _store.watchSections();

  @override
  Stream<List<MenuItem>> watchMenuItems(String venueId) => _store.watchItems();

  @override
  Stream<List<MenuItem>> watchMenuItemsForVersion(
    String venueId,
    String versionId,
  ) => _store.watchItems();

  @override
  Future<List<MenuItem>> getMenuItems(String venueId) async => _store.items;

  @override
  Future<List<MenuItem>> getMenuItemsForVersion(
    String venueId,
    String versionId,
  ) async => _store.items;

  @override
  Future<MenuDraftContext> ensureDraftVersion({
    required String venueId,
    required String venueCategory,
    required String merchantUid,
  }) async => MenuDraftContext(
    venueId: venueId,
    draftVersionId: _store.draftVersionId,
    activeVersionId: _store.activeVersionId,
  );

  @override
  Future<void> publishDraftVersion({
    required String venueId,
    required String merchantUid,
  }) async => _store.publish();

  @override
  Future<void> rollbackToVersion({
    required String venueId,
    required String targetVersionId,
    required String merchantUid,
  }) async => _store.rollbackToInitial();

  @override
  Future<List<MenuVersionSummary>> listMenuVersions(String venueId) async => [
    MenuVersionSummary.fromDates(
      versionId: _store.activeVersionId,
      status: 'active',
      source: 'demo-local',
      createdAt: _store.publishedAt.subtract(const Duration(hours: 1)),
      publishedAt: _store.publishedAt,
    ),
    MenuVersionSummary.fromDates(
      versionId: demoMenuActiveVersionId,
      status: 'archived',
      source: 'demo-catalog',
      createdAt: demoMenuPublishedAt().subtract(const Duration(hours: 3)),
      publishedAt: demoMenuPublishedAt(),
    ),
  ];

  @override
  Future<MenuVersionSummary?> getMenuVersionSummaryById({
    required String venueId,
    required String versionId,
  }) async => MenuVersionSummary.fromDates(
    versionId: _store.activeVersionId,
    status: 'active',
    source: 'demo-local',
    createdAt: _store.publishedAt.subtract(const Duration(hours: 1)),
    publishedAt: _store.publishedAt,
  );

  @override
  Future<String> addMenuSection({
    required String venueId,
    required String versionId,
    required String nameAr,
    String? nameEn,
    String icon = 'restaurant_menu',
  }) async => _store.addSection(nameAr: nameAr, nameEn: nameEn, icon: icon);

  @override
  Future<void> updateMenuSection({
    required String venueId,
    required String versionId,
    required String sectionId,
    required String nameAr,
    String? nameEn,
    String? icon,
  }) async => _store.updateSection(
    sectionId: sectionId,
    nameAr: nameAr,
    nameEn: nameEn,
    icon: icon,
  );

  @override
  Future<void> deleteMenuSection({
    required String venueId,
    required String versionId,
    required String sectionId,
    required String fallbackSectionId,
  }) async => _store.deleteSection(sectionId, fallbackSectionId);

  @override
  Future<void> reorderMenuSections({
    required String venueId,
    required String versionId,
    required List<MenuSection> orderedSections,
  }) async => _store.reorderSections(orderedSections);

  @override
  Future<String> addMenuItem(
    String venueId,
    MenuItem item, {
    String? versionId,
  }) async => _store.addItem(item);

  @override
  Future<void> updateMenuItem(
    String venueId,
    MenuItem item, {
    String? versionId,
  }) async => _store.updateItem(item);

  @override
  Future<void> deleteMenuItem(
    String venueId,
    MenuItem item, {
    String? versionId,
  }) async => _store.deleteItem(item.id);

  @override
  Future<void> reorderMenuItems({
    required String venueId,
    String? versionId,
    required List<MenuItem> orderedItems,
  }) async => _store.reorderItems(orderedItems);

  @override
  Future<void> toggleAvailability(
    String venueId,
    String itemId,
    bool available, {
    String? versionId,
  }) async => _store.toggleAvailability(itemId, available);

  @override
  Future<String> uploadMenuItemPhoto(String venueId, File file) async =>
      Uri.file(file.path).toString();
}
