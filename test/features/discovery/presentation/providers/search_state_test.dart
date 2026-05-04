import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wain_app/features/discovery/presentation/providers/search_state.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';

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

    test('active filter count includes discovery and filter sheet choices', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(searchProvider.notifier);
      notifier.setMoods(['chill']);
      notifier.setOccasions(['birthday']);
      notifier.setTimes(['evening']);
      notifier.setBudgetRange(50, 120);
      notifier.setCuisineTypes(['cafe']);
      notifier.setSortBy(SortBy.distance);

      expect(notifier.hasActiveFilters, isTrue);
      expect(notifier.activeFilterCount, 6);
    });

    test('persists and restores complete search state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(searchProvider.notifier);
      notifier.setCity('bethlehem');
      notifier.setMoods(['family']);
      notifier.setOccasions(['meeting']);
      notifier.setTimes(['morning']);
      notifier.setBudgetRange(40, 160);
      notifier.setCuisineTypes(['palestinian']);
      notifier.setSortBy(SortBy.budgetLow);
      await Future<void>.delayed(Duration.zero);

      final restoredContainer = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(restoredContainer.dispose);

      final restored = restoredContainer.read(searchProvider);
      expect(restored.city, 'bethlehem');
      expect(restored.moodTags, ['family']);
      expect(restored.occasionTags, ['meeting']);
      expect(restored.timeTags, ['morning']);
      expect(restored.minBudget, 40);
      expect(restored.maxBudget, 160);
      expect(restored.cuisineTypes, ['palestinian']);
      expect(restored.sortBy, SortBy.budgetLow);
    });
  });
}
