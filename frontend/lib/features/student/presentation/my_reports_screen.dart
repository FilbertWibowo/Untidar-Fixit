import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/reports_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/report_card.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import 'report_detail_screen.dart';

class MyReportsScreen extends StatelessWidget {
  final Function(int)? onNavigate;

  const MyReportsScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final reportsProvider = context.watch<ReportsProvider>();
    final theme = Theme.of(context);
    final myReports = reportsProvider.myReports;

    return RefreshIndicator(
      onRefresh: () => reportsProvider.fetchMyReports(),
      child: myReports.isEmpty && !reportsProvider.isLoading
          ? EmptyState(
              icon: Icons.assignment_late_outlined,
              title: 'Belum Ada Laporan Anda',
              message: 'Anda belum pernah mengirim pengaduan kerusakan fasilitas kampus.',
              actionLabel: 'Buat Laporan Sekarang',
              onAction: onNavigate != null ? () => onNavigate!(1) : null,
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Pengaduan Saya',
                      style: AppTypography.headingMedium(theme.colorScheme.onSurface),
                    ),
                    Text(
                      '${myReports.length} Laporan',
                      style: AppTypography.bodySmall(theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (reportsProvider.isLoading)
                  ...List.generate(3, (_) => const ReportCardSkeleton())
                else
                  ...myReports.map((report) {
                    return ReportCard(
                      report: report,
                      isMyReport: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportDetailScreen(reportId: report.id),
                          ),
                        );
                      },
                    );
                  }),
              ],
            ),
    );
  }
}
