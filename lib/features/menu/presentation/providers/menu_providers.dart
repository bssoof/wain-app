import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Singleton repository instance.
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository();
});

/// Stream of menu items for a given venue.
final menuItemsProvider = StreamProvider.family<List<MenuItem>, String>((
  ref,
  venueId,
) {
  final repo = ref.watch(menuRepositoryProvider);
  return repo.watchMenuItems(venueId);
});

/// Stream menu items for a specific version (typically merchant draft editing).
final menuVersionItemsProvider =
    StreamProvider.family<List<MenuItem>, MenuVersionItemsQuery>((ref, query) {
      final repo = ref.watch(menuRepositoryProvider);
      return repo.watchMenuItemsForVersion(query.venueId, query.versionId);
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
