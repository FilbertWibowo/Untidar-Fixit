import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PriorityBadge extends StatelessWidget {
  final int score;
  final bool showScore;

  const PriorityBadge({
    super.key,
    required this.score,
    this.showScore = true,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    if (score >= 15) {
      color = AppColors.priorityCritical;
      label = 'Kritis';
      icon = Icons.warning_rounded;
    } else if (score >= 10) {
      color = AppColors.priorityHigh;
      label = 'Tinggi';
      icon = Icons.arrow_upward_rounded;
    } else if (score >= 5) {
      color = AppColors.priorityMedium;
      label = 'Sedang';
      icon = Icons.remove_rounded;
    } else {
      color = AppColors.priorityLow;
      label = 'Rendah';
      icon = Icons.arrow_downward_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            showScore ? '$label ($score)' : label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
