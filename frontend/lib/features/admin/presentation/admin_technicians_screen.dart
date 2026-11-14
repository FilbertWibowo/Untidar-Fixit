import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/admin_provider.dart';

class AdminTechniciansScreen extends StatefulWidget {
  const AdminTechniciansScreen({super.key});

  @override
  State<AdminTechniciansScreen> createState() => _AdminTechniciansScreenState();
}

class _AdminTechniciansScreenState extends State<AdminTechniciansScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchTechnicians();
    });
  }

  void _showAddTechnicianDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final specController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Teknisi Sarpras', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
            const SizedBox(height: 10),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Nomor WhatsApp / HP')),
            const SizedBox(height: 10),
            TextField(controller: specController, decoration: const InputDecoration(labelText: 'Bidang Keahlian (Kelistrikan, Plumbing, IT, dll.)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final ok = await context.read<AdminProvider>().addTechnician(
                    nameController.text.trim(),
                    phoneController.text.trim(),
                    specController.text.trim(),
                  );
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Teknisi berhasil ditambahkan.'), backgroundColor: AppColors.accent),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final theme = Theme.of(context);
    final techs = admin.technicians;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Data Teknisi & Petugas Lapangan', style: AppTypography.headingMedium(theme.colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text('Tim teknisi Sarpras Universitas Tidar yang menangani penugasan perbaikan.', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Tambah Teknisi'),
                onPressed: _showAddTechnicianDialog,
              ),
            ],
          ),
          const SizedBox(height: 20),

          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: techs.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final t = techs[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                    child: Text(
                      (t['name'] ?? 'T')[0].toUpperCase(),
                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(t['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Keahlian: ${t['specialty']} • Telp: ${t['phone']}', style: const TextStyle(fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.statusSelesai.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Aktif Bertugas', style: TextStyle(fontSize: 11, color: AppColors.statusSelesai, fontWeight: FontWeight.bold)),
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
