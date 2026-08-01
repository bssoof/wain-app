import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/core/providers/location_provider.dart';
import 'package:wain_app/features/discovery/presentation/providers/search_state.dart';
import 'package:wain_app/features/map/presentation/providers/map_providers.dart';
import 'package:wain_app/features/profile/presentation/providers/settings_providers.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';

Venue _venue(
  String id, {
  required int minPrice,
  required int maxPrice,
  List<String> categories = const ['cafe'],
  List<String> moodTags = const [],
  List<String> occasionTags = const [],
  List<String> timeTags = const [],
}) {
  return Venue(
    id: id,
    nameAr: id,
    nameEn: id,
    lat: 31.9,
    lng: 35.2,
    city: 'ramallah',
    categories: categories,
    tags: VenueTags(
      mood: moodTags,
      occasion: occasionTags,
      timeOfDay: timeTags,
    ),
    minPrice: minPrice,
    maxPrice: maxPrice,
    rating: 4,
    phone: '',
  );
}

void main() {
  group('MapFilter', () {
    test('applies discovery filters including time, budget, and sort', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(mapFilterProvider.notifier)
          .applyFromSearchState(
            moodTags: ['chill'],
            occasionTags: ['birthday'],
            timeTags: ['evening'],
            categories: ['cafe'],
            minBudget: 50,
            maxBudget: 130,
            sortBy: SortBy.rating,
          );

      final state = container.read(mapFilterProvider);
      expect(state.moodTags, ['chill']);
      expect(state.occasionTags, ['birthday']);
      expect(state.timeTags, ['evening']);
      expect(state.categories, ['cafe']);
      expect(state.minBudget, 50);
      expect(state.maxBudget, 130);
      expect(state.sortBy, SortOption.topRated);
      expect(state.softDiscoveryFilters, isTrue);
      expect(state.hasActiveFilters, isTrue);
    });

    test('budget alone counts as an active map filter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(mapFilterProvider.notifier).setBudget(40, 90);

      expect(container.read(mapFilterProvider).hasActiveFilters, isTrue);
    });

    test('filtered venues apply budget and time filters from map state', () {
      final container = ProviderContainer(
        overrides: [
          cityProvider.overrideWithValue('ramallah'),
          cachedVenuesProvider(city: 'ramallah').overrideWithValue(
            VenuesState(
              isLoading: false,
              venues: [
                _venue('too-cheap', minPrice: 10, maxPrice: 35),
                _venue('wrong-time', minPrice: 60, maxPrice: 100),
                _venue(
                  'match',
                  minPrice: 70,
                  maxPrice: 120,
                  timeTags: ['evening'],
                ),
              ],
            ),
          ),
          userLocationProvider.overrideWith(
            (ref) => Stream.value(
              const UserLocation(latitude: 31.9, longitude: 35.2),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(mapFilterProvider.notifier)
          .applyFromSearchState(
            timeTags: ['evening'],
            minBudget: 50,
            maxBudget: 130,
          );

      final venues = container.read(filteredVenuesProvider);
      expect(venues.map((venue) => venue.id), ['match']);
    });

    test('budget filters keep venues with unknown legacy prices', () {
      final container = ProviderContainer(
        overrides: [
          cityProvider.overrideWithValue('ramallah'),
          cachedVenuesProvider(city: 'ramallah').overrideWithValue(
            VenuesState(
              isLoading: false,
              venues: [
                _venue('legacy-unknown-price', minPrice: 0, maxPrice: 0),
                _venue('too-cheap', minPrice: 10, maxPrice: 35),
                _venue('match', minPrice: 70, maxPrice: 120),
              ],
            ),
          ),
          userLocationProvider.overrideWith(
            (ref) => Stream.value(
              const UserLocation(latitude: 31.9, longitude: 35.2),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(mapFilterProvider.notifier).setBudget(50, 130);

      final venues = container.read(filteredVenuesProvider);
      expect(
        venues.map((venue) => venue.id),
        unorderedEquals(['legacy-unknown-price', 'match']),
      );
    });

    test('category filters match aliases instead of exact strings only', () {
      final container = ProviderContainer(
        overrides: [
          cityProvider.overrideWithValue('ramallah'),
          cachedVenuesProvider(city: 'ramallah').overrideWithValue(
            VenuesState(
              isLoading: false,
              venues: [
                _venue(
                  'restaurant-plural',
                  minPrice: 60,
                  maxPrice: 100,
                  categories: ['restaurants'],
                ),
                _venue(
                  'restaurant-arabic',
                  minPrice: 60,
                  maxPrice: 100,
                  categories: ['مطاعم'],
                ),
                _venue(
                  'coffee',
                  minPrice: 60,
                  maxPrice: 100,
                  categories: ['coffee'],
                ),
              ],
            ),
          ),
          userLocationProvider.overrideWith(
            (ref) => Stream.value(
              const UserLocation(latitude: 31.9, longitude: 35.2),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(mapFilterProvider.notifier).toggleCategory('restaurant');

      final venues = container.read(filteredVenuesProvider);
      expect(
        venues.map((venue) => venue.id),
        unorderedEquals(['restaurant-plural', 'restaurant-arabic']),
      );
    });

    test('family and cafe filters match normalized venue metadata', () {
      final container = ProviderContainer(
        overrides: [
          cityProvider.overrideWithValue('ramallah'),
          cachedVenuesProvider(city: 'ramallah').overrideWithValue(
            VenuesState(
              isLoading: false,
              venues: [
                _venue(
                  'family-coffee',
                  minPrice: 60,
                  maxPrice: 100,
                  categories: ['coffee_shop'],
                  occasionTags: ['family'],
                ),
                _venue(
                  'family-cafe',
                  minPrice: 60,
                  maxPrice: 100,
                  categories: ['cafe'],
                  occasionTags: ['عائلي'],
                ),
                _venue(
                  'coffee-only',
                  minPrice: 60,
                  maxPrice: 100,
                  categories: ['coffee'],
                ),
              ],
            ),
          ),
          userLocationProvider.overrideWith(
            (ref) => Stream.value(
              const UserLocation(latitude: 31.9, longitude: 35.2),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(mapFilterProvider.notifier)
        ..toggleCategory('cafe')
        ..toggleOccasion('family_kids');

      final venues = container.read(filteredVenuesProvider);
      expect(
        venues.map((venue) => venue.id),
        unorderedEquals(['family-coffee', 'family-cafe']),
      );
    });

    test('soft discovery filters fall back instead of emptying map', () {
      final container = ProviderContainer(
        overrides: [
          cityProvider.overrideWithValue('ramallah'),
          cachedVenuesProvider(city: 'ramallah').overrideWithValue(
            VenuesState(
              isLoading: false,
              venues: [
                _venue('first', minPrice: 60, maxPrice: 100),
                _venue('second', minPrice: 70, maxPrice: 120),
              ],
            ),
          ),
          userLocationProvider.overrideWith(
            (ref) => Stream.value(
              const UserLocation(latitude: 31.9, longitude: 35.2),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(mapFilterProvider.notifier)
          .applyFromSearchState(categories: ['nonexistent']);

      final venues = container.read(filteredVenuesProvider);
      expect(venues.map((venue) => venue.id), ['first', 'second']);
    });

    test('manual map filters remain strict', () {
      final container = ProviderContainer(
        overrides: [
          cityProvider.overrideWithValue('ramallah'),
          cachedVenuesProvider(city: 'ramallah').overrideWithValue(
            VenuesState(
              isLoading: false,
              venues: [_venue('first', minPrice: 60, maxPrice: 100)],
            ),
          ),
          userLocationProvider.overrideWith(
            (ref) => Stream.value(
              const UserLocation(latitude: 31.9, longitude: 35.2),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(mapFilterProvider.notifier).toggleCategory('restaurant');

      final venues = container.read(filteredVenuesProvider);
      expect(venues, isEmpty);
    });
  });
}
