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

  // ✅ HANDLE PULL-TO-REFRESH
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Jenis Sampah',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchJenisSampah, // ✅ Tetap bisa retry manual
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
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
            Icon(Icons.category, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Belum ada data jenis sampah',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // ✅ WRAP DENGAN RefreshIndicator
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: const Color(0xFF4CAF50),
      backgroundColor: Colors.white,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
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

    // ✅ Icon mapping berdasarkan jenis sampah
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
          orElse: () => MapEntry('lainnya', Icons.category),
        )
        .value;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ✅ Icon / Gambar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: gambarUrl != null
                ? ClipOval(
                    child: Image.network(
                      gambarUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(icon, size: 40, color: const Color(0xFF4CAF50)),
                    ),
                  )
                : Icon(icon, size: 40, color: const Color(0xFF4CAF50)),
          ),
          const SizedBox(height: 12),

          // ✅ Nama Jenis Sampah
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              namaJenis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),

          // ✅ Harga per Satuan
          Text(
            _formatRupiah(harga) + ' / $satuan',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4CAF50),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
