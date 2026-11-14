import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/reports_provider.dart';
import '../../../shared/models/report_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/report_card.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import 'report_detail_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const StudentHomeScreen({super.key, required this.onNavigate});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final _searchController = TextEditingController();
  String _selectedCategoryFilter = 'all'; // 'all', 'ft3', 'ac', 'listrik', 'air', 'wifi'
  String _selectedStatus = 'all'; // 'all', 'active', 'selesai'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final reportsProvider = context.watch<ReportsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = auth.user;

    // Filter reports based on IT-tools search & category tabs
    final query = _searchController.text.trim().toLowerCase();
    List<ReportModel> displayedReports = reportsProvider.reports.where((r) {
      if (query.isNotEmpty) {
        final matchesTitle = r.title.toLowerCase().contains(query);
        final matchesDesc = r.description.toLowerCase().contains(query);
        final matchesLoc = r.fullLocation.toLowerCase().contains(query);
        final matchesCat = r.categoryName.toLowerCase().contains(query);
        final matchesTicket = r.ticketNumber.toLowerCase().contains(query);
        if (!matchesTitle && !matchesDesc && !matchesLoc && !matchesCat && !matchesTicket) {
          return false;
        }
      }

      if (_selectedCategoryFilter == 'ft3') {
        final loc = r.fullLocation.toLowerCase();
        if (!loc.contains('teknik 3') && !loc.contains('3.4.') && !loc.contains('1.4.')) {
          return false;
        }
      } else if (_selectedCategoryFilter == 'ac') {
        if (!r.categoryName.toLowerCase().contains('ac')) return false;
      } else if (_selectedCategoryFilter == 'listrik') {
        if (!r.categoryName.toLowerCase().contains('listrik') && !r.categoryName.toLowerCase().contains('lampu')) return false;
      } else if (_selectedCategoryFilter == 'air') {
        if (!r.categoryName.toLowerCase().contains('air') && !r.categoryName.toLowerCase().contains('toilet')) return false;
      } else if (_selectedCategoryFilter == 'wifi') {
        if (!r.categoryName.toLowerCase().contains('wifi') && !r.categoryName.toLowerCase().contains('jaringan')) return false;
      }

      if (_selectedStatus == 'active') {
        if (r.status == 'selesai' || r.status == 'ditolak') return false;
      } else if (_selectedStatus == 'selesai') {
        if (r.status != 'selesai') return false;
      }

      return true;
    }).toList();

    final isMobile = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: () => reportsProvider.initData(),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14.0 : 24.0,
          vertical: isMobile ? 16.0 : 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Title (Fixed: Full-width layout, never compressed vertically)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Text(
                        'Layanan Fasilitas Kampus Untidar',
                        style: TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Text(
                        'Tuguran & Sidotopo',
                        style: TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Pusat Pengaduan & Fasilitas Kampus',
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sistem pelaporan kerusakan fasilitas kampus Universitas Tidar secara cepat, transparan, dan terpantau.',
                  style: TextStyle(
                    fontSize: isMobile ? 13.5 : 15,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // IT-Tools Style 2-Column Action Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 750;

                final leftCard = Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2430) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_task_rounded, color: Color(0xFF3B5BDB), size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Buat Pengaduan Fasilitas',
                                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Scan QR atau pilih dari denah 3D',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B5BDB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Lapor Fasilitas', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                            onPressed: () => widget.onNavigate(1),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF3B5BDB),
                              side: const BorderSide(color: Color(0xFF3B5BDB)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                            label: const Text('Scan QR Stiker', style: TextStyle(fontSize: 12.5)),
                            onPressed: () => widget.onNavigate(2),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFD97706),
                              side: const BorderSide(color: Color(0xFFD97706)),
                              backgroundColor: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.view_in_ar_rounded, size: 16, color: Color(0xFFD97706)),
                            label: const Text('Denah 3D Tuguran', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                            onPressed: () => widget.onNavigate(2),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                final rightCard = Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2430) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF059669), size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status Penanganan Sarpras',
                                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Transparansi proses perbaikan fasilitas',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${reportsProvider.reports.where((r) => r.status != "selesai" && r.status != "ditolak").length}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3B5BDB)),
                                  ),
                                  const Text('Kasus Aktif', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${reportsProvider.reports.where((r) => r.status == "selesai").length}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                  ),
                                  const Text('Kasus Selesai', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${reportsProvider.myReports.length}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                  ),
                                  const Text('Laporan Saya', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: leftCard),
                      const SizedBox(width: 14),
                      Expanded(child: rightCard),
                    ],
                  );
                }

                return Column(
                  children: [
                    leftCard,
                    const SizedBox(height: 14),
                    rightCard,
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // IT-Tools Signature Central Search Bar
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2430) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ketik untuk mencari (contoh: 3.4.4, AC bocor, GKB, FT-03, WiFi)...',
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF3B5BDB), size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                              ),
                              child: const Text(
                                'Ctrl+K',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // IT-Tools Horizontal Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('all', 'Semua Kategori', Icons.grid_view_rounded, reportsProvider.reports.length),
                  const SizedBox(width: 8),
                  _buildCategoryChip('ft3', '⭐ Gedung FT 3 Lt 4', Icons.apartment_rounded, 
                    reportsProvider.reports.where((r) => r.fullLocation.contains('Teknik 3') || r.fullLocation.contains('3.4.') || r.fullLocation.contains('1.4.')).length
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryChip('ac', 'AC & Pendingin', Icons.ac_unit_rounded,
                    reportsProvider.reports.where((r) => r.categoryName.toLowerCase().contains('ac')).length
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryChip('listrik', 'Listrik & Lampu', Icons.bolt_rounded,
                    reportsProvider.reports.where((r) => r.categoryName.toLowerCase().contains('listrik') || r.categoryName.toLowerCase().contains('lampu')).length
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryChip('air', 'Air & Sanitasi', Icons.water_drop_rounded,
                    reportsProvider.reports.where((r) => r.categoryName.toLowerCase().contains('air') || r.categoryName.toLowerCase().contains('toilet')).length
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryChip('wifi', 'Jaringan / WiFi', Icons.wifi_rounded,
                    reportsProvider.reports.where((r) => r.categoryName.toLowerCase().contains('wifi') || r.categoryName.toLowerCase().contains('jaringan')).length
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Results Counter & Status Filter Row (Responsive to prevent overlapping on mobile)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Text(
                  'Menampilkan ${displayedReports.length} laporan fasilitas',
                  style: TextStyle(
                    fontSize: isMobile ? 13.5 : 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusPill('all', 'Semua'),
                      const SizedBox(width: 6),
                      _buildStatusPill('active', 'Diproses'),
                      const SizedBox(width: 6),
                      _buildStatusPill('selesai', 'Selesai'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // IT-Tools Card Grid View
            if (reportsProvider.isLoading)
              const ReportCardSkeleton()
            else if (displayedReports.isEmpty)
              const EmptyState(
                title: 'Tidak ada laporan yang cocok',
                message: 'Silakan ubah kata kunci pencarian atau pilih kategori lain.',
                icon: Icons.search_off_rounded,
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 1;
                  if (constraints.maxWidth > 1050) {
                    crossAxisCount = 3;
                  } else if (constraints.maxWidth > 650) {
                    crossAxisCount = 2;
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: crossAxisCount == 1
                          ? (constraints.maxWidth < 450 ? 1.25 : 1.35)
                          : 1.45,
                    ),
                    itemCount: displayedReports.length,
                    itemBuilder: (context, index) {
                      final report = displayedReports[index];
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
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String key, String label, IconData icon, int count) {
    final isSelected = _selectedCategoryFilter == key;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _selectedCategoryFilter = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B5BDB)
              : (isDark ? const Color(0xFF1E2430) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B5BDB)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF3B5BDB).withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E293B)),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.2) : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String key, String label) {
    final isSelected = _selectedStatus == key;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _selectedStatus = key),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E3A8A)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1E3A8A)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}
