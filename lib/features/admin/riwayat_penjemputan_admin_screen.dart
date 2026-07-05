import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:resik/features/admin/qr_barcode_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import 'home_admin_screen.dart';
import 'form_penjemputan_screen.dart';
import 'riwayat_setor_admin_screen.dart';

class RiwayatPenjemputanAdminScreen extends StatefulWidget {
  const RiwayatPenjemputanAdminScreen({super.key});

  @override
  State<RiwayatPenjemputanAdminScreen> createState() =>
      _RiwayatPenjemputanAdminScreenState();
}

class _RiwayatPenjemputanAdminScreenState
    extends State<RiwayatPenjemputanAdminScreen> {
  List<dynamic> _riwayatPenjemputan = [];
  bool _isLoading = true;
  int _selectedIndex = 3;
  String _activeBubble = 'penjemputan';

  @override
  void initState() {
    super.initState();
    _fetchRiwayatPenjemputan();
  }

  Future<void> _handleRefresh() async {
    await _fetchRiwayatPenjemputan();
  }

  Future<void> _fetchRiwayatPenjemputan() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminData = jsonDecode(prefs.getString('user_data') ?? '{}');
      final adminId = adminData['id_petugas'];

      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/riwayat-penjemputan-admin/$adminId',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          if (result['status'] == 'success') {
            setState(() {
              _riwayatPenjemputan = result['data'] ?? [];
              _isLoading = false;
            });
          }
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ FUNGSI ZOOM FOTO
  void _showImagePopup(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
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
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(dialogContext),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
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
          'Riwayat Admin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // ✅ BUBBLE TABS
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildBubble(
                    'Riwayat Setor',
                    Icons.upload_rounded,
                    _activeBubble == 'setor',
                    () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RiwayatSetorAdminScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBubble(
                    'Riwayat Penjemputan',
                    Icons.local_shipping,
                    _activeBubble == 'penjemputan',
                    () {
                      setState(() => _activeBubble = 'penjemputan');
                    },
                  ),
                ),
              ],
            ),
          ),

          // ✅ CONTENT
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: const Color(0xFF4CAF50),
              backgroundColor: Colors.white,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _riwayatPenjemputan.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_shipping,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada riwayat penjemputan',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _riwayatPenjemputan.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _buildPenjemputanCard(_riwayatPenjemputan[index]),
                    ),
            ),
          ),

          // ✅ BOTTOM NAVIGATION
          _buildBottomNav(),
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                )
              : null,
          color: isActive ? null : const Color(0xFFE8F5E9),
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
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF4CAF50),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ CARD PENJEMPUTAN - DESAIN MODERN
  Widget _buildPenjemputanCard(Map<String, dynamic> item) {
    final String status = (item['status'] ?? 'diproses')
        .toString()
        .toLowerCase();
    final berat = (item['berat'] ?? 0).toDouble();
    final String? fotoUrl = item['foto'];
    final String lokasi = item['lokasi'] ?? '-';
    final String waktu = item['waktu'] ?? '-';
    final String keterangan = item['keterangan']?.toString() ?? '';

    // Status config
    Color statusColor;
    String statusText;
    IconData statusIcon;
    Color statusBgColor;

    switch (status) {
      case 'disetujui':
        statusColor = const Color(0xFF2E7D32);
        statusText = 'Disetujui';
        statusIcon = Icons.check_circle_outline;
        statusBgColor = const Color(0xFFE8F5E9);
        break;
      case 'ditolak':
        statusColor = const Color(0xFFC62828);
        statusText = 'Ditolak';
        statusIcon = Icons.cancel_outlined;
        statusBgColor = const Color(0xFFFFEBEE);
        break;
      default:
        statusColor = const Color(0xFFEF6C00);
        statusText = 'Diproses';
        statusIcon = Icons.pending_actions;
        statusBgColor = const Color(0xFFFFF3E0);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ FOTO (BISA DI-TAP UNTUK ZOOM)
          if (fotoUrl != null && fotoUrl.isNotEmpty) ...[
            GestureDetector(
              onTap: () => _showImagePopup(context, fotoUrl),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      fotoUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Badge Zoom
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.zoom_in_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ✅ HEADER CARD
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: Color(0xFF1976D2),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Penjemputan Sampah',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              waktu,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(color: Colors.grey.shade200, height: 1, thickness: 1),

          // ✅ INFO SECTION
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.location_on_outlined,
                  'Lokasi',
                  lokasi,
                  color: const Color(0xFF1976D2),
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  Icons.scale_outlined,
                  'Berat',
                  '${berat.toStringAsFixed(1)} kg',
                  color: const Color(0xFF7B1FA2),
                ),
                if (keterangan.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    Icons.notes_rounded,
                    'Keterangan',
                    keterangan,
                    color: const Color(0xFF455A64),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ INFO ROW DENGAN ICON
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color color = const Color(0xFF1B5E20),
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'active': Icons.home, 'label': 'Beranda'},
      {'icon': Icons.qr_code_scanner, 'active': Icons.qr_code, 'label': 'Scan'},
      {
        'icon': Icons.local_shipping,
        'active': Icons.local_shipping,
        'label': 'Penjemputan',
      },
      {
        'icon': Icons.history_outlined,
        'active': Icons.history,
        'label': 'Riwayat',
      },
    ];

    return Container(
      height: 65,
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrBarcodeScreen()),
                );
              } else if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FormPenjemputanScreen(),
                  ),
                );
              }
              setState(() => _selectedIndex = index);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: isActive
                  ? BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(20),
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
                  if (isActive) const SizedBox(width: 6),
                  if (isActive)
                    Text(
                      item['label'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
