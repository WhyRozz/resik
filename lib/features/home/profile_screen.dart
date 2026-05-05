import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import '../auth/login/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _userData = {};

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

      setState(() => _isSaving = false);

      // ✅ Tampilkan error detail dari Laravel
      if (response.statusCode == 422) {
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
        return;
      }

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final result = jsonDecode(response.body);

      if (mounted) {
        if (result['status'] == 'success') {
          // Update local data
          final updatedData = {
            ..._userData,
            'nama': _namaCtrl.text,
            'no_telepon': _telpCtrl.text,
            'tanggal_lahir': _tglLahirCtrl.text,
            'alamat': _alamatCtrl.text,
          };

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(updatedData));

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diupdate!'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal update profil'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on SocketException {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada koneksi internet'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
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

                  // ️ Foto Profil
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        backgroundImage: _userData['foto'] != null
                            ? NetworkImage(_userData['foto'])
                            : null,
                        child: _userData['foto'] == null
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Color(0xFF1B5E20),
                              )
                            : null,
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
