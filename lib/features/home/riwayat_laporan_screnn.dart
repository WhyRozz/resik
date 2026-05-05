import 'package:flutter/material.dart';
import 'home_user_screen.dart';
import 'laporan_screen.dart';
import 'detail_laporan_screen.dart';
import 'riwayat_setor_screen.dart';
import 'info_tps_screen.dart';

class RiwayatLaporanScreen extends StatelessWidget {
  const RiwayatLaporanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Data dummy (nanti diganti dengan API)
    final List<Map<String, dynamic>> laporanData = [
      {
        'judul': 'Sampah Menumpuk di Jalan Raya',
        'alamat': 'Jl. Melangun Kulon',
        'tanggal': '24 April 2026',
        'status': 'Proses',
        'foto': 'https://via.placeholder.com/100', // Nanti dari API
      },
      {
        'judul': 'Sampah Menumpuk',
        'alamat': 'Jl. Melangun Kulon',
        'tanggal': '24 April 2026',
        'status': 'Proses',
        'foto': null, // Tidak ada foto
      },
      {
        'judul': 'Sampah Menumpuk...',
        'alamat': 'Jl. Melangun Kulon',
        'tanggal': '24 April 2026',
        'status': 'Proses',
        'foto': null,
      },
      {
        'judul': 'Sampah Menumpuk...',
        'alamat': 'Jl. Melangun Kulon',
        'tanggal': '24 April 2026',
        'status': 'Proses',
        'foto': null,
      },
    ];

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
          'Cek Status Laporan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // ✅ LIST RIWAYAT LAPORAN
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: laporanData.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final data = laporanData[index];
                return _buildLaporanCard(context, data); // ✅ Pass context
              },
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
                  child: _buildBubble(
                    'Riwayat',
                    Icons.history,
                    true, // Active
                    () {},
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

  // ✅ CARD RIWAYAT LAPORAN (SESUAI GAMBAR)
  Widget _buildLaporanCard(BuildContext context, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailLaporanScreen(
              laporan: <String, dynamic>{
                'nama': 'Farida',
                'lokasi': data['alamat'],
                'keterangan': data['judul'],
                'tanggal': data['tanggal'],
                'status': data['status'],
                'foto': data['foto'],
              },
            ),
          ),
        );
      },
      child: Row(
        children: [
          // Thumbnail Foto
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: data['foto'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      data['foto'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  )
                : const Icon(Icons.image, color: Colors.grey, size: 32),
          ),
          const SizedBox(width: 12),
          // Info Laporan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['judul'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Alamat', data['alamat']),
                _buildInfoRow('Tanggal', data['tanggal']),
                const SizedBox(height: 8),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107), // Kuning untuk "Proses"
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data['status'],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 11, color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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
          final isActive = index == 1; // Tab Laporan aktif
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
