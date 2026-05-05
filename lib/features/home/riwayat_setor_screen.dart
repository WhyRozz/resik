import 'package:flutter/material.dart';
import 'package:resik/features/home/home_user_screen.dart';
import 'laporan_screen.dart';
import 'info_tps_screen.dart';
import 'riwayat_penarikan_screen.dart';

class RiwayatSetorScreen extends StatefulWidget {
  const RiwayatSetorScreen({super.key});

  @override
  State<RiwayatSetorScreen> createState() => _RiwayatSetorScreenState();
}

class _RiwayatSetorScreenState extends State<RiwayatSetorScreen> {
  int _filterIndex = 0; // 0: Semua Riwayat, 1: 7 Hari Terakhir

  // Data dummy (nanti diganti API dengan filter tanggal)
  final List<Map<String, dynamic>> _allData = [
    {
      'tanggal': 'Senin, 27 April 2026',
      'bank': 'Bank Sampah Kecamatan',
      'jenis': '',
      'berat': '',
      'harga': '',
    },
    {
      'tanggal': 'Senin, 25 Februari 2026',
      'bank': 'Bank Sampah Kecamatan',
      'jenis': '',
      'berat': '',
      'harga': '',
    },
    {
      'tanggal': 'Senin, 25 Februari 2026',
      'bank': 'Bank Sampah Kecamatan',
      'jenis': '',
      'berat': '',
      'harga': '',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filter data berdasarkan pilihan
    final displayData = _filterIndex == 0 ? _allData : _getlast7DaysData();

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
          'Riwayat Setor',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // ✅ FILTER TABS
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterBubble(
                    'Semua Riwayat',
                    _filterIndex == 0,
                    () => setState(() => _filterIndex = 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFilterBubble(
                    '7 Hari Terakhir',
                    _filterIndex == 1,
                    () => setState(() => _filterIndex = 1),
                  ),
                ),
              ],
            ),
          ),

          // ✅ LIST RIWAYAT
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: displayData.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final data = displayData[index];
                return _buildSetorCard(data);
              },
            ),
          ),

          // ✅ BUBBLE TABS (BANK SAMPAH)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _buildBubble(
                    'Riwayat Setor',
                    Icons.upload_rounded,
                    true, // Active
                    () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBubble(
                    'Riwayat Penarikan',
                    Icons.download_rounded,
                    false,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RiwayatPenarikanScreen(),
                      ),
                    ),
                  ),
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

  // ✅ FILTER BUBBLE
  Widget _buildFilterBubble(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4CAF50) : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF4CAF50),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ✅ CARD RIWAYAT SETOR (SESUAI GAMBAR)
  Widget _buildSetorCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Text(
            data['bank'],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 12),
          // Info Rows
          _buildInfoRow('Jenis Sampah', data['jenis'] ?? '-'),
          const SizedBox(height: 6),
          _buildInfoRow('Berat', data['berat'] ?? '-'),
          const SizedBox(height: 6),
          _buildInfoRow('Total Harga', data['harga'] ?? '-'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 12, color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1B5E20),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
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
          color: isActive ? const Color(0xFF4CAF50) : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : const Color(0xFF4CAF50),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF4CAF50),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ BOTTOM NAVIGATION STYLE KONSISTEN
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
          // Index 2 (Bank Sampah) aktif di halaman ini
          final isActive = index == 2;
          final item = items[index];

          return GestureDetector(
            onTap: () {
              if (index == 0)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeUserScreen()),
                );
              else if (index == 1)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LaporanScreen()),
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

  // // ✅ FILTER DATA 7 HARI TERAKHIR
  // List<Map<String, dynamic>> _getlast7DaysData() {
  //   final now = DateTime.now();
  //   final sevenDaysAgo = now.subtract(const Duration(days: 7));

  //   return _allData.where((item) {
  //     // Parse tanggal dari string (nanti disesuaikan dengan format dari API)
  //     // Contoh: "Senin, 27 April 2026"
  //     final tanggalStr = item['tanggal'] as String;
  //     // Simple check - nanti pakai proper date parsing
  //     return true; // Placeholder - implementasi sesuai kebutuhan
  //   }).toList();
  // }

  List<Map<String, dynamic>> _getlast7DaysData() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    return _allData.where((item) {
      final tanggal = DateTime.parse(
        item['tanggal_iso'],
      ); // Format ISO dari API
      return tanggal.isAfter(sevenDaysAgo);
    }).toList();
  }
}
