import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailCtrl = TextEditingController();
  final GlobalKey _emailFieldKey = GlobalKey(); // ✅ Key untuk shake animation

  bool _isLoading = false;

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
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // ✅ SHAKE ANIMATION
  void _shakeEmailField() {
    _shakeController.forward(from: 0);
  }

  Future<void> _handleResetPassword() async {
    final email = _emailCtrl.text.trim();

    // Validasi format email
    if (email.isEmpty || !email.contains('@')) {
      _shakeEmailField();
      _showSnackBar('Email tidak valid');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.forgotPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      setState(() => _isLoading = false);

      final result = jsonDecode(response.body);

      if (result['status'] == 'success') {
        // ✅ Cek apakah ada pesan khusus "email tidak ditemukan"
        final message = result['message'] ?? '';

        if (message.toLowerCase().contains('tidak ditemukan') ||
            message.toLowerCase().contains('not found') ||
            message.toLowerCase().contains('tidak terdaftar')) {
          // ✅ Email tidak terdaftar → Shake + error message
          _shakeEmailField();
          _showSnackBar('Email belum terdaftar');
        } else {
          // ✅ Email terdaftar → Lanjut ke OTP
          _showSnackBar('Kode verifikasi telah dikirim');
          Navigator.pushNamed(context, '/verify-otp', arguments: email);
        }
      } else {
        final message =
            result['message'] ?? 'Gagal mengirim link reset password';

        // ✅ Cek error email tidak terdaftar
        if (message.toLowerCase().contains('tidak ditemukan') ||
            message.toLowerCase().contains('not found') ||
            message.toLowerCase().contains('tidak terdaftar')) {
          _shakeEmailField();
          _showSnackBar('Email belum terdaftar');
        } else {
          _showSnackBar(message);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _shakeEmailField();
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
                        // Judul - diperkecil dikit
                        const Text(
                          'Lupa Kata Sandi?',
                          style: TextStyle(
                            fontSize: 24, // ← Dari 28 jadi 24
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                            fontFamily: 'Montserrat',
                          ),
                        ),

                        const SizedBox(height: 15), // ← Dari 20 jadi 15
                        // Ilustrasi - diperkecil
                        Image.asset(
                          'assets/images/forgot-pict.png',
                          height: 150, // ← Dari 180 jadi 150
                          width: double.infinity,
                          fit: BoxFit.contain, // ← Tambah ini
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150, // ← Dari 240 jadi 150
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ), // ← Tambah ini
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F8E9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock_reset,
                                    size: 60, // ← Dari 80 jadi 60
                                    color: Color(0xFF2E7D32),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Ilustrasi Lupa Password',
                                    style: TextStyle(color: Color(0xFF1B5E20)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 25), // ← Dari 30 jadi 25
                        // Text instruction - diperbold
                        const Text(
                          'Masukkan Alamat Email',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold, // ← Tambah ini
                            color: Color(0xFF1B5E20),
                            fontFamily: 'Montserrat',
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Input Email - tambah margin horizontal
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ), // ← Tambah ini
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F8E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                color: Color(0xFF1B5E20),
                                fontFamily: 'Montserrat',
                              ),
                              decoration: InputDecoration(
                                hintText: 'contoh@email.com',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontFamily: 'Montserrat',
                                ),
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: Color(0xFF2E7D32),
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
                          ),
                        ),

                        const SizedBox(height: 20), // ← Tambah spacing
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

                        const SizedBox(height: 10), // ← Kurangi spacing
                        // Tombol Kirim - tambah margin horizontal
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ), // ← Tambah ini
                          child: Container(
                            width: double.infinity,
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
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isLoading ? null : _handleResetPassword,
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
                        ),

                        const SizedBox(height: 25), // ← Tambah spacing bawah
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
}
