import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/admin_provider.dart';
import '../../../shared/widgets/campus_heatmap_grid.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const AdminDashboardScreen({super.key, this.onNavigate});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final stats = admin.stats;
    final theme = Theme.of(context);

    if (admin.isLoading && stats == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return RefreshIndicator(
      onRefresh: () => admin.fetchDashboardStats(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard Sarpras Untidar', style: AppTypography.headingLarge(theme.colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(
                      'Pusat Kendali Pengaduan & Pemeliharaan Fasilitas Kampus Tuguran',
                      style: AppTypography.bodySmall(theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
                if (widget.onNavigate != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 40),
                    ),
                    icon: const Icon(Icons.format_list_bulleted_rounded, size: 18),
                    label: const Text('Buka Antrian Prioritas'),
                    onPressed: () => widget.onNavigate!(1),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Top KPI Summary Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final count = constraints.maxWidth > 900
                    ? 4
                    : constraints.maxWidth > 600
                        ? 2
                        : 2;

                return GridView.count(
                  crossAxisCount: count,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.8,
                  children: [
                    _buildKpiCard(
                      context,
                      title: 'Laporan Aktif (Antrian)',
                      value: '${stats?.activeReports ?? 0}',
                      icon: Icons.pending_actions_rounded,
                      color: AppColors.statusDitugaskan,
                    ),
                    _buildKpiCard(
                      context,
                      title: 'Selesai Diperbaiki',
                      value: '${stats?.resolvedReports ?? 0}',
                      icon: Icons.task_alt_rounded,
                      color: AppColors.statusSelesai,
                    ),
                    _buildKpiCard(
                      context,
                      title: 'Rata-rata Penyelesaian',
                      value: '${stats?.avgResolveHours ?? 0} Jam',
                      icon: Icons.timer_outlined,
                      color: AppColors.statusTerkirim,
                    ),
                    _buildKpiCard(
                      context,
                      title: 'Indeks Kepuasan Mahasiswa',
                      value: '${stats?.avgRating ?? 0} / 5.0 ⭐',
                      icon: Icons.thumb_up_alt_outlined,
                      color: Colors.amber.shade700,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // Section: Campus Tuguran Heatmap
            Row(
              children: [
                const Icon(Icons.grid_view_rounded, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Text('Peta Status Kerusakan Gedung Kampus Tuguran', style: AppTypography.headingSmall(theme.colorScheme.onSurface)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Indikator warna: Hijau (Aman / 0 Masalah Aktif), Kuning (1-2 Masalah), Merah (3+ Masalah Kritis).',
              style: AppTypography.bodySmall(theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 14),

            CampusHeatmapGrid(
              buildings: stats?.buildingHeatmap ?? [],
              onBuildingSelected: (name) {
                if (widget.onNavigate != null) {
                  widget.onNavigate!(1); // Go to queue
                }
              },
            ),
            const SizedBox(height: 28),

            // Top Problematic Buildings & Category Distribution
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Buildings
                    Expanded(
                      flex: isWide ? 1 : 0,
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.leaderboard_rounded, size: 18, color: Color(0xFFD97706)),
                                      SizedBox(width: 8),
                                      Text(
                                        'Gedung Paling Butuh Perhatian',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                  const Text('Urut Aktif', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (stats?.topBuildings != null && (stats?.topBuildings.isNotEmpty ?? false))
                                ...(stats?.topBuildings ?? []).asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final b = entry.value;
                                  final activeCount = int.tryParse(b['active_reports']?.toString() ?? '0') ?? 0;
                                  final rankColors = [
                                    const Color(0xFFEF4444),
                                    const Color(0xFFF97316),
                                    const Color(0xFFF59E0B),
                                    const Color(0xFF3B82F6),
                                    const Color(0xFF64748B),
                                  ];
                                  final badgeColor = idx < rankColors.length ? rankColors[idx] : const Color(0xFF64748B);

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 7.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFF1F5F9)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: badgeColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '#${idx + 1}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: badgeColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              b['building']?.toString() ?? '',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: badgeColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '$activeCount Aduan Aktif',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                })
                              else
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Text('Tidak ada laporan kerusakan aktif.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),

                    // Categories
                    Expanded(
                      flex: isWide ? 1 : 0,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Distribusi Kategori Fasilitas Rusak', style: AppTypography.headingSmall(theme.colorScheme.onSurface).copyWith(fontSize: 14)),
                              const SizedBox(height: 12),
                              if (stats?.categoriesStats != null)
                                ...stats!.categoriesStats.map((c) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.build_circle_outlined, size: 16, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            c['name']?.toString() ?? '',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        Text(
                                          '${c['count']} Laporan',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 20, color: color),
              ],
            ),
            Text(
              value,
              style: AppTypography.headingMedium(color).copyWith(fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }
}
