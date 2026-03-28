// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'venue.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Venue {

@JsonKey(includeToJson: false) String get id;@JsonKey(name: 'name_ar') String get nameAr;@JsonKey(name: 'name_en') String get nameEn;@JsonKey(name: 'name_ar_norm') String get nameArNorm;@JsonKey(name: 'name_en_norm') String get nameEnNorm;@JsonKey(fromJson: _toDouble) double get lat;@JsonKey(fromJson: _toDouble) double get lng; String get city;@JsonKey(fromJson: _toStringList) List<String> get categories; VenueTags get tags;@JsonKey(name: 'all_tags', fromJson: _toStringList) List<String> get allTags;@JsonKey(name: 'min_price', fromJson: _toInt) int get minPrice;@JsonKey(name: 'max_price', fromJson: _toInt) int get maxPrice; String get currency;@JsonKey(fromJson: _toDouble) double get rating; String get phone; String get instagram; String get whatsapp; String get facebook; String get website;@JsonKey(fromJson: _toStringList) List<String> get photos;@JsonKey(name: 'menu_images', fromJson: _toStringList) List<String> get menuImages;@JsonKey(fromJson: _toHoursMap) Map<String, List<VenueHours>> get hours;@JsonKey(name: 'is_24h') bool get is24h; VenuePartner get partner;@JsonKey(name: 'has_active_offers') bool get hasActiveOffers;@JsonKey(name: 'transport_enabled') bool get transportEnabled;@JsonKey(name: 'transport_partner_ids', fromJson: _toStringList) List<String> get transportPartnerIds;@JsonKey(name: 'transport_notes_ar') String get transportNotesAr;@JsonKey(name: 'transport_notes_en') String get transportNotesEn;@JsonKey(name: 'last_story_at', fromJson: _toTimestamp, toJson: _timestampToJson) Timestamp? get lastStoryAt;@JsonKey(name: 'created_at', fromJson: _toTimestamp, toJson: _timestampToJson) Timestamp? get createdAt;@JsonKey(name: 'updated_at', fromJson: _toTimestamp, toJson: _timestampToJson) Timestamp? get updatedAt;
/// Create a copy of Venue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VenueCopyWith<Venue> get copyWith => _$VenueCopyWithImpl<Venue>(this as Venue, _$identity);

  /// Serializes this Venue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Venue&&(identical(other.id, id) || other.id == id)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.nameArNorm, nameArNorm) || other.nameArNorm == nameArNorm)&&(identical(other.nameEnNorm, nameEnNorm) || other.nameEnNorm == nameEnNorm)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.city, city) || other.city == city)&&const DeepCollectionEquality().equals(other.categories, categories)&&(identical(other.tags, tags) || other.tags == tags)&&const DeepCollectionEquality().equals(other.allTags, allTags)&&(identical(other.minPrice, minPrice) || other.minPrice == minPrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.instagram, instagram) || other.instagram == instagram)&&(identical(other.whatsapp, whatsapp) || other.whatsapp == whatsapp)&&(identical(other.facebook, facebook) || other.facebook == facebook)&&(identical(other.website, website) || other.website == website)&&const DeepCollectionEquality().equals(other.photos, photos)&&const DeepCollectionEquality().equals(other.menuImages, menuImages)&&const DeepCollectionEquality().equals(other.hours, hours)&&(identical(other.is24h, is24h) || other.is24h == is24h)&&(identical(other.partner, partner) || other.partner == partner)&&(identical(other.hasActiveOffers, hasActiveOffers) || other.hasActiveOffers == hasActiveOffers)&&(identical(other.transportEnabled, transportEnabled) || other.transportEnabled == transportEnabled)&&const DeepCollectionEquality().equals(other.transportPartnerIds, transportPartnerIds)&&(identical(other.transportNotesAr, transportNotesAr) || other.transportNotesAr == transportNotesAr)&&(identical(other.transportNotesEn, transportNotesEn) || other.transportNotesEn == transportNotesEn)&&(identical(other.lastStoryAt, lastStoryAt) || other.lastStoryAt == lastStoryAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,nameAr,nameEn,nameArNorm,nameEnNorm,lat,lng,city,const DeepCollectionEquality().hash(categories),tags,const DeepCollectionEquality().hash(allTags),minPrice,maxPrice,currency,rating,phone,instagram,whatsapp,facebook,website,const DeepCollectionEquality().hash(photos),const DeepCollectionEquality().hash(menuImages),const DeepCollectionEquality().hash(hours),is24h,partner,hasActiveOffers,transportEnabled,const DeepCollectionEquality().hash(transportPartnerIds),transportNotesAr,transportNotesEn,lastStoryAt,createdAt,updatedAt]);

@override
String toString() {
  return 'Venue(id: $id, nameAr: $nameAr, nameEn: $nameEn, nameArNorm: $nameArNorm, nameEnNorm: $nameEnNorm, lat: $lat, lng: $lng, city: $city, categories: $categories, tags: $tags, allTags: $allTags, minPrice: $minPrice, maxPrice: $maxPrice, currency: $currency, rating: $rating, phone: $phone, instagram: $instagram, whatsapp: $whatsapp, facebook: $facebook, website: $website, photos: $photos, menuImages: $menuImages, hours: $hours, is24h: $is24h, partner: $partner, hasActiveOffers: $hasActiveOffers, transportEnabled: $transportEnabled, transportPartnerIds: $transportPartnerIds, transportNotesAr: $transportNotesAr, transportNotesEn: $transportNotesEn, lastStoryAt: $lastStoryAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $VenueCopyWith<$Res>  {
  factory $VenueCopyWith(Venue value, $Res Function(Venue) _then) = _$VenueCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id,@JsonKey(name: 'name_ar') String nameAr,@JsonKey(name: 'name_en') String nameEn,@JsonKey(name: 'name_ar_norm') String nameArNorm,@JsonKey(name: 'name_en_norm') String nameEnNorm,@JsonKey(fromJson: _toDouble) double lat,@JsonKey(fromJson: _toDouble) double lng, String city,@JsonKey(fromJson: _toStringList) List<String> categories, VenueTags tags,@JsonKey(name: 'all_tags', fromJson: _toStringList) List<String> allTags,@JsonKey(name: 'min_price', fromJson: _toInt) int minPrice,@JsonKey(name: 'max_price', fromJson: _toInt) int maxPrice, String currency,@JsonKey(fromJson: _toDouble) double rating, String phone, String instagram, String whatsapp, String facebook, String website,@JsonKey(fromJson: _toStringList) List<String> photos,@JsonKey(name: 'menu_images', fromJson: _toStringList) List<String> menuImages,@JsonKey(fromJson: _toHoursMap) Map<String, List<VenueHours>> hours,@JsonKey(name: 'is_24h') bool is24h, VenuePartner partner,@JsonKey(name: 'has_active_offers') bool hasActiveOffers,@JsonKey(name: 'transport_enabled') bool transportEnabled,@JsonKey(name: 'transport_partner_ids', fromJson: _toStringList) List<String> transportPartnerIds,@JsonKey(name: 'transport_notes_ar') String transportNotesAr,@JsonKey(name: 'transport_notes_en') String transportNotesEn,@JsonKey(name: 'last_story_at', fromJson: _toTimestamp, toJson: _timestampToJson) Timestamp? lastStoryAt,@JsonKey(name: 'created_at', fromJson: _toTimestamp, toJson: _timestampToJson) Timestamp? createdAt,@JsonKey(name: 'updated_at', fromJson: _toTimestamp, toJson: _timestampToJson) Timestamp? updatedAt
});


