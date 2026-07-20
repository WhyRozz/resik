import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../config/api_config.dart';
import 'home_user_screen.dart';
import 'riwayat_laporan_screnn.dart';
import 'riwayat_setor_screen.dart';
import 'info_tps_screen.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});
  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _tanggalCtrl = TextEditingController();
  final _lokasiCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();

  File? _imageFile;
  final _picker = ImagePicker();
  bool _isLoading = false;
  bool _isGettingLocation = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString('user_data');
    if (userDataStr != null && mounted) {
      setState(() {
        _userData = jsonDecode(userDataStr);
        _namaCtrl.text = _userData?['nama'] ?? '';
        _tanggalCtrl.text = DateFormat(
          'dd-MM-yyyy HH:mm',
        ).format(DateTime.now());
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Pilih Sumber Foto',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ambil foto baru atau pilih dari galeri',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSourceOption(
                          icon: Icons.camera_alt_rounded,
                          label: 'Kamera',
                          color: const Color(0xFF4CAF50),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.camera);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSourceOption(
                          icon: Icons.photo_library_rounded,
                          label: 'Galeri',
                          color: const Color(0xFF2196F3),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.gallery);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Lokasi tidak aktif. Silakan aktifkan GPS.');
        setState(() => _isGettingLocation = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Izin lokasi ditolak');
          setState(() => _isGettingLocation = false);
          return;
        }
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String street = place.street ?? '';
          String locality = place.locality ?? '';
          String administrativeArea = place.administrativeArea ?? '';
          String postalCode = place.postalCode ?? '';
          String country = place.country ?? '';
          List<String> addressParts = [
            if (street.isNotEmpty) street,
            if (locality.isNotEmpty) locality,
            if (administrativeArea.isNotEmpty) administrativeArea,
            if (postalCode.isNotEmpty) postalCode,
            if (country.isNotEmpty) country,
          ];
          String alamat = addressParts.join(', ');
          if (alamat.isEmpty)
            alamat = '${position.latitude}, ${position.longitude}';
          setState(() => _lokasiCtrl.text = alamat);
        } else {
          setState(
            () => _lokasiCtrl.text =
                '${position.latitude}, ${position.longitude}',
          );
          _showError('Alamat tidak ditemukan, menggunakan koordinat');
        }
      } catch (e) {
        setState(
          () =>
              _lokasiCtrl.text = '${position.latitude}, ${position.longitude}',
        );
        _showError('Gagal mendapatkan alamat: $e');
      }
    } catch (e) {
      _showError('Gagal mendapatkan lokasi: $e');
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(msg)),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _submitLaporan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      _showError('Foto bukti wajib diupload');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      final userType = prefs.getString('user_type');
      if (userDataStr == null || userType == null) {
        setState(() => _isLoading = false);
        _showError('Silakan login ulang');
        return;
      }
      final userData = jsonDecode(userDataStr);
      final userId = userData['id_masyarakat'] ?? userData['id_pns'];
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.laporanStore),
      );
      request.headers.addAll({'Accept': 'application/json'});
      request.fields['user_id'] = userId.toString();
      request.fields['tipe'] = userType;
      request.fields['nama'] = _namaCtrl.text;
      request.fields['tanggal'] = _tanggalCtrl.text;
      request.fields['lokasi'] = _lokasiCtrl.text;
      request.fields['keterangan'] = _keteranganCtrl.text;
      request.files.add(
        await http.MultipartFile.fromPath(
          'foto',
          _imageFile!.path,
          filename: 'laporan_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      var response = await http.Response.fromStream(streamedResponse);
      var result = jsonDecode(response.body);
      if (mounted) {
        setState(() => _isLoading = false);
        if (response.statusCode == 200 && result['status'] == 'success') {
          _showSuccessDialog();
        } else {
          _showError(result['message'] ?? 'Gagal mengirim laporan');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Koneksi error: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Laporan Terkirim!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Laporan Anda berhasil dikirim dan sedang menunggu verifikasi dari admin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeUserScreen(), // ← KE BERANDA
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Kembali ke Beranda', // ← TEKS BARU
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _tanggalCtrl.dispose();
    _lokasiCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  // ============ HELPER WIDGETS ============

  Widget _buildSectionHeader({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
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
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefix,
    Widget? suffix,
    bool filled = true,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      filled: filled,
      fillColor: Colors.white,
      prefixIcon: prefix,
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final items = [
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
      height: 65,
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
          final isActive = index == 1;
          final item = items[index];
          return GestureDetector(
            onTap: () {
              if (index == 0) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeUserScreen()),
                  (route) => false,
                );
              } else if (index == 2) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const RiwayatSetorScreen()),
                  (route) => false,
                );
              } else if (index == 3) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const InfoTpsScreen()),
                  (route) => false,
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: isActive
                  ? const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
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
                  if (isActive) const SizedBox(width: 6),
                  if (isActive)
                    Text(
                      item['label'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // ============ CUSTOM APPBAR ============
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
                child: Row(
                  children: [
                    // Icon kembali
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ✅ ICON WARNING DIPINDAH KE KIRI (SETELAH ICON KEMBALI)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Text di tengah
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Laporan Baru',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Laporkan sampah ilegal di sekitarmu',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ============ FORM CONTENT ============
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== SECTION 1: UPLOAD FOTO =====
                    _buildSectionHeader(
                      number: '1',
                      title: 'Foto Bukti',
                      subtitle: 'Upload foto lokasi sampah ilegal',
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: _imageFile != null
                              ? null
                              : Border.all(
                                  color: const Color(
                                    0xFF4CAF50,
                                  ).withOpacity(0.3),
                                  width: 1.5,
                                  strokeAlign: BorderSide.strokeAlignInside,
                                ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _imageFile != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(_imageFile!, fit: BoxFit.cover),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.7),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 12,
                                      left: 12,
                                      right: 12,
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check_circle,
                                              color: Color(0xFF4CAF50),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Foto berhasil diupload',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  'Tap untuk ganti foto',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.edit,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF4CAF50,
                                        ).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add_a_photo_rounded,
                                        size: 40,
                                        color: Color(0xFF4CAF50),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Tap untuk upload foto',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Format: JPG, PNG (Max 5MB)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ===== SECTION 2: DETAIL LAPORAN =====
                    _buildSectionHeader(
                      number: '2',
                      title: 'Detail Laporan',
                      subtitle: 'Lengkapi informasi laporan',
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Tanggal
                          _buildFieldLabel(
                            'Tanggal Pelaporan',
                            Icons.calendar_today_rounded,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _tanggalCtrl,
                            readOnly: true,
                            decoration: _inputDecoration(
                              hint: 'Pilih tanggal',
                              prefix: const Icon(
                                Icons.event,
                                color: Color(0xFF4CAF50),
                                size: 20,
                              ),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? 'Tanggal wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),

                          // Nama
                          _buildFieldLabel(
                            'Nama Pelapor',
                            Icons.person_rounded,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _namaCtrl,
                            readOnly: true,
                            decoration: _inputDecoration(
                              hint: 'Otomatis dari profil',
                              prefix: const Icon(
                                Icons.badge_rounded,
                                color: Color(0xFF4CAF50),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Lokasi
                          _buildFieldLabel(
                            'Lokasi Sampah',
                            Icons.location_on_rounded,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _lokasiCtrl,
                            readOnly: true,
                            maxLines: 2,
                            minLines: 1,
                            decoration: _inputDecoration(
                              hint: 'Tap tombol lokasi untuk deteksi otomatis',
                              prefix: const Icon(
                                Icons.place_rounded,
                                color: Color(0xFF4CAF50),
                                size: 20,
                              ),
                              suffix: _isGettingLocation
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF4CAF50),
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      onPressed: _getCurrentLocation,
                                      icon: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF2E7D32),
                                              Color(0xFF4CAF50),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.my_location,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? 'Lokasi wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),

                          // Keterangan
                          _buildFieldLabel('Keterangan', Icons.notes_rounded),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _keteranganCtrl,
                            maxLines: 4,
                            minLines: 3,
                            decoration: _inputDecoration(
                              hint: 'Deskripsikan kondisi sampah ilegal...',
                              prefix: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Icon(
                                  Icons.edit_note_rounded,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                              ),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? 'Keterangan wajib diisi' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ===== TOMBOL SUBMIT =====
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitLaporan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          disabledBackgroundColor: Colors.grey[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                          shadowColor: const Color(0xFF2E7D32).withOpacity(0.4),
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Mengirim Laporan...',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Kirim Laporan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // ============ BOTTOM NAV ============
          _buildBottomNav(context),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF4CAF50)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B5E20),
          ),
        ),
      ],
    );
  }
}
