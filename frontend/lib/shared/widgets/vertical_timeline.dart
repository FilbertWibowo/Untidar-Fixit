import 'package:flutter/material.dart';
import '../../core/api/endpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../models/report_model.dart';

class VerticalTimeline extends StatelessWidget {
  final List<TimelineEvent> events;
  final String currentStatus;

  const VerticalTimeline({
    super.key,
    required this.events,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Belum ada riwayat progres.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isLast = index == events.length - 1;

        Color dotColor;
        IconData icon;
        String statusTitle;

        switch (event.status.toLowerCase()) {
          case 'terkirim':
            dotColor = AppColors.statusTerkirim;
            icon = Icons.send_rounded;
            statusTitle = 'Laporan Dikirimkan';
            break;
          case 'diverifikasi':
            dotColor = AppColors.statusDiverifikasi;
            icon = Icons.verified_rounded;
            statusTitle = 'Diverifikasi Sarpras';
            break;
          case 'ditugaskan':
            dotColor = AppColors.statusDitugaskan;
            icon = Icons.engineering_rounded;
            statusTitle = 'Teknisi Ditugaskan';
            break;
          case 'selesai':
            dotColor = AppColors.statusSelesai;
            icon = Icons.check_circle_rounded;
            statusTitle = 'Perbaikan Selesai';
            break;
          case 'ditolak':
            dotColor = AppColors.statusDitolak;
            icon = Icons.cancel_rounded;
            statusTitle = 'Laporan Ditolak';
            break;
          default:
            dotColor = Colors.grey;
            icon = Icons.info_rounded;
            statusTitle = event.status;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line & Dot
              SizedBox(
                width: 36,
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: dotColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: dotColor, width: 2),
                      ),
                      child: Icon(icon, size: 14, color: dotColor),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 8 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            statusTitle,
                            style: AppTypography.headingSmall(
                              Theme.of(context).colorScheme.onSurface,
                            ).copyWith(fontSize: 14),
                          ),
                          Text(
                            event.createdAt,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Oleh: ${event.changedByName} (${event.changedByRole})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      if (event.note != null && event.note!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            event.note!,
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                      if (event.photoPath != null && event.photoPath!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            '${Endpoints.uploadsBaseUrl}${event.photoPath}',
                            height: 140,
                            width: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              height: 80,
                              width: 160,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
