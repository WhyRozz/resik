import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';

class RegisterStep2 extends StatefulWidget {
  final String nama;
  final String? gender;
  final DateTime? tglLahir;
  final String alamat;
  final String? job;
  final String? dinasId;

  const RegisterStep2({
    super.key,
    required this.nama,
    required this.gender,
    required this.tglLahir,
    required this.alamat,
    required this.job,
    required this.dinasId,
  });

  @override
  State<RegisterStep2> createState() => _RegisterStep2State();
}

class _RegisterStep2State extends State<RegisterStep2> {
  final TextEditingController _teleponCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Logo & Title
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 10),
                child: Column(
                  children: [
                    Image.asset('assets/images/logo-resik.png', height: 80),
                    const SizedBox(height: 10),
                    const Text(
                      'Daftar Akun',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const Text(
                      'Lengkapi Data Diri Anda',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1B5E20),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),

              // Area Form (White Container)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. No Telepon
                        _buildLabel('No Telepon'),
                        _buildTextField(
                          controller: _teleponCtrl,
                          hint: 'Masukkan no telepon',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),

                        // 2. Email
                        _buildLabel('Email'),
                        _buildTextField(
                          controller: _emailCtrl,
                          hint: 'Masukkan email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // 3. Kata Sandi
                        _buildLabel('Kata Sandi'),
                        _buildTextField(
                          controller: _passwordCtrl,
                          hint: 'Masukkan kata sandi',
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF2E7D32),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 4. Konfirmasi Kata Sandi
                        _buildLabel('Konfirmasi Kata Sandi'),
                        _buildTextField(
                          controller: _confirmPasswordCtrl,
                          hint: 'Masukkan ulang kata sandi',
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF2E7D32),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Tombol Daftar
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              _handleRegister();
                            },
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'DAFTAR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
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

  // --- Helper Widgets ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1B5E20),
          fontFamily: 'Montserrat',
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(
          color: Color(0xFF1B5E20),
          fontFamily: 'Montserrat',
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontFamily: 'Montserrat',
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  void _handleRegister() async {
    // Validasi
    if (_teleponCtrl.text.isEmpty) {
      _showSnackBar('No telepon harus diisi');
      return;
    }
    if (_emailCtrl.text.isEmpty || !_emailCtrl.text.contains('@')) {
      _showSnackBar('Email tidak valid');
      return;
    }
    if (_passwordCtrl.text.isEmpty || _passwordCtrl.text.length < 6) {
      _showSnackBar('Password minimal 6 karakter');
      return;
    }
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      _showSnackBar('Password tidak cocok');
      return;
    }

    // Show loading
    _showLoading();

    try {
      // Prepare data
      final requestData = {
        'nama': widget.nama,
        'email': _emailCtrl.text,
        'password': _passwordCtrl.text,
        'no_telepon': _teleponCtrl.text,
        'jenis_kelamin': widget.gender,
        'tanggal_lahir': widget.tglLahir != null
            ? '${widget.tglLahir!.year}-${widget.tglLahir!.month.toString().padLeft(2, '0')}-${widget.tglLahir!.day.toString().padLeft(2, '0')}'
            : null,
        'alamat': widget.alamat,
        'pekerjaan': widget.job,
        'id_dinas': widget.dinasId != null ? int.parse(widget.dinasId!) : null,
      };

      // Hit API
      final response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      final result = jsonDecode(response.body);

      if (result['status'] == 'success') {
        // ✅ DAPAT BARCODE ID DARI RESPONSE
        final barcodeId = result['data']['barcode_id'];

        _hideLoading();
        _showSnackBar('Registrasi berhasil! Barcode: $barcodeId');

        // Navigate to login atau OTP verification
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _hideLoading();
        _showSnackBar(result['message'] ?? 'Registrasi gagal');
      }
    } catch (e) {
      _hideLoading();
      _showSnackBar('Terjadi kesalahan: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
      ),
    );
  }

  void _hideLoading() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _teleponCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }
}
