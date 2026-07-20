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
        _waktuCtrl.text = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Sumber Foto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildImageSourceButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Kamera',
                        color: const Color(0xFF2E7D32),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildImageSourceButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Galeri',
                        color: const Color(0xFF1976D2),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _submitPenjemputan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final adminData = jsonDecode(prefs.getString('user_data') ?? '{}');
      final adminId = adminData['id_petugas'];

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/penjemputan/store'),
      );

      request.headers.addAll({'Accept': 'application/json'});
      request.fields['id_petugas'] = adminId.toString();
      request.fields['nama_admin'] =
          _adminData?['nama'] ?? _adminData?['nama_lengkap'] ?? 'Admin';
      request.fields['waktu'] = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(DateTime.now());
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2E7D32),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Berhasil!',
              style: TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Penjemputan berhasil diajukan. Menunggu konfirmasi dari admin.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeAdminScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _waktuCtrl.dispose();
    _lokasiCtrl.dispose();
    _beratCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF2E7D32),
              size: 16,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Ajukan Penjemputan',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: WillPopScope(
        onWillPop: () async {
          if (_isLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sedang memproses, mohon tunggu...'),
                backgroundColor: Colors.orange,
              ),
            );
            return false;
          }
          return true;
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Title
                _buildSectionTitle(
                  'Detail Penjemputan',
                  'Lengkapi data penjemputan',
                ),
                const SizedBox(height: 16),

                // Upload Foto
                _buildFotoUpload(),
                const SizedBox(height: 16),

                // Waktu Pengajuan
                _buildWaktuField(),
                const SizedBox(height: 16),

                // Lokasi
                _buildLokasiField(),
                const SizedBox(height: 16),

                // Berat
                _buildBeratField(),
                const SizedBox(height: 16),

                // Keterangan
                _buildKeteranganField(),
                const SizedBox(height: 24),

                // Submit Button
                _buildSubmitButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFotoUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Lokasi (Opsional)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B5E20),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _imageFile != null
                    ? const Color(0xFF4CAF50)
                    : Colors.grey.shade200,
                width: _imageFile != null ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _imageFile != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(
                          _imageFile!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Foto berhasil dipilih',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                                size: 16,
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_a_photo_rounded,
                          size: 32,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Upload Foto Lokasi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Format: JPG, PNG (Maks 10MB)',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaktuField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Waktu Pengajuan',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B5E20),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFF2E7D32),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _waktuCtrl.text.isEmpty ? 'Otomatis' : _waktuCtrl.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'AUTO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLokasiField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lokasi Penjemputan',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B5E20),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isLoading ? null : _getCurrentLocation,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _lokasiCtrl.text.isNotEmpty
                    ? const Color(0xFF4CAF50)
                    : Colors.grey.shade200,
                width: _lokasiCtrl.text.isNotEmpty ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _lokasiCtrl.text.isEmpty
                      ? const Text(
                          'Klik untuk mendapatkan lokasi',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        )
                      : Text(
                          _lokasiCtrl.text,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                const SizedBox(width: 8),
                _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF2E7D32),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: Color(0xFF2E7D32),
                          size: 16,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBeratField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estimasi Berat Sampah',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B5E20),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _beratCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.scale_rounded, color: Color(0xFF2E7D32)),
              suffixText: 'kg',
              suffixStyle: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            validator: (v) {
              if (v!.isEmpty) return 'Berat wajib diisi';
              if (double.tryParse(v) == null)
                return 'Masukkan angka yang valid';
              if (double.parse(v) <= 0) return 'Berat harus lebih dari 0';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKeteranganField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Keterangan (Opsional)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B5E20),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _keteranganCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Jenis sampah, akses lokasi, dll',
              hintStyle: TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.notes_rounded, color: Color(0xFF2E7D32)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitPenjemputan,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isLoading
                  ? Colors.grey[400]
                  : const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[400],
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: _isLoading ? 0 : 4,
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
                        'Memproses...',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Kirim Pengajuan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
        if (_isLoading)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.orange[700],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sedang memproses... Mohon jangan tap tombol lagi!',
                    style: TextStyle(
                      color: Colors.orange[900],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
