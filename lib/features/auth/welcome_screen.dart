import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Positioned(
            top: -70,
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/welcome_bg3.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: const Color(0xFFE8F5E9));
              },
            ),
          ),

          // 2. Konten Utama
          SafeArea(
            child: SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(), // Scroll halus khas iOS/Android modern
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight - padding.top - padding.bottom,
                    maxHeight:
                        850, // Batas agar tidak terlalu renggang di tablet
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // === GRUP ATAS (Judul, Logo, Deskripsi) ===
                        Column(
                          children: [
                            const SizedBox(height: 30),

                            // Judul
                            const Text(
                              "Selamat Datang",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF134B25),
                                fontFamily: 'Montserrat',
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Logo RESIK
                            Image.asset(
                              'assets/images/logo-resik.png',
                              width: 120,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: Icon(
                                    Icons.error_outline,
                                    size: 60,
                                    color: Colors.red,
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 20),

                            // Deskripsi
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                "Jaga bumi lebih mudah dengan RESIK. Pilah sampah secara cerdas dan berikan kontribusi nyata bagi alam. Mari beraksi bersama mewujudkan Nganjuk yang bersih, hijau, dan lestari demi masa depan.",
                                textAlign: TextAlign.justify,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1B5E20),
                                  fontFamily: 'Montserrat',
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // === GRUP BAWAH (Tombol Mulai) ===
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/login',
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0B6B2B),
                                  elevation: 6,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Mulai",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Montserrat',
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
