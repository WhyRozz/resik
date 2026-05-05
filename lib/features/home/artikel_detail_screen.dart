import 'package:flutter/material.dart';
import '../../config/api_config.dart';

class ArtikelDetailScreen extends StatelessWidget {
  final Map<String, dynamic> artikel;

  const ArtikelDetailScreen({super.key, required this.artikel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: Text(artikel['judul'] ?? 'Detail Artikel'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            if (artikel['foto'] != null)
              Image.network(
                '${ApiConfig.baseUrl}/storage/${artikel['foto']}',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            
            // Konten
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artikel['judul'] ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    artikel['konten'] ?? artikel['deskripsi'] ?? '',
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}