import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/reports_provider.dart';
import '../../../shared/models/location_model.dart';
import '../../../shared/models/picked_photo.dart';
import '../../../shared/models/report_model.dart';
import '../../../shared/widgets/tuguran_interactive_map.dart';

class CreateReportScreen extends StatefulWidget {
  final LocationModel? prefilledLocation;
  final Function(int)? onNavigate;

  const CreateReportScreen({
    super.key,
    this.prefilledLocation,
    this.onNavigate,
  });

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  String? _selectedBuilding;
  String? _selectedFloor;
  LocationModel? _selectedLocation;
  int? _selectedCategoryId;
  String _selectedUrgency = 'rendah';

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<PickedPhoto> _pickedPhotos = [];

  bool _isCheckingSimilar = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledLocation != null) {
      _applyPrefilledLocation(widget.prefilledLocation!);
    }
  }

  void _applyPrefilledLocation(LocationModel loc) {
    _selectedBuilding = loc.building;
    _selectedFloor = loc.floor;
    _selectedLocation = loc;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    if (_pickedPhotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 3 foto lampiran.')),
      );
      return;
    }

    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );

    if (files.isNotEmpty) {
      for (final f in files) {
        if (_pickedPhotos.length < 3) {
          final bytes = await f.readAsBytes();
          setState(() {
            _pickedPhotos.add(PickedPhoto(name: f.name, bytes: bytes));
          });
        }
      }
    }
  }

  Future<void> _checkSimilarAndSubmit() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih lokasi ruangan kampus.')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kategori fasilitas.')),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan isi judul pengaduan.')),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan isi deskripsi kerusakan secara detail.')),
      );
      return;
    }

    final reportsProvider = context.read<ReportsProvider>();
    setState(() => _isCheckingSimilar = true);

    // Feature 2: Anti-Spam detector: check similar open reports at the same location & category
    final similarReports = await reportsProvider.checkSimilarReports(
      _selectedLocation!.id,
      _selectedCategoryId!,
    );
    setState(() => _isCheckingSimilar = false);

    if (!mounted) return;

    if (similarReports.isNotEmpty) {
      // Show "Saya Mengalami Hal Serupa" Anti-Spam Dialog!
      _showSimilarReportsDialog(similarReports);
    } else {
      _executeSubmitReport();
    }
  }

  void _showSimilarReportsDialog(List<ReportModel> similar) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.statusDitugaskan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline, color: AppColors.statusDitugaskan),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Laporan Serupa Ditemukan!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fasilitas di lokasi ${_selectedLocation?.room} sudah pernah dilaporkan mahasiswa lain. Meng-upvote laporan ini akan meningkatkan prioritas tim Sarpras!',
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: similar.length,
                    itemBuilder: (_, i) {
                      final item = similar[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(ctx).dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.ticketNumber} • ${item.upvoteCount} Mahasiswa telah mendukung',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 36),
                                ),
                                icon: const Icon(Icons.thumb_up_rounded, size: 14),
                                label: const Text('Saya Mengalami Hal Serupa (Upvote)'),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await context.read<ReportsProvider>().toggleUpvote(item);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Terima kasih! Dukungan Anda telah dicatat.'),
                                        backgroundColor: AppColors.accent,
                                      ),
                                    );
                                    if (widget.onNavigate != null) {
                                      widget.onNavigate!(3); // Go to public feed
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _executeSubmitReport();
              },
              child: const Text('Tetap Buat Laporan Baru (Bukan Duplikat)'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeSubmitReport() async {
    final reportsProvider = context.read<ReportsProvider>();
    final success = await reportsProvider.createReport(
      locationId: _selectedLocation!.id,
      categoryId: _selectedCategoryId!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      urgencyLevel: _selectedUrgency,
      pickedFiles: _pickedPhotos,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan pengaduan fasilitas berhasil dikirim!'),
          backgroundColor: AppColors.accent,
        ),
      );
      if (widget.onNavigate != null) {
        widget.onNavigate!(4); // Navigate to My Reports
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reportsProvider.errorMessage ?? 'Gagal membuat laporan.'),
          backgroundColor: AppColors.statusDitolak,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsProvider = context.watch<ReportsProvider>();
    final theme = Theme.of(context);

    // Hierarchical Location Dropdown options
    final tree = reportsProvider.locationsTree;
    final buildings = tree.keys.toList();
    final floors = _selectedBuilding != null && tree[_selectedBuilding] != null
        ? (tree[_selectedBuilding] as Map).keys.cast<String>().toList()
        : <String>[];
    final rooms = _selectedBuilding != null && _selectedFloor != null && tree[_selectedBuilding][_selectedFloor] != null
        ? (tree[_selectedBuilding][_selectedFloor] as List)
            .map((e) => LocationModel.fromJson(e))
            .toList()
        : <LocationModel>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Buat Laporan Fasilitas Baru',
            style: AppTypography.headingMedium(theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Lengkapi informasi kerusakan agar tim Sarpras Kampus Tuguran dapat menindaklanjuti dengan cepat.',
            style: AppTypography.bodySmall(theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),

          // 1. Lokasi Bertingkat (Gedung -> Lantai -> Ruang)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_city_rounded, color: Color(0xFF3B5BDB), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '1. Pilih Lokasi Kampus Tuguran',
                            style: AppTypography.headingSmall(theme.colorScheme.onSurface),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD97706),
                          side: const BorderSide(color: Color(0xFFD97706)),
                          backgroundColor: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        icon: const Icon(Icons.view_in_ar_rounded, size: 14),
                        label: const Text('Denah 3D Tuguran'),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => Dialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 680),
                                padding: const EdgeInsets.all(20),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TuguranInteractiveMap(
                                        showHeader: true,
                                        initialSelectedNumber: 6,
                                        onSpotSelected: (spot, room) {
                                          Navigator.pop(ctx);
                                          // Find matching building in list
                                          String? targetBuilding;
                                          for (final b in buildings) {
                                            if (b.toLowerCase().contains(spot.name.toLowerCase().split(' ')[0]) ||
                                                (spot.number == 6 && b.contains('Teknik 3'))) {
                                              targetBuilding = b;
                                              break;
                                            }
                                          }
                                          targetBuilding ??= buildings.isNotEmpty ? buildings.first : spot.name;

                                          setState(() {
                                            _selectedBuilding = targetBuilding;
                                            _selectedFloor = spot.number == 6 ? 'Lantai 4' : null;
                                            _selectedLocation = null;
                                          });

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Memilih ${spot.name}. Silakan tentukan ruangan.'),
                                              backgroundColor: const Color(0xFF3B5BDB),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Tutup'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Dropdown Gedung
                  DropdownButtonFormField<String>(
                    value: buildings.contains(_selectedBuilding) ? _selectedBuilding : null,
                    decoration: const InputDecoration(
                      labelText: 'Gedung / Fakultas',
                      prefixIcon: Icon(Icons.domain_rounded, size: 20),
                    ),
                    items: buildings.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedBuilding = val;
                        _selectedFloor = null;
                        _selectedLocation = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Dropdown Lantai
                  if (_selectedBuilding != null) ...[
                    DropdownButtonFormField<String>(
                      value: floors.contains(_selectedFloor) ? _selectedFloor : null,
                      decoration: const InputDecoration(
                        labelText: 'Lantai / Area',
                        prefixIcon: Icon(Icons.stairs_rounded, size: 20),
                      ),
                      items: floors.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedFloor = val;
                          _selectedLocation = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Dropdown Ruangan
                  if (_selectedFloor != null) ...[
                    DropdownButtonFormField<LocationModel>(
                      value: rooms.any((r) => r.id == _selectedLocation?.id)
                          ? rooms.firstWhere((r) => r.id == _selectedLocation?.id)
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Nama Ruangan / Titik Fasilitas',
                        prefixIcon: Icon(Icons.meeting_room_rounded, size: 20),
                      ),
                      items: rooms.map((r) => DropdownMenuItem(value: r, child: Text('${r.room} (${r.code})'))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedLocation = val;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Kategori Fasilitas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.category_rounded, color: AppColors.accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '2. Kategori Fasilitas Rusak',
                        style: AppTypography.headingSmall(theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: reportsProvider.categories.map((cat) {
                      final isSelected = _selectedCategoryId == cat.id;
                      return ChoiceChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        selectedColor: AppColors.accent.withValues(alpha: 0.2),
                        side: BorderSide(color: isSelected ? AppColors.accent : theme.dividerColor),
                        onSelected: (val) {
                          setState(() {
                            _selectedCategoryId = val ? cat.id : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Detail Pengaduan
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note_rounded, color: AppColors.accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '3. Detail Kerusakan',
                        style: AppTypography.headingSmall(theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul Singkat Kerusakan',
                      hintText: 'Contoh: AC Ruang GKB 3.02 Bocor Menetes',
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Detail Masalah',
                      hintText: 'Jelaskan kronologi, posisi spesifik kerusakan, dan dampaknya pada perkuliahan...',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Urgency Selector
                  const Text('Tingkat Urgensi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildUrgencyChip('rendah', 'Rendah (Normal)', AppColors.priorityLow),
                      const SizedBox(width: 8),
                      _buildUrgencyChip('sedang', 'Sedang', AppColors.priorityMedium),
                      const SizedBox(width: 8),
                      _buildUrgencyChip('tinggi', 'Tinggi (Darurat)', AppColors.priorityHigh),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Foto Bukti (1-3 foto)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.photo_camera_rounded, color: AppColors.accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '4. Foto Bukti Kerusakan (Maks 3 Foto)',
                        style: AppTypography.headingSmall(theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ..._pickedPhotos.map((file) {
                        return Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(file.bytes, fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: InkWell(
                                onTap: () => setState(() => _pickedPhotos.remove(file)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      if (_pickedPhotos.length < 3)
                        InkWell(
                          onTap: _pickPhotos,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.dividerColor, style: BorderStyle.solid),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 24, color: AppColors.accent),
                                SizedBox(height: 4),
                                Text('Tambah', style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Action
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_isCheckingSimilar || reportsProvider.isLoading) ? null : _checkSimilarAndSubmit,
              child: (_isCheckingSimilar || reportsProvider.isLoading)
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Kirim Pengaduan Fasilitas'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildUrgencyChip(String value, String label, Color color) {
    final isSelected = _selectedUrgency == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? color : null,
      ),
      side: BorderSide(color: isSelected ? color : Theme.of(context).dividerColor),
      onSelected: (_) => setState(() => _selectedUrgency = value),
    );
  }
}
