import 'package:flutter/material.dart';

/// Shared spacing, radius, and sizing tokens.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const double touchTargetMin = 48;

  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(20));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(999));

  static const EdgeInsets screenPadding = EdgeInsets.all(xl);
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: lg,
  );
  static const EdgeInsets compactPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );
}
