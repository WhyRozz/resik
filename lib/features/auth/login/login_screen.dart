import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ UBAH: StatelessWidget → StatefulWidget
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ✅ Tambah controller sebagai instance variable
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    // ✅ Bersihkan controller saat widget dihapus
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ✅ Fungsi Login yang sudah benar
  Future<void> _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Email dan password wajib diisi');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      setState(() => _isLoading = false);
      final result = jsonDecode(response.body);

      if (result['status'] == 'success') {
        // ✅ 1. AMBIL DATA USER (tanpa token)
        final String tipe = result['data']['tipe'] ?? '';

        if (tipe.isEmpty) {
          _showSnackBar('Tipe user tidak ditemukan');
          return;
        }

        // ✅ 2. Proses User Data
        final Map<String, dynamic> userData = Map<String, dynamic>.from(
          result['data']['user'] ?? {},
        );

        userData['tipe'] = tipe;

        // ✅ AMBIL ID SESUAI ROLE (PENTING!)
        String? userId;
        if (tipe == 'masyarakat') {
          userId = userData['id_masyarakat']?.toString();
        } else if (tipe == 'pns') {
          userId = userData['id_pns']?.toString();
        } else if (tipe == 'petugas') {
          userId = userData['id_petugas']?.toString(); // ✅ Tambah ini!
        }

        if (userId == null) {
          _showSnackBar('ID user tidak valid');
          return;
        }

        // ✅ 3. Simpan ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_type', tipe);
        await prefs.setString('user_data', jsonEncode(userData));
        await prefs.setBool('is_logged_in', true);

        debugPrint("✅ Login sukses! Tipe: $tipe, User ID: $userId");

        // ✅ 4. Fetch Saldo Awal (HANYA untuk masyarakat/pns)
        double initialSaldo = 0;
        double initialSetoran = 0;

        if (tipe == 'masyarakat' || tipe == 'pns') {
          // ✅ Jangan fetch untuk petugas!
          try {
            final saldoResponse = await http
                .get(
                  Uri.parse(
                    '${ApiConfig.baseUrl}/api/get-saldo?user_id=$userId&tipe=$tipe',
                  ),
                  headers: {'Accept': 'application/json'},
                )
                .timeout(const Duration(seconds: 5));

            if (saldoResponse.statusCode == 200) {
              final saldoResult = jsonDecode(saldoResponse.body);
              if (saldoResult['status'] == 'success') {
                initialSaldo = (saldoResult['data']['saldo'] ?? 0).toDouble();
                initialSetoran = (saldoResult['data']['total_setoran'] ?? 0)
                    .toDouble();
              }
            }
          } catch (e) {
            debugPrint("⚠️ Gagal fetch saldo awal: $e");
          }
        }

        // ✅ 5. NAVIGASI
        if (tipe == 'masyarakat' || tipe == 'pns') {
          Navigator.pushReplacementNamed(
            context,
            '/home-user',
            arguments: {
              'initialSaldo': initialSaldo,
              'initialTotalSetoran': initialSetoran,
            },
          );
        } else if (tipe == 'petugas') {
          Navigator.pushReplacementNamed(
            context,
            '/home-admin',
          ); // ✅ Admin langsung ke home-admin
        } else {
          _showSnackBar('Tipe user tidak dikenali');
        }

        _showSnackBar('Login berhasil!');
      } else {
        _showSnackBar(result['message'] ?? 'Login gagal');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Login Error: $e");
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Ilustrasi
                Image.asset(
                  'assets/images/login-pict.png',
                  height: 180,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person, size: 100, color: Colors.white),
                          SizedBox(height: 5),
                          Text(
                            'Ilustrasi Login',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Area Form Putih
                Container(
                  margin: const EdgeInsets.only(top: 0),
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'LOGIN',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Input Email ✅ Pakai controller yang benar
                      _buildLabel('Email'),
                      _buildTextField(
                        hint: 'Masukkan Emailmu',
                        prefixIcon: Icons.email_outlined,
                        controller: _emailCtrl, // ← ✅ Instance variable
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Input Kata Sandi ✅ Pakai controller yang benar
                      _buildLabel('Kata Sandi'),
                      _buildTextField(
                        hint: 'Masukkan Kata Sandi',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        controller: _passwordCtrl, // ← ✅ Instance variable
                      ),
                      const SizedBox(height: 8),

                      // Lupa kata sandi?
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/forgot-password');
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Lupa kata sandi?',
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 12,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tombol Masuk ✅ Panggil _handleLogin()
                      Container(
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
                            onTap: _isLoading ? null : _handleLogin,
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
                                      'Masuk',
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
                      const SizedBox(height: 24),

                      // Divider "atau"
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey[300],
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'atau',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey[300],
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Belum punya akun? Daftar Disini
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Belum punya akun? ',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/register-step1');
                            },
                            child: const Text(
                              'Daftar Disini',
                              style: TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widgets
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

  Widget _buildTextField({
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    required TextEditingController controller, // ← ✅ Wajib dikasih controller
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller, // ← ✅ Pakai controller dari parameter
        obscureText: obscureText,
        keyboardType: keyboardType,
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
          prefixIcon: Icon(prefixIcon, color: const Color(0xFF2E7D32)),
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
