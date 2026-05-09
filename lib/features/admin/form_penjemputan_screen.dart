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
import 'home_admin_screen.dart';

class FormPenjemputanScreen extends StatefulWidget {
  const FormPenjemputanScreen({super.key});

  @override
  State<FormPenjemputanScreen> createState() => _FormPenjemputanScreenState();
}

class _FormPenjemputanScreenState extends State<FormPenjemputanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaAdminCtrl = TextEditingController();
  final _waktuCtrl = TextEditingController();
  final _lokasiCtrl = TextEditingController();
  final _beratCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();

  File? _imageFile;
  final _picker = ImagePicker();
  bool _isLoading = false;
  Map<String, dynamic>? _adminData;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString('user_data');
    if (userDataStr != null && mounted) {
      final userData = jsonDecode(userDataStr);
      setState(() {
        _adminData = userData;
        _namaAdminCtrl.text = userData['nama_lengkap'] ?? 'Admin';
        _waktuCtrl.text = DateFormat(
          'yyyy-MM-dd HH:mm:ss',
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
                      subtitle: const Text('Gunakan kamera'),
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
                      subtitle: const Text('Pilih foto dari galeri'),
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
          String alamat = [
            place.street,
            place.locality,
            place.administrativeArea,
            place.postalCode,
            place.country,
          ].where((e) => e != null && e.isNotEmpty).join(', ');

          setState(
            () => _lokasiCtrl.text = alamat.isEmpty
                ? '${position.latitude}, ${position.longitude}'
                : alamat,
          );
        } else {
          setState(
            () => _lokasiCtrl.text =
                '${position.latitude}, ${position.longitude}',
          );
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

  Future<void> _submitPenjemputan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final adminData = jsonDecode(prefs.getString('user_data') ?? '{}');
      final adminId = adminData['id_petugas']; // ✅ Ambil id_petugas

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/penjemputan/store'),
      );

      request.headers.addAll({'Accept': 'application/json'});
      request.fields['id_petugas'] = adminId.toString(); // ✅ Kirim id_petugas
      request.fields['nama_admin'] = _namaAdminCtrl.text;
      request.fields['waktu'] = _waktuCtrl.text;
      request.fields['lokasi'] = _lokasiCtrl.text;
      request.fields['berat'] = _beratCtrl.text;
      request.fields['keterangan'] = _keteranganCtrl.text;
      request.fields['status'] = 'diproses';

      if (_imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'foto',
            _imageFile!.path,
            filename:
                'penjemputan_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      }

      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      var response = await http.Response.fromStream(streamedResponse);
      var result = jsonDecode(response.body);

      if (mounted) {
        setState(() => _isLoading = false);

        if (response.statusCode == 200 || response.statusCode == 201) {
          _showSuccessDialog();
        } else {
          _showError(result['message'] ?? 'Gagal mengajukan penjemputan');
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
          'Penjemputan berhasil diajukan. Menunggu konfirmasi.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeAdminScreen()),
                (route) => false,
              );
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
    _namaAdminCtrl.dispose();
    _waktuCtrl.dispose();
    _lokasiCtrl.dispose();
    _beratCtrl.dispose();
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

  InputDecoration _inputDecoration(
    String hint, {
    Widget? suffix,
    String? helperText,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.grey),
    helperText: helperText,
    helperStyle: const TextStyle(fontSize: 11, color: Colors.grey),
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

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
          'Ajukan Penjemputan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📸 UPLOAD FOTO (Optional)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Foto Lokasi (Opsional)'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: _imageFile != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
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
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo,
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Klik untuk ganti foto',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
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
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                    color: Color(0xFF4CAF50),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Upload Foto',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Format: JPG, PNG',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 👤 NAMA ADMIN (Read-only)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Nama Petugas'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _namaAdminCtrl,
                      readOnly: true,
                      decoration: _inputDecoration('Otomatis dari login'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 📅 WAKTU (Read-only - Auto current time)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Waktu Pengajuan'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _waktuCtrl,
                      readOnly: true,
                      decoration: _inputDecoration('Otomatis'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 📍 LOKASI (Button Get Location)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Lokasi Penjemputan'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _lokasiCtrl,
                      readOnly: true,
                      decoration: _inputDecoration(
                        'Klik icon lokasi untuk mendapatkan alamat',
                        suffix: IconButton(
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location,
                                  color: Color(0xFF4CAF50),
                                ),
                          onPressed: _isLoading ? null : _getCurrentLocation,
                        ),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Lokasi wajib diisi' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ⚖️ BERAT (Input dalam kg)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Estimasi Berat Sampah'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _beratCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecoration(
                        'Masukkan berat (kg)',
                        helperText: 'Contoh: 5.5',
                      ),
                      validator: (v) {
                        if (v!.isEmpty) return 'Berat wajib diisi';
                        if (double.tryParse(v) == null)
                          return 'Masukkan angka yang valid';
                        if (double.parse(v) <= 0)
                          return 'Berat harus lebih dari 0';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 📝 KETERANGAN (Optional)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Keterangan (Opsional)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _keteranganCtrl,
                      maxLines: 3,
                      decoration: _inputDecoration(
                        'Jenis sampah, akses lokasi, dll',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 🚀 TOMBOL SUBMIT
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPenjemputan,
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
                          'AJUKAN PENJEMPUTAN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
