import 'package:flutter/material.dart';

class CampusHeatmapGrid extends StatelessWidget {
  final List<Map<String, dynamic>> buildings;
  final Function(String buildingName)? onBuildingSelected;

  const CampusHeatmapGrid({
    super.key,
    required this.buildings,
    this.onBuildingSelected,
  });

  IconData _getBuildingIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('teknik') || lower.contains('ft')) {
      return Icons.precision_manufacturing_rounded;
    } else if (lower.contains('ekonomi') || lower.contains('fe')) {
      return Icons.trending_up_rounded;
    } else if (lower.contains('perpus')) {
      return Icons.local_library_rounded;
    } else if (lower.contains('gku') || lower.contains('gkb') || lower.contains('kuliah bersama')) {
      return Icons.school_rounded;
    } else if (lower.contains('rektorat')) {
      return Icons.account_balance_rounded;
    } else if (lower.contains('masjid')) {
      return Icons.mosque_rounded;
    } else if (lower.contains('parkir')) {
      return Icons.local_parking_rounded;
    } else if (lower.contains('kantin') || lower.contains('koperasi')) {
      return Icons.storefront_rounded;
    } else if (lower.contains('satpam')) {
      return Icons.shield_rounded;
    }
    return Icons.domain_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (buildings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text('Belum ada data sebaran gedung.', style: TextStyle(color: Color(0xFF64748B))),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1100
            ? 4
            : constraints.maxWidth > 750
                ? 3
                : constraints.maxWidth > 500
                    ? 2
                    : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.55,
          ),
          itemCount: buildings.length,
          itemBuilder: (context, index) {
            final b = buildings[index];
            final name = b['building']?.toString() ?? 'Gedung Kampus';
            final activeIssues = int.tryParse(b['active_issues']?.toString() ?? '0') ?? 0;
            final totalReports = int.tryParse(b['total_reports']?.toString() ?? '0') ?? 0;
            final resolved = (totalReports - activeIssues).clamp(0, totalReports);

            Color statusColor;
            Color statusBg;
            String statusLabel;
            IconData statusIcon;

            if (activeIssues == 0) {
              statusColor = const Color(0xFF16A34A);
              statusBg = const Color(0xFFDCFCE7);
              statusLabel = 'Aman & Terawat';
              statusIcon = Icons.check_circle_rounded;
            } else if (activeIssues <= 2) {
              statusColor = const Color(0xFFD97706);
              statusBg = const Color(0xFFFEF3C7);
              statusLabel = '$activeIssues Masalah Aktif';
              statusIcon = Icons.info_rounded;
            } else {
              statusColor = const Color(0xFFDC2626);
              statusBg = const Color(0xFFFEE2E2);
              statusLabel = '$activeIssues Kritis';
              statusIcon = Icons.warning_rounded;
            }

            final iconData = _getBuildingIcon(name);

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onBuildingSelected != null ? () => onBuildingSelected!(name) : null,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: activeIssues > 2 ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
                      width: activeIssues > 2 ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header Card: Icon Gedung + Nama Gedung + Status Pill
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFDBEAFE)),
                            ),
                            child: Icon(iconData, color: const Color(0xFF2563EB), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$totalReports total laporan tercatat',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Status Bar & Health Indicator
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon, size: 12, color: statusColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusLabel,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '$resolved selesai',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Visual Health Line
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: totalReports == 0 ? 1.0 : (resolved / totalReports),
                              backgroundColor: activeIssues > 0 ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                activeIssues == 0
                                    ? const Color(0xFF22C55E)
                                    : activeIssues <= 2
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFEF4444),
                              ),
                              minHeight: 5,
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
