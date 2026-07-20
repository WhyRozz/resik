import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../config/api_config.dart';
import 'home_user_screen.dart';
import 'laporan_screen.dart';
import 'detail_laporan_screen.dart';
import 'riwayat_setor_screen.dart';
import 'info_tps_screen.dart';

class RiwayatLaporanScreen extends StatefulWidget {
  const RiwayatLaporanScreen({super.key});

  @override
  State<RiwayatLaporanScreen> createState() => _RiwayatLaporanScreenState();
}

class _RiwayatLaporanScreenState extends State<RiwayatLaporanScreen> {
  List<dynamic> _laporanData = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRiwayatLaporan();
  }

  Future<void> _fetchRiwayatLaporan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      final userType = prefs.getString('user_type');

      if (userDataStr == null || userType == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Silakan login ulang';
        });
        return;
      }

      final userData = jsonDecode(userDataStr);
      final userId = userData['id_masyarakat'] ?? userData['id_pns'];

      final response = await http.get(
        Uri.parse(ApiConfig.laporanIndex).replace(
          queryParameters: {'user_id': userId.toString(), 'tipe': userType},
        ),
        headers: {'Accept': 'application/json'},
      );

      debugPrint("📄 RAW Response: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['status'] == 'success') {
        final data = result['data'] ?? [];

        for (var item in data) {
          debugPrint("📸 Foto URL: ${item['foto']}");
        }

        setState(() {
          _laporanData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Gagal memuat data';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("🚨 Exception: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'Koneksi error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _fetchRiwayatLaporan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8F4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF2E7D32),
              size: 16,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomeUserScreen()),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF2E7D32), const Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.assignment_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Riwayat Laporan',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // ✅ LIST RIWAYAT LAPORAN - MODERN DESIGN
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  )
                : _errorMessage != null
                ? Center(
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
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _fetchRiwayatLaporan,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
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
                  )
                : _laporanData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.report_outlined,
                            size: 64,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Belum ada riwayat laporan',
                          style: TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ayo buat laporan pertama Anda!',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LaporanScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text('Buat Laporan Sekarang'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: const Color(0xFF2E7D32),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _laporanData.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final data = _laporanData[index];
                        return _buildModernLaporanCard(context, data);
                      },
                    ),
                  ),
          ),

          // ✅ BUBBLE TABS
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _buildBubble(
                    'Sampah Ilegal',
                    Icons.warning,
                    false,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LaporanScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBubble('Riwayat', Icons.history, true, () {}),
                ),
              ],
            ),
          ),

          // ✅ BOTTOM NAVIGATION (KONSISTEN)
          _buildConsistentBottomNav(context),
        ],
      ),
    );
  }

  // ✅ HELPER: Format tanggal dengan jam (handle timezone)
  String _formatTanggal(String? tanggalStr) {
    if (tanggalStr == null || tanggalStr.isEmpty) return '-';
    try {
      // Parse dari string
      final dt = DateTime.parse(tanggalStr);

      // ✅ Convert ke local timezone (WIB/Asia/Jakarta)
      final localDt = dt.toLocal();

      return '${localDt.day.toString().padLeft(2, '0')}-${localDt.month.toString().padLeft(2, '0')}-${localDt.year} ${localDt.hour.toString().padLeft(2, '0')}:${localDt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return tanggalStr;
    }
  }

  // ✅ MODERN CARD DESIGN
  Widget _buildModernLaporanCard(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final status = data['status'] ?? 'Unknown';
    final statusData = _getStatusData(status);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailLaporanScreen(laporan: data),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail dengan Gradient Overlay
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                color: Colors.grey.shade200,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Foto atau Placeholder
                  data['foto'] != null && data['foto'].toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: Image.network(
                            data['foto'].toString(),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF2E7D32),
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint("❌ Error load gambar: $error");
                              debugPrint("🔗 URL: ${data['foto']}");
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.grey,
                                  size: 48,
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFE8F5E9),
                                const Color(0xFFC8E6C9),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.image_outlined,
                            color: Color(0xFF2E7D32),
                            size: 48,
                          ),
                        ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                  // Status Badge Modern dengan Gradient
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: statusData['gradientColors'] as List<Color>,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (statusData['shadowColor'] as Color)
                                .withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              statusData['icon'] as IconData,
                              color: Colors.white,
                              size: 11,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ], // (tutup children Stack)
              ), // (tutup Stack)
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul
                  Text(
                    data['judul'] ?? data['keterangan'] ?? 'Tanpa Judul',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Lokasi
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFE65100),
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data['alamat'] ?? data['lokasi'] ?? '-',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Tanggal
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.calendar_today_outlined,
                          color: Color(0xFF7B1FA2),
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTanggal(data['tanggal']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusData(String status) {
    switch (status.toLowerCase()) {
      case 'diproses':
      case 'proses':
        return {
          'gradientColors': [const Color(0xFFFFB347), const Color(0xFFFFA000)],
          'icon': Icons.schedule_rounded,
          'shadowColor': const Color(0xFFFFA000),
        };
      case 'diterima':
      case 'berhasil':
      case 'selesai':
        return {
          'gradientColors': [const Color(0xFF66BB6A), const Color(0xFF2E7D32)],
          'icon': Icons.check_circle_rounded,
          'shadowColor': const Color(0xFF2E7D32),
        };
      case 'ditolak':
        return {
          'gradientColors': [const Color(0xFFEF5350), const Color(0xFFC62828)],
          'icon': Icons.cancel_rounded,
          'shadowColor': const Color(0xFFC62828),
        };
      case 'ditarik':
        return {
          'gradientColors': [Colors.grey.shade400, Colors.grey.shade600],
          'icon': Icons.archive_outlined,
          'shadowColor': Colors.grey.shade600,
        };
      default:
        return {
          'gradientColors': [Colors.grey.shade400, Colors.grey.shade600],
          'icon': Icons.help_outline_rounded,
          'shadowColor': Colors.grey.shade600,
        };
    }
  }

  Widget _buildBubble(
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : const Color(0xFF2E7D32),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF2E7D32),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsistentBottomNav(BuildContext context) {
    final items = [
      {'icon': Icons.home_outlined, 'active': Icons.home, 'label': 'Home'},
      {
        'icon': Icons.assignment_outlined,
        'active': Icons.assignment,
        'label': 'Laporan',
      },
      {
        'icon': Icons.store_outlined,
        'active': Icons.store,
        'label': 'Bank Sampah',
      },
      {
        'icon': Icons.location_on_outlined,
        'active': Icons.location_on,
        'label': 'Info TPS',
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isActive = index == 1;
          final item = items[index];

          return GestureDetector(
            onTap: () {
              if (index == 0)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeUserScreen()),
                );
              else if (index == 2)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RiwayatSetorScreen()),
                );
              else if (index == 3)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InfoTpsScreen()),
                );
            },
            child: Container(
              padding: isActive
                  ? const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: isActive
                  ? BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(30),
                    )
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive
                        ? item['active'] as IconData
                        : item['icon'] as IconData,
                    color: isActive ? Colors.white : Colors.grey,
                    size: 22,
                  ),
                  if (isActive) const SizedBox(width: 8),
                  if (isActive)
                    Text(
                      item['label'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
