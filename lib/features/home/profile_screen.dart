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
  final _wilayahKerjaCtrl = TextEditingController();

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
  bool _otpVerified = false;

  // Untuk verifikasi password
  final _otpPasswordCtrl = TextEditingController();
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmNewPasswordCtrl = TextEditingController();
  String? _passwordVerificationCode;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  String _getFotoUrl(String? path) {
    return ApiConfig.imageUrl(path);
  }

  int get userId {
    return _userData['tipe'] == 'pns'
        ? _userData['id_pns']
        : _userData['id_masyarakat'];
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

      // ✅ AUTO-SAVE SETELAH PILIH FOTO
      await _saveProfileImage();
    }
  }

  // ✅ FUNGSI ZOOM FOTO PROFIL
  void _showProfileImagePopup(String imageUrl) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // ✅ FOTO DENGAN ZOOM
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                boundaryMargin: const EdgeInsets.all(20),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 80,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
            // ✅ ICON SILANG DI POJOK KANAN ATAS
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(dialogContext),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

          // ✅ GABUNGKAN KECAMATAN DAN DESA UNTUK PNS
          final kec = _userData['nama_kecamatan'] ?? '-';
          final desa = _userData['nama_desa'] ?? '-';
          _wilayahKerjaCtrl.text = '$kec, $desa';
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
        Uri.parse(ApiConfig.updateFoto),
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
          await _loadUserData();
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

      final response = await http.post(
        Uri.parse(ApiConfig.profileUpdate),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
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

      print('🔵 Response Status: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('🔵 Result Status: ${result['status']}');

        if (result['status'] == 'success') {
          final updatedData = {
            ..._userData,
            'nama': _namaCtrl.text,
            'tanggal_lahir': _tglLahirCtrl.text,
            'jenis_kelamin': _jenisKelaminCtrl.text,
            'alamat': _alamatCtrl.text,
          };
          await prefs.setString('user_data', jsonEncode(updatedData));
          await _loadUserData();
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
          print('❌ Error: ${result['message']}');
          print('❌ Errors: ${result['errors']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal update'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
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

      final response = await http.post(
        Uri.parse(ApiConfig.profileUpdate),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
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
          await _loadUserData();
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
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.email_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Ubah Email',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Content berdasarkan step
                  if (_emailVerificationCode == null) ...[
                    // STEP 1: Input Email Baru
                    const Text(
                      'Masukkan email baru yang ingin Anda gunakan:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Input Email
                    TextField(
                      controller: _newEmailCtrl,
                      decoration: InputDecoration(
                        hintText: 'contoh@email.com',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Color(0xFF22C55E),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF22C55E),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),

                    // Tombol Kirim Kode
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_newEmailCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Email baru wajib diisi'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final response = await http.post(
                            Uri.parse(ApiConfig.sendEmailOtp),
                            headers: ApiConfig.headers,
                            body: jsonEncode({
                              "user_id": userId,
                              "tipe": _userData['tipe'],
                              "email": _newEmailCtrl.text.trim(),
                            }),
                          );

                          final result = jsonDecode(response.body);

                          if (response.statusCode == 200) {
                            _emailVerificationCode = "sent";
                            setDialogState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message']),
                                backgroundColor: const Color(0xFF22C55E),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result['message'] ?? 'Gagal mengirim kode',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF22C55E).withOpacity(0.4),
                        ),
                        child: const Text(
                          'Kirim Kode Verifikasi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ] else if (!_otpVerified) ...[
                    // STEP 2: Input OTP
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF22C55E).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF22C55E),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Kode telah dikirim ke ${_newEmailCtrl.text}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1B5E20),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Masukkan kode verifikasi 4 digit:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Input OTP
                    TextField(
                      controller: _otpEmailCtrl,
                      decoration: InputDecoration(
                        hintText: '0000',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF22C55E),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF22C55E),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tombol Verifikasi
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final response = await http.post(
                            Uri.parse(ApiConfig.verifyEmailOtp),
                            headers: ApiConfig.headers,
                            body: jsonEncode({
                              "user_id": userId,
                              "tipe": _userData['tipe'],
                              "otp": _otpEmailCtrl.text.trim(),
                            }),
                          );

                          final result = jsonDecode(response.body);

                          if (response.statusCode == 200 &&
                              result['status'] == 'success') {
                            setDialogState(() {
                              _otpVerified = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Kode verifikasi benar'),
                                backgroundColor: Color(0xFF22C55E),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result['message'] ?? 'Kode verifikasi salah',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF22C55E).withOpacity(0.4),
                        ),
                        child: const Text(
                          'Verifikasi Kode',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tombol Kembali
                    TextButton(
                      onPressed: () async {
                        setDialogState(() {
                          _emailVerificationCode = null;
                          _otpEmailCtrl.clear();
                        });
                      },
                      child: const Text(
                        '← Kirim Ulang Kode',
                        style: TextStyle(
                          color: Color(0xFF22C55E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ] else ...[
                    // STEP 3: Sukses
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF22C55E).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF22C55E),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Verifikasi Berhasil!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Email akan diubah ke ${_newEmailCtrl.text}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final response = await http.put(
                            Uri.parse(ApiConfig.updateEmail),
                            headers: ApiConfig.headers,
                            body: jsonEncode({
                              "user_id": userId,
                              "tipe": _userData['tipe'],
                              "email": _newEmailCtrl.text.trim(),
                              "otp": _otpEmailCtrl.text.trim(),
                            }),
                          );

                          final result = jsonDecode(response.body);

                          if (response.statusCode == 200 &&
                              result['status'] == 'success') {
                            _userData['email'] = _newEmailCtrl.text.trim();

                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString(
                              "user_data",
                              jsonEncode(_userData),
                            );

                            await _loadUserData();

                            if (mounted) Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result['message'] ?? 'Email berhasil diubah!',
                                ),
                                backgroundColor: const Color(0xFF22C55E),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result['message'] ?? 'Gagal mengubah email',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF22C55E).withOpacity(0.4),
                        ),
                        child: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tombol Batal
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          _emailVerificationCode = null;
                          _otpVerified = false;
                          _otpEmailCtrl.clear();
                          _newEmailCtrl.clear();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPasswordChangeDialog() {
    // Reset state dialog
    _passwordVerificationCode = null;
    _otpPasswordCtrl.clear();
    _newPasswordCtrl.clear();
    _confirmNewPasswordCtrl.clear();
    _showNewPassword = false;
    _showConfirmPassword = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final validation = _validatePassword(_newPasswordCtrl.text);
          final isStrong = _isPasswordStrong(_newPasswordCtrl.text);

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22C55E).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    const Text(
                      'Ubah Password',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // STEP 1: KIRIM OTP
                    if (_passwordVerificationCode == null) ...[
                      const Text(
                        'Kode verifikasi akan dikirim ke email Anda untuk keamanan.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Email Info Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2196F3).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 18,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Email terdaftar',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6B7280),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _userData['email'] ?? '-',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1976D2),
                                      fontFamily: 'Poppins',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tombol Kirim Kode
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            final response = await http.post(
                              Uri.parse(ApiConfig.sendEmailOtp),
                              headers: ApiConfig.headers,
                              body: jsonEncode({
                                "user_id": userId,
                                "tipe": _userData['tipe'],
                              }),
                            );

                            final result = jsonDecode(response.body);

                            if (response.statusCode == 200 &&
                                result['status'] == 'success') {
                              setDialogState(() {
                                _passwordVerificationCode = "sent";
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result['message'] ??
                                        'Kode OTP telah dikirim',
                                  ),
                                  backgroundColor: const Color(0xFF22C55E),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result['message'] ?? 'Gagal mengirim OTP',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            shadowColor: const Color(
                              0xFF22C55E,
                            ).withOpacity(0.4),
                          ),
                          child: const Text(
                            'Kirim Kode Verifikasi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tombol Batal
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),

                      // STEP 2: VERIFIKASI OTP
                    ] else if (!_otpVerified) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF22C55E).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // ← TAMBAH INI
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Color(0xFF22C55E),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                // ← GANTI Row jadi Column
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Kode verifikasi telah dikirim ke:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6B7280),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _userData['email'] ?? '-',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B5E20),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Masukkan kode verifikasi 4 digit:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Input OTP
                      TextField(
                        controller: _otpPasswordCtrl,
                        decoration: InputDecoration(
                          hintText: '0000',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF22C55E),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF22C55E),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tombol Verifikasi
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_otpPasswordCtrl.text.trim().length != 4) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('OTP harus 4 digit'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final response = await http.post(
                              Uri.parse(ApiConfig.verifyEmailOtp),
                              headers: ApiConfig.headers,
                              body: jsonEncode({
                                "user_id": userId,
                                "tipe": _userData['tipe'],
                                "otp": _otpPasswordCtrl.text.trim(),
                              }),
                            );

                            final result = jsonDecode(response.body);

                            if (response.statusCode == 200 &&
                                result['status'] == 'success') {
                              FocusScope.of(context).unfocus();

                              setDialogState(() {
                                _otpVerified = true;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Verifikasi berhasil! Silakan masukkan password baru',
                                  ),
                                  backgroundColor: Color(0xFF22C55E),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result['message'] ??
                                        'Kode verifikasi salah',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            shadowColor: const Color(
                              0xFF22C55E,
                            ).withOpacity(0.4),
                          ),
                          child: const Text(
                            'Verifikasi Kode',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tombol Kembali
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            _passwordVerificationCode = null;
                            _otpPasswordCtrl.clear();
                          });
                        },
                        child: const Text(
                          '← Kirim Ulang Kode',
                          style: TextStyle(
                            color: Color(0xFF22C55E),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),

                      // STEP 3: FORM PASSWORD BARU
                    ] else ...[
                      const Text(
                        'Masukkan kata sandi baru',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Baru
                      TextField(
                        controller: _newPasswordCtrl,
                        decoration: InputDecoration(
                          hintText: 'Password baru',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF22C55E),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showNewPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                _showNewPassword = !_showNewPassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF22C55E),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        obscureText: !_showNewPassword,
                        onChanged: (val) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 12),

                      // Konfirmasi Password
                      TextField(
                        controller: _confirmNewPasswordCtrl,
                        decoration: InputDecoration(
                          hintText: 'Konfirmasi password baru',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF22C55E),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                _showConfirmPassword = !_showConfirmPassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF22C55E),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        obscureText: !_showConfirmPassword,
                      ),
                      const SizedBox(height: 16),

                      // Password Requirements
                      _buildModernPasswordRequirements(validation, isStrong),
                      const SizedBox(height: 24),

                      // Tombol Simpan
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isStrong
                              ? () async {
                                  if (_newPasswordCtrl.text !=
                                      _confirmNewPasswordCtrl.text) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Konfirmasi password tidak cocok',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  final response = await http.put(
                                    Uri.parse(ApiConfig.updatePassword),
                                    headers: ApiConfig.headers,
                                    body: jsonEncode({
                                      "user_id": userId,
                                      "tipe": _userData['tipe'],
                                      "password_baru": _newPasswordCtrl.text,
                                      "password_baru_confirmation":
                                          _confirmNewPasswordCtrl.text,
                                      "otp": _otpPasswordCtrl.text.trim(),
                                    }),
                                  );

                                  final result = jsonDecode(response.body);

                                  if (response.statusCode == 200 &&
                                      result['status'] == 'success') {
                                    if (mounted) Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          result['message'] ??
                                              'Password berhasil diubah!',
                                        ),
                                        backgroundColor: const Color(
                                          0xFF22C55E,
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          result['message'] ??
                                              'Gagal mengubah password',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isStrong
                                ? const Color(0xFF22C55E)
                                : Colors.grey[300],
                            foregroundColor: isStrong
                                ? Colors.white
                                : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: isStrong ? 4 : 0,
                            shadowColor: isStrong
                                ? const Color(0xFF22C55E).withOpacity(0.4)
                                : Colors.transparent,
                          ),
                          child: const Text(
                            'Simpan Perubahan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tombol Batal
                      TextButton(
                        onPressed: () {
                          _newPasswordCtrl.clear();
                          _confirmNewPasswordCtrl.clear();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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

  Widget _buildModernPasswordRequirements(
    Map<String, bool> validation,
    bool isStrong,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isStrong ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isStrong ? const Color(0xFF22C55E) : const Color(0xFFFF9800),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isStrong ? Icons.check_circle : Icons.info_outline,
                size: 18,
                color: isStrong
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFFF9800),
              ),
              const SizedBox(width: 8),
              Text(
                'Persyaratan Password:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isStrong
                      ? const Color(0xFF1B5E20)
                      : const Color(0xFFF57C00),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildModernRequirementItem(
            'Minimal 8 karakter',
            validation['minLength']!,
          ),
          _buildModernRequirementItem(
            'Huruf besar (A-Z)',
            validation['hasUppercase']!,
          ),
          _buildModernRequirementItem(
            'Huruf kecil (a-z)',
            validation['hasLowercase']!,
          ),
          _buildModernRequirementItem('Angka (0-9)', validation['hasNumber']!),
          _buildModernRequirementItem(
            'Simbol (!@#\$%&*)',
            validation['hasSymbol']!,
          ),
        ],
      ),
    );
  }

  Widget _buildModernRequirementItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isMet ? const Color(0xFF22C55E) : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMet ? Icons.check : Icons.close,
              size: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isMet ? const Color(0xFF1B5E20) : Colors.grey[600],
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
              fontFamily: 'Poppins',
            ),
          ),
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

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible:
          false, // User harus memilih tombol, tidak bisa klik luar
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Icon dengan Gradien Modern
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              // ✅ Judul
              const Text(
                'Keluar dari Aplikasi?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),

              // ✅ Subtitle
              const Text(
                'Apakah Anda yakin ingin keluar? Anda harus login kembali untuk mengakses akun Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 24),

              // ✅ Tombol Aksi
              Row(
                children: [
                  // Tombol Batal
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B7280),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Tombol Ya, Keluar
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Tutup dialog dulu
                        _performLogout(); // Baru jalankan logout
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFFEF4444).withOpacity(0.4),
                      ),
                      child: const Text(
                        'Ya, Keluar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
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
    );
  }

  Future<void> _performLogout() async {
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

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _telpCtrl.dispose();
    _tglLahirCtrl.dispose();
    _alamatCtrl.dispose();
    _pekerjaanCtrl.dispose();
    _wilayahKerjaCtrl.dispose();
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
                              const SizedBox(
                                width: 48,
                              ), // Placeholder agar layout tetap rapi
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Profile Image dengan Preview
                        Stack(
                          children: [
                            // ✅ BUNGKUS DENGAN GESTURE DETECTOR UNTUK ZOOM
                            GestureDetector(
                              onTap: () {
                                // ✅ Tampilkan foto full screen jika ada
                                if (_profileImageFile != null) {
                                  // Jika ada foto baru yang belum diupload
                                  showDialog(
                                    context: context,
                                    builder: (dialogContext) => Dialog(
                                      backgroundColor: Colors.black,
                                      insetPadding: EdgeInsets.zero,
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: InteractiveViewer(
                                              minScale: 0.5,
                                              maxScale: 4.0,
                                              child: Image.file(
                                                _profileImageFile!,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top:
                                                MediaQuery.of(
                                                  context,
                                                ).padding.top +
                                                16,
                                            right: 16,
                                            child: GestureDetector(
                                              onTap: () =>
                                                  Navigator.pop(dialogContext),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.4),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.close_rounded,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else if (_userData['foto'] != null &&
                                    _userData['foto'].toString().isNotEmpty) {
                                  // ✅ Tampilkan foto dari server
                                  _showProfileImagePopup(
                                    _userData['foto'].toString(),
                                  );
                                }
                              },
                              child: Container(
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
                                                _userData['foto'].toString(),
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

                        // ✅ TAMBAHKAN INI: Tampilkan khusus jika user adalah PNS
                        if (userType == 'pns') ...[
                          _buildInfoField(
                            label: 'Kecamatan / Desa',
                            value: _wilayahKerjaCtrl.text,
                            icon: Icons.location_city,
                          ),
                          const SizedBox(height: 8),
                        ],

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
                                      : () async {
                                          await _saveDataPribadi(); // ← HANYA INI, TIDAK PERLU UPLOAD FOTO LAGI
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
                          value: '(Klik icon edit untuk mengubah)',
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
                            onPressed:
                                _showLogoutConfirmationDialog, // ✅ UBAH KE METHOD DIALOG
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFEF4444),
                            ),
                            label: const Text(
                              'Keluar dari Akun',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFEF4444),
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
        // ✅ ICON HANYA MUNCUL KETIKA TIDAK SEDANG EDIT
        if (!isEditing)
          IconButton(
            icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
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
                              value: controller.text.isNotEmpty
                                  ? controller.text
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
                              items: (dropdownItems ?? [])
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  controller.text = val ?? '';
                                });
                              },
                            )
                          : isDate
                          ? GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _tglLahirCtrl.text.isNotEmpty
                                      ? DateTime.parse(_tglLahirCtrl.text)
                                      : DateTime.now(),
                                  firstDate: DateTime(1950),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  controller.text =
                                      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
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
