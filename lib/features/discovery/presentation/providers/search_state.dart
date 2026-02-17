import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_state.freezed.dart';
part 'search_state.g.dart';

/// Sort options for search results
enum SortBy {
  rating,    // التقييم
  distance,  // المسافة
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

@Riverpod(keepAlive: true)
class SearchNotifier extends _$SearchNotifier {
  @override
  SearchState build() => const SearchState();

  void setMoods(List<String> tags) => state = state.copyWith(moodTags: tags);
  void setOccasions(List<String> tags) => state = state.copyWith(occasionTags: tags);
  void setTimes(List<String> tags) => state = state.copyWith(timeTags: tags);
  
  void setBudgetRange(int min, int max) => state = state.copyWith(
    minBudget: min,
    maxBudget: max,
  );
  
  void setCuisineTypes(List<String> types) => state = state.copyWith(cuisineTypes: types);
  
  void toggleCuisine(String cuisine) {
    final current = List<String>.from(state.cuisineTypes);
    if (current.contains(cuisine)) {
      current.remove(cuisine);
    } else {
      current.add(cuisine);
    }
    state = state.copyWith(cuisineTypes: current);
  }
  
  void setSortBy(SortBy sortBy) => state = state.copyWith(sortBy: sortBy);

  void reset({String city = 'ramallah'}) => state = const SearchState(city: 'ramallah');
  
  /// Check if any filters are active
  bool get hasActiveFilters {
    return state.minBudget != 30 ||
           state.maxBudget != 200 ||
           state.cuisineTypes.isNotEmpty ||
           state.sortBy != SortBy.rating;
  }
  
  /// Count of active filters
  int get activeFilterCount {
    int count = 0;
    if (state.minBudget != 30 || state.maxBudget != 200) count++;
    if (state.cuisineTypes.isNotEmpty) count++;
    if (state.sortBy != SortBy.rating) count++;
    return count;
  }
}