$VenueTagsCopyWith<$Res> get tags;$VenuePartnerCopyWith<$Res> get partner;

}
/// @nodoc
class _$VenueCopyWithImpl<$Res>
    implements $VenueCopyWith<$Res> {
  _$VenueCopyWithImpl(this._self, this._then);

  final Venue _self;
  final $Res Function(Venue) _then;

/// Create a copy of Venue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nameAr = null,Object? nameEn = null,Object? nameArNorm = null,Object? nameEnNorm = null,Object? lat = null,Object? lng = null,Object? city = null,Object? categories = null,Object? tags = null,Object? allTags = null,Object? minPrice = null,Object? maxPrice = null,Object? currency = null,Object? rating = null,Object? phone = null,Object? instagram = null,Object? whatsapp = null,Object? facebook = null,Object? website = null,Object? photos = null,Object? menuImages = null,Object? hours = null,Object? is24h = null,Object? partner = null,Object? hasActiveOffers = null,Object? transportEnabled = null,Object? transportPartnerIds = null,Object? transportNotesAr = null,Object? transportNotesEn = null,Object? lastStoryAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,nameArNorm: null == nameArNorm ? _self.nameArNorm : nameArNorm // ignore: cast_nullable_to_non_nullable
as String,nameEnNorm: null == nameEnNorm ? _self.nameEnNorm : nameEnNorm // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as VenueTags,allTags: null == allTags ? _self.allTags : allTags // ignore: cast_nullable_to_non_nullable
as List<String>,minPrice: null == minPrice ? _self.minPrice : minPrice // ignore: cast_nullable_to_non_nullable
as int,maxPrice: null == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,instagram: null == instagram ? _self.instagram : instagram // ignore: cast_nullable_to_non_nullable
as String,whatsapp: null == whatsapp ? _self.whatsapp : whatsapp // ignore: cast_nullable_to_non_nullable
as String,facebook: null == facebook ? _self.facebook : facebook // ignore: cast_nullable_to_non_nullable
as String,website: null == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<String>,menuImages: null == menuImages ? _self.menuImages : menuImages // ignore: cast_nullable_to_non_nullable
as List<String>,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as Map<String, List<VenueHours>>,is24h: null == is24h ? _self.is24h : is24h // ignore: cast_nullable_to_non_nullable
as bool,partner: null == partner ? _self.partner : partner // ignore: cast_nullable_to_non_nullable
as VenuePartner,hasActiveOffers: null == hasActiveOffers ? _self.hasActiveOffers : hasActiveOffers // ignore: cast_nullable_to_non_nullable
as bool,transportEnabled: null == transportEnabled ? _self.transportEnabled : transportEnabled // ignore: cast_nullable_to_non_nullable
as bool,transportPartnerIds: null == transportPartnerIds ? _self.transportPartnerIds : transportPartnerIds // ignore: cast_nullable_to_non_nullable
as List<String>,transportNotesAr: null == transportNotesAr ? _self.transportNotesAr : transportNotesAr // ignore: cast_nullable_to_non_nullable
as String,transportNotesEn: null == transportNotesEn ? _self.transportNotesEn : transportNotesEn // ignore: cast_nullable_to_non_nullable
as String,lastStoryAt: freezed == lastStoryAt ? _self.lastStoryAt : lastStoryAt // ignore: cast_nullable_to_non_nullable
as Timestamp?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as Timestamp?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as Timestamp?,
  ));
}
/// Create a copy of Venue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VenueTagsCopyWith<$Res> get tags {
  
  return $VenueTagsCopyWith<$Res>(_self.tags, (value) {
    return _then(_self.copyWith(tags: value));
  });
}/// Create a copy of Venue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VenuePartnerCopyWith<$Res> get partner {
  
  return $VenuePartnerCopyWith<$Res>(_self.partner, (value) {
    return _then(_self.copyWith(partner: value));
  });
}
}


