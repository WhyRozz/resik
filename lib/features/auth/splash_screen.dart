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

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Fade IN
    _controller.forward();

    // Tunggu 2 detik, lalu Fade OUT dan navigate
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            _checkLoginAndNavigate();
          }
        });
      }
    });
  }

  Future<void> _checkLoginAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();

    final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final String? userData = prefs.getString('user_data');

    if (!mounted) return;

    if (isLoggedIn && userData != null) {
      final data = jsonDecode(userData);
      final tipe = data['tipe'];

      if (tipe == 'petugas') {
        Navigator.pushReplacementNamed(context, '/home-admin');
      } else {
        // masyarakat & pns
        Navigator.pushReplacementNamed(context, '/home-user');
      }
    } else {
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
            ),
          ),
        ),
      ),
    );
  }
}
