import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shared shadow tiers for elevated and overlay surfaces.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: AppColors.shadowSoft,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> overlay = [
    BoxShadow(
      color: AppColors.shadowOverlay,
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
}
