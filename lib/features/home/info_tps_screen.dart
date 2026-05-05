import 'package:flutter/material.dart';
import 'home_user_screen.dart';
import 'package:resik/features/home/riwayat_penarikan_screen.dart';
import 'package:resik/features/home/riwayat_setor_screen.dart';


class InfoTpsScreen extends StatelessWidget {
  const InfoTpsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        title: const Text(
          'Info TPS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      // ✅ KONTEN PLACEHOLDER (Nanti diganti dengan Peta/List TPS)
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Info TPS',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fitur akan segera hadir',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      // ✅ NAVIGASI BAWAH (SAMA PERSIS DENGAN BERANDA & LAPORAN)
      bottomNavigationBar: _buildConsistentBottomNav(context),
    );
  }

  // ✅ WIDGET NAVIGASI STYLE BERANDA (Pill Hijau Active, Icon Only Inactive)
  Widget _buildConsistentBottomNav(BuildContext context) {
    final items = [
      {'icon': Icons.home_outlined, 'active': Icons.home, 'label': 'Home'},
      {'icon': Icons.assignment_outlined, 'active': Icons.assignment, 'label': 'Laporan'},
      {'icon': Icons.store_outlined, 'active': Icons.store, 'label': 'Bank Sampah'},
      {'icon': Icons.location_on_outlined, 'active': Icons.location_on, 'label': 'Info TPS'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          // ✅ Index 3 (Info TPS) selalu aktif di halaman ini
          final isActive = index == 3;
          final item = items[index];

          return GestureDetector(
            onTap: () {
              if (index == 0) Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeUserScreen()),
                ); // Kembali ke Home
              else if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const RiwayatSetorScreen()));
              else if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const RiwayatPenarikanScreen()));
              // Index 3 tidak perlu aksi karena sudah di halaman ini
            },
            child: Container(
              padding: isActive
                  ? const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: isActive
                  ? BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(30))
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive ? item['active'] as IconData : item['icon'] as IconData,
                    color: isActive ? Colors.white : Colors.grey,
                    size: 22,
                  ),
                  if (isActive) const SizedBox(width: 8),
                  if (isActive)
                    Text(
                      item['label'] as String,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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