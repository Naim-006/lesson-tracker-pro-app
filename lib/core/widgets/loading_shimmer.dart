import 'package:flutter/material.dart';

class LoadingShimmer extends StatefulWidget {
  final int itemCount;
  final double itemHeight;

  const LoadingShimmer({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 88,
  });

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200;
    final highlightColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.itemCount,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: widget.itemHeight,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _buildShimmerItem(baseColor, highlightColor),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerItem(Color base, Color highlight) {
    return Row(
      children: [
        const SizedBox(width: 16),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 14,
                decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 8),
              Container(
                width: 200,
                height: 12,
                decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 60,
          height: 24,
          decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(8)),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}
