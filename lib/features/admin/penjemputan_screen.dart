import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import 'home_admin_screen.dart';
import 'form_penjemputan_screen.dart';

class PenjemputanScreen extends StatefulWidget {
  const PenjemputanScreen({super.key});

  @override
  State<PenjemputanScreen> createState() => _PenjemputanScreenState();
}

class _PenjemputanScreenState extends State<PenjemputanScreen> {
  int _selectedIndex = 2; // Index Penjemputan
  String? _activeBubble; // 'form' | 'riwayat'

  List<dynamic> _penjemputanList = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filterStatus = 'all'; // 'all' | 'pending' | 'approved' | 'rejected'

  @override
  void initState() {
    super.initState();
    _activeBubble = 'riwayat'; // Default ke riwayat
    _fetchPenjemputanList();
  }

  Future<void> _fetchPenjemputanList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final adminData = jsonDecode(prefs.getString('user_data') ?? '{}');
      final adminId = adminData['id_petugas'];

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/riwayat-penjemputan/$adminId'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("📥 Status: ${response.statusCode}");
      debugPrint("📄 Response: ${response.body}");

      if (mounted) {
        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          if (result['status'] == 'success') {
            setState(() {
              _penjemputanList = result['data'] ?? [];
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

  void _onBubbleTap(String bubble) {
    setState(() => _activeBubble = bubble);
    
    if (bubble == 'form') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FormPenjemputanScreen()),
      ).then((result) {
        // Refresh list jika ada data baru
        if (result == true) {
          _fetchPenjemputanList();
        }
      });
    }
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
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeAdminScreen()),
            (route) => false,
          ),
        ),
        title: const Text(
          'Penjemputan Sampah',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchPenjemputanList,
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ FILTER TABS
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(child: _buildFilterTab('Semua', _filterStatus == 'all', () {
                  setState(() => _filterStatus = 'all');
                })),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterTab('Menunggu', _filterStatus == 'pending', () {
                  setState(() => _filterStatus = 'pending');
                })),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterTab('Disetujui', _filterStatus == 'approved', () {
                  setState(() => _filterStatus = 'approved');
                })),
              ],
            ),
          ),

          // ✅ LIST DATA
          Expanded(
            child: _buildContent(),
          ),

          // ✅ BUBBLE TABS (Form & Riwayat)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _buildBubble(
                    'Form Penjemputan',
                    Icons.add_circle_outline,
                    _activeBubble == 'form',
                    () => _onBubbleTap('form'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBubble(
                    'Riwayat Penjemputan',
                    Icons.history,
                    _activeBubble == 'riwayat',
                    () => _onBubbleTap('riwayat'),
                  ),
                ),
              ],
            ),
          ),

          // ✅ BOTTOM NAVIGATION
          _buildBottomNav(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onBubbleTap('form'),
        backgroundColor: const Color(0xFF4CAF50),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Ajukan Penjemputan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ✅ HELPER: Filter Tab
  Widget _buildFilterTab(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4CAF50) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  // ✅ HELPER: Bubble
  Widget _buildBubble(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF81C784)])
              : null,
          color: isActive ? null : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.white : const Color(0xFF4CAF50)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF4CAF50),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ HELPER: Bottom Navigation
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'active': Icons.home, 'label': 'Beranda'},
      {'icon': Icons.qr_code_scanner, 'active': Icons.qr_code, 'label': 'Scan'},
      {'icon': Icons.delivery_dining_outlined, 'active': Icons.delivery_dining, 'label': 'Penjemputan'},
      {'icon': Icons.history_outlined, 'active': Icons.history, 'label': 'Riwayat'},
    ];

    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isActive = _selectedIndex == index;
          final item = items[index];

          return GestureDetector(
            onTap: () {
              if (index == 0) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeAdminScreen()),
                  (route) => false,
                );
              } else if (index == 1) {
                // Scan - tetap di halaman ini atau navigate
              } else if (index == 3) {
                // Riwayat - navigate ke riwayat admin
              }
              setState(() => _selectedIndex = index);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: isActive
                  ? BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(20))
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isActive ? item['active'] as IconData : item['icon'] as IconData,
                      color: isActive ? Colors.white : Colors.grey, size: 22),
                  if (isActive) const SizedBox(width: 6),
                  if (isActive)
                    Text(item['label'] as String,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ✅ HELPER: Build Content
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
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
              child: Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPenjemputanList,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50), foregroundColor: Colors.white),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    // Filter data berdasarkan status
    final filteredList = _filterStatus == 'all'
        ? _penjemputanList
        : _penjemputanList.where((item) {
            final status = (item['status'] ?? '').toString().toLowerCase();
            if (_filterStatus == 'pending') return status == 'diproses' || status == 'pending';
            if (_filterStatus == 'approved') return status == 'disetujui';
            if (_filterStatus == 'rejected') return status == 'ditolak';
            return true;
          }).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _filterStatus == 'all' ? 'Belum ada penjemputan' : 'Tidak ada penjemputan ${_filterStatus.toLowerCase()}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildPenjemputanCard(filteredList[index]),
    );
  }

  // ✅ CARD PENJEMPUTAN
  Widget _buildPenjemputanCard(Map<String, dynamic> item) {
    final String lokasi = item['lokasi'] ?? '-';
    final double berat = (item['berat'] ?? 0).toDouble();
    final String keterangan = item['keterangan'] ?? '-';
    final String status = item['status'] ?? 'diproses';
    final String waktu = _formatTanggal(item['waktu'] ?? item['created_at']);
    final String? fotoUrl = item['foto'];

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'disetujui':
        statusColor = Colors.green;
        statusText = 'Disetujui';
        statusIcon = Icons.check_circle;
        break;
      case 'ditolak':
        statusColor = Colors.red;
        statusText = 'Ditolak';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Diproses';
        statusIcon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Lokasi & Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.location_on, color: Color(0xFF2196F3), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lokasi Penjemputan', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                    const SizedBox(height: 2),
                    Text(lokasi, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(statusText.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Detail: Berat & Waktu
          _buildInfoRow('Estimasi Berat', '${berat.toStringAsFixed(1)} kg'),
          _buildInfoRow('Waktu Pengajuan', waktu),

          if (keterangan != '-' && keterangan.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.note, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(keterangan, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                ],
              ),
            ),
          ],

          // Foto (jika ada)
          if (fotoUrl != null && fotoUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                fotoUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          const Text(': ', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF1B5E20), fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  String _formatTanggal(String? tanggalStr) {
    if (tanggalStr == null || tanggalStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(tanggalStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return tanggalStr;
    }
  }
}