import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/notification_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import 'report_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final theme = Theme.of(context);
    final items = notifProvider.notifications;

    return RefreshIndicator(
      onRefresh: () => notifProvider.fetchNotifications(),
      child: items.isEmpty && !notifProvider.isLoading
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Tidak Ada Notifikasi',
              message: 'Semua pembaruan status laporan fasilitas akan muncul di sini.',
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Notifikasi In-App', style: AppTypography.headingMedium(theme.colorScheme.onSurface)),
                    if (notifProvider.unreadCount > 0)
                      TextButton.icon(
                        icon: const Icon(Icons.done_all_rounded, size: 16),
                        label: const Text('Tandai Semua Dibaca'),
                        onPressed: () => notifProvider.markAllAsRead(),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                ...items.map((n) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: n.isRead ? theme.cardTheme.color : AppColors.accent.withValues(alpha: 0.06),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: n.isRead ? Colors.grey.withValues(alpha: 0.1) : AppColors.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          n.isRead ? Icons.notifications_outlined : Icons.notifications_active_rounded,
                          color: n.isRead ? Colors.grey : AppColors.accent,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        n.title,
                        style: TextStyle(
                          fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(n.message, style: const TextStyle(fontSize: 13, height: 1.3)),
                          const SizedBox(height: 4),
                          Text(
                            n.createdAt,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      trailing: n.reportId != null
                          ? const Icon(Icons.chevron_right_rounded, size: 20)
                          : null,
                      onTap: () {
                        if (!n.isRead) {
                          notifProvider.markAsRead(n.id);
                        }
                        if (n.reportId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportDetailScreen(reportId: n.reportId!),
                            ),
                          );
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
