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

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _shakePassword = false;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _confirmPasswordCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Map<String, bool> _validatePassword(String password) {
    return {
      'minLength': password.length >= 8,
      'hasUppercase': password.contains(RegExp(r'[A-Z]')),
      'hasLowercase': password.contains(RegExp(r'[a-z]')),
      'hasNumber': password.contains(RegExp(r'[0-9]')),
      'hasSymbol': password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]')),
    };
  }

  bool _isPasswordStrong(String password) {
    final validation = _validatePassword(password);
    return validation.values.every((v) => v);
  }

  int _getPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    final validation = _validatePassword(password);
    return validation.values.where((v) => v).length;
  }

  void _triggerShake() {
    setState(() => _shakePassword = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _shakePassword = false);
    });
  }

  Future<void> _resetPassword() async {
    final password = _passwordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();

    if (password.isEmpty) {
      _triggerShake();
      _showSnackBar('Password baru tidak boleh kosong', isError: true);
      return;
    }

    if (!_isPasswordStrong(password)) {
      _triggerShake();
      _showSnackBar('Password tidak memenuhi persyaratan!', isError: true);
      return;
    }

    if (password != confirmPassword) {
      _triggerShake();
      _showSnackBar('Konfirmasi password tidak cocok', isError: true);
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

      if (!mounted) return;
      setState(() => _isLoading = false);

      final result = jsonDecode(response.body);

      if (result['status'] == 'success') {
        _showSnackBar('Password berhasil direset!', isError: false);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      } else {
        _showSnackBar(
          result['message'] ?? 'Gagal reset password',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Terjadi kesalahan: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFE53935)
            : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passwordValidation = _validatePassword(_passwordCtrl.text);
    final isStrongPassword = _isPasswordStrong(_passwordCtrl.text);
    final strength = _getPasswordStrength(_passwordCtrl.text);
    final isConfirmMatch =
        _confirmPasswordCtrl.text.isNotEmpty &&
        _passwordCtrl.text == _confirmPasswordCtrl.text;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50), Color(0xFF66BB6A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Header Icon
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              const Text(
                'Buat Password Baru',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Password baru harus kuat dan berbeda dari sebelumnya',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                    height: 1.4,
                  ),
                ),
              ),

              // Form Card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Password Baru
                        _buildSectionLabel('Password Baru', Icons.lock_outline),
                        const SizedBox(height: 10),

                        // Password Field dengan shake effect sederhana
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          transform: _shakePassword
                              ? (Matrix4.identity()
                                  ..translate(_shakePassword ? 10.0 : 0.0, 0))
                              : Matrix4.identity(),
                          child: _buildModernPasswordField(
                            controller: _passwordCtrl,
                            hint: 'Masukkan password baru',
                            obscureText: _obscurePassword,
                            onToggle: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                            isValid:
                                _passwordCtrl.text.isNotEmpty &&
                                isStrongPassword,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Strength Indicator
                        _buildStrengthIndicator(strength),

                        const SizedBox(height: 16),

                        // Password Requirements
                        _buildModernPasswordRequirements(
                          passwordValidation,
                          isStrongPassword,
                        ),

                        const SizedBox(height: 20),

                        // Konfirmasi Password
                        _buildSectionLabel(
                          'Konfirmasi Password',
                          Icons.lock_outline,
                        ),
                        const SizedBox(height: 10),

                        _buildModernPasswordField(
                          controller: _confirmPasswordCtrl,
                          hint: 'Ulangi password baru',
                          obscureText: _obscureConfirmPassword,
                          onToggle: () {
                            setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            );
                          },
                          isValid: isConfirmMatch,
                          showMatchIndicator:
                              _confirmPasswordCtrl.text.isNotEmpty,
                        ),

                        // Match indicator
                        if (_confirmPasswordCtrl.text.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isConfirmMatch
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isConfirmMatch
                                    ? const Color(0xFF22C55E).withOpacity(0.3)
                                    : const Color(0xFFE53935).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isConfirmMatch
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: 14,
                                  color: isConfirmMatch
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFE53935),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isConfirmMatch
                                      ? 'Password cocok'
                                      : 'Password tidak cocok',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isConfirmMatch
                                        ? const Color(0xFF1B5E20)
                                        : const Color(0xFFC62828),
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Submit Button
                        _buildSubmitButton(isStrongPassword, isConfirmMatch),

                        const SizedBox(height: 12),

                        // Back to Login
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: const Text(
                              'Kembali ke Login',
                              style: TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                        ),
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

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
            fontFamily: 'Montserrat',
          ),
        ),
      ],
    );
  }

  Widget _buildModernPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggle,
    bool isValid = false,
    bool showMatchIndicator = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: showMatchIndicator
              ? (isValid ? const Color(0xFF22C55E) : const Color(0xFFE53935))
              : Colors.grey.shade200,
          width: showMatchIndicator ? 2 : 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          color: Color(0xFF1B5E20),
          fontFamily: 'Montserrat',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontFamily: 'Montserrat',
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: showMatchIndicator
                ? (isValid ? const Color(0xFF22C55E) : const Color(0xFFE53935))
                : const Color(0xFF4CAF50),
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: Colors.grey[500],
              size: 20,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildStrengthIndicator(int strength) {
    final colors = [
      Colors.grey.shade300,
      const Color(0xFFE53935),
      const Color(0xFFFF9800),
      const Color(0xFFFFC107),
      const Color(0xFF8BC34A),
      const Color(0xFF22C55E),
    ];

    final labels = [
      '',
      'Sangat Lemah',
      'Lemah',
      'Sedang',
      'Kuat',
      'Sangat Kuat',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: index < strength
                      ? colors[strength]
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        if (strength > 0) ...[
          const SizedBox(height: 6),
          Text(
            labels[strength],
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors[strength],
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModernPasswordRequirements(
    Map<String, bool> validation,
    bool isStrong,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isStrong ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isStrong
              ? const Color(0xFF22C55E).withOpacity(0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isStrong ? Icons.check_circle : Icons.info_outline,
                size: 16,
                color: isStrong ? const Color(0xFF22C55E) : Colors.grey[500],
              ),
              const SizedBox(width: 8),
              Text(
                'Persyaratan Password:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isStrong ? const Color(0xFF1B5E20) : Colors.grey[700],
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
              size: 10,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isMet ? const Color(0xFF1B5E20) : Colors.grey[600],
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isStrong, bool isMatch) {
    final canSubmit = isStrong && isMatch && !_isLoading;

    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: canSubmit
            ? const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
              )
            : null,
        color: canSubmit ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(14),
        boxShadow: canSubmit
            ? [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canSubmit ? _resetPassword : null,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: canSubmit ? Colors.white : Colors.grey[500],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Reset Password',
                        style: TextStyle(
                          color: canSubmit ? Colors.white : Colors.grey[500],
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
