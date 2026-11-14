import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/admin_provider.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAuditLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final theme = Theme.of(context);
    final logs = admin.auditLogs;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log Aktivitas Sistem (Audit Trail)', style: AppTypography.headingMedium(theme.colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text('Rekam jejak forensik seluruh tindakan admin sarpras: verifikasi, penugasan teknisi, penyelesaian, dan penolakan.', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 20),

          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final l = logs[index];

                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security_rounded, size: 18, color: AppColors.primary),
                  ),
                  title: Row(
                    children: [
                      Text(l['action']?.toString() ?? '', style: AppTypography.ticketCode(AppColors.primary)),
                      const Spacer(),
                      Text(l['created_at']?.toString() ?? '', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(l['details']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('Oleh: ${l['user_name'] ?? "Sistem"} (${l['user_role'] ?? "-"}) • IP: ${l['ip_address'] ?? "-"}', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
