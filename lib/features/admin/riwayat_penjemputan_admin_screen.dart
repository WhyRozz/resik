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
  final String? highlightId;

  const RiwayatPenjemputanAdminScreen({super.key, this.highlightId});

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
  String? _highlightedItemId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchRiwayatPenjemputan();

    // Set highlight jika ada ID
    if (widget.highlightId != null) {
      _highlightedItemId = widget.highlightId;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Auto scroll ke item yang di-highlight
  void _scrollToHighlighted() {
    if (_highlightedItemId == null || _riwayatPenjemputan.isEmpty) return;

    // Cari index item yang di-highlight
    final index = _riwayatPenjemputan.indexWhere(
      (item) => item['id'].toString() == _highlightedItemId,
    );

    if (index != -1 && _scrollController.hasClients) {
      // Hitung posisi scroll (estimasi tinggi per item)
      final itemHeight = 350.0; // Estimasi tinggi card

      // ✅ RUMUS SEDERHANA - item muncul di ATAS layar
      final scrollPosition = index * itemHeight;

      _scrollController.animateTo(
        scrollPosition.clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
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

            // Auto scroll setelah data load
            if (_highlightedItemId != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToHighlighted();
              });
            }
          }
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
              top: MediaQuery.of(dialogContext).padding.top + 16,
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF2E7D32),
              size: 16,
            ),
          ),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeAdminScreen()),
            (route) => false,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Riwayat Penjemputan',
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
          // BUBBLE TABS
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
                    Icons.local_shipping_rounded,
                    _activeBubble == 'penjemputan',
                    () {
                      setState(() => _activeBubble = 'penjemputan');
                    },
                  ),
                ),
              ],
            ),
          ),

          // CONTENT
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: const Color(0xFF2E7D32),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                      ),
                    )
                  : _riwayatPenjemputan.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height - 300,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.local_shipping_rounded,
                                    size: 60,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada riwayat penjemputan',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tarik ke bawah untuk refresh',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _riwayatPenjemputan.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _buildPenjemputanCard(_riwayatPenjemputan[index]),
                    ),
            ),
          ),

          // BOTTOM NAV
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
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                )
              : null,
          color: isActive ? null : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
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
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF2E7D32),
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

  Widget _buildPenjemputanCard(Map<String, dynamic> item) {
    final String status = (item['status'] ?? 'diproses')
        .toString()
        .toLowerCase();
    final double berat = (item['berat'] ?? 0).toDouble();
    String? fotoUrl = item['foto'];
    if (fotoUrl != null && !fotoUrl.startsWith('http')) {
      fotoUrl = '${ApiConfig.storageUrl}/$fotoUrl';
    }
    final String lokasi = item['lokasi'] ?? '-';
    final String waktu = _formatTanggal(item['waktu'] ?? item['created_at']);
    final String keterangan = item['keterangan']?.toString() ?? '';

    // ✅ CEK APAKAH ITEM INI DI-HIGHLIGHT
    final isHighlighted =
        _highlightedItemId != null &&
        item['id'].toString() == _highlightedItemId;

    Color statusColor;
    String statusText;
    IconData statusIcon;
    Color statusBgColor;

    switch (status) {
      case 'disetujui':
        statusColor = const Color(0xFF2E7D32);
        statusBgColor = const Color(0xFFE8F5E9);
        statusText = 'DISETUJUI';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'ditolak':
        statusColor = Colors.red.shade700;
        statusBgColor = Colors.red.shade50;
        statusText = 'DITOLAK';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.orange.shade700;
        statusBgColor = Colors.orange.shade50;
        statusText = 'DIPROSES';
        statusIcon = Icons.schedule_rounded;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ✅ HIGHLIGHT BACKGROUND
        color: isHighlighted
            ? const Color(0xFFFFF9C4) // Kuning muda
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFFFFA000) // Border kuning/oranye
              : (status == 'diproses'
                    ? Colors.orange.withOpacity(0.3)
                    : Colors.grey.shade200),
          width: isHighlighted ? 3 : (status == 'diproses' ? 1.5 : 1),
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? const Color(0xFFFFA000).withOpacity(0.3)
                : Colors.black.withOpacity(0.04),
            blurRadius: isHighlighted ? 16 : 10,
            offset: Offset(0, isHighlighted ? 4 : 2), // ✅ HAPUS const
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ BADGE "DITUNJUKKAN" UNTUK ITEM YANG DI-HIGHLIGHT
          if (isHighlighted)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFA000), Color(0xFFFFC107)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_downward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'DITUNJUKKAN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          // FOTO
          if (fotoUrl != null && fotoUrl.isNotEmpty) ...[
            GestureDetector(
              onTap: () => _showImagePopup(context, fotoUrl!),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      fotoUrl!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
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
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // HEADER
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withOpacity(0.2),
                      statusColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Penjemputan Sampah',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      waktu,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 12),

          // LOKASI
          _buildInfoRow('Lokasi', lokasi, Icons.location_on_rounded),

          // BERAT
          _buildInfoRow('Berat', _formatBerat(berat), Icons.scale_rounded),

          // KETERANGAN
          if (keterangan.isNotEmpty)
            _buildInfoRow('Keterangan', keterangan, Icons.note_alt_rounded),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 12, color: const Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
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

  // FORMAT TANGGAL: dd/mm/yyyy HH:MM dengan konversi UTC ke WIB
  String _formatTanggal(String? tanggalStr) {
    if (tanggalStr == null || tanggalStr.isEmpty) return '-';

    try {
      DateTime dt;

      if (tanggalStr.endsWith('Z')) {
        dt = DateTime.parse(tanggalStr);
        dt = dt.add(const Duration(hours: 7));
      } else {
        dt = DateTime.parse(tanggalStr);
      }

      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return tanggalStr;
    }
  }

  // FORMAT BERAT TANPA .0
  String _formatBerat(double berat) {
    if (berat == berat.toInt()) {
      return '${berat.toInt()} kg';
    }
    return '${berat.toStringAsFixed(1)} kg';
  }
}
