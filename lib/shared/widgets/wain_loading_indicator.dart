import 'package:flutter/material.dart';
import 'package:wain_app/core/theme/app_theme.dart';

/// Custom loading indicator using WAIN branded image.
class WainLoadingIndicator extends StatefulWidget {
  final double size;
  final Duration duration;
  final bool animate;
  final Color fallbackColor;

  const WainLoadingIndicator({
    super.key,
    this.size = 44,
    this.duration = const Duration(milliseconds: 1400),
    this.animate = true,
    this.fallbackColor = AppTheme.primaryColor,
  });

  @override
  State<WainLoadingIndicator> createState() => _WainLoadingIndicatorState();
}

class _WainLoadingIndicatorState extends State<WainLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WainLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final constrained =
            constraints.hasBoundedWidth && constraints.hasBoundedHeight;
        final maxSide = constrained
            ? constraints.biggest.shortestSide.clamp(12.0, 160.0)
            : widget.size;

        Widget image = Image.asset(
          'assets/images/Group 6.png',
          width: maxSide,
          height: maxSide,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.hourglass_top_rounded,
              size: maxSide * 0.72,
              color: widget.fallbackColor,
            );
          },
        );

        if (!widget.animate) {
          return Center(child: image);
        }

        return Center(
          child: RotationTransition(
            turns: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: _controller, curve: Curves.linear),
            ),
            child: image,
          ),
        );
      },
    );
  }
}
