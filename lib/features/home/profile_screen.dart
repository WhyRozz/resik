import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import '../auth/login/login_screen.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _userData = {};

  final _picker = ImagePicker();
  File? _profileImageFile; // ✅ Untuk simpan foto yang dipilih
  String? _selectedImagePath; // ✅ Untuk preview (network/file)

  final _namaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telpCtrl = TextEditingController();
  final _tglLahirCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _pekerjaanCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (picked != null && mounted) {
      setState(() {
        _profileImageFile = File(picked.path);
        _selectedImagePath = picked.path; // Untuk preview lokal
      });
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString('user_data');
    if (userDataStr != null) {
      setState(() {
        _userData = jsonDecode(userDataStr);
        _namaCtrl.text = _userData['nama'] ?? '';
        _emailCtrl.text = _userData['email'] ?? '';
        _telpCtrl.text = _userData['no_telepon'] ?? '';
        _tglLahirCtrl.text = _userData['tanggal_lahir'] ?? '';
        _alamatCtrl.text = _userData['alamat'] ?? '';

        // Mapping tipe ke nama pekerjaan yang readable
        final tipe = _userData['tipe'] ?? _userData['role'] ?? '';
        _pekerjaanCtrl.text = tipe == 'pns' ? 'PNS / ASN' : 'Masyarakat Umum';

        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      // ✅ DEBUG LOG
      debugPrint("📤 Request URL: ${ApiConfig.profileUpdate}");
      debugPrint(
        "📤 User ID: ${_userData['id_masyarakat'] ?? _userData['id_pns']}",
      );
      debugPrint("📤 Tipe: ${_userData['tipe']}");

      if (_profileImageFile != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(ApiConfig.profileUpdate),
        );

        // ✅ WAJIB: Tambah header ini agar Laravel return JSON, bukan HTML redirect
        request.headers['Accept'] = 'application/json';

        request.fields['user_id'] =
            (_userData['id_masyarakat'] ?? _userData['id_pns']).toString();
        request.fields['tipe'] = _userData['tipe'] ?? '';
        request.fields['nama'] = _namaCtrl.text;
        request.fields['no_telepon'] = _telpCtrl.text;

        if (_tglLahirCtrl.text.isNotEmpty) {
          request.fields['tanggal_lahir'] = _tglLahirCtrl.text;
        }

        request.fields['alamat'] = _alamatCtrl.text;

        request.files.add(
          await http.MultipartFile.fromPath(
            'foto',
            _profileImageFile!.path,
            filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );

        debugPrint("📤 Sending multipart request...");

        var streamedResponse = await request.send().timeout(
          const Duration(seconds: 30),
        );
        var response = await http.Response.fromStream(streamedResponse);

        debugPrint("📥 Status Code: ${response.statusCode}");
        debugPrint("📥 Headers: ${response.headers}");

        // ✅ FIX: Cek panjang string dulu sebelum substring
        final bodyPreview = response.body.length > 200
            ? response.body.substring(0, 200)
            : response.body;
        debugPrint("📥 Body Preview: $bodyPreview");

        if (response.statusCode == 302) {
          debugPrint("⚠️ Redirect Location: ${response.headers['location']}");
        }

        // ✅ FIX: Handle 401 Unauthorized khusus
        if (response.statusCode == 401) {
          debugPrint("❌ 401 Unauthorized - Backend minta token!");
          debugPrint(
            "💡 Solusi: Tambah header 'Authorization' atau hapus middleware auth di route",
          );
        }

        _handleSaveResponse(response);
      } else {
        // ✅ Jika tidak ada foto baru, pakai JSON biasa
        final response = await http.put(
          Uri.parse(ApiConfig.profileUpdate),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': _userData['id_masyarakat'] ?? _userData['id_pns'],
            'tipe': _userData['tipe'],
            'nama': _namaCtrl.text,
            'no_telepon': _telpCtrl.text,
            'tanggal_lahir': _tglLahirCtrl.text.isEmpty
                ? null
                : _tglLahirCtrl.text,
            'alamat': _alamatCtrl.text,
          }),
        );

        _handleSaveResponse(response);
      }
    } catch (e) {
      debugPrint("❌ Exception: $e");
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    // 1. Ambil token dulu
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // 2. Hubungi Laravel untuk invalidate token (Opsional tapi sangat disarankan)
    if (token != null && token.isNotEmpty) {
      try {
        await http
            .post(
              Uri.parse(ApiConfig.logout),
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 5));

        debugPrint('✅ Token berhasil di-revoke di server');
      } catch (e) {
        debugPrint('️ Gagal logout di server (lanjut hapus lokal): $e');
        // Lanjutkan proses logout lokal meski request ke server gagal
      }
    }

    // 3. Hapus semua data lokal
    await prefs.clear();

    // 4. Navigasi aman ke LoginScreen
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false, // Hapus semua halaman sebelumnya
      );
    }
  }

  // ✅ HELPER: Handle response dari server (untuk avoid code duplication)
  void _handleSaveResponse(http.Response response) async {
    setState(() => _isSaving = false);

    // ✅ Handle Validation Error (422)
    if (response.statusCode == 422) {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Validasi gagal';
        final errors = errorData['errors'] ?? {};

        String detailError = '';
        errors.forEach((key, value) {
          detailError += '$key: ${value.join(', ')}\n';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$errorMessage\n\n$detailError'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Validasi gagal'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    // ✅ Handle Server Error (bukan 200)
    if (response.statusCode != 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server error: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // ✅ Parse JSON Response
    try {
      final result = jsonDecode(response.body);

      if (mounted) {
        if (result['status'] == 'success') {
          // ✅ AUTO-REFRESH: Update local data
          final updatedData = {
            ..._userData,
            'nama': _namaCtrl.text,
            'no_telepon': _telpCtrl.text,
            'tanggal_lahir': _tglLahirCtrl.text,
            'alamat': _alamatCtrl.text,

            // ✅ PENTING: Ambil foto dari response, fallback ke foto lama
            'foto': result['data']?['foto'] ?? _userData['foto'],
          };

          // Debug: Cek URL foto yang diterima
          debugPrint("📸 Foto URL dari server: ${updatedData['foto']}");

          // Simpan ke SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(updatedData));

          // Update state agar UI langsung refresh
          setState(() {
            _userData = updatedData;
            _profileImageFile = null;
            _selectedImagePath = null;
          });

          // ✅ Tampilkan success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diupdate!'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );

          // ✅ Kembali ke halaman sebelumnya
          Navigator.pop(context, true);
        } else {
          // ✅ Handle error dari response JSON
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal update profil'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // ✅ Handle JSON parse error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses response: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _telpCtrl.dispose();
    _tglLahirCtrl.dispose();
    _alamatCtrl.dispose();
    _pekerjaanCtrl.dispose();
    super.dispose();
  }

  // 🎨 Widget Input Field Custom
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    TextInputType? keyboardType,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B5E20),
            fontFamily: 'Montserrat',
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          onTap: onTap,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1B5E20),
            fontFamily: 'Montserrat',
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly
                ? Colors.grey.shade200
                : Colors.white.withOpacity(0.9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: _pickProfileImage,
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          // ✅ PRIORITAS: File lokal > Network URL > Default icon
                          backgroundImage: _profileImageFile != null
                              ? FileImage(_profileImageFile!)
                              : (_userData['foto'] != null &&
                                        _userData['foto'].toString().isNotEmpty
                                    ? NetworkImage(_userData['foto'].toString())
                                    : null),
                          child:
                              (_profileImageFile == null &&
                                  (_userData['foto'] == null ||
                                      _userData['foto'].toString().isEmpty))
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Color(0xFF1B5E20),
                                )
                              : null,
                        ),
                      ),

                      // ✅ Tambah error handling dengan Image.network widget terpisah untuk debug
                      if (_userData['foto'] != null &&
                          _profileImageFile == null)
                        Positioned.fill(
                          child: Image.network(
                            _userData['foto'].toString(),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint("❌ Error load gambar profil: $error");
                              debugPrint("🔗 URL: ${_userData['foto']}");
                              return const Icon(
                                Icons.person,
                                size: 60,
                                color: Color(0xFF1B5E20),
                              );
                            },
                          ),
                        ),

                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // 📝 Form Fields
                  _buildField(label: 'Nama', controller: _namaCtrl),
                  _buildField(
                    label: 'Email',
                    controller: _emailCtrl,
                    readOnly: true,
                  ),
                  _buildField(
                    label: 'No Telp',
                    controller: _telpCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildField(
                    label: 'Tanggal Lahir',
                    controller: _tglLahirCtrl,
                    readOnly: true,
                  ),
                  _buildField(label: 'Alamat', controller: _alamatCtrl),
                  _buildField(
                    label: 'Pekerjaan',
                    controller: _pekerjaanCtrl,
                    readOnly: true,
                  ),

                  const SizedBox(height: 20),

                  // 🔘 Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _logout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Keluar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Simpan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
