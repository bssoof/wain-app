// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchState {

 String get city; List<String> get moodTags; List<String> get occasionTags; List<String> get timeTags;// Budget filter (30-200 ILS per person)
 int get minBudget; int get maxBudget;// Cuisine multi-select
 List<String> get cuisineTypes;// Sort options
 SortBy get sortBy;
/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchStateCopyWith<SearchState> get copyWith => _$SearchStateCopyWithImpl<SearchState>(this as SearchState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchState&&(identical(other.city, city) || other.city == city)&&const DeepCollectionEquality().equals(other.moodTags, moodTags)&&const DeepCollectionEquality().equals(other.occasionTags, occasionTags)&&const DeepCollectionEquality().equals(other.timeTags, timeTags)&&(identical(other.minBudget, minBudget) || other.minBudget == minBudget)&&(identical(other.maxBudget, maxBudget) || other.maxBudget == maxBudget)&&const DeepCollectionEquality().equals(other.cuisineTypes, cuisineTypes)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy));
}


@override
int get hashCode => Object.hash(runtimeType,city,const DeepCollectionEquality().hash(moodTags),const DeepCollectionEquality().hash(occasionTags),const DeepCollectionEquality().hash(timeTags),minBudget,maxBudget,const DeepCollectionEquality().hash(cuisineTypes),sortBy);

@override
String toString() {
  return 'SearchState(city: $city, moodTags: $moodTags, occasionTags: $occasionTags, timeTags: $timeTags, minBudget: $minBudget, maxBudget: $maxBudget, cuisineTypes: $cuisineTypes, sortBy: $sortBy)';
}


}

/// @nodoc
abstract mixin class $SearchStateCopyWith<$Res>  {
  factory $SearchStateCopyWith(SearchState value, $Res Function(SearchState) _then) = _$SearchStateCopyWithImpl;
@useResult
$Res call({
 String city, List<String> moodTags, List<String> occasionTags, List<String> timeTags, int minBudget, int maxBudget, List<String> cuisineTypes, SortBy sortBy
});




}
/// @nodoc
class _$SearchStateCopyWithImpl<$Res>
    implements $SearchStateCopyWith<$Res> {
  _$SearchStateCopyWithImpl(this._self, this._then);

  final SearchState _self;
  final $Res Function(SearchState) _then;

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? city = null,Object? moodTags = null,Object? occasionTags = null,Object? timeTags = null,Object? minBudget = null,Object? maxBudget = null,Object? cuisineTypes = null,Object? sortBy = null,}) {
  return _then(_self.copyWith(
city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,moodTags: null == moodTags ? _self.moodTags : moodTags // ignore: cast_nullable_to_non_nullable
as List<String>,occasionTags: null == occasionTags ? _self.occasionTags : occasionTags // ignore: cast_nullable_to_non_nullable
as List<String>,timeTags: null == timeTags ? _self.timeTags : timeTags // ignore: cast_nullable_to_non_nullable
as List<String>,minBudget: null == minBudget ? _self.minBudget : minBudget // ignore: cast_nullable_to_non_nullable
as int,maxBudget: null == maxBudget ? _self.maxBudget : maxBudget // ignore: cast_nullable_to_non_nullable
as int,cuisineTypes: null == cuisineTypes ? _self.cuisineTypes : cuisineTypes // ignore: cast_nullable_to_non_nullable
as List<String>,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as SortBy,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchState].
extension SearchStatePatterns on SearchState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchState value)  $default,){
final _that = this;
switch (_that) {
case _SearchState():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchState value)?  $default,){
final _that = this;
switch (_that) {
case _SearchState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String city,  List<String> moodTags,  List<String> occasionTags,  List<String> timeTags,  int minBudget,  int maxBudget,  List<String> cuisineTypes,  SortBy sortBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchState() when $default != null:
return $default(_that.city,_that.moodTags,_that.occasionTags,_that.timeTags,_that.minBudget,_that.maxBudget,_that.cuisineTypes,_that.sortBy);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String city,  List<String> moodTags,  List<String> occasionTags,  List<String> timeTags,  int minBudget,  int maxBudget,  List<String> cuisineTypes,  SortBy sortBy)  $default,) {final _that = this;
switch (_that) {
case _SearchState():
return $default(_that.city,_that.moodTags,_that.occasionTags,_that.timeTags,_that.minBudget,_that.maxBudget,_that.cuisineTypes,_that.sortBy);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String city,  List<String> moodTags,  List<String> occasionTags,  List<String> timeTags,  int minBudget,  int maxBudget,  List<String> cuisineTypes,  SortBy sortBy)?  $default,) {final _that = this;
switch (_that) {
case _SearchState() when $default != null:
return $default(_that.city,_that.moodTags,_that.occasionTags,_that.timeTags,_that.minBudget,_that.maxBudget,_that.cuisineTypes,_that.sortBy);case _:
  return null;

}
}

}

