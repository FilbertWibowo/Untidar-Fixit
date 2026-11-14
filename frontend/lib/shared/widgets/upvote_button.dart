import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class UpvoteButton extends StatelessWidget {
  final int count;
  final bool hasUpvoted;
  final bool isOwnReport;
  final VoidCallback? onToggle;
  final bool isCompact;

  const UpvoteButton({
    super.key,
    required this.count,
    required this.hasUpvoted,
    this.isOwnReport = false,
    this.onToggle,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.accent;
    final inactiveColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    if (isOwnReport) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.thumb_up_alt_outlined, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              '$count Didukung',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 12,
            vertical: isCompact ? 5 : 8,
          ),
          decoration: BoxDecoration(
            color: hasUpvoted ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
            border: Border.all(
              color: hasUpvoted ? activeColor : inactiveColor.withValues(alpha: 0.3),
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasUpvoted ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                size: isCompact ? 14 : 16,
                color: hasUpvoted ? activeColor : inactiveColor,
              ),
              const SizedBox(width: 6),
              Text(
                hasUpvoted ? 'Mengalami ($count)' : 'Hal Serupa ($count)',
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: FontWeight.bold,
                  color: hasUpvoted ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
