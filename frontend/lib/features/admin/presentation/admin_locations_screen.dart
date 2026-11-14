import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/admin_provider.dart';
import '../../../shared/models/location_model.dart';

class AdminLocationsScreen extends StatefulWidget {
  const AdminLocationsScreen({super.key});

  @override
  State<AdminLocationsScreen> createState() => _AdminLocationsScreenState();
}

class _AdminLocationsScreenState extends State<AdminLocationsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchLocations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddLocationDialog() {
    final buildingController = TextEditingController(text: 'Gedung Kuliah Bersama (GKB)');
    final floorController = TextEditingController(text: 'Lantai 3');
    final roomController = TextEditingController();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Titik Lokasi Kampus Untidar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: buildingController, decoration: const InputDecoration(labelText: 'Gedung')),
              const SizedBox(height: 10),
              TextField(controller: floorController, decoration: const InputDecoration(labelText: 'Lantai / Area')),
              const SizedBox(height: 10),
              TextField(controller: roomController, decoration: const InputDecoration(labelText: 'Nama Ruangan (contoh: R.305)')),
              const SizedBox(height: 10),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Kode Unik QR (opsional, otomatis dibuatkan)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (roomController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final ok = await context.read<AdminProvider>().addLocation(
                    buildingController.text.trim(),
                    floorController.text.trim(),
                    roomController.text.trim(),
                    codeController.text.trim(),
                  );
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lokasi baru berhasil ditambahkan beserta tanda tangan QR!'), backgroundColor: AppColors.accent),
                );
              }
            },
            child: const Text('Simpan & Generate QR'),
          ),
        ],
      ),
    );
  }

  void _showQrStickerDialog(LocationModel loc) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sticker Header (Simulasi Stiker Pintu Ruang Kampus)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'UNIVERSITAS TIDAR • SARPRAS',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                loc.building,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              Text(
                '${loc.floor} • ${loc.room}',
                style: const TextStyle(fontSize: 14, color: AppColors.accent, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // QR Code Graphic
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: QrImageView(
                  data: 'laportidar://report?code=${loc.code}&sig=${loc.qrSignature}',
                  version: QrVersions.auto,
                  size: 180.0,
                ),
              ),
              const SizedBox(height: 12),

              // Unique Code + HMAC Security Badge
              Text(
                'KODE: ${loc.code}',
                style: AppTypography.ticketCode(AppColors.primary).copyWith(fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: AppColors.accent),
                  SizedBox(width: 4),
                  Text(
                    'Tervalidasi Digital Signature (HMAC SHA-256)',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: const Text('Cetak Stiker'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Perintah cetak stiker dikirim ke printer/PDF.'), backgroundColor: AppColors.accent),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final theme = Theme.of(context);
    final locations = admin.locations;

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
                  Text('Kelola Lokasi & Stiker QR', style: AppTypography.headingMedium(theme.colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(
                    'Data titik ruangan Kampus Tuguran dan pencetakan stiker QR ber-HMAC.',
                    style: AppTypography.bodySmall(theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                label: const Text('Tambah Lokasi'),
                onPressed: _showAddLocationDialog,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Table / List of locations
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: locations.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final loc = locations[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.room_rounded, color: AppColors.accent, size: 20),
                  ),
                  title: Text('${loc.room} (${loc.floor})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${loc.building} • Kode: ${loc.code}', style: const TextStyle(fontSize: 12)),
                  trailing: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface,
                      foregroundColor: theme.colorScheme.onSurface,
                      side: BorderSide(color: theme.dividerColor),
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 16, color: AppColors.accent),
                    label: const Text('Lihat / Cetak QR', style: TextStyle(fontSize: 11)),
                    onPressed: () => _showQrStickerDialog(loc),
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
