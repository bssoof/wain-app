// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'menu_section.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MenuSection {

 String get id;@JsonKey(name: 'name_ar') String get nameAr;@JsonKey(name: 'name_en') String get nameEn; String get icon;@JsonKey(name: 'sort_order') int get sortOrder;
/// Create a copy of MenuSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuSectionCopyWith<MenuSection> get copyWith => _$MenuSectionCopyWithImpl<MenuSection>(this as MenuSection, _$identity);

  /// Serializes this MenuSection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuSection&&(identical(other.id, id) || other.id == id)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nameAr,nameEn,icon,sortOrder);

@override
String toString() {
  return 'MenuSection(id: $id, nameAr: $nameAr, nameEn: $nameEn, icon: $icon, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $MenuSectionCopyWith<$Res>  {
  factory $MenuSectionCopyWith(MenuSection value, $Res Function(MenuSection) _then) = _$MenuSectionCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'name_ar') String nameAr,@JsonKey(name: 'name_en') String nameEn, String icon,@JsonKey(name: 'sort_order') int sortOrder
});




}
/// @nodoc
class _$MenuSectionCopyWithImpl<$Res>
    implements $MenuSectionCopyWith<$Res> {
  _$MenuSectionCopyWithImpl(this._self, this._then);

  final MenuSection _self;
  final $Res Function(MenuSection) _then;

/// Create a copy of MenuSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nameAr = null,Object? nameEn = null,Object? icon = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MenuSection].
extension MenuSectionPatterns on MenuSection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuSection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuSection value)  $default,){
final _that = this;
switch (_that) {
case _MenuSection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuSection value)?  $default,){
final _that = this;
switch (_that) {
case _MenuSection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'name_ar')  String nameAr, @JsonKey(name: 'name_en')  String nameEn,  String icon, @JsonKey(name: 'sort_order')  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuSection() when $default != null:
return $default(_that.id,_that.nameAr,_that.nameEn,_that.icon,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'name_ar')  String nameAr, @JsonKey(name: 'name_en')  String nameEn,  String icon, @JsonKey(name: 'sort_order')  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _MenuSection():
return $default(_that.id,_that.nameAr,_that.nameEn,_that.icon,_that.sortOrder);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'name_ar')  String nameAr, @JsonKey(name: 'name_en')  String nameEn,  String icon, @JsonKey(name: 'sort_order')  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _MenuSection() when $default != null:
return $default(_that.id,_that.nameAr,_that.nameEn,_that.icon,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MenuSection implements MenuSection {
  const _MenuSection({required this.id, @JsonKey(name: 'name_ar') required this.nameAr, @JsonKey(name: 'name_en') this.nameEn = '', this.icon = 'restaurant_menu', @JsonKey(name: 'sort_order') this.sortOrder = 0});
  factory _MenuSection.fromJson(Map<String, dynamic> json) => _$MenuSectionFromJson(json);

@override final  String id;
@override@JsonKey(name: 'name_ar') final  String nameAr;
@override@JsonKey(name: 'name_en') final  String nameEn;
@override@JsonKey() final  String icon;
@override@JsonKey(name: 'sort_order') final  int sortOrder;

/// Create a copy of MenuSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuSectionCopyWith<_MenuSection> get copyWith => __$MenuSectionCopyWithImpl<_MenuSection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuSectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuSection&&(identical(other.id, id) || other.id == id)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nameAr,nameEn,icon,sortOrder);

@override
String toString() {
  return 'MenuSection(id: $id, nameAr: $nameAr, nameEn: $nameEn, icon: $icon, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$MenuSectionCopyWith<$Res> implements $MenuSectionCopyWith<$Res> {
  factory _$MenuSectionCopyWith(_MenuSection value, $Res Function(_MenuSection) _then) = __$MenuSectionCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'name_ar') String nameAr,@JsonKey(name: 'name_en') String nameEn, String icon,@JsonKey(name: 'sort_order') int sortOrder
});




}
/// @nodoc
class __$MenuSectionCopyWithImpl<$Res>
    implements _$MenuSectionCopyWith<$Res> {
  __$MenuSectionCopyWithImpl(this._self, this._then);

  final _MenuSection _self;
  final $Res Function(_MenuSection) _then;

/// Create a copy of MenuSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nameAr = null,Object? nameEn = null,Object? icon = null,Object? sortOrder = null,}) {
  return _then(_MenuSection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
