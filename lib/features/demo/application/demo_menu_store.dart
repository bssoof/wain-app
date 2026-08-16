import 'dart:async';

import 'package:wain_app/features/menu/data/demo_menu_catalog.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/domain/entities/menu_section.dart';

/// Editable, process-local copy of the demo menu used by merchant screens.
class DemoMenuStore {
  DemoMenuStore() {
    reset(notify: false);
  }

  final StreamController<void> _changes = StreamController<void>.broadcast(
    sync: true,
  );

  late List<MenuSection> _sections;
  late List<MenuItem> _items;
  late DateTime publishedAt;
  var _sectionSerial = 0;
  var _itemSerial = 0;
  var _versionSerial = 0;

  String get draftVersionId => 'demo_draft_${_versionSerial + 1}';
  String get activeVersionId => _versionSerial == 0
      ? demoMenuActiveVersionId
      : 'demo_published_$_versionSerial';
  List<MenuSection> get sections => List.unmodifiable(_sections);
  List<MenuItem> get items => List.unmodifiable(_items);

  Stream<List<MenuSection>> watchSections() =>
      _watch(() => List<MenuSection>.unmodifiable(_sections));
  Stream<List<MenuItem>> watchItems() =>
      _watch(() => List<MenuItem>.unmodifiable(_items));

  Stream<T> _watch<T>(T Function() value) async* {
    yield value();
    await for (final _ in _changes.stream) {
      yield value();
    }
  }

  void reset({bool notify = true}) {
    _sections = demoMenuSections.map((section) => section.copyWith()).toList();
    _items = demoMenuItems.map((item) => item.copyWith()).toList();
    publishedAt = demoMenuPublishedAt();
    _sectionSerial = 0;
    _itemSerial = 0;
    _versionSerial = 0;
    if (notify) _notify();
  }

  String addSection({
    required String nameAr,
    String? nameEn,
    required String icon,
  }) {
    final normalized = nameAr.trim();
    if (normalized.isEmpty) throw StateError('Section name is required.');
    if (_sections.any((section) => section.nameAr.trim() == normalized)) {
      throw StateError('Section already exists.');
    }
    _sectionSerial += 1;
    final id = 'demo_section_local_$_sectionSerial';
    _sections.add(
      MenuSection(
        id: id,
        nameAr: normalized,
        nameEn: nameEn?.trim().isNotEmpty == true ? nameEn!.trim() : normalized,
        icon: icon,
        sortOrder: _sections.length,
      ),
    );
    _notify();
    return id;
  }

  void updateSection({
    required String sectionId,
    required String nameAr,
    String? nameEn,
    String? icon,
  }) {
    final index = _sections.indexWhere((section) => section.id == sectionId);
    if (index < 0) throw StateError('section_not_found');
    final current = _sections[index];
    _sections[index] = current.copyWith(
      nameAr: nameAr.trim(),
      nameEn: nameEn?.trim().isNotEmpty == true
          ? nameEn!.trim()
          : nameAr.trim(),
      icon: icon?.trim().isNotEmpty == true ? icon!.trim() : current.icon,
    );
    _notify();
  }

  void deleteSection(String sectionId, String fallbackSectionId) {
    if (sectionId == fallbackSectionId) {
      throw StateError('Fallback section must be different.');
    }
    if (!_sections.any((section) => section.id == fallbackSectionId)) {
      throw StateError('Fallback section does not exist.');
    }
    _sections.removeWhere((section) => section.id == sectionId);
    _items = [
      for (final item in _items)
        item.category == sectionId
            ? item.copyWith(category: fallbackSectionId)
            : item,
    ];
    _normalizeSortOrders();
    _notify();
  }

  void reorderSections(List<MenuSection> ordered) {
    _sections = [
      for (var index = 0; index < ordered.length; index += 1)
        ordered[index].copyWith(sortOrder: index),
    ];
    _notify();
  }

  String addItem(MenuItem item) {
    _itemSerial += 1;
    final id = 'demo_item_local_$_itemSerial';
    _items.add(item.copyWith(id: id, sortOrder: _items.length));
    _notify();
    return id;
  }

  void updateItem(MenuItem item) {
    final index = _items.indexWhere((candidate) => candidate.id == item.id);
    if (index < 0) throw StateError('item_not_found');
    _items[index] = item;
    _notify();
  }

  void deleteItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    _normalizeSortOrders();
    _notify();
  }

  void reorderItems(List<MenuItem> ordered) {
    _items = [
      for (var index = 0; index < ordered.length; index += 1)
        ordered[index].copyWith(sortOrder: index),
    ];
    _notify();
  }

  void toggleAvailability(String itemId, bool available) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index < 0) throw StateError('item_not_found');
    _items[index] = _items[index].copyWith(isAvailable: available);
    _notify();
  }

  void publish() {
    if (_items.isEmpty) throw StateError('Cannot publish an empty menu draft.');
    _versionSerial += 1;
    publishedAt = DateTime.now();
    _notify();
  }

  void rollbackToInitial() {
    _sections = demoMenuSections.map((section) => section.copyWith()).toList();
    _items = demoMenuItems.map((item) => item.copyWith()).toList();
    publishedAt = DateTime.now();
    _versionSerial += 1;
    _notify();
  }

  void _normalizeSortOrders() {
    _sections = [
      for (var index = 0; index < _sections.length; index += 1)
        _sections[index].copyWith(sortOrder: index),
    ];
    _items = [
      for (var index = 0; index < _items.length; index += 1)
        _items[index].copyWith(sortOrder: index),
    ];
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  void dispose() => _changes.close();
}
