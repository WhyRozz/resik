import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'detail_penarikan_screen.dart';
import 'riwayat_setor_screen.dart';
import 'home_user_screen.dart';
import 'laporan_screen.dart';
import 'info_tps_screen.dart';
import 'package:intl/intl.dart';

class RiwayatPenarikanScreen extends StatefulWidget {
  const RiwayatPenarikanScreen({super.key});

  @override
  State<RiwayatPenarikanScreen> createState() => _RiwayatPenarikanScreenState();
}

class _RiwayatPenarikanScreenState extends State<RiwayatPenarikanScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _riwayatData = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filterStatus = 'all';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
    _fadeController.forward();
    _fetchRiwayatPenarikan();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ✅ FORMAT WIB LANGSUNG - TANPA KONVERSI!
  String _formatWIBFromString(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return '-';
    }

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

  Future<void> _handleRefresh() async {
    await _fetchRiwayatPenarikan();
  }

  Future<void> _fetchRiwayatPenarikan() async {
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

      final response = await http
          .get(
            Uri.parse(ApiConfig.penarikanIndex).replace(
              queryParameters: {
                'id_masyarakat': userType == 'masyarakat'
                    ? userId.toString()
                    : null,
                'id_pns': userType == 'pns' ? userId.toString() : null,
                'tipe_user': userType,
              },
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      final result = jsonDecode(response.body);

      if (mounted) {
        if (response.statusCode == 200 && result['status'] == 'success') {
          setState(() {
            _riwayatData = result['data'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Gagal memuat data';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Koneksi error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // ============ CUSTOM APPBAR ============
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Riwayat Penarikan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Semua transaksi penarikan saldo',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ============ FILTER TABS ============
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterTab(
                    icon: Icons.list_alt_rounded,
                    label: 'Semua',
                    isActive: _filterStatus == 'all',
                    onTap: () => setState(() => _filterStatus = 'all'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFilterTab(
                    icon: Icons.schedule_rounded,
                    label: 'Diproses',
                    isActive: _filterStatus == 'proses',
                    onTap: () => setState(() => _filterStatus = 'proses'),
                  ),
                ),
              ],
            ),
          ),

          // ============ LIST DATA ============
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: const Color(0xFF4CAF50),
              backgroundColor: Colors.white,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildContent(),
              ),
            ),
          ),

          // ============ BUBBLE TABS ============
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _buildBubble(
                    'Riwayat Setor',
                    Icons.upload_rounded,
                    false,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RiwayatSetorScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBubble(
                    'Riwayat Penarikan',
                    Icons.download_rounded,
                    true,
                    () {},
                  ),
                ),
              ],
            ),
          ),

          // ============ BOTTOM NAV ============
          _buildConsistentBottomNav(context),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                )
              : null,
          color: isActive ? null : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: isActive ? null : Border.all(color: Colors.grey.shade200),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
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
              size: 16,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
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
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    blurRadius: 6,
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
                overflow: TextOverflow.ellipsis,
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
          final isActive = index == 2;
          final item = items[index];

          return GestureDetector(
            onTap: () {
              if (index == 0) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeUserScreen()),
                  (route) => false,
                );
              } else if (index == 1) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LaporanScreen()),
                  (route) => false,
                );
              } else if (index == 3) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const InfoTpsScreen()),
                  (route) => false,
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: isActive
                  ? const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
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

  Widget _buildContent() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 300,
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                      color: Colors.red.withOpacity(0.1),
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
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _fetchRiwayatPenarikan,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final filteredData = _filterStatus == 'proses'
        ? _riwayatData.where((item) {
            final status = (item['status'] ?? '')
                .toString()
                .toLowerCase()
                .trim();
            return status == 'diproses';
          }).toList()
        : _riwayatData;

    if (filteredData.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4CAF50).withOpacity(0.1),
                          const Color(0xFF81C784).withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 60,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _filterStatus == 'proses'
                        ? 'Tidak ada penarikan diproses'
                        : 'Belum ada riwayat penarikan',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _filterStatus == 'proses'
                        ? 'Semua penarikan sudah selesai'
                        : 'Tarik ke bawah untuk refresh',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: filteredData.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final data = filteredData[index];
        return _buildPenarikanCard(data);
      },
    );
  }

  Widget _buildPenarikanCard(Map<String, dynamic> data) {
    final String status = (data['status'] ?? 'Unknown').toString();
    final String tanggal = _formatWIBFromString(data['tanggal_penarikan']);
    final String namaPenerima = (data['nama_penerima'] ?? data['nama'] ?? '-')
        .toString();
    final String jenisEWallet = (data['jenis_ewallet'] ?? '-').toString();
    final String nomorEWallet = (data['nomor_ewallet'] ?? '-').toString();
    final double jumlahUang = (data['jumlah_uang'] ?? 0).toDouble();
    final String? alasanPenolakan = data['alasan_penolakan']?.toString();
    final String jenisLayanan = (data['jenis_layanan'] ?? 'e-wallet')
        .toString();
    final String namaBank = (data['nama_bank'] ?? '').toString();

    final statusLower = status.toLowerCase().trim();

    Color statusColor;
    Color statusBgColor;
    String statusText;
    IconData statusIcon;

    switch (statusLower) {
      case 'diproses':
        statusColor = const Color(0xFFEF6C00);
        statusBgColor = const Color(0xFFFFF3E0);
        statusText = 'DIPROSES';
        statusIcon = Icons.schedule_rounded;
        break;
      case 'berhasil':
        statusColor = const Color(0xFF2E7D32);
        statusBgColor = const Color(0xFFE8F5E9);
        statusText = 'BERHASIL';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'ditolak':
        statusColor = const Color(0xFFC62828);
        statusBgColor = const Color(0xFFFFEBEE);
        statusText = 'DITOLAK';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.shade100;
        statusText = status.toUpperCase();
        statusIcon = Icons.help_outline;
    }

    return GestureDetector(
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_penarikan_detail', jsonEncode(data));
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DetailPenarikanScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100, width: 1),
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
            // Header: Icon + Info + Status
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
                  child: Icon(
                    jenisLayanan == 'bank'
                        ? Icons.account_balance_rounded
                        : Icons.account_balance_wallet_rounded,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Penarikan Saldo',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 10,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tanggal,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
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
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Detail Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FBF9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  // ✅ TAMBAHKAN BARIS NAMA PENERIMA DI SINI
                  _buildInfoRow(
                    'Penerima',
                    namaPenerima,
                    Icons.person_outline_rounded,
                  ),
                  const Divider(height: 16, color: Color(0xFFE8F5E9)),
                  _buildInfoRow(
                    'Metode',
                    jenisLayanan == 'bank' ? namaBank : jenisEWallet,
                    Icons.payment_rounded,
                  ),
                  const Divider(height: 16, color: Color(0xFFE8F5E9)),
                  _buildInfoRow(
                    'Nomor',
                    jenisLayanan == 'bank'
                        ? 'Rek: $nomorEWallet'
                        : 'No: $nomorEWallet',
                    Icons.tag_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Footer: Jumlah Penarikan
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE8F5E9),
                    const Color(0xFFE8F5E9).withOpacity(0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jumlah Penarikan',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRupiah(jumlahUang),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),

            // Alasan Penolakan (jika ada)
            if (statusLower == 'ditolak' &&
                alasanPenolakan != null &&
                alasanPenolakan.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
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
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFC62828),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Alasan Penolakan',
                          style: TextStyle(
                            fontSize: 11,
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
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
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
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 11, color: Colors.grey)),
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

  String _formatRupiah(double angka) {
    return 'Rp ${angka.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }
}
