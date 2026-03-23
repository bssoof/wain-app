import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Restrained blur wrapper for approved floating overlays only.
class BlurContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final Color color;
  final Border? border;
  final double sigma;

  const BlurContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppSpacing.radiusMd,
    this.color = const Color(0xD9FFFFFF),
    this.border,
    this.sigma = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius,
            border: border,
          ),
          child: child,
        ),
      ),
    );
  }
}
