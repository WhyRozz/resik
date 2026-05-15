import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  final GlobalKey _passwordFieldKey = GlobalKey();

  bool _isLoading = false;
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
    _shakeAnimation = Tween<double>(
      begin: -10,
      end: 10,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_shakeController);

    // ✅ LISTENER untuk update real-time saat user mengetik
    _passwordCtrl.addListener(() {
      setState(() {
        // Rebuild UI setiap kali ada perubahan di password field
      });
    });

    _confirmPasswordCtrl.addListener(() {
      setState(() {
        // Rebuild UI setiap kali ada perubahan di confirm password field
      });
    });
  }

  @override
  void dispose() {
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
  void _shakeField() {
    _shakeController.forward(from: 0).then((_) {
      _showSnackBar('Password tidak memenuhi persyaratan!');
    });
  }

  Future<void> _resetPassword() async {
    final password = _passwordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();

    // Validasi password kuat
    final validation = _validatePassword(password);

    if (password.isEmpty) {
      _shakeField();
      _showSnackBar('Password baru tidak boleh kosong');
      return;
    }

    if (!validation['minLength']!) {
      _shakeField();
      _showSnackBar('Password minimal 8 karakter');
      return;
    }

    if (!validation['hasUppercase']!) {
      _shakeField();
      _showSnackBar('Password harus mengandung huruf besar');
      return;
    }

    if (!validation['hasLowercase']!) {
      _shakeField();
      _showSnackBar('Password harus mengandung huruf kecil');
      return;
    }

    if (!validation['hasNumber']!) {
      _shakeField();
      _showSnackBar('Password harus mengandung angka');
      return;
    }

    if (!validation['hasSymbol']!) {
      _shakeField();
      _showSnackBar('Password harus mengandung Simbol (!@#\$%&*)');
      return;
    }

    if (password != confirmPassword) {
      _shakeField();
      _showSnackBar('Konfirmasi password tidak cocok');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resetPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'token': widget.token,
          'password': password,
          'password_confirmation': confirmPassword,
        }),
      );

      setState(() => _isLoading = false);

      final result = jsonDecode(response.body);

      if (result['status'] == 'success') {
        _showSnackBar('Password berhasil direset');
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else {
        _showSnackBar(result['message'] ?? 'Gagal reset password');
      }
    } catch (e) {
      setState(() => _isLoading = false);
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
              // Back Button
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Judul
                        const Text(
                          'Password Baru',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                            fontFamily: 'Montserrat',
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Input Password Baru
                        _buildLabel('Masukkan Kata Sandi Baru'),

                        // ✅ SHAKE ANIMATION WRAPPER
                        AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(_shakeAnimation.value, 0),
                              child: child,
                            );
                          },
                          child: _buildPasswordField(
                            key: _passwordFieldKey,
                            controller: _passwordCtrl,
                            hint: '••••••••',
                            obscureText: _obscurePassword,
                            onToggle: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                        ),

                        // ✅ PASSWORD REQUIREMENTS INDICATOR
                        _buildPasswordRequirements(
                          passwordValidation,
                          isStrongPassword,
                        ),

                        const SizedBox(height: 20),

                        // Input Konfirmasi Password
                        _buildLabel('Konfirmasi Kata Sandi'),
                        _buildPasswordField(
                          controller: _confirmPasswordCtrl,
                          hint: '••••••••',
                          obscureText: _obscureConfirmPassword,
                          onToggle: () {
                            setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            );
                          },
                        ),
                        const SizedBox(height: 30),

                        // Kembali ke Login
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: const Text(
                            'Kembali ke Login?',
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 14,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Tombol Kirim
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            color:
                                isStrongPassword &&
                                    _confirmPasswordCtrl.text.isNotEmpty
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
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap:
                                  (isStrongPassword &&
                                      _confirmPasswordCtrl.text.isNotEmpty &&
                                      !_isLoading)
                                  ? _resetPassword
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Center(
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
                                        'Kirim',
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B5E20),
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }

  // ✅ WIDGET PASSWORD REQUIREMENTS
  Widget _buildPasswordRequirements(
    Map<String, bool> validation,
    bool isStrong,
  ) {
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
          Text(
            'Persyaratan Password:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isStrong
                  ? const Color(0xFF1B5E20)
                  : const Color(0xFFE65100),
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
          _buildRequirementItem(
            'Simbol (!@#\$%&*)', // ← Escape $ dengan backslash
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

  Widget _buildPasswordField({
    Key? key,
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
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
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF2E7D32),
            ),
            onPressed: onToggle,
          ),
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
}
