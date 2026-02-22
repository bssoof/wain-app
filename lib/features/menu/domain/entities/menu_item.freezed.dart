// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'menu_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MenuItem {

@JsonKey(includeToJson: false) String get id;@JsonKey(name: 'name_ar') String get nameAr;@JsonKey(name: 'name_en') String get nameEn;@JsonKey(name: 'description_ar') String get descriptionAr; double get price; String get currency;/// Section key, e.g. "hot_drinks", "main_courses"
 String get category;@JsonKey(name: 'photo_url') String get photoUrl;@JsonKey(name: 'is_available') bool get isAvailable;@JsonKey(name: 'is_featured') bool get isFeatured;@JsonKey(name: 'sort_order') int get sortOrder; String get source;@JsonKey(name: 'created_at', fromJson: _timestampFromJson, toJson: _timestampToJson, includeToJson: false) Timestamp? get createdAt;@JsonKey(name: 'updated_at', fromJson: _timestampFromJson, toJson: _timestampToJson, includeToJson: false) Timestamp? get updatedAt;
/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuItemCopyWith<MenuItem> get copyWith => _$MenuItemCopyWithImpl<MenuItem>(this as MenuItem, _$identity);

  /// Serializes this MenuItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuItem&&(identical(other.id, id) || other.id == id)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.descriptionAr, descriptionAr) || other.descriptionAr == descriptionAr)&&(identical(other.price, price) || other.price == price)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.category, category) || other.category == category)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.source, source) || other.source == source)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nameAr,nameEn,descriptionAr,price,currency,category,photoUrl,isAvailable,isFeatured,sortOrder,source,createdAt,updatedAt);

@override
String toString() {
  return 'MenuItem(id: $id, nameAr: $nameAr, nameEn: $nameEn, descriptionAr: $descriptionAr, price: $price, currency: $currency, category: $category, photoUrl: $photoUrl, isAvailable: $isAvailable, isFeatured: $isFeatured, sortOrder: $sortOrder, source: $source, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MenuItemCopyWith<$Res>  {
  factory $MenuItemCopyWith(MenuItem value, $Res Function(MenuItem) _then) = _$MenuItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id,@JsonKey(name: 'name_ar') String nameAr,@JsonKey(name: 'name_en') String nameEn,@JsonKey(name: 'description_ar') String descriptionAr, double price, String currency, String category,@JsonKey(name: 'photo_url') String photoUrl,@JsonKey(name: 'is_available') bool isAvailable,@JsonKey(name: 'is_featured') bool isFeatured,@JsonKey(name: 'sort_order') int sortOrder, String source,@JsonKey(name: 'created_at', fromJson: _timestampFromJson, toJson: _timestampToJson, includeToJson: false) Timestamp? createdAt,@JsonKey(name: 'updated_at', fromJson: _timestampFromJson, toJson: _timestampToJson, includeToJson: false) Timestamp? updatedAt
});




}
/// @nodoc
class _$MenuItemCopyWithImpl<$Res>
    implements $MenuItemCopyWith<$Res> {
  _$MenuItemCopyWithImpl(this._self, this._then);

  final MenuItem _self;
  final $Res Function(MenuItem) _then;

/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nameAr = null,Object? nameEn = null,Object? descriptionAr = null,Object? price = null,Object? currency = null,Object? category = null,Object? photoUrl = null,Object? isAvailable = null,Object? isFeatured = null,Object? sortOrder = null,Object? source = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,descriptionAr: null == descriptionAr ? _self.descriptionAr : descriptionAr // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,photoUrl: null == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as Timestamp?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as Timestamp?,
  ));
}

}


