import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/admin_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final theme = Theme.of(context);
    final users = admin.users;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kelola Pengguna Sistem', style: AppTypography.headingMedium(theme.colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text('Daftar mahasiswa terdaftar dan staf Sarpras Untidar.', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 20),

          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final u = users[index];
                final isAdmin = u['role'] == 'admin';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isAdmin ? AppColors.statusDiverifikasi.withValues(alpha: 0.2) : AppColors.accent.withValues(alpha: 0.2),
                    child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.school, color: isAdmin ? AppColors.statusDiverifikasi : AppColors.accent, size: 20),
                  ),
                  title: Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Email: ${u['email']}${u['npm'] != null ? " • NPM: ${u['npm']}" : ""}', style: const TextStyle(fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAdmin ? AppColors.statusDiverifikasi.withValues(alpha: 0.15) : AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      u['role']?.toString().toUpperCase() ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isAdmin ? AppColors.statusDiverifikasi : AppColors.accent,
                      ),
                    ),
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
