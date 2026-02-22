// ignore_for_file: invalid_annotation_target

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu_item.freezed.dart';
part 'menu_item.g.dart';

Timestamp? _timestampFromJson(Object? value) {
  if (value is Timestamp) return value;
  if (value is String) {
    final dt = DateTime.tryParse(value);
    if (dt != null) return Timestamp.fromDate(dt);
  }
  return null;
}

String? _timestampToJson(Timestamp? value) => value?.toDate().toIso8601String();

/// A single item on a venue's menu.
@freezed
sealed class MenuItem with _$MenuItem {
  const factory MenuItem({
    @JsonKey(includeToJson: false) required String id,
    @JsonKey(name: 'name_ar') required String nameAr,
    @JsonKey(name: 'name_en') @Default('') String nameEn,
    @JsonKey(name: 'description_ar') @Default('') String descriptionAr,
    required double price,
    @Default('ILS') String currency,

    /// Section key, e.g. "hot_drinks", "main_courses"
    required String category,
    @JsonKey(name: 'photo_url') @Default('') String photoUrl,
    @JsonKey(name: 'is_available') @Default(true) bool isAvailable,
    @JsonKey(name: 'is_featured') @Default(false) bool isFeatured,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @Default('manual') String source,
    @JsonKey(
      name: 'created_at',
      fromJson: _timestampFromJson,
      toJson: _timestampToJson,
      includeToJson: false,
    )
    Timestamp? createdAt,
    @JsonKey(
      name: 'updated_at',
      fromJson: _timestampFromJson,
      toJson: _timestampToJson,
      includeToJson: false,
    )
    Timestamp? updatedAt,
  }) = _MenuItem;

  factory MenuItem.fromJson(Map<String, dynamic> json) =>
      _$MenuItemFromJson(json);

  factory MenuItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return MenuItem.fromJson({...data, 'id': doc.id});
  }
}
