import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../models/report_model.dart';
import 'priority_badge.dart';
import 'status_badge.dart';
import 'upvote_button.dart';

class ReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onTap;
  final VoidCallback? onUpvote;
  final bool isMyReport;

  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
    this.onUpvote,
    this.isMyReport = false,
  });

  // Category Icon & Pastel Color Scheme (IT-Tools Style)
  Map<String, dynamic> _getCategoryStyle(String categoryName) {
    final cat = categoryName.toLowerCase();
    if (cat.contains('ac') || cat.contains('pendingin')) {
      return {'icon': Icons.ac_unit_rounded, 'color': const Color(0xFF2563EB), 'bg': const Color(0xFFEFF6FF)};
    } else if (cat.contains('listrik') || cat.contains('lampu')) {
      return {'icon': Icons.bolt_rounded, 'color': const Color(0xFFD97706), 'bg': const Color(0xFFFFFBEB)};
    } else if (cat.contains('air') || cat.contains('toilet') || cat.contains('sanitasi')) {
      return {'icon': Icons.water_drop_rounded, 'color': const Color(0xFF059669), 'bg': const Color(0xFFECFDF5)};
    } else if (cat.contains('wifi') || cat.contains('jaringan')) {
      return {'icon': Icons.wifi_rounded, 'color': const Color(0xFF4F46E5), 'bg': const Color(0xFFEEF2FF)};
    } else if (cat.contains('furnitur') || cat.contains('kursi')) {
      return {'icon': Icons.chair_rounded, 'color': const Color(0xFF9333EA), 'bg': const Color(0xFFFAF5FF)};
    } else if (cat.contains('kebersihan')) {
      return {'icon': Icons.cleaning_services_rounded, 'color': const Color(0xFF0891B2), 'bg': const Color(0xFFECFEFF)};
    } else if (cat.contains('parkir') || cat.contains('keamanan')) {
      return {'icon': Icons.local_parking_rounded, 'color': const Color(0xFFEA580C), 'bg': const Color(0xFFFFF7ED)};
    } else if (cat.contains('proyektor') || cat.contains('audio')) {
      return {'icon': Icons.videocam_rounded, 'color': const Color(0xFFE11D48), 'bg': const Color(0xFFFFF1F2)};
    }
    return {'icon': Icons.build_rounded, 'color': const Color(0xFF3B5BDB), 'bg': const Color(0xFFEFF6FF)};
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catStyle = _getCategoryStyle(report.categoryName);
    final isFT3 = report.fullLocation.contains('Teknik 3') || report.fullLocation.contains('3.4.') || report.fullLocation.contains('1.4.');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: AppColors.headerBlue.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFT3
                  ? const Color(0xFF3B5BDB).withValues(alpha: 0.4)
                  : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
              width: isFT3 ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: IT-Tools Style Icon Box + Status & Priority
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pastel Icon Container (IT-Tools signature)
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? (catStyle['color'] as Color).withValues(alpha: 0.2) : catStyle['bg'] as Color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      catStyle['icon'] as IconData,
                      color: catStyle['color'] as Color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Ticket & Location Pill
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            Text(
                              report.ticketNumber,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary,
                                letterSpacing: 0.3,
                              ),
                            ),
                            if (isFT3) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFF59E0B)),
                                ),
                                child: const Text(
                                  'FT 3 Lt 4',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          report.fullLocation,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Status Badge & Priority Pill
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(status: report.status, isCompact: true),
                      const SizedBox(height: 4),
                      PriorityBadge(score: report.priorityScore),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title (Plus Jakarta Sans Bold)
              Text(
                report.title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Description preview
              Text(
                report.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),

              const Divider(height: 16, thickness: 0.8),

              // Footer Row: Upvote Action Button & Category Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.label_outline_rounded, size: 12, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          report.categoryName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),

                  UpvoteButton(
                    count: report.upvoteCount,
                    hasUpvoted: report.userHasUpvoted,
                    isOwnReport: isMyReport,
                    onToggle: onUpvote,
                    isCompact: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
