import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/features/demo/application/demo_merchant_session.dart';
import 'package:wain_app/features/demo/data/demo_menu_repository.dart';
import '../../data/demo_menu_catalog.dart';
import '../../data/repositories/menu_repository.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/menu_section.dart';

class MenuVersionItemsQuery {
  final String venueId;
  final String versionId;

  const MenuVersionItemsQuery({required this.venueId, required this.versionId});

  @override
  bool operator ==(Object other) {
    return other is MenuVersionItemsQuery &&
        other.venueId == venueId &&
        other.versionId == versionId;
  }

  @override
  int get hashCode => Object.hash(venueId, versionId);
}

class MenuVersionSectionsQuery {
  final String venueId;
  final String versionId;
  final String venueCategory;

  const MenuVersionSectionsQuery({
    required this.venueId,
    required this.versionId,
    required this.venueCategory,
  });

  @override
  bool operator ==(Object other) {
    return other is MenuVersionSectionsQuery &&
        other.venueId == venueId &&
        other.versionId == versionId &&
        other.venueCategory == venueCategory;
  }

  @override
  int get hashCode => Object.hash(venueId, versionId, venueCategory);
}

class MenuActiveSectionsQuery {
  final String venueId;
  final String venueCategory;

  const MenuActiveSectionsQuery({
    required this.venueId,
    required this.venueCategory,
  });

  @override
  bool operator ==(Object other) {
    return other is MenuActiveSectionsQuery &&
        other.venueId == venueId &&
        other.venueCategory == venueCategory;
  }

  @override
  int get hashCode => Object.hash(venueId, venueCategory);
}

/// Singleton repository instance.
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  if (isDemoMerchantSession(ref)) {
    return DemoMenuRepository(ref.watch(demoMenuStoreProvider));
  }
  return MenuRepository();
});

/// Stream of menu items for a given venue.
final menuItemsProvider = StreamProvider.family<List<MenuItem>, String>((
  ref,
  venueId,
) {
  // Guarded before the repository is read, not inside it. MenuRepository's
  // default constructor argument resolves FirebaseFirestore.instance, so
  // merely constructing it touches Firebase — which happened for the demo
  // venue even though watchMenuItems would then have returned local data.
  if (shouldUseDemoMenu(venueId)) {
    return Stream<List<MenuItem>>.value(demoMenuItems);
  }
  final repo = ref.watch(menuRepositoryProvider);
  return repo.watchMenuItems(venueId);
});

/// Stream menu items for a specific version (typically merchant draft editing).
final menuVersionItemsProvider =
    StreamProvider.family<List<MenuItem>, MenuVersionItemsQuery>((ref, query) {
      final repo = ref.watch(menuRepositoryProvider);
      return repo.watchMenuItemsForVersion(query.venueId, query.versionId);
    });

/// Stream menu sections for a specific version (merchant draft/editor use).
final menuVersionSectionsProvider =
    StreamProvider.family<List<MenuSection>, MenuVersionSectionsQuery>((
      ref,
      query,
    ) {
      final repo = ref.watch(menuRepositoryProvider);
      return repo.watchMenuSectionsForVersion(
        query.venueId,
        query.versionId,
        venueCategory: query.venueCategory,
      );
    });

/// Stream visible menu sections for customers from the active menu version.
final menuActiveSectionsProvider =
    StreamProvider.family<List<MenuSection>, MenuActiveSectionsQuery>((
      ref,
      query,
    ) {
      if (shouldUseDemoMenu(query.venueId)) {
        return Stream<List<MenuSection>>.value(demoMenuSections);
      }
      final repo = ref.watch(menuRepositoryProvider);
      return repo.watchMenuSections(
        query.venueId,
        venueCategory: query.venueCategory,
      );
    });

/// List all menu versions for rollback/history actions in merchant panel.
final menuVersionsProvider =
    FutureProvider.family<List<MenuVersionSummary>, String>((ref, venueId) {
      final repo = ref.watch(menuRepositoryProvider);
      return repo.listMenuVersions(venueId);
    });

/// Menu sections for a given venue category (e.g. "cafe").
final menuSectionsProvider = Provider.family<List<MenuSection>, String>((
  ref,
  venueCategory,
) {
  final repo = ref.watch(menuRepositoryProvider);
  return repo.getSectionsForCategory(venueCategory);
});

/// Grouped menu items by category for easy display.
/// Returns a `Map<String, List<MenuItem>>` where keys are section IDs.
final groupedMenuItemsProvider =
    Provider.family<Map<String, List<MenuItem>>, List<MenuItem>>((ref, items) {
      final grouped = <String, List<MenuItem>>{};
      for (final item in items) {
        grouped.putIfAbsent(item.category, () => []).add(item);
      }
      return grouped;
    });
