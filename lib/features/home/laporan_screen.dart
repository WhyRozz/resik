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
        _tanggalCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Text(
                      'Pilih Sumber Foto',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      title: const Text(
                        'Ambil Foto',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Gunakan kamera untuk mengambil foto',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                      title: const Text(
                        'Pilih dari Galeri',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Pilih foto dari galeri perangkat'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Lokasi tidak aktif. Silakan aktifkan GPS.');
        setState(() => _isLoading = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Izin lokasi ditolak');
          setState(() => _isLoading = false);
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
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
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
        debugPrint('Response Status: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        if (response.statusCode == 200 && result['status'] == 'success') {
          _showSuccessDialog();
        } else {
          _showError(result['message'] ?? 'Gagal mengirim laporan');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Exception: $e');
      _showError('Koneksi error: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 32),
            SizedBox(width: 8),
            Text('Berhasil!', style: TextStyle(color: Color(0xFF1B5E20))),
          ],
        ),
        content: const Text(
          'Laporan berhasil dikirim. Menunggu verifikasi admin.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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

  // ✅ HELPER WIDGETS
  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1B5E20),
    ),
  );

  InputDecoration _inputDecoration(String hint, {Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      );

  // ✅ BUBBLE TABS (Sama seperti RiwayatLaporanScreen)
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

  // ✅ BOTTOM NAVIGATION (KONSISTEN SEMUA SCREEN)
  Widget _buildConsistentBottomNav(BuildContext context) {
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
      padding: const EdgeInsets.symmetric(vertical: 12),
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
          final isActive = index == 1; // Tab Laporan aktif di screen ini
          final item = items[index];

          return GestureDetector(
            onTap: () {
              if (index == 0)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeUserScreen()),
                );
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
              // index 1 = Laporan (screen saat ini), tidak perlu navigasi
            },
            child: Container(
              padding: isActive
                  ? const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
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
          // ✅ FORM LAPORAN (Scrollable)
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📸 UPLOAD FOTO
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: _imageFile != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(
                                      _imageFile!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo,
                                          size: 48,
                                          color: Colors.white,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Klik untuk ganti foto',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: 12),
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
                                    'Format: JPG, PNG (Max 5MB)',
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
                    // 📅 TANGGAL
                    _buildLabel('Tanggal'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _tanggalCtrl,
                      readOnly: true,
                      onTap: () => setState(
                        () => _tanggalCtrl.text = DateFormat(
                          'dd-MM-yyyy',
                        ).format(DateTime.now()),
                      ),
                      decoration: _inputDecoration('Pilih tanggal'),
                      validator: (v) =>
                          v!.isEmpty ? 'Tanggal wajib diisi' : null,
                    ),
                    const SizedBox(height: 15),
                    // 👤 NAMA LENGKAP
                    _buildLabel('Nama Lengkap'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _namaCtrl,
                      readOnly: true,
                      decoration: _inputDecoration('Otomatis dari profil'),
                    ),
                    const SizedBox(height: 15),
                    // 📍 LOKASI
                    _buildLabel('Lokasi Foto'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _lokasiCtrl,
                      readOnly: true,
                      decoration: _inputDecoration(
                        'Klik icon lokasi',
                        suffix: IconButton(
                          icon: const Icon(
                            Icons.my_location,
                            color: Color(0xFF4CAF50),
                          ),
                          onPressed: _getCurrentLocation,
                        ),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Lokasi wajib diisi' : null,
                    ),
                    const SizedBox(height: 15),
                    // 📝 KETERANGAN
                    _buildLabel('Keterangan'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _keteranganCtrl,
                      maxLines: 3,
                      decoration: _inputDecoration(
                        'Deskripsi singkat kejadian',
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Keterangan wajib diisi' : null,
                    ),
                    const SizedBox(height: 30),
                    // 🚀 TOMBOL SUBMIT
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitLaporan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'UPLOAD LAPORAN',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ), // Spacer agar form tidak mepet bubble tabs
                  ],
                ),
              ),
            ),
          ),
          // ✅ BUBBLE TABS
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _buildBubble(
                    'Sampah Ilegal',
                    Icons.warning,
                    true, // ✅ Aktif karena ini screen Laporan
                    () {}, // Sudah di screen ini, tidak perlu action
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBubble(
                    'Riwayat',
                    Icons.history,
                    false,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RiwayatLaporanScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ✅ BOTTOM NAVIGATION
          _buildConsistentBottomNav(context),
        ],
      ),
    );
  }
}
