import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/discovery/presentation/providers/search_state.dart';

void main() {
  group('SearchNotifier', () {
    test('setCity updates the selected city', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(searchProvider.notifier).setCity('nablus');

      expect(container.read(searchProvider).city, 'nablus');
    });

    test('reset uses passed city and clears filter state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(searchProvider.notifier);
      notifier.setCity('bethlehem');
      notifier.setBudgetRange(60, 140);
      notifier.setCuisineTypes(['coffee', 'desserts']);
      notifier.setSortBy(SortBy.distance);

      notifier.reset(city: 'jerusalem');

      final state = container.read(searchProvider);
      expect(state.city, 'jerusalem');
      expect(state.minBudget, 30);
      expect(state.maxBudget, 200);
      expect(state.cuisineTypes, isEmpty);
      expect(state.sortBy, SortBy.rating);
    });
  });
}
