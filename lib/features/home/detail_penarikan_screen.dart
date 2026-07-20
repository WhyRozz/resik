import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class DetailPenarikanScreen extends StatefulWidget {
  final Map<String, dynamic>? penarikanData;

  const DetailPenarikanScreen({super.key, this.penarikanData});

  @override
  State<DetailPenarikanScreen> createState() => _DetailPenarikanScreenState();
}

class _DetailPenarikanScreenState extends State<DetailPenarikanScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _penarikanData;
  bool _isLoading = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String _formatWIBFromString(dynamic value) {
    if (value == null || value.toString().isEmpty) return '-';
    try {
      final String str = value.toString();
      DateTime dt;

      if (RegExp(r'^\d{2}-\d{2}-\d{4} \d{2}:\d{2}$').hasMatch(str)) {
        dt = DateFormat('dd-MM-yyyy HH:mm').parse(str);
      } else if (RegExp(
        r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$',
      ).hasMatch(str)) {
        dt = DateFormat('yyyy-MM-dd HH:mm:ss').parse(str);
      } else if (RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$').hasMatch(str)) {
        dt = DateFormat('yyyy-MM-dd HH:mm').parse(str);
      } else if (str.endsWith('Z')) {
        dt = DateTime.parse(str).add(const Duration(hours: 7));
      } else if (str.contains('T')) {
        dt = DateTime.parse(str);
      } else {
        dt = DateTime.parse(str);
      }

      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (e) {
      return value.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _loadPenarikanData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadPenarikanData() async {
    if (widget.penarikanData != null) {
      if (mounted) {
        setState(() {
          _penarikanData = widget.penarikanData;
          _isLoading = false;
        });
        _fadeController.forward();
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString('last_penarikan_detail');

    if (mounted) {
      if (dataStr != null) {
        final data = jsonDecode(dataStr);

        // PERBAIKAN: Cek nama dengan lebih ketat
        final namaDariData = data['nama']?.toString().trim();
        if (namaDariData == null ||
            namaDariData.isEmpty ||
            namaDariData.toLowerCase() == 'null' ||
            namaDariData == '-' ||
            namaDariData == 'User') {
          final userDataStr = prefs.getString('user_data');
          if (userDataStr != null) {
            try {
              final userData = jsonDecode(userDataStr);
              final namaUser = userData['nama']?.toString().trim();
              if (namaUser != null && namaUser.isNotEmpty) {
                data['nama'] = namaUser;
                debugPrint('✅ Fallback nama dari user_data: $namaUser');
              }
            } catch (e) {
              debugPrint('❌ Gagal parse user_data: $e');
            }
          }
        }

        setState(() {
          _penarikanData = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
      _fadeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
            ),
          ),
          child: const SafeArea(
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ),
      );
    }

    if (_penarikanData == null) {
      return _buildEmptyState();
    }

    final int idPenarikan =
        _penarikanData!['id_penarikan'] ?? _penarikanData!['id'] ?? 0;
    final String idTransaksi = '#TRX-${idPenarikan.toString().padLeft(5, '0')}';

    final String status = (_penarikanData!['status'] ?? 'Unknown').toString();
    final String tanggal = _formatWIBFromString(
      _penarikanData!['tanggal_penarikan'],
    );
    final String jenisEWallet = (_penarikanData!['jenis_ewallet'] ?? '-')
        .toString();
    final String nomorEWallet = (_penarikanData!['nomor_ewallet'] ?? '-')
        .toString();
    final double jumlahUang = (_penarikanData!['jumlah_uang'] ?? 0).toDouble();
    final String? alasanPenolakan = _penarikanData!['alasan_penolakan']
        ?.toString();
    final String? tanggalDisetujui = _penarikanData!['tanggal_disetujui']
        ?.toString();
    final String jenisLayanan = (_penarikanData!['jenis_layanan'] ?? 'e-wallet')
        .toString();
    final String namaBank = (_penarikanData!['nama_bank'] ?? '-').toString();

    // PERBAIKAN: Ambil nama dengan fallback ke user_data
    String nama = (_penarikanData!['nama_penerima'] ?? '').toString().trim();
    if (nama.isEmpty ||
        nama == '-' ||
        nama.toLowerCase() == 'null' ||
        nama == 'User') {
      // Fallback ke SharedPreferences
      SharedPreferences.getInstance().then((prefs) {
        final userDataStr = prefs.getString('user_data');
        if (userDataStr != null) {
          try {
            final userData = jsonDecode(userDataStr);
            nama = userData['nama']?.toString().trim() ?? 'User';
            if (mounted) setState(() {}); // Refresh UI
          } catch (e) {
            nama = 'User';
          }
        }
      });
    }

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status.toLowerCase()) {
      case 'berhasil':
        statusColor = const Color(0xFF2E7D32);
        statusIcon = Icons.check_circle_rounded;
        statusText = 'BERHASIL';
        break;
      case 'proses':
      case 'pending':
      case 'diproses':
        statusColor = const Color(0xFFEF6C00);
        statusIcon = Icons.schedule_rounded;
        statusText = 'DIPROSES';
        break;
      case 'ditolak':
        statusColor = const Color(0xFFC62828);
        statusIcon = Icons.cancel_rounded;
        statusText = 'DITOLAK';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = status.toUpperCase();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // ============ APPBAR ============
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
                child: Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Struk Penarikan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ============ STRUK CONTENT ============
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildReceiptCard(
                      idTransaksi: idTransaksi,
                      status: statusText,
                      statusColor: statusColor,
                      statusIcon: statusIcon,
                      tanggal: tanggal,
                      nama: nama,
                      jenisLayanan: jenisLayanan,
                      namaBank: namaBank,
                      jenisEWallet: jenisEWallet,
                      nomorEWallet: nomorEWallet,
                      jumlahUang: jumlahUang,
                      tanggalDisetujui: tanggalDisetujui,
                      alasanPenolakan: alasanPenolakan,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
                child: Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Struk Penarikan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      size: 60,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Data Tidak Tersedia',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard({
    required String idTransaksi,
    required String status,
    required Color statusColor,
    required IconData statusIcon,
    required String tanggal,
    required String nama,
    required String jenisLayanan,
    required String namaBank,
    required String jenisEWallet,
    required String nomorEWallet,
    required double jumlahUang,
    String? tanggalDisetujui,
    String? alasanPenolakan,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ===== HEADER STRUK =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [statusColor, statusColor.withOpacity(0.85)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Penarikan Saldo',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // ===== ZIGZAG EFFECT =====
          SizedBox(
            height: 12,
            child: Stack(
              children: [
                Positioned(
                  left: -8,
                  top: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F7FA),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: -8,
                  top: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F7FA),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Dashed line
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomPaint(
                      size: const Size(double.infinity, 1),
                      painter: DashedLinePainter(
                        color: Colors.grey.shade300,
                        dashWidth: 5,
                        dashSpace: 3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ===== BODY STRUK =====
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              children: [
                // ID Transaksi
                _buildReceiptRow(
                  label: 'ID Transaksi',
                  value: idTransaksi,
                  isMonospace: true,
                ),
                _buildDashedDivider(),
                _buildReceiptRow(label: 'Tanggal', value: tanggal),
                _buildDashedDivider(),
                _buildReceiptRow(label: 'Nama Penerima', value: nama),
                _buildDashedDivider(),
                _buildReceiptRow(
                  label: 'Metode',
                  value: jenisLayanan == 'bank' ? namaBank : jenisEWallet,
                ),
                _buildDashedDivider(),
                _buildReceiptRow(
                  label: jenisLayanan == 'bank'
                      ? 'No. Rekening'
                      : 'No. E-Wallet',
                  value: nomorEWallet,
                  isMonospace: true,
                ),
                if (tanggalDisetujui != null &&
                    tanggalDisetujui.isNotEmpty) ...[
                  _buildDashedDivider(),
                  _buildReceiptRow(
                    label: 'Disetujui',
                    value: _formatWIBFromString(tanggalDisetujui),
                  ),
                ],
              ],
            ),
          ),

          // ===== TOTAL AMOUNT =====
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'TOTAL PENARIKAN',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1B5E20),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatRupiah(jumlahUang),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // ===== ALASAN PENOLAKAN =====
          if (status == 'DITOLAK' &&
              alasanPenolakan != null &&
              alasanPenolakan.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFC62828).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Color(0xFFC62828),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Alasan Penolakan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC62828),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alasanPenolakan,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFC62828),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

          // ===== FOOTER STRUK =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 1),
                  painter: DashedLinePainter(
                    color: Colors.grey.shade300,
                    dashWidth: 5,
                    dashSpace: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.eco_rounded,
                      size: 14,
                      color: const Color(0xFF4CAF50),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'RESIK - Bank Sampah Digital',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Terima kasih telah menggunakan layanan kami',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[400],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow({
    required String label,
    required String value,
    bool isMonospace = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(':  ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B5E20),
                fontFamily: isMonospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: CustomPaint(
        size: const Size(double.infinity, 1),
        painter: DashedLinePainter(
          color: Colors.grey.shade200,
          dashWidth: 3,
          dashSpace: 3,
        ),
      ),
    );
  }

  String _formatRupiah(double angka) {
    return 'Rp ${angka.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }
}

// ===== PAINTER UNTUK DASHED LINE =====
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    required this.color,
    this.dashWidth = 5,
    this.dashSpace = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
