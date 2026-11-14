import 'package:flutter/material.dart';

class BuildingSpot {
  final int number;
  final String name;
  final String category;
  final String description;
  final double xRatio; // Relative position 0.0 - 1.0 on the image
  final double yRatio;
  final List<String> availableRooms;

  const BuildingSpot({
    required this.number,
    required this.name,
    required this.category,
    required this.description,
    required this.xRatio,
    required this.yRatio,
    required this.availableRooms,
  });
}

class TuguranInteractiveMap extends StatefulWidget {
  final Function(BuildingSpot spot, String? selectedRoom)? onSpotSelected;
  final int? initialSelectedNumber;
  final bool showHeader;

  const TuguranInteractiveMap({
    super.key,
    this.onSpotSelected,
    this.initialSelectedNumber,
    this.showHeader = true,
  });

  @override
  State<TuguranInteractiveMap> createState() => _TuguranInteractiveMapState();
}

class _TuguranInteractiveMapState extends State<TuguranInteractiveMap> {
  BuildingSpot? _selectedSpot;

  // 23 Spots matching the official 3D Tuguran isometric map uploaded by user
  final List<BuildingSpot> _spots = const [
    BuildingSpot(
      number: 1,
      name: 'Pos Satpam',
      category: 'Keamanan & Gerbang',
      description: 'Pos keamanan utama gerbang masuk kampus Tuguran.',
      xRatio: 0.83,
      yRatio: 0.36,
      availableRooms: ['Pos Jaga Depan', 'Akses Masuk Gerbang'],
    ),
    BuildingSpot(
      number: 2,
      name: 'Koperasi Untidar',
      category: 'Layanan Mahasiswa',
      description: 'Pusat belanja kebutuhan kuliah, ATK, dan fotokopi kampus.',
      xRatio: 0.84,
      yRatio: 0.41,
      availableRooms: ['Ruang Toko Koperasi', 'Layanan Fotokopi'],
    ),
    BuildingSpot(
      number: 3,
      name: 'Gedung Fakultas Ekonomi',
      category: 'Akademik FE',
      description: 'Gedung perkuliahan FE. Ruang A.2b.01 - A.4b.02, Lab Komputer FE.',
      xRatio: 0.76,
      yRatio: 0.49,
      availableRooms: ['A.2b.01', 'A.2b.02', 'A.3b.07 Lab Komputer', 'A.4a.01', 'A.4b.02'],
    ),
    BuildingSpot(
      number: 4,
      name: 'Gedung Kuliah Umum (GKU)',
      category: 'Akademik Bersama',
      description: 'Gedung perkuliahan bersama berkapasitas besar & auditorium serbaguna.',
      xRatio: 0.65,
      yRatio: 0.39,
      availableRooms: ['Ruang Kuliah GKU 1.01', 'Ruang Kuliah GKU 2.01', 'Auditorium Utama GKU'],
    ),
    BuildingSpot(
      number: 5,
      name: 'Gedung FKIP',
      category: 'Akademik FKIP',
      description: 'Gedung perkuliahan Fakultas Keguruan dan Ilmu Pendidikan.',
      xRatio: 0.69,
      yRatio: 0.62,
      availableRooms: ['Ruang Kuliah FKIP 2.01', 'Ruang Microteaching', 'Selasar FKIP'],
    ),
    BuildingSpot(
      number: 6,
      name: 'Area Parkir Timur',
      category: 'Fasilitas Parkir',
      description: 'Area parkir kendaraan roda dua dan roda empat area timur kampus.',
      xRatio: 0.59,
      yRatio: 0.68,
      availableRooms: ['Parkir Motor Timur', 'Parkir Mobil Dosen'],
    ),
    BuildingSpot(
      number: 7,
      name: 'Gedung Rektorat Utama',
      category: 'Pimpinan & Administrasi',
      description: 'Kantor Rektor, Wakil Rektor, BUK, BAKPK, dan Biro Administrasi Untidar.',
      xRatio: 0.52,
      yRatio: 0.51,
      availableRooms: ['Ruang Sidang Senat', 'Layanan Terpadu Rektorat', 'Lobi Pimpinan'],
    ),
    BuildingSpot(
      number: 8,
      name: 'Gedung Rektorat (Layanan)',
      category: 'Pelayanan Terpadu',
      description: 'Layanan administrasi mahasiswa, akademik, dan registrasi perkuliahan.',
      xRatio: 0.48,
      yRatio: 0.59,
      availableRooms: ['Loket Registrasi Akademik', 'Layanan Kemahasiswaan', 'Ruang Rapat'],
    ),
    BuildingSpot(
      number: 9,
      name: 'Gedung UPA TIK',
      category: 'Teknologi Informasi',
      description: 'Unit Pengelola Akademik TIK, server pusat, jaringan kampus & helpdesk.',
      xRatio: 0.40,
      yRatio: 0.56,
      availableRooms: ['Helpdesk UPA TIK', 'NOC Server Room', 'Lab Jaringan'],
    ),
    BuildingSpot(
      number: 10,
      name: 'Gedung FKIP Utama',
      category: 'Akademik FKIP',
      description: 'Gedung biru utama perkuliahan FKIP & Lab Komputer 1 Lt. 1.',
      xRatio: 0.49,
      yRatio: 0.75,
      availableRooms: ['Ruang Kuliah FKIP 1.01', 'Lab Komputer 1 Lt.1', 'Ruang Dosen FKIP'],
    ),
    BuildingSpot(
      number: 11,
      name: 'Gedung Sayap Depan',
      category: 'Layanan & Kemahasiswaan',
      description: 'Gedung pendukung perkuliahan & sekretariat organisasi mahasiswa.',
      xRatio: 0.34,
      yRatio: 0.85,
      availableRooms: ['Ruang Kuliah Depan 1', 'Ruang Ormawa', 'Selasar'],
    ),
    BuildingSpot(
      number: 12,
      name: 'Area Parkir Tengah',
      category: 'Fasilitas Parkir',
      description: 'Area parkir luas mahasiswa di lapangan tengah depan Fakultas Teknik.',
      xRatio: 0.35,
      yRatio: 0.70,
      availableRooms: ['Parkir Motor Tengah', 'Parkir Sepeda'],
    ),
    BuildingSpot(
      number: 13,
      name: 'Gedung Teknik 2 (FT-02)',
      category: 'Akademik FT',
      description: 'Gedung FT-02. Lab Komputer 2 Lt 2, Lab Mekatronika & Otomasi.',
      xRatio: 0.24,
      yRatio: 0.76,
      availableRooms: ['Ruang FT.201', 'Lab Komputer 2 Lt.2', 'Studio Desain'],
    ),
    BuildingSpot(
      number: 14,
      name: 'Gedung Teknik 1 (FT-01)',
      category: 'Akademik FT',
      description: 'Gedung FT-01. Lab Komputer 2 Lt 2, Lab Komputer 3 Lt 3, Ruang Kuliah E.01.',
      xRatio: 0.26,
      yRatio: 0.62,
      availableRooms: ['E.01.01', 'Lab Komputer 2 Lt.2', 'Lab Komputer 3 Lt.3'],
    ),
    BuildingSpot(
      number: 15,
      name: 'Gedung Kuliah Barat',
      category: 'Akademik',
      description: 'Gedung perkuliahan dan laboratorium praktikum terpadu.',
      xRatio: 0.16,
      yRatio: 0.59,
      availableRooms: ['Ruang Kuliah B.101', 'Lab Dasar Terpadu'],
    ),
    BuildingSpot(
      number: 16,
      name: 'Masjid Tuguran (Manarul Ilmi)',
      category: 'Fasilitas Ibadah',
      description: 'Tempat ibadah utama sivitas akademika kampus Tuguran & area wudhu.',
      xRatio: 0.25,
      yRatio: 0.51,
      availableRooms: ['Area Utama Sholat', 'Tempat Wudhu Pria', 'Tempat Wudhu Wanita'],
    ),
    BuildingSpot(
      number: 17,
      name: 'Area Parkir Gedung Bertingkat',
      category: 'Fasilitas Parkir',
      description: 'Gedung parkir terpadu kampus Tuguran samping masjid.',
      xRatio: 0.29,
      yRatio: 0.43,
      availableRooms: ['Lantai 1 Parkir Motor', 'Lantai 2 Parkir Motor', 'Lantai 3 Parkir Motor'],
    ),
    BuildingSpot(
      number: 18,
      name: 'Gedung Teknik 3 (FT-03)',
      category: '⭐ Akademik FT 3 (Lantai 4 Khusus)',
      description: 'Gedung FT-03 Lantai 4 dengan Ruang 3.4.4, 3.4.5, 3.4.6, 1.4.6 & Lab Komputer 3.',
      xRatio: 0.42,
      yRatio: 0.47,
      availableRooms: ['Ruang Kuliah 3.4.4', 'Ruang Kuliah 3.4.5', 'Ruang Kuliah 3.4.6', 'Ruang Kuliah 1.4.6', 'Lab Komputer 3 Lt.4'],
    ),
    BuildingSpot(
      number: 19,
      name: 'Area Parkir Samping GKU',
      category: 'Fasilitas Parkir',
      description: 'Area drop-off & parkir dosen/karyawan dekat perpustakaan & GKU.',
      xRatio: 0.52,
      yRatio: 0.38,
      availableRooms: ['Parkir Mobil GKU', 'Drop Zone'],
    ),
    BuildingSpot(
      number: 20,
      name: 'Perpustakaan Untidar',
      category: 'Sumber Belajar',
      description: 'Pusat perpustakaan digital, ruang baca mandiri, koleksi skripsi & e-journal.',
      xRatio: 0.50,
      yRatio: 0.29,
      availableRooms: ['Lantai 1 Sirkulasi', 'Lantai 2 Ruang Baca Digital', 'Lantai 3 Ruang Diskusi'],
    ),
    BuildingSpot(
      number: 21,
      name: 'Gedung Fisipol',
      category: 'Akademik FISIP',
      description: 'Gedung perkuliahan Fakultas Ilmu Sosial dan Ilmu Politik.',
      xRatio: 0.35,
      yRatio: 0.30,
      availableRooms: ['Ruang Kuliah FISIP 1.01', 'Ruang Kuliah FISIP 2.01', 'Lab Diplomasi'],
    ),
    BuildingSpot(
      number: 22,
      name: 'Kantin Tuguran',
      category: 'Fasilitas Konsumsi',
      description: 'Pusat kantin sehat mahasiswa, stand kuliner, dan area santai.',
      xRatio: 0.43,
      yRatio: 0.22,
      availableRooms: ['Stand Makanan Utama', 'Area Makan Mahasiswa'],
    ),
    BuildingSpot(
      number: 23,
      name: 'Pos Satpam dan ATM',
      category: 'Keamanan & Perbankan',
      description: 'Pos keamanan gerbang belakang & galeri ATM perbankan kampus.',
      xRatio: 0.49,
      yRatio: 0.20,
      availableRooms: ['Galeri ATM Center', 'Pos Keamanan Belakang'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedNumber != null) {
      _selectedSpot = _spots.firstWhere(
        (s) => s.number == widget.initialSelectedNumber,
        orElse: () => _spots[17], // Spot 18: Gedung Teknik 3
      );
    } else {
      _selectedSpot = _spots[17];
    }
  }

  void _onSpotTap(BuildingSpot spot) {
    setState(() {
      _selectedSpot = spot;
    });
    _showBuildingDetailsModal(spot);
  }

  void _showBuildingDetailsModal(BuildingSpot spot) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2430) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: spot.number == 6 ? const Color(0xFFD97706) : const Color(0xFF3B5BDB),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${spot.number}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spot.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          spot.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: spot.number == 6 ? const Color(0xFFD97706) : const Color(0xFF3B5BDB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                spot.description,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Ruangan di Gedung Ini:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: spot.availableRooms.map((room) {
                  final isSpecialFT3 = room.contains('3.4.') || room.contains('1.4.');
                  return ActionChip(
                    avatar: Icon(
                      Icons.meeting_room_outlined,
                      size: 14,
                      color: isSpecialFT3 ? const Color(0xFFD97706) : const Color(0xFF3B5BDB),
                    ),
                    label: Text(
                      room,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSpecialFT3 ? FontWeight.bold : FontWeight.w500,
                        color: isSpecialFT3 ? const Color(0xFFB45309) : (isDark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                    ),
                    backgroundColor: isSpecialFT3
                        ? (isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7))
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF)),
                    side: BorderSide(
                      color: isSpecialFT3 ? const Color(0xFFF59E0B) : const Color(0xFFBFDBFE),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (widget.onSpotSelected != null) {
                        widget.onSpotSelected!(spot, room);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B5BDB),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: Text('Buat Laporan di ${spot.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(ctx);
                  if (widget.onSpotSelected != null) {
                    widget.onSpotSelected!(spot, null);
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.map_rounded, size: 18, color: Color(0xFF3B5BDB)),
                      const SizedBox(width: 6),
                      Text(
                        'Denah 3D Kampus Tuguran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Text(
                          'Khusus Tuguran',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pencet nomor gedung pada denah 3D isometrik untuk melihat ruangan dan membuat pengaduan.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // 3D Isometric Map Container (Smooth, No eye-blink shutter)
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: 16 / 11, // Fits the UTBK Tuguran isometric map layout
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                return Stack(
                  children: [
                    // Map Image
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/denah_tuguran_3d.png',
                        fit: BoxFit.fill,
                      ),
                    ),

                    // Interactive Hotspots (Numbers 1 - 12)
                    ..._spots.map((spot) {
                      final isSelected = _selectedSpot?.number == spot.number;
                      final isSpecialFT3 = spot.number == 6; // FT 3

                      return Positioned(
                        left: (spot.xRatio * width) - 16,
                        top: (spot.yRatio * height) - 16,
                        child: GestureDetector(
                          onTap: () => _onSpotTap(spot),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 36 : 30,
                            height: isSelected ? 36 : 30,
                            decoration: BoxDecoration(
                              color: isSpecialFT3
                                  ? const Color(0xFFD97706) // Special Gold for FT 3
                                  : (isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF3B5BDB)),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: isSelected ? 2.5 : 1.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isSpecialFT3 ? const Color(0xFFD97706) : const Color(0xFF3B5BDB))
                                      .withValues(alpha: 0.6),
                                  blurRadius: isSelected ? 12 : 6,
                                  spreadRadius: isSelected ? 2 : 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${spot.number}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSelected ? 14 : 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Quick Selector Chips for the 12 buildings
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _spots.map((spot) {
              final isSelected = _selectedSpot?.number == spot.number;
              final isFT3 = spot.number == 6;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  avatar: CircleAvatar(
                    backgroundColor: isFT3 ? const Color(0xFFD97706) : const Color(0xFF3B5BDB),
                    child: Text(
                      '${spot.number}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  label: Text(
                    spot.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF1E3A8A) : (isDark ? Colors.white70 : const Color(0xFF334155)),
                    ),
                  ),
                  selected: isSelected,
                  backgroundColor: isFT3
                      ? (isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7))
                      : (isDark ? const Color(0xFF1E2430) : Colors.white),
                  selectedColor: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.5) : const Color(0xFFEFF6FF),
                  side: BorderSide(
                    color: isFT3 ? const Color(0xFFF59E0B) : (isSelected ? const Color(0xFF3B5BDB) : const Color(0xFFCBD5E1)),
                  ),
                  onSelected: (val) {
                    _onSpotTap(spot);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
