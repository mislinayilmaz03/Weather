import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A shimmer-effect placeholder for images that haven't loaded yet.
/// Creates a realistic "loading" feel for the outfit image area.
class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isDark;

  const ShimmerPlaceholder({
    super.key,
    this.width = double.infinity,
    this.height = 200,
    this.borderRadius = 16,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Shimmer.fromColors(
        baseColor: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.grey.shade300,
        highlightColor: isDark
            ? Colors.white.withOpacity(0.18)
            : Colors.grey.shade100,
        period: const Duration(milliseconds: 1800),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.15)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 120,
                height: 10,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 8,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
