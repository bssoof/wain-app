// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu_section.freezed.dart';
part 'menu_section.g.dart';

/// A section/category within a venue's menu (e.g. "Hot Drinks", "Main Courses").
/// Sections are defined per venue-category in the `menu_config` Firestore collection.
@freezed
sealed class MenuSection with _$MenuSection {
  const factory MenuSection({
    required String id,
    @JsonKey(name: 'name_ar') required String nameAr,
    @JsonKey(name: 'name_en') @Default('') String nameEn,
    @Default('restaurant_menu') String icon,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
  }) = _MenuSection;

  factory MenuSection.fromJson(Map<String, dynamic> json) =>
      _$MenuSectionFromJson(json);
}
