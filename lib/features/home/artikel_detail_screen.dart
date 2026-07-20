import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/api_config.dart';

class ArtikelDetailScreen extends StatelessWidget {
  final Map<String, dynamic> artikel;

  const ArtikelDetailScreen({super.key, required this.artikel});

  // ✅ FUNGSI POP-UP FOTO (Disempurnakan)
  void _showImagePopup(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Hero(
                  tag: 'artikel_foto',
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 80,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(dialogContext),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 16,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Gambar dengan Gradient Overlay & Tap Area Penuh
            Stack(
              children: [
                // 1. GAMBAR UTAMA (Hero tetap di sini biar animasi zoom mulus)
                Hero(
                  tag: 'artikel_foto',
                  child: Image.network(
                    ApiConfig.imageUrl(artikel['foto']),
                    width: double.infinity,
                    height: 280,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 280,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image_outlined,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

                // 2. GRADIENT OVERLAY (Di atas gambar)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 140,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // 3. INFO DI TENGAH BAWAH (Di atas gradient)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(artikel['tanggal']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 1,
                            height: 12,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.zoom_in_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Tap untuk zoom',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. GESTURE DETECTOR PALING ATAS (Invisible Layer)
                // Ini yang bikin SELURUH area foto bisa diklik!
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior
                        .opaque, // KUNCI AGAR BISA KLIK DI AREA TRANSPARAN
                    onTap: () => _showImagePopup(
                      context,
                      ApiConfig.imageUrl(artikel['foto']),
                    ),
                    child: Container(
                      color: Colors
                          .transparent, // Container bening sebagai area klik
                    ),
                  ),
                ),
              ],
            ),

            // KONTEN ARTIKEL
            Container(
              margin: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori badge (jika ada)
                  if (artikel['kategori'] != null &&
                      artikel['kategori'].toString().isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFA5D6A7),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.label_rounded,
                            color: Color(0xFF2E7D32),
                            size: 11,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            artikel['kategori'].toString().toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Judul (di tengah)
                  Center(
                    child: Text(
                      artikel['judul'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                        height: 1.4,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const SizedBox(height: 16),

                  // Konten artikel
                  Text(
                    artikel['konten'] ?? artikel['deskripsi'] ?? '',
                    textAlign: TextAlign.justify,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: Color(0xFF2C3E50),
                      height: 1.8,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.1,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Footer card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RESIK - Peduli Lingkungan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Artikel edukasi untuk lingkungan kota Nganjuk yang lebih baik',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null || dateString.toString().isEmpty) return '-';
    final dateStr = dateString.toString();

    if (RegExp(
      r'^\d{1,2}\s+(Januari|Februari|Maret|April|Mei|Juni|Juli|Agustus|September|Oktober|November|Desember)\s+\d{4}$',
    ).hasMatch(dateStr)) {
      return dateStr;
    }

    try {
      DateTime date;
      if (dateStr.contains(' ') || dateStr.contains('T')) {
        date = DateTime.parse(dateStr);
      } else if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        } else {
          return dateStr;
        }
      } else if (int.tryParse(dateStr) != null) {
        date = DateTime.fromMillisecondsSinceEpoch(int.parse(dateStr));
      } else {
        return dateStr;
      }

      final months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