/// Adds pattern-matching-related methods to [Venue].
extension VenuePatterns on Venue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Venue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Venue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Venue value)  $default,){
final _that = this;
switch (_that) {
case _Venue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Venue value)?  $default,){
final _that = this;
switch (_that) {
case _Venue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @JsonKey(name: 'name_ar')  String nameAr, @JsonKey(name: 'name_en')  String nameEn, @JsonKey(name: 'name_ar_norm')  String nameArNorm, @JsonKey(name: 'name_en_norm')  String nameEnNorm, @JsonKey(fromJson: _toDouble)  double lat, @JsonKey(fromJson: _toDouble)  double lng,  String city, @JsonKey(fromJson: _toStringList)  List<String> categories,  VenueTags tags, @JsonKey(name: 'all_tags', fromJson: _toStringList)  List<String> allTags, @JsonKey(name: 'min_price', fromJson: _toInt)  int minPrice, @JsonKey(name: 'max_price', fromJson: _toInt)  int maxPrice,  String currency, @JsonKey(fromJson: _toDouble)  double rating,  String phone,  String instagram,  String whatsapp,  String facebook,  String website, @JsonKey(fromJson: _toStringList)  List<String> photos, @JsonKey(name: 'menu_images', fromJson: _toStringList)  List<String> menuImages, @JsonKey(fromJson: _toHoursMap)  Map<String, List<VenueHours>> hours, @JsonKey(name: 'is_24h')  bool is24h,  VenuePartner partner, @JsonKey(name: 'has_active_offers')  bool hasActiveOffers, @JsonKey(name: 'transport_enabled')  bool transportEnabled, @JsonKey(name: 'transport_partner_ids', fromJson: _toStringList)  List<String> transportPartnerIds, @JsonKey(name: 'transport_notes_ar')  String transportNotesAr, @JsonKey(name: 'transport_notes_en')  String transportNotesEn, @JsonKey(name: 'last_story_at', fromJson: _toTimestamp, toJson: _timestampToJson)  Timestamp? lastStoryAt, @JsonKey(name: 'created_at', fromJson: _toTimestamp, toJson: _timestampToJson)  Timestamp? createdAt, @JsonKey(name: 'updated_at', fromJson: _toTimestamp, toJson: _timestampToJson)  Timestamp? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Venue() when $default != null:
return $default(_that.id,_that.nameAr,_that.nameEn,_that.nameArNorm,_that.nameEnNorm,_that.lat,_that.lng,_that.city,_that.categories,_that.tags,_that.allTags,_that.minPrice,_that.maxPrice,_that.currency,_that.rating,_that.phone,_that.instagram,_that.whatsapp,_that.facebook,_that.website,_that.photos,_that.menuImages,_that.hours,_that.is24h,_that.partner,_that.hasActiveOffers,_that.transportEnabled,_that.transportPartnerIds,_that.transportNotesAr,_that.transportNotesEn,_that.lastStoryAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @JsonKey(name: 'name_ar')  String nameAr, @JsonKey(name: 'name_en')  String nameEn, @JsonKey(name: 'name_ar_norm')  String nameArNorm, @JsonKey(name: 'name_en_norm')  String nameEnNorm, @JsonKey(fromJson: _toDouble)  double lat, @JsonKey(fromJson: _toDouble)  double lng,  String city, @JsonKey(fromJson: _toStringList)  List<String> categories,  VenueTags tags, @JsonKey(name: 'all_tags', fromJson: _toStringList)  List<String> allTags, @JsonKey(name: 'min_price', fromJson: _toInt)  int minPrice, @JsonKey(name: 'max_price', fromJson: _toInt)  int maxPrice,  String currency, @JsonKey(fromJson: _toDouble)  double rating,  String phone,  String instagram,  String whatsapp,  String facebook,  String website, @JsonKey(fromJson: _toStringList)  List<String> photos, @JsonKey(name: 'menu_images', fromJson: _toStringList)  List<String> menuImages, @JsonKey(fromJson: _toHoursMap)  Map<String, List<VenueHours>> hours, @JsonKey(name: 'is_24h')  bool is24h,  VenuePartner partner, @JsonKey(name: 'has_active_offers')  bool hasActiveOffers, @JsonKey(name: 'transport_enabled')  bool transportEnabled, @JsonKey(name: 'transport_partner_ids', fromJson: _toStringList)  List<String> transportPartnerIds, @JsonKey(name: 'transport_notes_ar')  String transportNotesAr, @JsonKey(name: 'transport_notes_en')  String transportNotesEn, @JsonKey(name: 'last_story_at', fromJson: _toTimestamp, toJson: _timestampToJson)  Timestamp? lastStoryAt, @JsonKey(name: 'created_at', fromJson: _toTimestamp, toJson: _timestampToJson)  Timestamp? createdAt, @JsonKey(name: 'updated_at', fromJson: _toTimestamp, toJson: _timestampToJson)  Timestamp? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Venue():
return $default(_that.id,_that.nameAr,_that.nameEn,_that.nameArNorm,_that.nameEnNorm,_that.lat,_that.lng,_that.city,_that.categories,_that.tags,_that.allTags,_that.minPrice,_that.maxPrice,_that.currency,_that.rating,_that.phone,_that.instagram,_that.whatsapp,_that.facebook,_that.website,_that.photos,_that.menuImages,_that.hours,_that.is24h,_that.partner,_that.hasActiveOffers,_that.transportEnabled,_that.transportPartnerIds,_that.transportNotesAr,_that.transportNotesEn,_that.lastStoryAt,_that.createdAt,_that.updatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id, @JsonKey(name: 'name_ar')  String nameAr, @JsonKey(name: 'name_en')  String nameEn, @JsonKey(name: 'name_ar_norm')  String nameArNorm, @JsonKey(name: 'name_en_norm')  String nameEnNorm, @JsonKey(fromJson: _toDouble)  double lat, @JsonKey(fromJson: _toDouble)  double lng,  String city, @JsonKey(fromJson: _toStringList)  List<String> categories,  VenueTags tags, @JsonKey(name: 'all_tags', fromJson: _toStringList)  List<String> allTags, @JsonKey(name: 'min_price', fromJson: _toInt)  int minPrice, @JsonKey(name: 'max_price', fromJson: _toInt)  int maxPrice,  String currency, @JsonKey(fromJson: _toDouble)  double rating,  String phone,  String instagram,  String whatsapp,  String facebook,  String website, @JsonKey(fromJson: _toStringList)  List<String> photos, @JsonKey(name: 'menu_images', fromJson: _toStringList)  List<String> menuImages, @JsonKey(fromJson: _toHoursMap)  Map<String, List<VenueHours>> hours, @JsonKey(name: 'is_24h')  bool is24h,  VenuePartner partner, @JsonKey(name: 'has_active_offers')  bool hasActiveOffers, @JsonKey(name: 'transport_enabled')  bool transportEnabled, @JsonKey(name: 'transport_partner_ids', fromJson: _toStringList)  List<String> transportPartnerIds, @JsonKey(name: 'transport_notes_ar')  String transportNotesAr, @JsonKey(name: 'transport_notes_en')  String transportNotesEn, @JsonKey(name: 'last_story_at', fromJson: _toTimestamp, toJson: _timestampToJson)  Timestamp? lastStoryAt, @JsonKey(name: 'created_at', fromJson: _toTimestamp, toJson: _timestampToJson)  Timestamp? createdAt, @JsonKey(name: 'updated_at', fromJson: _toTimestamp, toJson: _timestampToJson)  Timestamp? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Venue() when $default != null:
return $default(_that.id,_that.nameAr,_that.nameEn,_that.nameArNorm,_that.nameEnNorm,_that.lat,_that.lng,_that.city,_that.categories,_that.tags,_that.allTags,_that.minPrice,_that.maxPrice,_that.currency,_that.rating,_that.phone,_that.instagram,_that.whatsapp,_that.facebook,_that.website,_that.photos,_that.menuImages,_that.hours,_that.is24h,_that.partner,_that.hasActiveOffers,_that.transportEnabled,_that.transportPartnerIds,_that.transportNotesAr,_that.transportNotesEn,_that.lastStoryAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Venue implements Venue {
  const _Venue({@JsonKey(includeToJson: false) required this.id, @JsonKey(name: 'name_ar') required this.nameAr, @JsonKey(name: 'name_en') required this.nameEn, @JsonKey(name: 'name_ar_norm') this.nameArNorm = '', @JsonKey(name: 'name_en_norm') this.nameEnNorm = '', @JsonKey(fromJson: _toDouble) required this.lat, @JsonKey(fromJson: _toDouble) required this.lng, required this.city, @JsonKey(fromJson: _toStringList) required final  List<String> categories, required this.tags, @JsonKey(name: 'all_tags', fromJson: _toStringList) final  List<String> allTags = const <String>[], @JsonKey(name: 'min_price', fromJson: _toInt) required this.minPrice, @JsonKey(name: 'max_price', fromJson: _toInt) required this.maxPrice, this.currency = 'ILS', @JsonKey(fromJson: _toDouble) required this.rating, required this.phone, this.instagram = '', this.whatsapp = '', this.facebook = '', this.website = '', @JsonKey(fromJson: _toStringList) final  List<String> photos = const <String>[], @JsonKey(name: 'menu_images', fromJson: _toStringList) final  List<String> menuImages = const <String>[], @JsonKey(fromJson: _toHoursMap) final  Map<String, List<VenueHours>> hours = const <String, List<VenueHours>>{}, @JsonKey(name: 'is_24h') this.is24h = false, this.partner = const VenuePartner(), @JsonKey(name: 'has_active_offers') this.hasActiveOffers = false, @JsonKey(name: 'transport_enabled') this.transportEnabled = false, @JsonKey(name: 'transport_partner_ids', fromJson: _toStringList) final  List<String> transportPartnerIds = const <String>[], @JsonKey(name: 'transport_notes_ar') this.transportNotesAr = '', @JsonKey(name: 'transport_notes_en') this.transportNotesEn = '', @JsonKey(name: 'last_story_at', fromJson: _toTimestamp, toJson: _timestampToJson) this.lastStoryAt, @JsonKey(name: 'created_at', fromJson: _toTimestamp, toJson: _timestampToJson) this.createdAt, @JsonKey(name: 'updated_at', fromJson: _toTimestamp, toJson: _timestampToJson) this.updatedAt}): _categories = categories,_allTags = allTags,_photos = photos,_menuImages = menuImages,_hours = hours,_transportPartnerIds = transportPartnerIds;
  factory _Venue.fromJson(Map<String, dynamic> json) => _$VenueFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override@JsonKey(name: 'name_ar') final  String nameAr;
@override@JsonKey(name: 'name_en') final  String nameEn;
@override@JsonKey(name: 'name_ar_norm') final  String nameArNorm;
@override@JsonKey(name: 'name_en_norm') final  String nameEnNorm;
@override@JsonKey(fromJson: _toDouble) final  double lat;
@override@JsonKey(fromJson: _toDouble) final  double lng;
@override final  String city;
 final  List<String> _categories;
@override@JsonKey(fromJson: _toStringList) List<String> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

@override final  VenueTags tags;
 final  List<String> _allTags;
@override@JsonKey(name: 'all_tags', fromJson: _toStringList) List<String> get allTags {
  if (_allTags is EqualUnmodifiableListView) return _allTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allTags);
}

@override@JsonKey(name: 'min_price', fromJson: _toInt) final  int minPrice;
@override@JsonKey(name: 'max_price', fromJson: _toInt) final  int maxPrice;
@override@JsonKey() final  String currency;
@override@JsonKey(fromJson: _toDouble) final  double rating;
@override final  String phone;
@override@JsonKey() final  String instagram;
@override@JsonKey() final  String whatsapp;
@override@JsonKey() final  String facebook;
@override@JsonKey() final  String website;
 final  List<String> _photos;
@override@JsonKey(fromJson: _toStringList) List<String> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}

 final  List<String> _menuImages;
@override@JsonKey(name: 'menu_images', fromJson: _toStringList) List<String> get menuImages {
  if (_menuImages is EqualUnmodifiableListView) return _menuImages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_menuImages);
}

 final  Map<String, List<VenueHours>> _hours;
@override@JsonKey(fromJson: _toHoursMap) Map<String, List<VenueHours>> get hours {
  if (_hours is EqualUnmodifiableMapView) return _hours;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_hours);
}

@override@JsonKey(name: 'is_24h') final  bool is24h;
@override@JsonKey() final  VenuePartner partner;
@override@JsonKey(name: 'has_active_offers') final  bool hasActiveOffers;
@override@JsonKey(name: 'transport_enabled') final  bool transportEnabled;
 final  List<String> _transportPartnerIds;
@override@JsonKey(name: 'transport_partner_ids', fromJson: _toStringList) List<String> get transportPartnerIds {
  if (_transportPartnerIds is EqualUnmodifiableListView) return _transportPartnerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transportPartnerIds);
}

@override@JsonKey(name: 'transport_notes_ar') final  String transportNotesAr;
@override@JsonKey(name: 'transport_notes_en') final  String transportNotesEn;
@override@JsonKey(name: 'last_story_at', fromJson: _toTimestamp, toJson: _timestampToJson) final  Timestamp? lastStoryAt;
@override@JsonKey(name: 'created_at', fromJson: _toTimestamp, toJson: _timestampToJson) final  Timestamp? createdAt;
@override@JsonKey(name: 'updated_at', fromJson: _toTimestamp, toJson: _timestampToJson) final  Timestamp? updatedAt;

/// Create a copy of Venue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VenueCopyWith<_Venue> get copyWith => __$VenueCopyWithImpl<_Venue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VenueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Venue&&(identical(other.id, id) || other.id == id)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.nameArNorm, nameArNorm) || other.nameArNorm == nameArNorm)&&(identical(other.nameEnNorm, nameEnNorm) || other.nameEnNorm == nameEnNorm)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.city, city) || other.city == city)&&const DeepCollectionEquality().equals(other._categories, _categories)&&(identical(other.tags, tags) || other.tags == tags)&&const DeepCollectionEquality().equals(other._allTags, _allTags)&&(identical(other.minPrice, minPrice) || other.minPrice == minPrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.instagram, instagram) || other.instagram == instagram)&&(identical(other.whatsapp, whatsapp) || other.whatsapp == whatsapp)&&(identical(other.facebook, facebook) || other.facebook == facebook)&&(identical(other.website, website) || other.website == website)&&const DeepCollectionEquality().equals(other._photos, _photos)&&const DeepCollectionEquality().equals(other._menuImages, _menuImages)&&const DeepCollectionEquality().equals(other._hours, _hours)&&(identical(other.is24h, is24h) || other.is24h == is24h)&&(identical(other.partner, partner) || other.partner == partner)&&(identical(other.hasActiveOffers, hasActiveOffers) || other.hasActiveOffers == hasActiveOffers)&&(identical(other.transportEnabled, transportEnabled) || other.transportEnabled == transportEnabled)&&const DeepCollectionEquality().equals(other._transportPartnerIds, _transportPartnerIds)&&(identical(other.transportNotesAr, transportNotesAr) || other.transportNotesAr == transportNotesAr)&&(identical(other.transportNotesEn, transportNotesEn) || other.transportNotesEn == transportNotesEn)&&(identical(other.lastStoryAt, lastStoryAt) || other.lastStoryAt == lastStoryAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,nameAr,nameEn,nameArNorm,nameEnNorm,lat,lng,city,const DeepCollectionEquality().hash(_categories),tags,const DeepCollectionEquality().hash(_allTags),minPrice,maxPrice,currency,rating,phone,instagram,whatsapp,facebook,website,const DeepCollectionEquality().hash(_photos),const DeepCollectionEquality().hash(_menuImages),const DeepCollectionEquality().hash(_hours),is24h,partner,hasActiveOffers,transportEnabled,const DeepCollectionEquality().hash(_transportPartnerIds),transportNotesAr,transportNotesEn,lastStoryAt,createdAt,updatedAt]);

@override
String toString() {
  return 'Venue(id: $id, nameAr: $nameAr, nameEn: $nameEn, nameArNorm: $nameArNorm, nameEnNorm: $nameEnNorm, lat: $lat, lng: $lng, city: $city, categories: $categories, tags: $tags, allTags: $allTags, minPrice: $minPrice, maxPrice: $maxPrice, currency: $currency, rating: $rating, phone: $phone, instagram: $instagram, whatsapp: $whatsapp, facebook: $facebook, website: $website, photos: $photos, menuImages: $menuImages, hours: $hours, is24h: $is24h, partner: $partner, hasActiveOffers: $hasActiveOffers, transportEnabled: $transportEnabled, transportPartnerIds: $transportPartnerIds, transportNotesAr: $transportNotesAr, transportNotesEn: $transportNotesEn, lastStoryAt: $lastStoryAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$VenueCopyWith<$Res> implements $VenueCopyWith<$Res> {
  factory _$VenueCopyWith(_Venue value, $Res Function(_Venue) _then) = __$VenueCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id,@JsonKey(name: 'name_ar') String nameAr,@JsonKey(name: 'name_en') String nameEn,@JsonKey(name: 'name_ar_norm') String nameArNorm,@JsonKey(name: 'name_en_norm') String nameEnNorm,@JsonKey(fromJson: _toDouble) double lat,@JsonKey(fromJson: _toDouble) double lng, String city,@JsonKey(fromJson: _toStringList) List<String> categories, VenueTags tags,@JsonKey(name: 'all_tags', fromJson: _toStringList) List<String> allTags,@JsonKey(name: 'min_price', fromJson: _toInt) int minPrice,@JsonKey(name: 'max_price', fromJson: _toInt) int maxPrice, String currency,@JsonKey(fromJson: _toDouble) double rating, String phone, String instagram, String whatsapp, String facebook, String website,@JsonKey(fromJson: _toStringList) List<String> photos,@JsonKey(name: 'menu_images', fromJson: _toStringList) List<String> menuImages,@JsonKey(fromJson: _toHoursMap) Map<String, List<VenueHours>> hours,@JsonKey(name: 'is_24h') bool is24h, VenuePartner partner,@JsonKey(name: 'has_active_offers') bool hasActiveOffers,@JsonKey(name: 'transport_enabled') bool transportEnabled,@JsonKey(name: 'transport_partner_ids', fromJson: _toStringList) List<String> transportPartnerIds,@JsonKey(name: 'transport_notes_ar') String transportNotesAr,@JsonKey(name: 'transport_notes_en') String transportNotesEn,@JsonKey(name: 'last_story_at', fromJson: _toTimestamp, toJson: _timestampToJson) Timestamp? lastStoryAt,@JsonKey(name: 'created_at', fromJson: _toTimestamp, toJson: _timestampToJson) Timestamp? createdAt,@JsonKey(name: 'updated_at', fromJson: _toTimestamp, toJson: _timestampToJson) Timestamp? updatedAt
});


