import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_screen.dart';
import 'dart:convert';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Inisialisasi Animasi
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Jalankan animasi Fade IN
    _controller.forward();

    // 2. Tunggu 2.5 detik (waktu yang pas dan aman), lalu cek login
    // Menggunakan satu Future.delayed lebih stabil daripada chaining .then()
    // yang rentan gagal di HP dengan penghemat baterai agresif (Xiaomi, Oppo, dll).
    Future.delayed(const Duration(milliseconds: 2500), () {
      _checkLoginAndNavigate();
    });
  }

  Future<void> _checkLoginAndNavigate() async {
    // 3. Cek mounted sebelum melakukan proses async
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final String? userData = prefs.getString('user_data');

      if (!mounted) return;

      // 4. Validasi data dengan ketat
      if (isLoggedIn && userData != null && userData.isNotEmpty) {
        // Safe JSON Decode dengan casting yang jelas
        final data = jsonDecode(userData) as Map<String, dynamic>;
        final tipe = data['tipe']?.toString() ?? '';

        if (tipe == 'petugas') {
          Navigator.pushReplacementNamed(context, '/home-admin');
        } else {
          // Untuk masyarakat & pns
          Navigator.pushReplacementNamed(context, '/home-user');
        }
      } else {
        // Jika tidak login, langsung ke Welcome Screen
        _goToWelcomeScreen();
      }
    } catch (e) {
      // 5. FALLBACK PENTING: Jika terjadi error (misal: JSON korup, prefs error),
      // JANGAN biarkan aplikasi stuck atau crash.
      debugPrint('❌ [SplashScreen] Error saat memproses data: $e');

      try {
        // Bersihkan data yang mungkin korup agar tidak error berulang
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('is_logged_in');
        await prefs.remove('user_data');
      } catch (clearError) {
        debugPrint('❌ [SplashScreen] Gagal membersihkan prefs: $clearError');
      }

      // Arahkan user ke Welcome Screen dengan aman
      if (mounted) {
        _goToWelcomeScreen();
      }
    }
  }

  // Fungsi terpisah untuk navigasi ke Welcome Screen agar kode lebih rapi
  void _goToWelcomeScreen() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const WelcomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4CAF50), Color(0xFF81C784), Colors.white],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Image.asset(
              'assets/images/logo-resik.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
              // 6. Error Builder: Mencegah layar putih/crash jika gambar gagal dimuat
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ [SplashScreen] Gagal memuat logo: $error');
                return const Icon(
                  Icons.error_outline,
                  size: 180,
                  color: Colors.red,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
