// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MenuItem _$MenuItemFromJson(Map<String, dynamic> json) => _MenuItem(
  id: json['id'] as String,
  nameAr: json['name_ar'] as String,
  nameEn: json['name_en'] as String? ?? '',
  descriptionAr: json['description_ar'] as String? ?? '',
  price: (json['price'] as num).toDouble(),
  currency: json['currency'] as String? ?? 'ILS',
  category: json['category'] as String,
  photoUrl: json['photo_url'] as String? ?? '',
  isAvailable: json['is_available'] as bool? ?? true,
  isFeatured: json['is_featured'] as bool? ?? false,
  sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
  createdAt: _timestampFromJson(json['created_at']),
  updatedAt: _timestampFromJson(json['updated_at']),
);

Map<String, dynamic> _$MenuItemToJson(_MenuItem instance) => <String, dynamic>{
  'name_ar': instance.nameAr,
  'name_en': instance.nameEn,
  'description_ar': instance.descriptionAr,
  'price': instance.price,
  'currency': instance.currency,
  'category': instance.category,
  'photo_url': instance.photoUrl,
  'is_available': instance.isAvailable,
  'is_featured': instance.isFeatured,
  'sort_order': instance.sortOrder,
};