@override $VenueTagsCopyWith<$Res> get tags;@override $VenuePartnerCopyWith<$Res> get partner;

}
/// @nodoc
class __$VenueCopyWithImpl<$Res>
    implements _$VenueCopyWith<$Res> {
  __$VenueCopyWithImpl(this._self, this._then);

  final _Venue _self;
  final $Res Function(_Venue) _then;

/// Create a copy of Venue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nameAr = null,Object? nameEn = null,Object? nameArNorm = null,Object? nameEnNorm = null,Object? lat = null,Object? lng = null,Object? city = null,Object? categories = null,Object? tags = null,Object? allTags = null,Object? minPrice = null,Object? maxPrice = null,Object? currency = null,Object? rating = null,Object? phone = null,Object? instagram = null,Object? whatsapp = null,Object? facebook = null,Object? website = null,Object? photos = null,Object? menuImages = null,Object? hours = null,Object? is24h = null,Object? partner = null,Object? hasActiveOffers = null,Object? transportEnabled = null,Object? transportPartnerIds = null,Object? transportNotesAr = null,Object? transportNotesEn = null,Object? lastStoryAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Venue(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,nameArNorm: null == nameArNorm ? _self.nameArNorm : nameArNorm // ignore: cast_nullable_to_non_nullable
as String,nameEnNorm: null == nameEnNorm ? _self.nameEnNorm : nameEnNorm // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as VenueTags,allTags: null == allTags ? _self._allTags : allTags // ignore: cast_nullable_to_non_nullable
as List<String>,minPrice: null == minPrice ? _self.minPrice : minPrice // ignore: cast_nullable_to_non_nullable
as int,maxPrice: null == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,instagram: null == instagram ? _self.instagram : instagram // ignore: cast_nullable_to_non_nullable
as String,whatsapp: null == whatsapp ? _self.whatsapp : whatsapp // ignore: cast_nullable_to_non_nullable
as String,facebook: null == facebook ? _self.facebook : facebook // ignore: cast_nullable_to_non_nullable
as String,website: null == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<String>,menuImages: null == menuImages ? _self._menuImages : menuImages // ignore: cast_nullable_to_non_nullable
as List<String>,hours: null == hours ? _self._hours : hours // ignore: cast_nullable_to_non_nullable
as Map<String, List<VenueHours>>,is24h: null == is24h ? _self.is24h : is24h // ignore: cast_nullable_to_non_nullable
as bool,partner: null == partner ? _self.partner : partner // ignore: cast_nullable_to_non_nullable
as VenuePartner,hasActiveOffers: null == hasActiveOffers ? _self.hasActiveOffers : hasActiveOffers // ignore: cast_nullable_to_non_nullable
as bool,transportEnabled: null == transportEnabled ? _self.transportEnabled : transportEnabled // ignore: cast_nullable_to_non_nullable
as bool,transportPartnerIds: null == transportPartnerIds ? _self._transportPartnerIds : transportPartnerIds // ignore: cast_nullable_to_non_nullable
as List<String>,transportNotesAr: null == transportNotesAr ? _self.transportNotesAr : transportNotesAr // ignore: cast_nullable_to_non_nullable
as String,transportNotesEn: null == transportNotesEn ? _self.transportNotesEn : transportNotesEn // ignore: cast_nullable_to_non_nullable
as String,lastStoryAt: freezed == lastStoryAt ? _self.lastStoryAt : lastStoryAt // ignore: cast_nullable_to_non_nullable
as Timestamp?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as Timestamp?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as Timestamp?,
  ));
}

