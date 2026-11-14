import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/reports_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/report_card.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import 'report_detail_screen.dart';

class PublicReportsScreen extends StatefulWidget {
  const PublicReportsScreen({super.key});

  @override
  State<PublicReportsScreen> createState() => _PublicReportsScreenState();
}

class _PublicReportsScreenState extends State<PublicReportsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsProvider = context.watch<ReportsProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final theme = Theme.of(context);

    final buildings = reportsProvider.locationsTree.keys.toList();

    return RefreshIndicator(
      onRefresh: () => reportsProvider.fetchReports(reset: true),
      child: Column(
        children: [
          // Filter & Search Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nomor tiket, gedung, ruangan, masalah...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              reportsProvider.setFilters(search: '');
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (val) {
                    reportsProvider.setFilters(search: val.trim());
                  },
                ),
                const SizedBox(height: 12),

                // Filter row: Building, Category, Status, Sort
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Gedung Filter
                      DropdownButton<String>(
                        value: reportsProvider.selectedBuilding,
                        hint: const Text('Semua Gedung', style: TextStyle(fontSize: 12)),
                        underline: const SizedBox.shrink(),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('Semua Gedung', style: TextStyle(fontSize: 12))),
                          ...buildings.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 12)))),
                        ],
                        onChanged: (val) => reportsProvider.setFilters(building: val),
                      ),
                      const SizedBox(width: 12),

                      // Kategori Filter
                      DropdownButton<int>(
                        value: reportsProvider.selectedCategoryId,
                        hint: const Text('Semua Kategori', style: TextStyle(fontSize: 12)),
                        underline: const SizedBox.shrink(),
                        items: [
                          const DropdownMenuItem(value: 0, child: Text('Semua Kategori', style: TextStyle(fontSize: 12))),
                          ...reportsProvider.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontSize: 12)))),
                        ],
                        onChanged: (val) => reportsProvider.setFilters(categoryId: val),
                      ),
                      const SizedBox(width: 12),

                      // Status Filter
                      DropdownButton<String>(
                        value: reportsProvider.selectedStatus,
                        hint: const Text('Semua Status', style: TextStyle(fontSize: 12)),
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Semua Status', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'terkirim', child: Text('Terkirim', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'diverifikasi', child: Text('Diverifikasi', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'ditugaskan', child: Text('Ditugaskan', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'selesai', child: Text('Selesai', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) => reportsProvider.setFilters(status: val),
                      ),
                      const SizedBox(width: 12),

                      // Sort Toggle
                      FilterChip(
                        label: Text(
                          reportsProvider.sortBy == 'priority' ? '🔥 Skor Prioritas' : '⏱ Terbaru',
                          style: const TextStyle(fontSize: 11),
                        ),
                        selected: reportsProvider.sortBy == 'priority',
                        onSelected: (_) {
                          final nextSort = reportsProvider.sortBy == 'priority' ? 'latest' : 'priority';
                          reportsProvider.setFilters(sort: nextSort);
                        },
                      ),
                      const SizedBox(width: 8),

                      if (reportsProvider.selectedBuilding != null ||
                          reportsProvider.selectedCategoryId != null ||
                          reportsProvider.selectedStatus != null)
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            reportsProvider.clearFilters();
                          },
                          child: const Text('Reset', style: TextStyle(fontSize: 12, color: AppColors.statusDitolak)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Feed List
          Expanded(
            child: reportsProvider.isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 5,
                    itemBuilder: (_, _) => const ReportCardSkeleton(),
                  )
                : reportsProvider.reports.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Tidak Ada Laporan Ditemukan',
                        message: 'Coba ubah kata kunci pencarian atau bersihkan filter yang aktif.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: reportsProvider.reports.length + (reportsProvider.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == reportsProvider.reports.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }

                          final report = reportsProvider.reports[index];
                          return ReportCard(
                            report: report,
                            isMyReport: report.userId == user?.id,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReportDetailScreen(reportId: report.id),
                                ),
                              );
                            },
                            onUpvote: () => reportsProvider.toggleUpvote(report),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