/// @nodoc


class _SearchState implements SearchState {
  const _SearchState({this.city = 'ramallah', final  List<String> moodTags = const <String>[], final  List<String> occasionTags = const <String>[], final  List<String> timeTags = const <String>[], this.minBudget = 30, this.maxBudget = 200, final  List<String> cuisineTypes = const <String>[], this.sortBy = SortBy.rating}): _moodTags = moodTags,_occasionTags = occasionTags,_timeTags = timeTags,_cuisineTypes = cuisineTypes;
  

@override@JsonKey() final  String city;
 final  List<String> _moodTags;
@override@JsonKey() List<String> get moodTags {
  if (_moodTags is EqualUnmodifiableListView) return _moodTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_moodTags);
}

 final  List<String> _occasionTags;
@override@JsonKey() List<String> get occasionTags {
  if (_occasionTags is EqualUnmodifiableListView) return _occasionTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_occasionTags);
}

 final  List<String> _timeTags;
@override@JsonKey() List<String> get timeTags {
  if (_timeTags is EqualUnmodifiableListView) return _timeTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_timeTags);
}

// Budget filter (30-200 ILS per person)
@override@JsonKey() final  int minBudget;
@override@JsonKey() final  int maxBudget;
// Cuisine multi-select
 final  List<String> _cuisineTypes;
// Cuisine multi-select
@override@JsonKey() List<String> get cuisineTypes {
  if (_cuisineTypes is EqualUnmodifiableListView) return _cuisineTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cuisineTypes);
}

// Sort options
@override@JsonKey() final  SortBy sortBy;

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchStateCopyWith<_SearchState> get copyWith => __$SearchStateCopyWithImpl<_SearchState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchState&&(identical(other.city, city) || other.city == city)&&const DeepCollectionEquality().equals(other._moodTags, _moodTags)&&const DeepCollectionEquality().equals(other._occasionTags, _occasionTags)&&const DeepCollectionEquality().equals(other._timeTags, _timeTags)&&(identical(other.minBudget, minBudget) || other.minBudget == minBudget)&&(identical(other.maxBudget, maxBudget) || other.maxBudget == maxBudget)&&const DeepCollectionEquality().equals(other._cuisineTypes, _cuisineTypes)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy));
}


@override
int get hashCode => Object.hash(runtimeType,city,const DeepCollectionEquality().hash(_moodTags),const DeepCollectionEquality().hash(_occasionTags),const DeepCollectionEquality().hash(_timeTags),minBudget,maxBudget,const DeepCollectionEquality().hash(_cuisineTypes),sortBy);

@override
String toString() {
  return 'SearchState(city: $city, moodTags: $moodTags, occasionTags: $occasionTags, timeTags: $timeTags, minBudget: $minBudget, maxBudget: $maxBudget, cuisineTypes: $cuisineTypes, sortBy: $sortBy)';
}


}

/// @nodoc
abstract mixin class _$SearchStateCopyWith<$Res> implements $SearchStateCopyWith<$Res> {
  factory _$SearchStateCopyWith(_SearchState value, $Res Function(_SearchState) _then) = __$SearchStateCopyWithImpl;
@override @useResult
$Res call({
 String city, List<String> moodTags, List<String> occasionTags, List<String> timeTags, int minBudget, int maxBudget, List<String> cuisineTypes, SortBy sortBy
});




}
/// @nodoc
class __$SearchStateCopyWithImpl<$Res>
    implements _$SearchStateCopyWith<$Res> {
  __$SearchStateCopyWithImpl(this._self, this._then);

  final _SearchState _self;
  final $Res Function(_SearchState) _then;

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? city = null,Object? moodTags = null,Object? occasionTags = null,Object? timeTags = null,Object? minBudget = null,Object? maxBudget = null,Object? cuisineTypes = null,Object? sortBy = null,}) {
  return _then(_SearchState(
city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,moodTags: null == moodTags ? _self._moodTags : moodTags // ignore: cast_nullable_to_non_nullable
as List<String>,occasionTags: null == occasionTags ? _self._occasionTags : occasionTags // ignore: cast_nullable_to_non_nullable
as List<String>,timeTags: null == timeTags ? _self._timeTags : timeTags // ignore: cast_nullable_to_non_nullable
as List<String>,minBudget: null == minBudget ? _self.minBudget : minBudget // ignore: cast_nullable_to_non_nullable
as int,maxBudget: null == maxBudget ? _self.maxBudget : maxBudget // ignore: cast_nullable_to_non_nullable
as int,cuisineTypes: null == cuisineTypes ? _self._cuisineTypes : cuisineTypes // ignore: cast_nullable_to_non_nullable
as List<String>,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as SortBy,
  ));
}


}

// dart format on
