import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wain_app/core/providers/location_provider.dart';
import 'package:wain_app/features/discovery/presentation/providers/search_state.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/profile/presentation/providers/settings_providers.dart';
import 'package:wain_app/core/utils/opening_hours_utils.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';

enum SortOption { nearest, topRated }

SortOption _sortOptionFromDiscovery(SortBy sortBy) {
  switch (sortBy) {
    case SortBy.rating:
      return SortOption.topRated;
    case SortBy.distance:
    case SortBy.budgetLow:
    case SortBy.budgetHigh:
      return SortOption.nearest;
  }
}

/// Currently selected venue on the map
class SelectedVenue extends Notifier<Venue?> {
  @override
  Venue? build() => null;

  void select(Venue? venue) {
    state = venue;
  }
}

final selectedVenueProvider = NotifierProvider<SelectedVenue, Venue?>(
  SelectedVenue.new,
);

/// Map filter state
class MapFilterState {
  final String query;
  final List<String> moodTags;
  final List<String> occasionTags;
  final List<String> timeTags;
  final List<String> categories;
  final bool openNow;
  final int? minBudget;
  final int? maxBudget;
  final dynamic searchCenter; // LatLng or null
  final bool showPartnersOnly;
  final bool hasOffers;
  final SortOption sortBy;
  final bool softDiscoveryFilters;

  const MapFilterState({
    this.query = '',
    this.moodTags = const [],
    this.occasionTags = const [],
    this.timeTags = const [],
    this.categories = const [],
    this.openNow = false,
    this.minBudget,
    this.maxBudget,
    this.searchCenter,
    this.showPartnersOnly = false,
    this.hasOffers = false,
    this.sortBy = SortOption.nearest,
    this.softDiscoveryFilters = false,
  });

  MapFilterState copyWith({
    String? query,
    List<String>? moodTags,
    List<String>? occasionTags,
    List<String>? timeTags,
    List<String>? categories,
    bool? openNow,
    int? minBudget,
    int? maxBudget,
    bool clearBudget = false,
    dynamic searchCenter,
    bool clearSearchCenter = false,
    bool? showPartnersOnly,
    bool? hasOffers,
    SortOption? sortBy,
    bool? softDiscoveryFilters,
  }) {
    return MapFilterState(
      query: query ?? this.query,
      moodTags: moodTags ?? this.moodTags,
      occasionTags: occasionTags ?? this.occasionTags,
      timeTags: timeTags ?? this.timeTags,
      categories: categories ?? this.categories,
      openNow: openNow ?? this.openNow,
      minBudget: clearBudget ? null : (minBudget ?? this.minBudget),
      maxBudget: clearBudget ? null : (maxBudget ?? this.maxBudget),
      searchCenter: clearSearchCenter
          ? null
          : (searchCenter ?? this.searchCenter),
      showPartnersOnly: showPartnersOnly ?? this.showPartnersOnly,
      hasOffers: hasOffers ?? this.hasOffers,
      sortBy: sortBy ?? this.sortBy,
      softDiscoveryFilters: softDiscoveryFilters ?? this.softDiscoveryFilters,
    );
  }

  bool get hasActiveFilters =>
      query.isNotEmpty ||
      moodTags.isNotEmpty ||
      occasionTags.isNotEmpty ||
      timeTags.isNotEmpty ||
      categories.isNotEmpty ||
      openNow ||
      minBudget != null ||
      maxBudget != null ||
      showPartnersOnly ||
      hasOffers ||
      sortBy != SortOption.nearest;
}

/// Map filter provider with notifier for state management
class MapFilter extends Notifier<MapFilterState> {
  @override
  MapFilterState build() => const MapFilterState();

  void setQuery(String query) {
    state = state.copyWith(query: query, softDiscoveryFilters: false);
  }

  void toggleMood(String mood) {
    final moods = List<String>.from(state.moodTags);
    if (moods.contains(mood)) {
      moods.remove(mood);
    } else {
      moods.add(mood);
    }
    state = state.copyWith(moodTags: moods, softDiscoveryFilters: false);
  }

  void toggleOccasion(String occasion) {
    final occasions = List<String>.from(state.occasionTags);
    if (occasions.contains(occasion)) {
      occasions.remove(occasion);
    } else {
      occasions.add(occasion);
    }
    state = state.copyWith(
      occasionTags: occasions,
      softDiscoveryFilters: false,
    );
  }

  void toggleCategory(String category) {
    final cats = List<String>.from(state.categories);
    if (cats.contains(category)) {
      cats.remove(category);
    } else {
      cats.add(category);
    }
    state = state.copyWith(categories: cats, softDiscoveryFilters: false);
  }

  void toggleOpenNow() {
    state = state.copyWith(
      openNow: !state.openNow,
      softDiscoveryFilters: false,
    );
  }

  void toggleShowPartners() {
    state = state.copyWith(
      showPartnersOnly: !state.showPartnersOnly,
      softDiscoveryFilters: false,
    );
  }

