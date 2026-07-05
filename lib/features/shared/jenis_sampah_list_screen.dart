import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class JenisSampahListScreen extends StatefulWidget {
  const JenisSampahListScreen({super.key});

  @override
  State<JenisSampahListScreen> createState() => _JenisSampahListScreenState();
}

class _JenisSampahListScreenState extends State<JenisSampahListScreen> {
  List<dynamic> _jenisSampahList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchJenisSampah();
  }

  Future<void> _handleRefresh() async {
    await _fetchJenisSampah();
  }

  Future<void> _fetchJenisSampah() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse(ApiConfig.jenisSampahList))
          .timeout(const Duration(seconds: 10));

      debugPrint("📥 Status: ${response.statusCode}");
      debugPrint("📄 Response: ${response.body}");

      if (mounted) {
        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          if (result['status'] == 'success') {
            setState(() {
              _jenisSampahList = result['data'] ?? [];
              _isLoading = false;
            });
          } else {
            setState(() {
              _errorMessage = result['message'] ?? 'Gagal memuat data';
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Server error: ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("❌ HTTP Error: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'Koneksi error: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _formatRupiah(double angka) {
    return 'Rp ${angka.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.recycling, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'Jenis Sampah',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchJenisSampah,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_jenisSampahList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.category_outlined,
                size: 56,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada data jenis sampah',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Data akan muncul setelah admin menambahkannya',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: const Color(0xFF4CAF50),
      backgroundColor: Colors.white,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.82,
        ),
        itemCount: _jenisSampahList.length,
        itemBuilder: (context, index) {
          final item = _jenisSampahList[index];
          return _buildJenisSampahCard(item);
        },
      ),
    );
  }

  Widget _buildJenisSampahCard(Map<String, dynamic> item) {
    final String namaJenis = item['jenis'] ?? 'Umum';
    final String satuan = item['satuan'] ?? 'kg';
    final double harga = (item['harga'] ?? 0).toDouble();
    final String? gambarUrl = item['gambar'];

    // ✅ DEBUG: Print URL gambar
    debugPrint("📸 [$namaJenis] URL: $gambarUrl");

    final iconMap = {
      'plastik': Icons.local_drink,
      'kertas': Icons.description,
      'kardus': Icons.inventory,
      'logam': Icons.build,
      'besi': Icons.hardware,
      'kaca': Icons.camera,
      'organik': Icons.eco,
      'minyak': Icons.opacity,
      'elektronik': Icons.devices,
      'lainnya': Icons.category,
    };
    final iconKey = namaJenis.toLowerCase().replaceAll(' ', '');
    final IconData icon = iconMap.entries
        .firstWhere(
          (e) => iconKey.contains(e.key),
          orElse: () => MapEntry('lainnya', Icons.category_rounded),
        )
        .value;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon/Gambar (1 Lingkaran Saja)
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFE8F5E9),
            backgroundImage: (gambarUrl != null && gambarUrl.isNotEmpty)
                ? NetworkImage(gambarUrl) // ✅ Langsung pakai gambarUrl
                : null,
            child: (gambarUrl == null || gambarUrl.isEmpty)
                ? Icon(icon, size: 40, color: const Color(0xFF4CAF50))
                : null,
          ),
          const SizedBox(height: 14),

          // Nama Jenis
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              namaJenis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B5E20),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),

          // Harga
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_formatRupiah(harga)} / $satuan',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
