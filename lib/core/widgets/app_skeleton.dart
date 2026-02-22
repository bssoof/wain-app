import 'package:flutter/material.dart';

/// Shimmer-style skeleton widgets that replace CircularProgressIndicator
/// during data loading, providing a premium loading experience.

// ── Shimmer effect ──────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
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
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-1.0 + 2.0 * _controller.value + 1.0, 0),
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Venue Card Skeleton ─────────────────────────────────────────

class VenueCardSkeleton extends StatelessWidget {
  const VenueCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const _ShimmerBox(width: 80, height: 80, borderRadius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _ShimmerBox(width: 140, height: 16),
                SizedBox(height: 8),
                _ShimmerBox(width: 100, height: 12),
                SizedBox(height: 8),
                _ShimmerBox(width: 60, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Venue Details Skeleton ──────────────────────────────────────

class VenueDetailsSkeleton extends StatelessWidget {
  const VenueDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image placeholder
          const _ShimmerBox(
            width: double.infinity,
            height: 250,
            borderRadius: 0,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const _ShimmerBox(width: 200, height: 22),
                const SizedBox(height: 12),
                // Subtitle
                const _ShimmerBox(width: 140, height: 14),
                const SizedBox(height: 20),
                // Tags row
                Row(
                  children: const [
                    _ShimmerBox(width: 70, height: 28, borderRadius: 14),
                    SizedBox(width: 8),
                    _ShimmerBox(width: 70, height: 28, borderRadius: 14),
                    SizedBox(width: 8),
                    _ShimmerBox(width: 70, height: 28, borderRadius: 14),
                  ],
                ),
                const SizedBox(height: 24),
                // Tabs placeholder
                const _ShimmerBox(
                  width: double.infinity,
                  height: 40,
                  borderRadius: 0,
                ),
                const SizedBox(height: 20),
                // Content rows
                const _ShimmerBox(width: double.infinity, height: 60),
                const SizedBox(height: 12),
                const _ShimmerBox(width: double.infinity, height: 60),
                const SizedBox(height: 12),
                const _ShimmerBox(width: double.infinity, height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Menu Item Skeleton ──────────────────────────────────────────

class MenuItemSkeleton extends StatelessWidget {
  const MenuItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: const [
          _ShimmerBox(width: 52, height: 52, borderRadius: 10),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: 120, height: 14),
                SizedBox(height: 6),
                _ShimmerBox(width: 60, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A list of skeleton cards for loading states
class VenueListSkeleton extends StatelessWidget {
  final int count;
  const VenueListSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (context, index) => const VenueCardSkeleton(),
    );
  }
}