  void toggleHasOffers() {
    state = state.copyWith(
      hasOffers: !state.hasOffers,
      softDiscoveryFilters: false,
    );
  }

  void setSort(SortOption option) {
    state = state.copyWith(sortBy: option, softDiscoveryFilters: false);
  }

  void setBudget(int min, int max) {
    state = state.copyWith(
      minBudget: min,
      maxBudget: max,
      softDiscoveryFilters: false,
    );
  }

  void setSearchArea(dynamic center) {
    state = state.copyWith(
      searchCenter: center,
      clearSearchCenter: center == null,
      softDiscoveryFilters: false,
    );
  }

  /// Apply search state from discovery flow filters.
  void applyFromSearchState({
    List<String> moodTags = const [],
    List<String> occasionTags = const [],
    List<String> timeTags = const [],
    List<String> categories = const [],
    int? minBudget,
    int? maxBudget,
    SortBy sortBy = SortBy.distance,
  }) {
    final usesDefaultBudget = minBudget == 30 && maxBudget == 200;

    state = state.copyWith(
      moodTags: moodTags,
      occasionTags: occasionTags,
      timeTags: timeTags,
      categories: categories,
      minBudget: usesDefaultBudget ? null : minBudget,
      maxBudget: usesDefaultBudget ? null : maxBudget,
      clearBudget: usesDefaultBudget,
      sortBy: _sortOptionFromDiscovery(sortBy),
      softDiscoveryFilters: true,
    );
  }

  void clearAll() {
    state = const MapFilterState();
  }
}

final mapFilterProvider = NotifierProvider<MapFilter, MapFilterState>(
  MapFilter.new,
);

/// Provider that fetches venue IDs with active offers from Firestore
final venueIdsWithOffersProvider = FutureProvider<Set<String>>((ref) async {
  final now = DateTime.now();
  final snapshot = await FirebaseFirestore.instance
      .collection('offers')
      .where('is_active', isEqualTo: true)
      .get();

  final venueIds = <String>{};
  for (final doc in snapshot.docs) {
    final data = doc.data();
    // Also check expiry if available
    final expiresAt = data['expires_at'];
    if (expiresAt != null) {
      final expiryDate = (expiresAt as dynamic).toDate() as DateTime;
      if (expiryDate.isBefore(now)) continue; // Skip expired
    }
    final venueId = data['venue_id'] as String?;
    if (venueId != null) venueIds.add(venueId);
  }
  return venueIds;
});

const Map<String, Set<String>> _filterAliases = {
  'restaurant': {
    'restaurant',
    'restaurants',
    'dining',
    'food',
    'مطعم',
    'مطاعم',
  },
  'cafe': {
    'cafe',
    'cafes',
    'coffee',
    'coffee_shop',
    'coffee shop',
    'coffeehouse',
    'كافيه',
    'كافيهات',
    'مقهى',
    'مقاهي',
    'قهوة',
  },
  'fast_food': {'fast_food', 'fast food', 'burger', 'burgers', 'وجبات سريعة'},
  'desserts': {'dessert', 'desserts', 'sweet', 'sweets', 'حلويات'},
  'seafood': {'seafood', 'fish', 'سمك', 'مأكولات بحرية'},
  'arabic': {
    'arabic',
    'middle_eastern',
    'middle eastern',
    'levantine',
    'شرقي',
    'عربي',
  },
  'italian': {'italian', 'pizza', 'pasta', 'ايطالي', 'إيطالي'},
  'asian': {'asian', 'sushi', 'chinese', 'japanese', 'آسيوي', 'اسيوي'},
  'american': {'american', 'steak', 'أمريكي', 'امريكي'},
  'family_kids': {
    'family_kids',
    'family',
    'kids',
    'عائلي',
    'عائلة',
    'اطفال',
    'أطفال',
  },
  'romantic': {'romantic', 'date', 'couples', 'رومانسي'},
};

String _normalizeFilterValue(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll(RegExp(r'[\s\-]+'), '_');
}

Set<String> _expandedFilterValues(Iterable<String> values) {
  final expanded = <String>{};

  for (final value in values) {
    final key = _normalizeFilterValue(value);
    if (key.isEmpty) continue;

    expanded.add(key);
    for (final entry in _filterAliases.entries) {
      final normalizedAliases = <String>{
        _normalizeFilterValue(entry.key),
        for (final alias in entry.value) _normalizeFilterValue(alias),
      };

      if (normalizedAliases.contains(key)) {
        expanded.addAll(normalizedAliases);
      }
    }
  }

  return expanded;
}

bool _matchesAnyFilterValue(
  Iterable<String> venueValues,
  Iterable<String> selectedFilters,
) {
  final selected = _expandedFilterValues(selectedFilters);
  if (selected.isEmpty) return true;

  final venue = _expandedFilterValues(venueValues);
  return venue.any(selected.contains);
}

