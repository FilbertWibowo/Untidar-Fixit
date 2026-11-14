import 'package:flutter/material.dart';

class SkeletonLoader extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class ReportCardSkeleton extends StatelessWidget {
  const ReportCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonLoader(height: 16, width: 120),
                SkeletonLoader(height: 20, width: 70),
              ],
            ),
            const SizedBox(height: 12),
            const SkeletonLoader(height: 20, width: double.infinity),
            const SizedBox(height: 8),
            const SkeletonLoader(height: 14, width: 200),
            const SizedBox(height: 16),
            const SkeletonLoader(height: 12, width: 140),
          ],
        ),
      ),
    );
  }
}