/// Adds pattern-matching-related methods to [MenuItem].
extension MenuItemPatterns on MenuItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuItem value)  $default,){
final _that = this;
switch (_that) {
case _MenuItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuItem value)?  $default,){
final _that = this;
switch (_that) {
case _MenuItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @JsonKey(name: 'name_ar')  String nameAr, @JsonKey(name: 'name_en')  String nameEn, @JsonKey(name: 'description_ar')  String descriptionAr,  double price,  String currency,  String category, @JsonKey(name: 'photo_url')  String photoUrl, @JsonKey(name: 'is_available')  bool isAvailable, @JsonKey(name: 'is_featured')  bool isFeatured, @JsonKey(name: 'sort_order')  int sortOrder,  String source, @JsonKey(name: 'created_at', fromJson: _timestampFromJson, toJson: _timestampToJson, includeToJson: false)  Timestamp? createdAt, @JsonKey(name: 'updated_at', fromJson: _timestampFromJson, toJson: _timestampToJson, includeToJson: false)  Timestamp? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuItem() when $default != null:
return $default(_that.id,_that.nameAr,_that.nameEn,_that.descriptionAr,_that.price,_that.currency,_that.category,_that.photoUrl,_that.isAvailable,_that.isFeatured,_that.sortOrder,_that.source,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @JsonKey(name: 'name_ar')  String nameAr, @JsonKey(name: 'name_en')  String nameEn, @JsonKey(name: 'description_ar')  String descriptionAr,  double price,  String currency,  String category, @JsonKey(name: 'photo_url')  String photoUrl, @JsonKey(name: 'is_available')  bool isAvailable, @JsonKey(name: 'is_featured')  bool isFeatured, @JsonKey(name: 'sort_order')  int sortOrder,  String source, @JsonKey(name: 'created_at', fromJson: _timestampFromJson, toJson: _timestampToJson, includeToJson: false)  Timestamp? createdAt, @JsonKey(name: 'updated_at', fromJson: _timestampFromJson, toJson: _timestampToJson, includeToJson: false)  Timestamp? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _MenuItem():
return $default(_that.id,_that.nameAr,_that.nameEn,_that.descriptionAr,_that.price,_that.currency,_that.category,_that.photoUrl,_that.isAvailable,_that.isFeatured,_that.sortOrder,_that.source,_that.createdAt,_that.updatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id, @JsonKey(name: 'name_ar')  String nameAr, @JsonKey(name: 'name_en')  String nameEn, @JsonKey(name: 'description_ar')  String descriptionAr,  double price,  String currency,  String category, @JsonKey(name: 'photo_url')  String photoUrl, @JsonKey(name: 'is_available')  bool isAvailable, @JsonKey(name: 'is_featured')  bool isFeatured, @JsonKey(name: 'sort_order')  int sortOrder,  String source, @JsonKey(name: 'created_at', fromJson: _timestampFromJson, toJson: _timestampToJson, includeToJson: false)  Timestamp? createdAt, @JsonKey(name: 'updated_at', fromJson: _timestampFromJson, toJson: _timestampToJson, includeToJson: false)  Timestamp? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MenuItem() when $default != null:
return $default(_that.id,_that.nameAr,_that.nameEn,_that.descriptionAr,_that.price,_that.currency,_that.category,_that.photoUrl,_that.isAvailable,_that.isFeatured,_that.sortOrder,_that.source,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MenuItem implements MenuItem {
  const _MenuItem({@JsonKey(includeToJson: false) required this.id, @JsonKey(name: 'name_ar') required this.nameAr, @JsonKey(name: 'name_en') this.nameEn = '', @JsonKey(name: 'description_ar') this.descriptionAr = '', required this.price, this.currency = 'ILS', required this.category, @JsonKey(name: 'photo_url') this.photoUrl = '', @JsonKey(name: 'is_available') this.isAvailable = true, @JsonKey(name: 'is_featured') this.isFeatured = false, @JsonKey(name: 'sort_order') this.sortOrder = 0, this.source = 'manual', @JsonKey(name: 'created_at', fromJson: _timestampFromJson, toJson: _timestampToJson, includeToJson: false) this.createdAt, @JsonKey(name: 'updated_at', fromJson: _timestampFromJson, toJson: _timestampToJson, includeToJson: false) this.updatedAt});
  factory _MenuItem.fromJson(Map<String, dynamic> json) => _$MenuItemFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override@JsonKey(name: 'name_ar') final  String nameAr;
@override@JsonKey(name: 'name_en') final  String nameEn;
@override@JsonKey(name: 'description_ar') final  String descriptionAr;
@override final  double price;
@override@JsonKey() final  String currency;
/// Section key, e.g. "hot_drinks", "main_courses"
@override final  String category;
@override@JsonKey(name: 'photo_url') final  String photoUrl;
@override@JsonKey(name: 'is_available') final  bool isAvailable;
@override@JsonKey(name: 'is_featured') final  bool isFeatured;
@override@JsonKey(name: 'sort_order') final  int sortOrder;
@override@JsonKey() final  String source;
@override@JsonKey(name: 'created_at', fromJson: _timestampFromJson, toJson: _timestampToJson, includeToJson: false) final  Timestamp? createdAt;
@override@JsonKey(name: 'updated_at', fromJson: _timestampFromJson, toJson: _timestampToJson, includeToJson: false) final  Timestamp? updatedAt;

/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuItemCopyWith<_MenuItem> get copyWith => __$MenuItemCopyWithImpl<_MenuItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuItem&&(identical(other.id, id) || other.id == id)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.descriptionAr, descriptionAr) || other.descriptionAr == descriptionAr)&&(identical(other.price, price) || other.price == price)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.category, category) || other.category == category)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.source, source) || other.source == source)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nameAr,nameEn,descriptionAr,price,currency,category,photoUrl,isAvailable,isFeatured,sortOrder,source,createdAt,updatedAt);

@override
String toString() {
  return 'MenuItem(id: $id, nameAr: $nameAr, nameEn: $nameEn, descriptionAr: $descriptionAr, price: $price, currency: $currency, category: $category, photoUrl: $photoUrl, isAvailable: $isAvailable, isFeatured: $isFeatured, sortOrder: $sortOrder, source: $source, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MenuItemCopyWith<$Res> implements $MenuItemCopyWith<$Res> {
  factory _$MenuItemCopyWith(_MenuItem value, $Res Function(_MenuItem) _then) = __$MenuItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id,@JsonKey(name: 'name_ar') String nameAr,@JsonKey(name: 'name_en') String nameEn,@JsonKey(name: 'description_ar') String descriptionAr, double price, String currency, String category,@JsonKey(name: 'photo_url') String photoUrl,@JsonKey(name: 'is_available') bool isAvailable,@JsonKey(name: 'is_featured') bool isFeatured,@JsonKey(name: 'sort_order') int sortOrder, String source,@JsonKey(name: 'created_at', fromJson: _timestampFromJson, toJson: _timestampToJson, includeToJson: false) Timestamp? createdAt,@JsonKey(name: 'updated_at', fromJson: _timestampFromJson, toJson: _timestampToJson, includeToJson: false) Timestamp? updatedAt
});




}
/// @nodoc
class __$MenuItemCopyWithImpl<$Res>
    implements _$MenuItemCopyWith<$Res> {
  __$MenuItemCopyWithImpl(this._self, this._then);

  final _MenuItem _self;
  final $Res Function(_MenuItem) _then;

/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nameAr = null,Object? nameEn = null,Object? descriptionAr = null,Object? price = null,Object? currency = null,Object? category = null,Object? photoUrl = null,Object? isAvailable = null,Object? isFeatured = null,Object? sortOrder = null,Object? source = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_MenuItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,descriptionAr: null == descriptionAr ? _self.descriptionAr : descriptionAr // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,photoUrl: null == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as Timestamp?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as Timestamp?,
  ));
}


}

// dart format on