bool _budgetOverlapsVenue(Venue venue, int minBudget, int maxBudget) {
  final hasKnownBudget = venue.minPrice > 0 || venue.maxPrice > 0;
  if (!hasKnownBudget) {
    return true;
  }

  final rawMin = venue.minPrice > 0 ? venue.minPrice : venue.maxPrice;
  final rawMax = venue.maxPrice > 0 ? venue.maxPrice : venue.minPrice;
  final venueMin = rawMin <= rawMax ? rawMin : rawMax;
  final venueMax = rawMax >= rawMin ? rawMax : rawMin;
  return venueMin <= maxBudget && venueMax >= minBudget;
}

/// Provider for filtered venues (Optimized for performance)
final filteredVenuesProvider = Provider.autoDispose<List<Venue>>((ref) {
  final city = ref.watch(cityProvider);
  // 1. Get raw venues
  final venuesState = ref.watch(cachedVenuesProvider(city: city));
  final venues = venuesState.venues;

  // 2. Get active filters
  final filterState = ref.watch(mapFilterProvider);

  // Get user location for sorting
  final userLocationAsync = ref.watch(userLocationProvider);
  final userLocation = userLocationAsync.asData?.value;

  if (venues.isEmpty) return [];
  // If no filters and no search center and nearest sort (default), return raw (or sorted by location if available)
  if (!filterState.hasActiveFilters &&
      filterState.searchCenter == null &&
      userLocation == null) {
    return venues;
  }

  // 3. Apply Filters
  var filtered = venues;

  // Search query
  if (filterState.query.isNotEmpty) {
    final q = filterState.query.toLowerCase();
    filtered = filtered.where((v) {
      return v.nameAr.toLowerCase().contains(q) ||
          v.nameEn.toLowerCase().contains(q) ||
          v.categories.any((c) => c.toLowerCase().contains(q));
    }).toList();
  }

  // Moods
  if (filterState.moodTags.isNotEmpty) {
    filtered = filtered.where((v) {
      return _matchesAnyFilterValue(v.tags.mood, filterState.moodTags);
    }).toList();
  }

  // Occasions
  if (filterState.occasionTags.isNotEmpty) {
    filtered = filtered.where((v) {
      return _matchesAnyFilterValue(v.tags.occasion, filterState.occasionTags);
    }).toList();
  }

  // Time of day
  if (filterState.timeTags.isNotEmpty) {
    filtered = filtered.where((v) {
      return _matchesAnyFilterValue(v.tags.timeOfDay, filterState.timeTags);
    }).toList();
  }

  // Categories
  if (filterState.categories.isNotEmpty) {
    filtered = filtered.where((v) {
      return _matchesAnyFilterValue(v.categories, filterState.categories);
    }).toList();
  }

  // Budget overlap: venue price range must intersect the selected range.
  if (filterState.minBudget != null || filterState.maxBudget != null) {
    final minBudget = filterState.minBudget ?? 0;
    final maxBudget = filterState.maxBudget ?? 1 << 30;
    filtered = filtered.where((v) {
      return _budgetOverlapsVenue(v, minBudget, maxBudget);
    }).toList();
  }

  // Open Now
  if (filterState.openNow) {
    filtered = filtered.where((v) {
      return OpeningHoursUtils.isOpenNow(v.hours, v.is24h);
    }).toList();
  }

  // Partners Only
  if (filterState.showPartnersOnly) {
    filtered = filtered.where((v) => v.partner.isPartner).toList();
  }

  // Has Offers — cross-reference with offers collection
  if (filterState.hasOffers) {
    final offerVenueIds =
        ref.watch(venueIdsWithOffersProvider).asData?.value ?? {};
    filtered = filtered.where((v) => offerVenueIds.contains(v.id)).toList();
  }

  if (filtered.isEmpty &&
      filterState.softDiscoveryFilters &&
      filterState.query.isEmpty) {
    // Discovery choices are useful map context, but they should not make the
    // map look broken when venue metadata is incomplete or tags do not match.
    filtered = venues;
  }

  // 4. Sort
  if (filterState.sortBy == SortOption.topRated) {
    filtered.sort((a, b) => b.rating.compareTo(a.rating));
  } else {
    // Nearest
    if (filterState.searchCenter != null) {
      final center = filterState.searchCenter;
      filtered.sort((a, b) {
        final distA =
            (a.lat - center.latitude) * (a.lat - center.latitude) +
            (a.lng - center.longitude) * (a.lng - center.longitude);
        final distB =
            (b.lat - center.latitude) * (b.lat - center.latitude) +
            (b.lng - center.longitude) * (b.lng - center.longitude);
        return distA.compareTo(distB);
      });
    } else if (userLocation != null) {
      filtered.sort((a, b) {
        final distA =
            (a.lat - userLocation.latitude) * (a.lat - userLocation.latitude) +
            (a.lng - userLocation.longitude) * (a.lng - userLocation.longitude);
        final distB =
            (b.lat - userLocation.latitude) * (b.lat - userLocation.latitude) +
            (b.lng - userLocation.longitude) * (b.lng - userLocation.longitude);
        return distA.compareTo(distB);
      });
    }
  }

  return filtered;
});
