import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/admin_provider.dart';
import '../../../shared/models/picked_photo.dart';
import '../../../shared/models/report_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/priority_badge.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../student/presentation/report_detail_screen.dart';

class AdminQueueScreen extends StatefulWidget {
  const AdminQueueScreen({super.key});

  @override
  State<AdminQueueScreen> createState() => _AdminQueueScreenState();
}

class _AdminQueueScreenState extends State<AdminQueueScreen> {
  String _selectedStatusFilter = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchReportQueue();
      context.read<AdminProvider>().fetchTechnicians();
    });
  }

  void _showVerifyDialog(ReportModel report) {
    final noteController = TextEditingController(text: 'Laporan kerusakan telah diverifikasi oleh tim Sarpras Tuguran.');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verifikasi Laporan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Konfirmasi validitas laporan ${report.ticketNumber}: ${report.title}'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Catatan Verifikasi'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await context.read<AdminProvider>().verifyReport(report.id, noteController.text.trim());
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Laporan berhasil diverifikasi.'), backgroundColor: AppColors.accent),
                );
              }
            },
            child: const Text('Verifikasi'),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(ReportModel report) {
    final admin = context.read<AdminProvider>();
    final techs = admin.technicians;
    int? selectedTechId = techs.isNotEmpty ? techs.first['id'] as int : null;
    final notesController = TextEditingController(text: 'Segera lakukan pengecekan dan perbaikan fasilitas di lokasi.');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tugaskan Teknisi Sarpras', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Penugasan untuk: ${report.title} (${report.fullLocation})'),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: selectedTechId,
                decoration: const InputDecoration(labelText: 'Pilih Teknisi'),
                items: techs.map((t) {
                  return DropdownMenuItem<int>(
                    value: t['id'] as int,
                    child: Text('${t['name']} (${t['specialty']})'),
                  );
                }).toList(),
                onChanged: (val) => setDialogState(() => selectedTechId = val),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Instruksi / Catatan Kerja'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: selectedTechId == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final ok = await context.read<AdminProvider>().assignTechnician(
                            report.id,
                            selectedTechId!,
                            notesController.text.trim(),
                          );
                      if (ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Teknisi berhasil ditugaskan!'), backgroundColor: AppColors.accent),
                        );
                      }
                    },
              child: const Text('Tugaskan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompleteDialog(ReportModel report) {
    final noteController = TextEditingController(text: 'Perbaikan fasilitas selesai dilaksanakan dan diuji aman.');
    PickedPhoto? pickedPhoto;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tandai Selesai Diperbaiki', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Penyelesaian tiket ${report.ticketNumber}'),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Catatan Perbaikan'),
              ),
              const SizedBox(height: 14),
              const Text('Wajib Foto Bukti Perbaikan (After):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                    label: Text(pickedPhoto != null ? 'Foto Terpilih' : 'Unggah Foto Bukti'),
                    onPressed: () async {
                      final files = await FilePicker.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['jpg', 'png', 'webp'],
                      );
                      if (files.isNotEmpty) {
                        final bytes = await files.first.readAsBytes();
                        setDialogState(() => pickedPhoto = PickedPhoto(name: files.first.name, bytes: bytes));
                      }
                    },
                  ),
                  if (pickedPhoto != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle, color: AppColors.accent, size: 18),
                  ],
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusSelesai),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await context.read<AdminProvider>().completeReport(
                      report.id,
                      noteController.text.trim(),
                      pickedPhoto,
                    );
                if (ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Laporan dinyatakan selesai diperbaiki!'), backgroundColor: AppColors.accent),
                  );
                }
              },
              child: const Text('Selesaikan Laporan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(ReportModel report) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Laporan Pengaduan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Penolakan tiket: ${report.ticketNumber}'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Alasan Penolakan (Wajib)',
                hintText: 'Contoh: Di luar kewenangan sarpras kampus atau bukan fasilitas fisik...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusDitolak),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final ok = await context.read<AdminProvider>().rejectReport(report.id, reasonController.text.trim());
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Laporan telah ditolak.'), backgroundColor: AppColors.statusDitolak),
                );
              }
            },
            child: const Text('Tolak Laporan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final theme = Theme.of(context);
    final reports = admin.queueReports;

    return RefreshIndicator(
      onRefresh: () => admin.fetchReportQueue(status: _selectedStatusFilter),
      child: Column(
        children: [
          // Header & Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Antrian Prioritas Sarpras', style: AppTypography.headingMedium(theme.colorScheme.onSurface)),
                    Text(
                      '${reports.length} Laporan',
                      style: AppTypography.bodySmall(theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Urutan otomatis berdasarkan Skor Prioritas = (Upvote x 2) + Bobot Kategori + Hari Terbuka + Urgensi.',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 14),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('', 'Semua Antrian'),
                      _buildFilterChip('terkirim', 'Terkirim (Menunggu Verifikasi)'),
                      _buildFilterChip('diverifikasi', 'Diverifikasi'),
                      _buildFilterChip('ditugaskan', 'Ditugaskan'),
                      _buildFilterChip('selesai', 'Selesai'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Queue List
          Expanded(
            child: admin.isLoading
                ? const Center(child: CircularProgressIndicator())
                : reports.isEmpty
                    ? const EmptyState(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Antrian Kosong',
                        message: 'Tidak ada laporan yang cocok dengan filter antrian saat ini.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          final report = reports[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Ticket + Badges
                                  Row(
                                    children: [
                                      Text(report.ticketNumber, style: AppTypography.ticketCode(theme.colorScheme.primary)),
                                      const SizedBox(width: 8),
                                      PriorityBadge(score: report.priorityScore),
                                      const Spacer(),
                                      StatusBadge(status: report.status, isCompact: true),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Title & Location
                                  Text(report.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${report.fullLocation} • Kategori: ${report.categoryName}',
                                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    report.description,
                                    style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 14),

                                  const Divider(height: 1),
                                  const SizedBox(height: 10),

                                  // Action Buttons depending on status
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(0, 36),
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                        ),
                                        icon: const Icon(Icons.visibility_outlined, size: 14),
                                        label: const Text('Detail', style: TextStyle(fontSize: 12)),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ReportDetailScreen(reportId: report.id),
                                            ),
                                          );
                                        },
                                      ),
                                      if (report.status == 'terkirim') ...[
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.statusDiverifikasi,
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size(0, 36),
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                          ),
                                          icon: const Icon(Icons.verified_outlined, size: 14),
                                          label: const Text('Verifikasi', style: TextStyle(fontSize: 12)),
                                          onPressed: () => _showVerifyDialog(report),
                                        ),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.statusDitolak,
                                            side: const BorderSide(color: AppColors.statusDitolak),
                                            minimumSize: const Size(0, 36),
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                          ),
                                          icon: const Icon(Icons.close_rounded, size: 14),
                                          label: const Text('Tolak', style: TextStyle(fontSize: 12)),
                                          onPressed: () => _showRejectDialog(report),
                                        ),
                                      ],
                                      if (report.status == 'diverifikasi' || report.status == 'terkirim') ...[
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.statusDitugaskan,
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size(0, 36),
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                          ),
                                          icon: const Icon(Icons.engineering_outlined, size: 14),
                                          label: const Text('Tugaskan Teknisi', style: TextStyle(fontSize: 12)),
                                          onPressed: () => _showAssignDialog(report),
                                        ),
                                      ],
                                      if (report.status == 'ditugaskan') ...[
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.statusSelesai,
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size(0, 36),
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                          ),
                                          icon: const Icon(Icons.check_circle_outline, size: 14),
                                          label: const Text('Selesaikan (Bukti Foto)', style: TextStyle(fontSize: 12)),
                                          onPressed: () => _showCompleteDialog(report),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
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

  Widget _buildFilterChip(String status, String label) {
    final isSelected = _selectedStatusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        selectedColor: AppColors.accent.withValues(alpha: 0.2),
        onSelected: (_) {
          setState(() => _selectedStatusFilter = status);
          context.read<AdminProvider>().fetchReportQueue(status: status);
        },
      ),
    );
  }
}
