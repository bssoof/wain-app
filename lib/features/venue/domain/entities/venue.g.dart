// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Venue _$VenueFromJson(Map<String, dynamic> json) => _Venue(
  id: json['id'] as String,
  nameAr: json['name_ar'] as String,
  nameEn: json['name_en'] as String,
  nameArNorm: json['name_ar_norm'] as String? ?? '',
  nameEnNorm: json['name_en_norm'] as String? ?? '',
  lat: _toDouble(json['lat']),
  lng: _toDouble(json['lng']),
  city: json['city'] as String,
  categories: _toStringList(json['categories']),
  tags: VenueTags.fromJson(json['tags'] as Map<String, dynamic>),
  allTags: json['all_tags'] == null
      ? const <String>[]
      : _toStringList(json['all_tags']),
  minPrice: _toInt(json['min_price']),
  maxPrice: _toInt(json['max_price']),
  currency: json['currency'] as String? ?? 'ILS',
  rating: _toDouble(json['rating']),
  phone: json['phone'] as String,
  instagram: json['instagram'] as String? ?? '',
  whatsapp: json['whatsapp'] as String? ?? '',
  facebook: json['facebook'] as String? ?? '',
  website: json['website'] as String? ?? '',
  photos: json['photos'] == null
      ? const <String>[]
      : _toStringList(json['photos']),
  menuImages: json['menu_images'] == null
      ? const <String>[]
      : _toStringList(json['menu_images']),
  hours: json['hours'] == null
      ? const <String, List<VenueHours>>{}
      : _toHoursMap(json['hours']),
  is24h: json['is_24h'] as bool? ?? false,
  partner: json['partner'] == null
      ? const VenuePartner()
      : VenuePartner.fromJson(json['partner'] as Map<String, dynamic>),
  hasActiveOffers: json['has_active_offers'] as bool? ?? false,
  lastStoryAt: _toTimestamp(json['last_story_at']),
  createdAt: _toTimestamp(json['created_at']),
  updatedAt: _toTimestamp(json['updated_at']),
);

Map<String, dynamic> _$VenueToJson(_Venue instance) => <String, dynamic>{
  'name_ar': instance.nameAr,
  'name_en': instance.nameEn,
  'name_ar_norm': instance.nameArNorm,
  'name_en_norm': instance.nameEnNorm,
  'lat': instance.lat,
  'lng': instance.lng,
  'city': instance.city,
  'categories': instance.categories,
  'tags': instance.tags,
  'all_tags': instance.allTags,
  'min_price': instance.minPrice,
  'max_price': instance.maxPrice,
  'currency': instance.currency,
  'rating': instance.rating,
  'phone': instance.phone,
  'instagram': instance.instagram,
  'whatsapp': instance.whatsapp,
  'facebook': instance.facebook,
  'website': instance.website,
  'photos': instance.photos,
  'menu_images': instance.menuImages,
  'hours': instance.hours,
  'is_24h': instance.is24h,
  'partner': instance.partner,
  'has_active_offers': instance.hasActiveOffers,
  'last_story_at': _timestampToJson(instance.lastStoryAt),
  'created_at': _timestampToJson(instance.createdAt),
  'updated_at': _timestampToJson(instance.updatedAt),
};

_VenueTags _$VenueTagsFromJson(Map<String, dynamic> json) => _VenueTags(
  mood: json['mood'] == null ? const <String>[] : _toStringList(json['mood']),
  occasion: json['occasion'] == null
      ? const <String>[]
      : _toStringList(json['occasion']),
  timeOfDay: json['time_of_day'] == null
      ? const <String>[]
      : _toStringList(json['time_of_day']),
  meal: json['meal'] == null ? const <String>[] : _toStringList(json['meal']),
);

Map<String, dynamic> _$VenueTagsToJson(_VenueTags instance) =>
    <String, dynamic>{
      'mood': instance.mood,
      'occasion': instance.occasion,
      'time_of_day': instance.timeOfDay,
      'meal': instance.meal,
    };

_VenueHours _$VenueHoursFromJson(Map<String, dynamic> json) => _VenueHours(
  open: json['open'] as String,
  close: json['close'] as String,
  spansMidnight: json['spans_midnight'] as bool? ?? false,
);

Map<String, dynamic> _$VenueHoursToJson(_VenueHours instance) =>
    <String, dynamic>{
      'open': instance.open,
      'close': instance.close,
      'spans_midnight': instance.spansMidnight,
    };

_VenuePartner _$VenuePartnerFromJson(Map<String, dynamic> json) =>
    _VenuePartner(
      isPartner: json['is_partner'] as bool? ?? false,
      tier: json['tier'] as String? ?? 'C',
    );

Map<String, dynamic> _$VenuePartnerToJson(_VenuePartner instance) =>
    <String, dynamic>{'is_partner': instance.isPartner, 'tier': instance.tier};
