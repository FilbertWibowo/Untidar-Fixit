import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class CampusHeatmapGrid extends StatelessWidget {
  final List<Map<String, dynamic>> buildings;
  final Function(String buildingName)? onBuildingSelected;

  const CampusHeatmapGrid({
    super.key,
    required this.buildings,
    this.onBuildingSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (buildings.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
                ? 3
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: buildings.length,
          itemBuilder: (context, index) {
            final b = buildings[index];
            final name = b['building']?.toString() ?? 'Gedung';
            final activeIssues = int.tryParse(b['active_issues']?.toString() ?? '0') ?? 0;
            final totalReports = int.tryParse(b['total_reports']?.toString() ?? '0') ?? 0;

            Color statusColor;
            String statusLabel;
            if (activeIssues == 0) {
              statusColor = AppColors.heatmapSafe;
              statusLabel = 'Aman';
            } else if (activeIssues <= 2) {
              statusColor = AppColors.heatmapModerate;
              statusLabel = '$activeIssues Masalah';
            } else {
              statusColor = AppColors.heatmapCritical;
              statusLabel = '$activeIssues Kritis';
            }

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onBuildingSelected != null ? () => onBuildingSelected!(name) : null,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: activeIssues > 2 ? statusColor.withValues(alpha: 0.5) : Theme.of(context).dividerColor,
                      width: activeIssues > 2 ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$totalReports total',
                            style: AppTypography.bodySmall(
                              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
