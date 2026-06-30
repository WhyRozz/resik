import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
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
  File? _profileImageFile;

  // Controllers untuk Data Pribadi
  final _namaCtrl = TextEditingController();
  final _tglLahirCtrl = TextEditingController();
  final _jenisKelaminCtrl = TextEditingController();
  final _pekerjaanCtrl = TextEditingController();

  // Controllers untuk Informasi Kontak
  final _emailCtrl = TextEditingController();
  final _telpCtrl = TextEditingController();

  // Controllers untuk Alamat
  final _alamatCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  // Mode edit per section
  bool _isEditingDataPribadi = false;
  bool _isEditingKontak = false;
  bool _isEditingPassword = false;

  // Untuk verifikasi email
  final _otpEmailCtrl = TextEditingController();
  final _newEmailCtrl = TextEditingController();
  final _newPasswordForEmailCtrl = TextEditingController();
  String? _emailVerificationCode;

  // Untuk verifikasi password
  final _otpPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmNewPasswordCtrl = TextEditingController();
  String? _passwordVerificationCode;

  String _getFotoUrl(String? path) {
    return ApiConfig.imageUrl(path);
  }

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
      });
      // Jangan auto save, tunggu user klik simpan di section Data Pribadi
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString('user_data');
    if (userDataStr != null) {
      setState(() {
        _userData = jsonDecode(userDataStr);

        // Data Pribadi
        _namaCtrl.text = _userData['nama'] ?? '';
        _tglLahirCtrl.text = _userData['tanggal_lahir'] ?? '';
        _jenisKelaminCtrl.text = _userData['jenis_kelamin'] ?? '';

        final tipe = _userData['tipe'] ?? 'masyarakat';

        if (tipe == 'pns') {
          _pekerjaanCtrl.text = 'ASN/PNS - ${_userData['nama_dinas'] ?? '-'}';
        } else {
          _pekerjaanCtrl.text =
              'Masyarakat - ${_userData['nama_kecamatan'] ?? '-'}, ${_userData['nama_desa'] ?? '-'}';
        }

        // Informasi Kontak
        _emailCtrl.text = _userData['email'] ?? '';
        _telpCtrl.text = _userData['no_telepon'] ?? '';

        // Alamat
        _alamatCtrl.text = _userData['alamat'] ?? '';

        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfileImage() async {
    if (_profileImageFile == null) return;

    // ✅ FIX AMAN: Ambil ID berdasarkan tipe user
    final String tipe = _userData['tipe'] ?? '';
    final dynamic userId = tipe == 'pns'
        ? _userData['id_pns']
        : _userData['id_masyarakat'];

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID tidak valid, silakan login ulang'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.profileUpdate),
      );

      request.headers['Accept'] = 'application/json';
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['user_id'] = userId.toString();
      request.fields['tipe'] = tipe;

      request.files.add(
        await http.MultipartFile.fromPath(
          'foto',
          _profileImageFile!.path,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          final updatedData = {
            ..._userData,
            'foto': result['data']?['foto'] ?? _userData['foto'],
          };
          await prefs.setString('user_data', jsonEncode(updatedData));
          setState(() {
            _userData = updatedData;
            _profileImageFile = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto profil berhasil diupdate!'),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error save profile image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveDataPribadi() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ FIX AMAN: Ambil ID berdasarkan tipe user
    final String tipe = _userData['tipe'] ?? '';
    final dynamic userId = tipe == 'pns'
        ? _userData['id_pns']
        : _userData['id_masyarakat'];

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID tidak valid, silakan login ulang'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.put(
        Uri.parse(ApiConfig.profileUpdate),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'tipe': tipe,
          'nama': _namaCtrl.text,
          'tanggal_lahir': _tglLahirCtrl.text.isEmpty
              ? null
              : _tglLahirCtrl.text,
          'jenis_kelamin': _jenisKelaminCtrl.text.isEmpty
              ? null
              : _jenisKelaminCtrl.text,
          'alamat': _alamatCtrl.text,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          final updatedData = {
            ..._userData,
            'nama': _namaCtrl.text,
            'tanggal_lahir': _tglLahirCtrl.text,
            'jenis_kelamin': _jenisKelaminCtrl.text,
            'alamat': _alamatCtrl.text,
          };
          await prefs.setString('user_data', jsonEncode(updatedData));
          setState(() {
            _userData = updatedData;
            _isEditingDataPribadi = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data pribadi berhasil diupdate!'),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal update'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server Error: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveKontak() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ FIX AMAN: Ambil ID berdasarkan tipe user
    final String tipe = _userData['tipe'] ?? '';
    final dynamic userId = tipe == 'pns'
        ? _userData['id_pns']
        : _userData['id_masyarakat'];

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID tidak valid, silakan login ulang'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.put(
        Uri.parse(ApiConfig.profileUpdate),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'tipe': tipe,
          'no_telepon': _telpCtrl.text,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          final updatedData = {..._userData, 'no_telepon': _telpCtrl.text};
          await prefs.setString('user_data', jsonEncode(updatedData));
          setState(() {
            _userData = updatedData;
            _isEditingKontak = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Informasi kontak berhasil diupdate!'),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal update'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server Error: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditingDataPribadi = false;
      _isEditingKontak = false;
      _profileImageFile = null;
    });
    _loadUserData(); // Reload data dari storage
  }

  void _showEmailChangeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Ubah Email',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_emailVerificationCode == null) ...[
                  const Text(
                    'Kode verifikasi akan dikirim ke email Anda saat ini.',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // TODO: Call API to send verification code to current email
                      setDialogState(() {
                        _emailVerificationCode = '123456'; // Simulated code
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Kode verifikasi dikirim ke email Anda',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Kirim Kode'),
                  ),
                ] else if (_newEmailCtrl.text.isEmpty) ...[
                  const Text(
                    'Masukkan kode verifikasi yang dikirim ke email Anda:',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _otpEmailCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan kode verifikasi',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setDialogState(() {
                              _emailVerificationCode = null;
                              _otpEmailCtrl.clear();
                            });
                          },
                          child: const Text('Kembali'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_otpEmailCtrl.text == _emailVerificationCode) {
                              setDialogState(() {
                                _newEmailCtrl.text = ''; // Show email input
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Kode verifikasi salah'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Verifikasi'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const Text(
                    'Masukkan email baru dan password untuk konfirmasi:',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _newEmailCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Email baru',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPasswordForEmailCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setDialogState(() {
                              _newEmailCtrl.text = '';
                              _newPasswordForEmailCtrl.text = '';
                            });
                          },
                          child: const Text('Kembali'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // TODO: Call API to update email
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Email berhasil diubah!'),
                              ),
                            );
                            if (mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPasswordChangeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final validation = _validatePassword(_newPasswordCtrl.text);
          final isStrong = _isPasswordStrong(_newPasswordCtrl.text);

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Ubah Password',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_passwordVerificationCode == null) ...[
                  const Text(
                    'Kode verifikasi akan dikirim ke email Anda.',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // TODO: Call API to send verification code
                      setDialogState(() {
                        _passwordVerificationCode = '123456'; // Simulated
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Kode verifikasi dikirim ke email Anda',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Kirim Kode'),
                  ),
                ] else if (_newPasswordCtrl.text.isEmpty) ...[
                  const Text(
                    'Masukkan password baru Anda:',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _newPasswordCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Password baru',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    onChanged: (val) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmNewPasswordCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Konfirmasi password baru',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordRequirements(validation, isStrong),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setDialogState(() {
                              _passwordVerificationCode = null;
                              _newPasswordCtrl.clear();
                              _confirmNewPasswordCtrl.clear();
                            });
                          },
                          child: const Text('Kembali'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!isStrong) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Password tidak memenuhi persyaratan',
                                  ),
                                ),
                              );
                              return;
                            }
                            if (_newPasswordCtrl.text !=
                                _confirmNewPasswordCtrl.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Konfirmasi password tidak cocok',
                                  ),
                                ),
                              );
                              return;
                            }
                            // TODO: Call API to update password
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password berhasil diubah!'),
                              ),
                            );
                            if (mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isStrong
                                ? const Color(0xFF22C55E)
                                : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Map<String, bool> _validatePassword(String password) {
    return {
      'minLength': password.length >= 8,
      'hasUppercase': password.contains(RegExp(r'[A-Z]')),
      'hasLowercase': password.contains(RegExp(r'[a-z]')),
      'hasNumber': password.contains(RegExp(r'[0-9]')),
      'hasSymbol': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };
  }

  bool _isPasswordStrong(String password) {
    final validation = _validatePassword(password);
    return validation['minLength']! &&
        validation['hasUppercase']! &&
        validation['hasLowercase']! &&
        validation['hasNumber']! &&
        validation['hasSymbol']!;
  }

  Widget _buildPasswordRequirements(
    Map<String, bool> validation,
    bool isStrong,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isStrong ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isStrong ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Persyaratan Password:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirementItem('Minimal 8 karakter', validation['minLength']!),
          _buildRequirementItem(
            'Huruf besar (A-Z)',
            validation['hasUppercase']!,
          ),
          _buildRequirementItem(
            'Huruf kecil (a-z)',
            validation['hasLowercase']!,
          ),
          _buildRequirementItem('Angka (0-9)', validation['hasNumber']!),
          _buildRequirementItem('Simbol (!@#\$%&*)', validation['hasSymbol']!),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? const Color(0xFF4CAF50) : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isMet ? const Color(0xFF1B5E20) : Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

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
      } catch (e) {
        debugPrint('⚠️ Gagal logout di server: $e');
      }
    }

    await prefs.clear();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur pesan masuk segera hadir'),
        backgroundColor: Color(0xFF22C55E),
      ),
    );
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _telpCtrl.dispose();
    _tglLahirCtrl.dispose();
    _alamatCtrl.dispose();
    _pekerjaanCtrl.dispose();
    _otpEmailCtrl.dispose();
    _newEmailCtrl.dispose();
    _newPasswordForEmailCtrl.dispose();
    _otpPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmNewPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userType = _userData['tipe'] ?? 'masyarakat';
    final userRole = userType == 'pns' ? 'ASN/PNS' : 'Masyarakat';
    final barcodeId = _userData['barcode_id'] ?? '-';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4CAF50),
              Color(0xFF81C784),
              Color(0xFFC8E6C9),
              Color(0xFFF1F8E9),
            ],
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header dengan Wave
              Stack(
                children: [
                  ClipPath(
                    clipper: WaveClipper(),
                    child: Container(
                      height: 280,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF22C55E),
                            Color(0xFF4CAF50),
                            Color(0xFF81C784),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Text(
                                'Profil',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.notifications_none,
                                  color: Colors.white,
                                ),
                                onPressed: _showNotifications,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Profile Image dengan Preview
                        Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: _profileImageFile != null
                                    ? Image.file(
                                        _profileImageFile!,
                                        fit: BoxFit.cover,
                                      )
                                    : (_userData['foto'] != null &&
                                              _userData['foto']
                                                  .toString()
                                                  .isNotEmpty
                                          ? Image.network(
                                              _getFotoUrl(_userData['foto']),
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.person,
                                                    size: 50,
                                                    color: Color(0xFF22C55E),
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.person,
                                              size: 50,
                                              color: Color(0xFF22C55E),
                                            )),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickProfileImage,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF16A34A),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _namaCtrl.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userRole,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.qr_code,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                barcodeId,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Content Scrollable
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // DATA PRIBADI SECTION
                        _buildSectionHeader(
                          'Data Pribadi',
                          Icons.person_outline,
                          _isEditingDataPribadi,
                          () {
                            setState(() {
                              if (_isEditingDataPribadi) {
                                _saveDataPribadi();
                              } else {
                                _isEditingDataPribadi = true;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildEditableField(
                          label: 'Nama Lengkap',
                          value: _namaCtrl.text,
                          controller: _namaCtrl,
                          isEditing: _isEditingDataPribadi,
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 8),
                        _buildEditableField(
                          label: 'Tanggal Lahir',
                          value: _tglLahirCtrl.text.isNotEmpty
                              ? _tglLahirCtrl.text
                              : '-',
                          controller: _tglLahirCtrl,
                          isEditing: _isEditingDataPribadi,
                          icon: Icons.calendar_today,
                          isDate: true,
                        ),
                        const SizedBox(height: 8),
                        _buildEditableField(
                          label: 'Jenis Kelamin',
                          value: _jenisKelaminCtrl.text.isNotEmpty
                              ? _jenisKelaminCtrl.text
                              : '-',
                          controller: _jenisKelaminCtrl,
                          isEditing: _isEditingDataPribadi,
                          icon: Icons.male,
                          isDropdown: true,
                          dropdownItems: ['Laki-laki', 'Perempuan'],
                        ),
                        const SizedBox(height: 8),
                        _buildInfoField(
                          label: 'Pekerjaan',
                          value: _pekerjaanCtrl.text,
                          icon: Icons.work_outline,
                        ),
                        const SizedBox(height: 8),
                        _buildEditableField(
                          label: 'Alamat',
                          value: _alamatCtrl.text.isNotEmpty
                              ? _alamatCtrl.text
                              : '-',
                          controller: _alamatCtrl,
                          isEditing: _isEditingDataPribadi,
                          icon: Icons.location_on,
                          maxLines: 2,
                        ),

                        // Tombol Simpan/Batal untuk Data Pribadi
                        if (_isEditingDataPribadi) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _cancelEdit,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey,
                                    side: const BorderSide(color: Colors.grey),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Batal'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () {
                                          _saveDataPribadi();
                                          if (_profileImageFile != null)
                                            _saveProfileImage();
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF22C55E),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
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
                                      : const Text('Simpan'),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 20),

                        // INFORMASI KONTAK SECTION
                        _buildSectionHeader(
                          'Informasi Kontak',
                          Icons.contact_mail,
                          _isEditingKontak,
                          () {
                            setState(() {
                              if (_isEditingKontak) {
                                _saveKontak();
                              } else {
                                _isEditingKontak = true;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildInfoFieldWithAction(
                          label: 'Email',
                          value: _emailCtrl.text,
                          icon: Icons.email_outlined,
                          onTap: _isEditingKontak
                              ? _showEmailChangeDialog
                              : null,
                          showAction: _isEditingKontak,
                        ),
                        const SizedBox(height: 8),
                        _buildEditableField(
                          label: 'No. Telepon',
                          value: _telpCtrl.text,
                          controller: _telpCtrl,
                          isEditing: _isEditingKontak,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),

                        // Tombol Simpan/Batal untuk Kontak
                        if (_isEditingKontak) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _cancelEdit,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey,
                                    side: const BorderSide(color: Colors.grey),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Batal'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveKontak,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF22C55E),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
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
                                      : const Text('Simpan'),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 20),

                        // KEAMANAN AKUN SECTION
                        _buildSectionHeader(
                          'Keamanan Akun',
                          Icons.lock_outline,
                          _isEditingPassword,
                          () {
                            setState(() {
                              if (_isEditingPassword) {
                                _isEditingPassword = false;
                              } else {
                                _showPasswordChangeDialog();
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildInfoFieldWithAction(
                          label: 'Ubah Password',
                          value: '(Klik untuk mengubah)',
                          icon: Icons.vpn_key,
                          onTap: _isEditingPassword
                              ? _showPasswordChangeDialog
                              : null,
                          showAction: true,
                        ),

                        const SizedBox(height: 32),

                        // Tombol Logout
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: const Text(
                              'Keluar',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    bool isEditing,
    VoidCallback onTap,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF22C55E)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF166534),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            isEditing ? Icons.check : Icons.edit,
            size: 20,
            color: isEditing ? const Color(0xFF22C55E) : Colors.grey,
          ),
          onPressed: onTap,
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
    required IconData icon,
    bool isDate = false,
    bool isDropdown = false,
    List<String>? dropdownItems,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF22C55E)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                isEditing
                    ? isDropdown
                          ? DropdownButtonFormField<String>(
                              value: dropdownItems!.contains(value)
                                  ? value
                                  : null,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                              ),
                              items: dropdownItems
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) => controller.text = val ?? '',
                            )
                          : isDate
                          ? GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1950),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  controller.text =
                                      '${picked.day}/${picked.month}/${picked.year}';
                                }
                              },
                              child: AbsorbPointer(
                                child: TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : TextField(
                              controller: controller,
                              keyboardType: keyboardType,
                              maxLines: maxLines,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                              ),
                            )
                    : Text(
                        value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                          fontFamily: 'Poppins',
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF22C55E)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoFieldWithAction({
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
    bool showAction = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF22C55E)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: onTap != null
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF111827),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            if (showAction && onTap != null)
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

// ✅ WAVE CLIPPER UNTUK BACKGROUND
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height - 40,
      size.width * 0.5,
      size.height - 60,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 80,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
