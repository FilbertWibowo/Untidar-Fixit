import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/reports_provider.dart';
import '../../../shared/models/report_model.dart';
import '../../../shared/widgets/priority_badge.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/upvote_button.dart';
import '../../../shared/widgets/vertical_timeline.dart';

class ReportDetailScreen extends StatefulWidget {
  final int reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  ReportModel? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final reportsProvider = context.read<ReportsProvider>();
    final data = await reportsProvider.getReportDetail(widget.reportId);
    if (mounted) {
      setState(() {
        _report = data;
        _isLoading = false;
      });
    }
  }

  void _showRatingDialog() {
    int selectedRating = 5;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Beri Rating Kepuasan Perbaikan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Bagaimana kualitas dan kecepatan penyelesaian fasilitas oleh tim Sarpras Untidar?',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        icon: Icon(
                          star <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () => setDialogState(() => selectedRating = star),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Komentar / Masukan (Opsional)',
                      hintText: 'Tulis apresiasi atau catatan Anda...',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final success = await context.read<ReportsProvider>().submitRating(
                          widget.reportId,
                          selectedRating,
                          reviewController.text.trim(),
                        );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Terima kasih atas penilaian Anda!'),
                          backgroundColor: AppColors.accent,
                        ),
                      );
                      _loadDetail();
                    }
                  },
                  child: const Text('Kirim Penilaian'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Pengaduan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Pengaduan')),
        body: const Center(child: Text('Laporan tidak ditemukan.')),
      );
    }

    final report = _report!;
    final isMyReport = report.userId == user?.id;

    final beforePhotos = report.photos.where((p) => p.type == 'before').toList();
    final afterPhotos = report.photos.where((p) => p.type == 'after').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(report.ticketNumber, style: AppTypography.ticketCode(theme.colorScheme.onSurface)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: StatusBadge(status: report.status),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority & Upvote Header Row
            Row(
              children: [
                PriorityBadge(score: report.priorityScore),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Text(
                    report.categoryName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                UpvoteButton(
                  count: report.upvoteCount,
                  hasUpvoted: report.userHasUpvoted,
                  isOwnReport: isMyReport,
                  onToggle: () async {
                    await context.read<ReportsProvider>().toggleUpvote(report);
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(report.title, style: AppTypography.headingMedium(theme.colorScheme.onSurface)),
            const SizedBox(height: 8),

            // Location card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.fullLocation,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        if (report.locationCode != null)
                          Text(
                            'Kode Lokasi: ${report.locationCode}',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rejection Banner if rejected
            if (report.status == 'ditolak' && report.rejectionReason != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.statusDitolak.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.statusDitolak.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cancel_rounded, color: AppColors.statusDitolak, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Laporan Ditolak oleh Sarpras',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.statusDitolak, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Alasan: ${report.rejectionReason}',
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Description
            Text('Deskripsi Kerusakan:', style: AppTypography.headingSmall(theme.colorScheme.onSurface).copyWith(fontSize: 14)),
            const SizedBox(height: 6),
            Text(report.description, style: const TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 20),

            // Photos Section (Before / After Comparison)
            if (report.photos.isNotEmpty) ...[
              Text('Dokumentasi Foto Fasilitas:', style: AppTypography.headingSmall(theme.colorScheme.onSurface).copyWith(fontSize: 14)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...beforePhotos.map((p) => _buildPhotoItem(context, p, 'Sebelum (Before)')),
                    ...afterPhotos.map((p) => _buildPhotoItem(context, p, 'Sesudah Selesai (After)', isAfter: true)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Assigned Technician Card if assigned
            if (report.assignment != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.statusDitugaskan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.statusDitugaskan.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.statusDitugaskan,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Teknisi Penanggung Jawab',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.statusDitugaskan),
                          ),
                          Text(
                            report.assignment!['technician_name'] ?? 'Teknisi Sarpras',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Keahlian: ${report.assignment!['specialty'] ?? "-"} • Telp: ${report.assignment!['technician_phone'] ?? "-"}',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Rating Card or Rating Trigger Button
            if (report.status == 'selesai') ...[
              if (report.rating != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Penilaian Mahasiswa:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 8),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < (int.tryParse(report.rating!['rating'].toString()) ?? 5)
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: Colors.amber,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (report.rating!['review'] != null && report.rating!['review'].toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '"${report.rating!['review']}"',
                          style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else if (isMyReport) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.star_outline_rounded, size: 20),
                    label: const Text('Beri Rating Kepuasan Pelayanan Sarpras'),
                    onPressed: _showRatingDialog,
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],

            // Section: Vertical Timeline Progress
            Row(
              children: [
                const Icon(Icons.timeline_rounded, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Text('Transparansi Progres Penanganan (Live Timeline)', style: AppTypography.headingSmall(theme.colorScheme.onSurface)),
              ],
            ),
            const SizedBox(height: 16),
            VerticalTimeline(
              events: report.timeline,
              currentStatus: report.status,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoItem(BuildContext context, ReportPhoto photo, String label, {bool isAfter = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              '${Endpoints.uploadsBaseUrl}${photo.filePath}',
              width: 180,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 180,
                height: 120,
                color: Colors.grey.shade200,
                child: const Center(child: Icon(Icons.broken_image)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isAfter ? AppColors.statusSelesai.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isAfter ? AppColors.statusSelesai : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