/// Create a copy of Venue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VenueTagsCopyWith<$Res> get tags {
  
  return $VenueTagsCopyWith<$Res>(_self.tags, (value) {
    return _then(_self.copyWith(tags: value));
  });
}/// Create a copy of Venue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VenuePartnerCopyWith<$Res> get partner {
  
  return $VenuePartnerCopyWith<$Res>(_self.partner, (value) {
    return _then(_self.copyWith(partner: value));
  });
}
}


/// @nodoc
mixin _$VenueTags {

@JsonKey(fromJson: _toStringList) List<String> get mood;@JsonKey(fromJson: _toStringList) List<String> get occasion;@JsonKey(name: 'time_of_day', fromJson: _toStringList) List<String> get timeOfDay;// واضح عندك في generated code: meal
@JsonKey(fromJson: _toStringList) List<String> get meal;
/// Create a copy of VenueTags
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VenueTagsCopyWith<VenueTags> get copyWith => _$VenueTagsCopyWithImpl<VenueTags>(this as VenueTags, _$identity);

  /// Serializes this VenueTags to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VenueTags&&const DeepCollectionEquality().equals(other.mood, mood)&&const DeepCollectionEquality().equals(other.occasion, occasion)&&const DeepCollectionEquality().equals(other.timeOfDay, timeOfDay)&&const DeepCollectionEquality().equals(other.meal, meal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(mood),const DeepCollectionEquality().hash(occasion),const DeepCollectionEquality().hash(timeOfDay),const DeepCollectionEquality().hash(meal));

@override
String toString() {
  return 'VenueTags(mood: $mood, occasion: $occasion, timeOfDay: $timeOfDay, meal: $meal)';
}


}

