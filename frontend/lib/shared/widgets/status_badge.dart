import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'terkirim':
        bg = AppColors.statusTerkirim.withValues(alpha: 0.15);
        fg = AppColors.statusTerkirim;
        icon = Icons.send_rounded;
        label = 'Terkirim';
        break;
      case 'diverifikasi':
        bg = AppColors.statusDiverifikasi.withValues(alpha: 0.15);
        fg = AppColors.statusDiverifikasi;
        icon = Icons.verified_rounded;
        label = 'Diverifikasi';
        break;
      case 'ditugaskan':
        bg = AppColors.statusDitugaskan.withValues(alpha: 0.15);
        fg = AppColors.statusDitugaskan;
        icon = Icons.engineering_rounded;
        label = 'Ditugaskan';
        break;
      case 'selesai':
        bg = AppColors.statusSelesai.withValues(alpha: 0.15);
        fg = AppColors.statusSelesai;
        icon = Icons.check_circle_rounded;
        label = 'Selesai';
        break;
      case 'ditolak':
        bg = AppColors.statusDitolak.withValues(alpha: 0.15);
        fg = AppColors.statusDitolak;
        icon = Icons.cancel_rounded;
        label = 'Ditolak';
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey;
        icon = Icons.info_rounded;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 12 : 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
