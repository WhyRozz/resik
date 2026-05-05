import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:resik/features/home/riwayat_laporan_screnn.dart';
import 'package:resik/features/home/riwayat_setor_screen.dart';
import 'dart:io';
import 'home_user_screen.dart';

// Import file lain
import 'info_tps_screen.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  int _subIndex = 0; // 0: Sampah Ilegal, 1: Riwayat

  // Controllers
  final _namaCtrl = TextEditingController();
  final _tanggalCtrl = TextEditingController();
  final _lokasiCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();

  // Image Picker
  File? _imageFile;
  final picker = ImagePicker();

  @override
  void dispose() {
    _namaCtrl.dispose();
    _tanggalCtrl.dispose();
    _lokasiCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pengajuan Laporan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // ==================== AREA FORM (SCROLLABLE) ====================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // --- UPLOAD FOTO ---
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.camera_alt,
                                color: Color(0xFF4CAF50),
                              ),
                              title: const Text('Ambil Foto'),
                              onTap: () {
                                _pickImage(ImageSource.camera);
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.photo_library,
                                color: Color(0xFF4CAF50),
                              ),
                              title: const Text('Pilih Galeri'),
                              onTap: () {
                                _pickImage(ImageSource.gallery);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.add_a_photo,
                                size: 48,
                                color: Color(0xFF4CAF50),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Upload Foto Bukti',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Format: JPG, PNG',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- INPUT FIELDS ---
                _buildInputField(
                  'Tanggal',
                  _tanggalCtrl,
                  readOnly: true,
                  hintText: "Pilih tanggal",
                ),
                const SizedBox(height: 15),
                _buildInputField(
                  'Nama Lengkap',
                  _namaCtrl,
                  hintText: "Masukkan nama anda",
                ),
                const SizedBox(height: 15),
                _buildInputField(
                  'Lokasi Foto',
                  _lokasiCtrl,
                  hintText: "Klik tombol lokasi",
                  suffix: Icon(Icons.location_on, color: Colors.green),
                ),
                const SizedBox(height: 15),
                _buildInputField(
                  'Keterangan',
                  _keteranganCtrl,
                  maxLines: 3,
                  hintText: "Deskripsi singkat kejadian",
                ),
                const SizedBox(height: 30),

                // --- TOMBOL UPLOAD ---
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'UPLOAD LAPORAN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100), // Spacer biar ga ketutup nav
              ],
            ),
          ),

          // ==================== BUBBLE TABS (SUB MENU) ====================
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _buildBubble(
                    'Sampah Ilegal',
                    Icons.warning,
                    _subIndex == 0,
                    () => setState(() => _subIndex = 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBubble(
                    'Sampah Ilegal',
                    Icons.warning,
                    false,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RiwayatLaporanScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==================== NAVIGASI BAWAH (SAMA PERSIS BERANDA) ====================
          _buildConsistentBottomNav(),
        ],
      ),
    );
  }

  // ✅ WIDGET NAVIGASI STYLE BERANDA (Pill Hijau Active, Icon Only Inactive)
  Widget _buildConsistentBottomNav() {
    // Index 1 adalah Laporan, jadi ini yang bakal aktif (hijau)
    final List<Map<String, dynamic>> items = [
      {'icon': Icons.home_outlined, 'active': Icons.home, 'label': 'Home'},
      {
        'icon': Icons.assignment_outlined,
        'active': Icons.assignment,
        'label': 'Laporan',
      },
      {
        'icon': Icons.store_outlined,
        'active': Icons.store,
        'label': 'Bank Sampah',
      },
      {
        'icon': Icons.location_on_outlined,
        'active': Icons.location_on,
        'label': 'Info TPS',
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ), // Padding atas bawah dikit
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          // Karena ini halaman Laporan, index 1 selalu TRUE
          final isActive = index == 1;
          final item = items[index];

          return GestureDetector(
            onTap: () {
              if (index == 0)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeUserScreen()),
                ); // Home -> Back
              else if (index == 2)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RiwayatSetorScreen()),
                );
              else if (index == 3)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InfoTpsScreen()),
                );
            },
            child: Container(
              padding: isActive
                  ? const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ) // Padding lebih lebar kalau aktif
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: isActive
                  ? BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(30),
                    )
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive
                        ? item['active'] as IconData
                        : item['icon'] as IconData,
                    color: isActive ? Colors.white : Colors.grey,
                    size: 22,
                  ),
                  // Teks MUNCUL HANYA kalau aktif
                  if (isActive) const SizedBox(width: 8),
                  if (isActive)
                    Text(
                      item['label'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBubble(
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4CAF50) : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : const Color(0xFF4CAF50),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF4CAF50),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController ctrl, {
    bool readOnly = false,
    VoidCallback? onTap,
    String? hintText,
    Widget? suffix,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