/// @nodoc
abstract mixin class $VenueTagsCopyWith<$Res>  {
  factory $VenueTagsCopyWith(VenueTags value, $Res Function(VenueTags) _then) = _$VenueTagsCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: _toStringList) List<String> mood,@JsonKey(fromJson: _toStringList) List<String> occasion,@JsonKey(name: 'time_of_day', fromJson: _toStringList) List<String> timeOfDay,@JsonKey(fromJson: _toStringList) List<String> meal
});




}
/// @nodoc
class _$VenueTagsCopyWithImpl<$Res>
    implements $VenueTagsCopyWith<$Res> {
  _$VenueTagsCopyWithImpl(this._self, this._then);

  final VenueTags _self;
  final $Res Function(VenueTags) _then;

/// Create a copy of VenueTags
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mood = null,Object? occasion = null,Object? timeOfDay = null,Object? meal = null,}) {
  return _then(_self.copyWith(
mood: null == mood ? _self.mood : mood // ignore: cast_nullable_to_non_nullable
as List<String>,occasion: null == occasion ? _self.occasion : occasion // ignore: cast_nullable_to_non_nullable
as List<String>,timeOfDay: null == timeOfDay ? _self.timeOfDay : timeOfDay // ignore: cast_nullable_to_non_nullable
as List<String>,meal: null == meal ? _self.meal : meal // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [VenueTags].
extension VenueTagsPatterns on VenueTags {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VenueTags value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VenueTags() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VenueTags value)  $default,){
final _that = this;
switch (_that) {
case _VenueTags():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VenueTags value)?  $default,){
final _that = this;
switch (_that) {
case _VenueTags() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _toStringList)  List<String> mood, @JsonKey(fromJson: _toStringList)  List<String> occasion, @JsonKey(name: 'time_of_day', fromJson: _toStringList)  List<String> timeOfDay, @JsonKey(fromJson: _toStringList)  List<String> meal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VenueTags() when $default != null:
return $default(_that.mood,_that.occasion,_that.timeOfDay,_that.meal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _toStringList)  List<String> mood, @JsonKey(fromJson: _toStringList)  List<String> occasion, @JsonKey(name: 'time_of_day', fromJson: _toStringList)  List<String> timeOfDay, @JsonKey(fromJson: _toStringList)  List<String> meal)  $default,) {final _that = this;
switch (_that) {
case _VenueTags():
return $default(_that.mood,_that.occasion,_that.timeOfDay,_that.meal);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: _toStringList)  List<String> mood, @JsonKey(fromJson: _toStringList)  List<String> occasion, @JsonKey(name: 'time_of_day', fromJson: _toStringList)  List<String> timeOfDay, @JsonKey(fromJson: _toStringList)  List<String> meal)?  $default,) {final _that = this;
switch (_that) {
case _VenueTags() when $default != null:
return $default(_that.mood,_that.occasion,_that.timeOfDay,_that.meal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VenueTags implements VenueTags {
  const _VenueTags({@JsonKey(fromJson: _toStringList) final  List<String> mood = const <String>[], @JsonKey(fromJson: _toStringList) final  List<String> occasion = const <String>[], @JsonKey(name: 'time_of_day', fromJson: _toStringList) final  List<String> timeOfDay = const <String>[], @JsonKey(fromJson: _toStringList) final  List<String> meal = const <String>[]}): _mood = mood,_occasion = occasion,_timeOfDay = timeOfDay,_meal = meal;
  factory _VenueTags.fromJson(Map<String, dynamic> json) => _$VenueTagsFromJson(json);

 final  List<String> _mood;
@override@JsonKey(fromJson: _toStringList) List<String> get mood {
  if (_mood is EqualUnmodifiableListView) return _mood;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mood);
}

 final  List<String> _occasion;
@override@JsonKey(fromJson: _toStringList) List<String> get occasion {
  if (_occasion is EqualUnmodifiableListView) return _occasion;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_occasion);
}

 final  List<String> _timeOfDay;
@override@JsonKey(name: 'time_of_day', fromJson: _toStringList) List<String> get timeOfDay {
  if (_timeOfDay is EqualUnmodifiableListView) return _timeOfDay;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_timeOfDay);
}

// واضح عندك في generated code: meal
 final  List<String> _meal;
// واضح عندك في generated code: meal
@override@JsonKey(fromJson: _toStringList) List<String> get meal {
  if (_meal is EqualUnmodifiableListView) return _meal;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_meal);
}


