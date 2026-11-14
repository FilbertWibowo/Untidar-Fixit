import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/reports_provider.dart';
import '../../../shared/models/location_model.dart';
import '../../../shared/widgets/tuguran_interactive_map.dart';
import 'create_report_screen.dart';

class ScanQrScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const ScanQrScreen({super.key, this.onNavigate});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _manualCodeController = TextEditingController(text: 'UNT-FT3-344');
  bool _isResolving = false;
  String? _resolveError;
  LocationModel? _resolvedLocation;

  // Preset demo QR codes with valid HMAC signatures
  final List<Map<String, String>> _demoQrs = [
    {
      'name': '⭐ FT 3 Lt 4 - Ruang 3.4.4',
      'code': 'UNT-FT3-344',
      'sig': '',
    },
    {
      'name': 'FT 3 Lt 4 - Ruang 3.4.5',
      'code': 'UNT-FT3-345',
      'sig': '',
    },
    {
      'name': 'GKB Lt 3 - Ruang 3.02',
      'code': 'TUG-GKB-302',
      'sig': '434220b224bcfa0ea996bdf2dd74d081f26a117b9b1399f6655c4538fe0d19d6',
    },
    {
      'name': 'FT Lt 1 - Lab Otomasi',
      'code': 'TUG-FT-LAB-101',
      'sig': '',
    },
    {
      'name': 'FE Lt 2 - Ruang A.2b.01',
      'code': 'UNT-FAKULTAS-A2B01',
      'sig': '',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  Future<void> _resolveCode(String code, {String? sig}) async {
    setState(() {
      _isResolving = true;
      _resolveError = null;
    });

    final reportsProvider = context.read<ReportsProvider>();
    final loc = await reportsProvider.resolveQrCode(code, sig ?? '');

    setState(() {
      _isResolving = false;
      _resolvedLocation = loc;
      if (loc == null) {
        _resolveError = reportsProvider.errorMessage ?? 'Kode QR tidak valid atau lokasi tidak ditemukan.';
      }
    });

    if (loc != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lokasi terverifikasi: ${loc.displayName}'),
          backgroundColor: const Color(0xFF3B5BDB),
        ),
      );
    }
  }

  void _proceedToReport() {
    if (_resolvedLocation != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Buat Laporan dari QR')),
            body: CreateReportScreen(
              prefilledLocation: _resolvedLocation,
              onNavigate: widget.onNavigate,
            ),
          ),
        ),
      );
    }
  }

  void _handleSpotSelectionFrom3D(BuildingSpot spot, String? room) {
    final reportsProvider = context.read<ReportsProvider>();
    // Try finding matching location in reportsProvider.locations
    LocationModel? match;
    for (final loc in reportsProvider.locations) {
      if (loc.building.toLowerCase().contains(spot.name.toLowerCase().split(' ')[0])) {
        if (room != null && loc.room.toLowerCase().contains(room.toLowerCase())) {
          match = loc;
          break;
        }
        match ??= loc;
      }
    }

    match ??= LocationModel(
      id: 19,
      building: spot.name,
      floor: (spot.number == 18 || spot.number == 6) ? 'Lantai 4' : 'Lantai 1',
      room: room ?? (spot.availableRooms.isNotEmpty ? spot.availableRooms.first : 'Ruang Umum'),
      code: (spot.number == 18 || spot.number == 6) ? 'UNT-FT3-344' : 'UNT-SPOT-${spot.number}',
      qrSignature: '',
      isActive: true,
    );

    setState(() {
      _resolvedLocation = match;
    });

    _proceedToReport();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
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
                  Text(
                    'Pindai QR / Pilih Denah 3D Tuguran',
                    style: AppTypography.headingMedium(theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pindai QR stiker di pintu ruangan atau pencet denah 3D interaktif Kampus Tuguran.',
                    style: AppTypography.bodySmall(theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tab Bar: Scan QR vs Denah 3D
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF3B5BDB),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF3B5BDB),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.qr_code_scanner_rounded, size: 18), text: 'Sensor QR Code'),
                Tab(icon: Icon(Icons.view_in_ar_rounded, size: 18), text: 'Denah 3D Interaktif Tuguran'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tab Content
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 1) {
                // Denah 3D View
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TuguranInteractiveMap(
                    showHeader: true,
                    initialSelectedNumber: 6, // Default FT 3
                    onSpotSelected: (spot, room) {
                      _handleSpotSelectionFrom3D(spot, room);
                    },
                  ),
                );
              }

              // Sensor QR Code View
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scanner Simulation Box
                  Center(
                    child: Container(
                      width: 320,
                      height: 220,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF3B5BDB), width: 2),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.qr_code_scanner_rounded, size: 50, color: Color(0xFF3B5BDB)),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Sensor QR Stiker Tuguran Aktif',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Arahkan ke stiker pintu ruangan kelas',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Verified Result Card if found
                  if (_resolvedLocation != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3B5BDB), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, color: Color(0xFF3B5BDB), size: 36),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lokasi Berhasil Terverifikasi!',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _resolvedLocation!.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                Text(
                                  'Kode: ${_resolvedLocation!.code} • HMAC Valid',
                                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B5BDB),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 38),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                            ),
                            onPressed: _proceedToReport,
                            child: const Text('Buat Laporan', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_resolveError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.statusDitolak.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.statusDitolak),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.statusDitolak, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _resolveError!,
                              style: const TextStyle(color: AppColors.statusDitolak, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Quick Demo QR Selector Chips
                  const Text(
                    'Uji Coba Cepat QR Ruangan (Klik untuk Simulasi Scan):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _demoQrs.map((item) {
                      final isFT3 = item['code']!.contains('FT3');
                      return ActionChip(
                        avatar: Icon(
                          Icons.qr_code,
                          size: 14,
                          color: isFT3 ? const Color(0xFFD97706) : const Color(0xFF3B5BDB),
                        ),
                        label: Text(
                          item['name']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isFT3 ? FontWeight.bold : FontWeight.w500,
                            color: isFT3 ? const Color(0xFFB45309) : const Color(0xFF1E293B),
                          ),
                        ),
                        backgroundColor: isFT3 ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                        side: BorderSide(
                          color: isFT3 ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                        ),
                        onPressed: () {
                          _manualCodeController.text = item['code']!;
                          _resolveCode(item['code']!, sig: item['sig']);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Manual Input Fallback
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fallback: Masukkan Kode Lokasi Manual',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _manualCodeController,
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'Contoh: UNT-FT3-344, TUG-GKB-302',
                                  prefixIcon: Icon(Icons.tag_rounded, size: 18),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B5BDB),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(100, 46),
                              ),
                              onPressed: _isResolving ? null : () => _resolveCode(_manualCodeController.text.trim()),
                              child: _isResolving
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Verifikasi'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
