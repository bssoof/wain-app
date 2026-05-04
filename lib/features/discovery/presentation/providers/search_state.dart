import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wain_app/core/constants/app_constants.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';

part 'search_state.freezed.dart';
part 'search_state.g.dart';

/// Sort options for search results
enum SortBy {
  rating, // التقييم
  distance, // المسافة
  budgetLow, // السعر: من الأقل للأعلى
  budgetHigh, // السعر: من الأعلى للأقل
}

@freezed
sealed class SearchState with _$SearchState {
  const factory SearchState({
    @Default('ramallah') String city,
    @Default(<String>[]) List<String> moodTags,
    @Default(<String>[]) List<String> occasionTags,
    @Default(<String>[]) List<String> timeTags,
    // Budget filter (30-200 ILS per person)
    @Default(30) int minBudget,
    @Default(200) int maxBudget,
    // Cuisine multi-select
    @Default(<String>[]) List<String> cuisineTypes,
    // Sort options
    @Default(SortBy.rating) SortBy sortBy,
  }) = _SearchState;
}

/// SharedPreferences key for persisted SearchState JSON.
const _kSearchStateKey = 'lastSearchState';

@Riverpod(keepAlive: true)
class SearchNotifier extends _$SearchNotifier {
  @override
  SearchState build() {
    // Attempt to restore persisted state on first access.
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final json = prefs.getString(_kSearchStateKey);
      if (json != null && json.isNotEmpty) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return SearchState(
          city: (map['city'] as String?) ?? AppConstants.defaultCity,
          moodTags: _toStringList(map['moodTags']),
          occasionTags: _toStringList(map['occasionTags']),
          timeTags: _toStringList(map['timeTags']),
          minBudget: (map['minBudget'] as num?)?.toInt() ?? 30,
          maxBudget: (map['maxBudget'] as num?)?.toInt() ?? 200,
          cuisineTypes: _toStringList(map['cuisineTypes']),
          sortBy: SortBy.values.firstWhere(
            (e) => e.name == (map['sortBy'] as String?),
            orElse: () => SortBy.rating,
          ),
        );
      }
    } catch (_) {
      // Corrupted prefs — fall through to default.
    }
    return const SearchState();
  }

  // ── Setters ──────────────────────────────────────────────

  void setCity(String city) {
    state = state.copyWith(city: city);
    _persist();
  }

  void setMoods(List<String> tags) {
    state = state.copyWith(moodTags: tags);
    _persist();
  }

  void setOccasions(List<String> tags) {
    state = state.copyWith(occasionTags: tags);
    _persist();
  }

  void setTimes(List<String> tags) {
    state = state.copyWith(timeTags: tags);
    _persist();
  }

  void setBudgetRange(int min, int max) {
    state = state.copyWith(minBudget: min, maxBudget: max);
    _persist();
  }

  void setCuisineTypes(List<String> types) {
    state = state.copyWith(cuisineTypes: types);
    _persist();
  }

  void toggleCuisine(String cuisine) {
    final current = List<String>.from(state.cuisineTypes);
    if (current.contains(cuisine)) {
      current.remove(cuisine);
    } else {
      current.add(cuisine);
    }
    state = state.copyWith(cuisineTypes: current);
    _persist();
  }

  void setSortBy(SortBy sortBy) {
    state = state.copyWith(sortBy: sortBy);
    _persist();
  }

  void reset({String city = AppConstants.defaultCity}) {
    state = SearchState(city: city);
    _persist();
  }

  /// Check if any filters are active
  bool get hasActiveFilters {
    return state.moodTags.isNotEmpty ||
        state.occasionTags.isNotEmpty ||
        state.timeTags.isNotEmpty ||
        state.minBudget != 30 ||
        state.maxBudget != 200 ||
        state.cuisineTypes.isNotEmpty ||
        state.sortBy != SortBy.rating;
  }

  /// Count of active filters
  int get activeFilterCount {
    int count = 0;
    if (state.moodTags.isNotEmpty) count++;
    if (state.occasionTags.isNotEmpty) count++;
    if (state.timeTags.isNotEmpty) count++;
    if (state.minBudget != 30 || state.maxBudget != 200) count++;
    if (state.cuisineTypes.isNotEmpty) count++;
    if (state.sortBy != SortBy.rating) count++;
    return count;
  }

  // ── Persistence helpers ──────────────────────────────────

  /// Persist current state to SharedPreferences as JSON.
  void _persist() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final map = <String, dynamic>{
        'city': state.city,
        'moodTags': state.moodTags,
        'occasionTags': state.occasionTags,
        'timeTags': state.timeTags,
        'minBudget': state.minBudget,
        'maxBudget': state.maxBudget,
        'cuisineTypes': state.cuisineTypes,
        'sortBy': state.sortBy.name,
      };
      prefs.setString(_kSearchStateKey, jsonEncode(map));
    } catch (_) {
      // Non-critical — silently ignore persistence failures.
    }
  }

  /// Remove persisted state (for testing).
  Future<void> clearPersistedState() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_kSearchStateKey);
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.cast<String>();
    }
    return const <String>[];
  }
}