/// Create a copy of VenueTags
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VenueTagsCopyWith<_VenueTags> get copyWith => __$VenueTagsCopyWithImpl<_VenueTags>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VenueTagsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VenueTags&&const DeepCollectionEquality().equals(other._mood, _mood)&&const DeepCollectionEquality().equals(other._occasion, _occasion)&&const DeepCollectionEquality().equals(other._timeOfDay, _timeOfDay)&&const DeepCollectionEquality().equals(other._meal, _meal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_mood),const DeepCollectionEquality().hash(_occasion),const DeepCollectionEquality().hash(_timeOfDay),const DeepCollectionEquality().hash(_meal));

@override
String toString() {
  return 'VenueTags(mood: $mood, occasion: $occasion, timeOfDay: $timeOfDay, meal: $meal)';
}


}

/// @nodoc
abstract mixin class _$VenueTagsCopyWith<$Res> implements $VenueTagsCopyWith<$Res> {
  factory _$VenueTagsCopyWith(_VenueTags value, $Res Function(_VenueTags) _then) = __$VenueTagsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: _toStringList) List<String> mood,@JsonKey(fromJson: _toStringList) List<String> occasion,@JsonKey(name: 'time_of_day', fromJson: _toStringList) List<String> timeOfDay,@JsonKey(fromJson: _toStringList) List<String> meal
});




}
/// @nodoc
class __$VenueTagsCopyWithImpl<$Res>
    implements _$VenueTagsCopyWith<$Res> {
  __$VenueTagsCopyWithImpl(this._self, this._then);

  final _VenueTags _self;
  final $Res Function(_VenueTags) _then;

/// Create a copy of VenueTags
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mood = null,Object? occasion = null,Object? timeOfDay = null,Object? meal = null,}) {
  return _then(_VenueTags(
mood: null == mood ? _self._mood : mood // ignore: cast_nullable_to_non_nullable
as List<String>,occasion: null == occasion ? _self._occasion : occasion // ignore: cast_nullable_to_non_nullable
as List<String>,timeOfDay: null == timeOfDay ? _self._timeOfDay : timeOfDay // ignore: cast_nullable_to_non_nullable
as List<String>,meal: null == meal ? _self._meal : meal // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$VenueHours {

 String get open; String get close;@JsonKey(name: 'spans_midnight') bool get spansMidnight;
/// Create a copy of VenueHours
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VenueHoursCopyWith<VenueHours> get copyWith => _$VenueHoursCopyWithImpl<VenueHours>(this as VenueHours, _$identity);

  /// Serializes this VenueHours to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VenueHours&&(identical(other.open, open) || other.open == open)&&(identical(other.close, close) || other.close == close)&&(identical(other.spansMidnight, spansMidnight) || other.spansMidnight == spansMidnight));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,open,close,spansMidnight);

@override
String toString() {
  return 'VenueHours(open: $open, close: $close, spansMidnight: $spansMidnight)';
}


}

/// @nodoc
abstract mixin class $VenueHoursCopyWith<$Res>  {
  factory $VenueHoursCopyWith(VenueHours value, $Res Function(VenueHours) _then) = _$VenueHoursCopyWithImpl;
@useResult
$Res call({
 String open, String close,@JsonKey(name: 'spans_midnight') bool spansMidnight
});




}
/// @nodoc
class _$VenueHoursCopyWithImpl<$Res>
    implements $VenueHoursCopyWith<$Res> {
  _$VenueHoursCopyWithImpl(this._self, this._then);

  final VenueHours _self;
  final $Res Function(VenueHours) _then;

/// Create a copy of VenueHours
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? open = null,Object? close = null,Object? spansMidnight = null,}) {
  return _then(_self.copyWith(
open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as String,close: null == close ? _self.close : close // ignore: cast_nullable_to_non_nullable
as String,spansMidnight: null == spansMidnight ? _self.spansMidnight : spansMidnight // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [VenueHours].
extension VenueHoursPatterns on VenueHours {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VenueHours value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VenueHours() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VenueHours value)  $default,){
final _that = this;
switch (_that) {
case _VenueHours():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VenueHours value)?  $default,){
final _that = this;
switch (_that) {
case _VenueHours() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String open,  String close, @JsonKey(name: 'spans_midnight')  bool spansMidnight)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VenueHours() when $default != null:
return $default(_that.open,_that.close,_that.spansMidnight);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String open,  String close, @JsonKey(name: 'spans_midnight')  bool spansMidnight)  $default,) {final _that = this;
switch (_that) {
case _VenueHours():
return $default(_that.open,_that.close,_that.spansMidnight);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String open,  String close, @JsonKey(name: 'spans_midnight')  bool spansMidnight)?  $default,) {final _that = this;
switch (_that) {
case _VenueHours() when $default != null:
return $default(_that.open,_that.close,_that.spansMidnight);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VenueHours implements VenueHours {
  const _VenueHours({required this.open, required this.close, @JsonKey(name: 'spans_midnight') this.spansMidnight = false});
  factory _VenueHours.fromJson(Map<String, dynamic> json) => _$VenueHoursFromJson(json);

@override final  String open;
@override final  String close;
@override@JsonKey(name: 'spans_midnight') final  bool spansMidnight;

/// Create a copy of VenueHours
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VenueHoursCopyWith<_VenueHours> get copyWith => __$VenueHoursCopyWithImpl<_VenueHours>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VenueHoursToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VenueHours&&(identical(other.open, open) || other.open == open)&&(identical(other.close, close) || other.close == close)&&(identical(other.spansMidnight, spansMidnight) || other.spansMidnight == spansMidnight));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,open,close,spansMidnight);

@override
String toString() {
  return 'VenueHours(open: $open, close: $close, spansMidnight: $spansMidnight)';
}


}

/// @nodoc
abstract mixin class _$VenueHoursCopyWith<$Res> implements $VenueHoursCopyWith<$Res> {
  factory _$VenueHoursCopyWith(_VenueHours value, $Res Function(_VenueHours) _then) = __$VenueHoursCopyWithImpl;
@override @useResult
$Res call({
 String open, String close,@JsonKey(name: 'spans_midnight') bool spansMidnight
});




}
/// @nodoc
class __$VenueHoursCopyWithImpl<$Res>
    implements _$VenueHoursCopyWith<$Res> {
  __$VenueHoursCopyWithImpl(this._self, this._then);

  final _VenueHours _self;
  final $Res Function(_VenueHours) _then;

/// Create a copy of VenueHours
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? open = null,Object? close = null,Object? spansMidnight = null,}) {
  return _then(_VenueHours(
open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as String,close: null == close ? _self.close : close // ignore: cast_nullable_to_non_nullable
as String,spansMidnight: null == spansMidnight ? _self.spansMidnight : spansMidnight // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$VenuePartner {

@JsonKey(name: 'is_partner') bool get isPartner; String get tier;
/// Create a copy of VenuePartner
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VenuePartnerCopyWith<VenuePartner> get copyWith => _$VenuePartnerCopyWithImpl<VenuePartner>(this as VenuePartner, _$identity);

  /// Serializes this VenuePartner to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VenuePartner&&(identical(other.isPartner, isPartner) || other.isPartner == isPartner)&&(identical(other.tier, tier) || other.tier == tier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isPartner,tier);

@override
String toString() {
  return 'VenuePartner(isPartner: $isPartner, tier: $tier)';
}


}

/// @nodoc
abstract mixin class $VenuePartnerCopyWith<$Res>  {
  factory $VenuePartnerCopyWith(VenuePartner value, $Res Function(VenuePartner) _then) = _$VenuePartnerCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'is_partner') bool isPartner, String tier
});




}
/// @nodoc
class _$VenuePartnerCopyWithImpl<$Res>
    implements $VenuePartnerCopyWith<$Res> {
  _$VenuePartnerCopyWithImpl(this._self, this._then);

  final VenuePartner _self;
  final $Res Function(VenuePartner) _then;

/// Create a copy of VenuePartner
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isPartner = null,Object? tier = null,}) {
  return _then(_self.copyWith(
isPartner: null == isPartner ? _self.isPartner : isPartner // ignore: cast_nullable_to_non_nullable
as bool,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [VenuePartner].
extension VenuePartnerPatterns on VenuePartner {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VenuePartner value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VenuePartner() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VenuePartner value)  $default,){
final _that = this;
switch (_that) {
case _VenuePartner():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VenuePartner value)?  $default,){
final _that = this;
switch (_that) {
case _VenuePartner() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'is_partner')  bool isPartner,  String tier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VenuePartner() when $default != null:
return $default(_that.isPartner,_that.tier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'is_partner')  bool isPartner,  String tier)  $default,) {final _that = this;
switch (_that) {
case _VenuePartner():
return $default(_that.isPartner,_that.tier);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'is_partner')  bool isPartner,  String tier)?  $default,) {final _that = this;
switch (_that) {
case _VenuePartner() when $default != null:
return $default(_that.isPartner,_that.tier);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VenuePartner implements VenuePartner {
  const _VenuePartner({@JsonKey(name: 'is_partner') this.isPartner = false, this.tier = 'C'});
  factory _VenuePartner.fromJson(Map<String, dynamic> json) => _$VenuePartnerFromJson(json);

@override@JsonKey(name: 'is_partner') final  bool isPartner;
@override@JsonKey() final  String tier;

/// Create a copy of VenuePartner
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VenuePartnerCopyWith<_VenuePartner> get copyWith => __$VenuePartnerCopyWithImpl<_VenuePartner>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VenuePartnerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VenuePartner&&(identical(other.isPartner, isPartner) || other.isPartner == isPartner)&&(identical(other.tier, tier) || other.tier == tier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isPartner,tier);

@override
String toString() {
  return 'VenuePartner(isPartner: $isPartner, tier: $tier)';
}


}

/// @nodoc
abstract mixin class _$VenuePartnerCopyWith<$Res> implements $VenuePartnerCopyWith<$Res> {
  factory _$VenuePartnerCopyWith(_VenuePartner value, $Res Function(_VenuePartner) _then) = __$VenuePartnerCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'is_partner') bool isPartner, String tier
});




}
/// @nodoc
class __$VenuePartnerCopyWithImpl<$Res>
    implements _$VenuePartnerCopyWith<$Res> {
  __$VenuePartnerCopyWithImpl(this._self, this._then);

  final _VenuePartner _self;
  final $Res Function(_VenuePartner) _then;

/// Create a copy of VenuePartner
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isPartner = null,Object? tier = null,}) {
  return _then(_VenuePartner(
isPartner: null == isPartner ? _self.isPartner : isPartner // ignore: cast_nullable_to_non_nullable
as bool,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
