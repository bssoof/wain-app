import 'package:flutter/material.dart';

/// Custom loading indicator using the Wain logo
class WainLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  
  const WainLoadingIndicator({
    super.key,
    this.size = 50,
    this.color,
  });

  @override
  State<WainLoadingIndicator> createState() => _WainLoadingIndicatorState();
}

class _WainLoadingIndicatorState extends State<WainLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Image.asset(
              'assets/icons/logo.png',
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  color: widget.color ?? const Color(0xFFC0006F),
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
