import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Gradient hijau ke putih di bawah
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4CAF50), // Hijau terang (atas)
              Color(0xFF66BB6A), // Hijau medium
              Colors.white, // Putih (bawah)
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            // CENTER INI PENTING: Supaya isi layar nempel ke tengah
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Judul
                const Text(
                  'Selamat Datang',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                    fontFamily: 'Montserrat',
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Ilustrasi
                Image.asset(
                  'assets/images/welcome-screen.png',
                  height: 200, // Sedikit saya kecilkan biar pas
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.withOpacity(0.2),
                      child: const Center(child: Icon(Icons.image, size: 50)),
                    );
                  },
                ),

                const SizedBox(
                  height: 144,
                ), // Jarak ke card (tidak terlalu jauh)
                // 3. Card Deskripsi
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Jaga bumi lebih mudah dengan RESIK. Pilih sampah secara cerdas dan berikan kontribusi nyata bagi alam. Mari bersiki bersama wujudkan Nganjuk yang bersih, hijau, dan lestari demi masa depan.',
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1B5E20),
                      fontFamily: 'Montserrat',
                      height: 1.6,
                    ),
                  ),
                ),

                const SizedBox(height: 24), // Jarak ke tombol
                // 4. Tombol Mulai
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
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Mulai',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Padding bawah dikit
              ],
            ),
          ),
        ),
      ),
    );
  }
}
