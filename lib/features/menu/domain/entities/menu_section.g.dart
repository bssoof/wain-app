// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_section.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MenuSection _$MenuSectionFromJson(Map<String, dynamic> json) => _MenuSection(
  id: json['id'] as String,
  nameAr: json['name_ar'] as String,
  nameEn: json['name_en'] as String? ?? '',
  icon: json['icon'] as String? ?? 'restaurant_menu',
  sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$MenuSectionToJson(_MenuSection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name_ar': instance.nameAr,
      'name_en': instance.nameEn,
      'icon': instance.icon,
      'sort_order': instance.sortOrder,
    };
