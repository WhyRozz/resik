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

class _RegisterStep2State extends State<RegisterStep2> with SingleTickerProviderStateMixin {
  final TextEditingController _teleponCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  
  final GlobalKey _passwordFieldKey = GlobalKey(); // ✅ Key untuk shake animation

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // ✅ Animation controller untuk shake
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    // ✅ Setup shake animation
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: -10, end: 10).chain(
      CurveTween(curve: Curves.easeInOut),
    ).animate(_shakeController);
    
    // ✅ LISTENER untuk update real-time saat user mengetik password
    _passwordCtrl.addListener(() {
      setState(() {
        // Rebuild UI untuk update password requirements indicator
      });
    });
  }

  @override
  void dispose() {
    _teleponCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // ✅ VALIDASI PASSWORD KUAT
  Map<String, bool> _validatePassword(String password) {
    return {
      'minLength': password.length >= 8,
      'hasUppercase': password.contains(RegExp(r'[A-Z]')),
      'hasLowercase': password.contains(RegExp(r'[a-z]')),
      'hasNumber': password.contains(RegExp(r'[0-9]')),
      'hasSymbol': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };
  }

  // ✅ CEK APAKAH PASSWORD SUDAH KUAT
  bool _isPasswordStrong(String password) {
    final validation = _validatePassword(password);
    return validation['minLength']! &&
           validation['hasUppercase']! &&
           validation['hasLowercase']! &&
           validation['hasNumber']! &&
           validation['hasSymbol']!;
  }

  // ✅ SHAKE ANIMATION
  void _shakePasswordField() {
    _shakeController.forward(from: 0);
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

  void _handleRegister() async {
    final password = _passwordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();
    
    // Validasi password kuat
    final validation = _validatePassword(password);
    
    if (password.isEmpty) {
      _shakePasswordField();
      _showSnackBar('Password tidak boleh kosong');
      return;
    }

    if (!validation['minLength']!) {
      _shakePasswordField();
      _showSnackBar('Password minimal 8 karakter');
      return;
    }

    if (!validation['hasUppercase']!) {
      _shakePasswordField();
      _showSnackBar('Password harus mengandung huruf besar');
      return;
    }

    if (!validation['hasLowercase']!) {
      _shakePasswordField();
      _showSnackBar('Password harus mengandung huruf kecil');
      return;
    }

    if (!validation['hasNumber']!) {
      _shakePasswordField();
      _showSnackBar('Password harus mengandung angka');
      return;
    }

    if (!validation['hasSymbol']!) {
      _shakePasswordField();
      _showSnackBar('Password harus mengandung simbol (!@#\$%&*)');
      return;
    }

    if (password != confirmPassword) {
      _shakePasswordField();
      _showSnackBar('Konfirmasi password tidak cocok');
      return;
    }

    // Validasi lainnya
    if (_teleponCtrl.text.isEmpty) {
      _showSnackBar('No telepon harus diisi');
      return;
    }
    if (_emailCtrl.text.isEmpty || !_emailCtrl.text.contains('@')) {
      _showSnackBar('Email tidak valid');
      return;
    }

    // Show loading
    _showLoading();

    try {
      // Prepare data
      final requestData = {
        'nama': widget.nama,
        'email': _emailCtrl.text,
        'password': password,
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
        final barcodeId = result['data']['barcode_id'];

        _hideLoading();
        _showSnackBar('Registrasi berhasil! Barcode: $barcodeId');

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

  @override
  Widget build(BuildContext context) {
    final passwordValidation = _validatePassword(_passwordCtrl.text);
    final isStrongPassword = _isPasswordStrong(_passwordCtrl.text);

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
                        
                        // ✅ SHAKE ANIMATION WRAPPER
                        AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(_shakeAnimation.value, 0),
                              child: child,
                            );
                          },
                          child: _buildTextField(
                            key: _passwordFieldKey,
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
                        ),
                        
                        // ✅ PASSWORD REQUIREMENTS INDICATOR
                        _buildPasswordRequirements(passwordValidation, isStrongPassword),
                        
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
                            onTap: (isStrongPassword && _confirmPasswordCtrl.text.isNotEmpty)
                                ? _handleRegister
                                : null,
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: (isStrongPassword && _confirmPasswordCtrl.text.isNotEmpty)
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey[400],
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
    Key? key,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      key: key,
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

  // ✅ WIDGET PASSWORD REQUIREMENTS
  Widget _buildPasswordRequirements(Map<String, bool> validation, bool isStrong) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
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
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirementItem(
            'Minimal 8 karakter',
            validation['minLength']!,
          ),
          _buildRequirementItem(
            'Huruf besar (A-Z)',
            validation['hasUppercase']!,
          ),
          _buildRequirementItem(
            'Huruf kecil (a-z)',
            validation['hasLowercase']!,
          ),
          _buildRequirementItem(
            'Angka (0-9)',
            validation['hasNumber']!,
          ),
          _buildRequirementItem(
            'Simbol (!@#\$%&*)',
            validation['hasSymbol']!,
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
            ),
          ),
        ],
      ),
    );
  }
}