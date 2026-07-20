import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'home_user_screen.dart';
import 'laporan_screen.dart';
import 'riwayat_penarikan_screen.dart';
import 'info_tps_screen.dart';
import 'dart:async';

class RiwayatSetorScreen extends StatefulWidget {
  final int? highlightId;

  const RiwayatSetorScreen({super.key, this.highlightId});

  @override
  State<RiwayatSetorScreen> createState() => _RiwayatSetorScreenState();
}

class _RiwayatSetorScreenState extends State<RiwayatSetorScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _setorData = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filterStatus = 'all';

  int? _highlightedId;
  Timer? _highlightTimer;
  final ScrollController _scrollController = ScrollController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  double _parseToDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
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
    _fadeController.forward();

    _fetchRiwayatSetor();

    if (widget.highlightId != null) {
      _highlightedId = widget.highlightId;
    }
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await _fetchRiwayatSetor();
  }

  Future<void> _fetchRiwayatSetor() async {
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

      final uri = Uri.parse(ApiConfig.riwayatSetorIndex).replace(
        queryParameters: {
          'id_masyarakat': userType == 'masyarakat' ? userId.toString() : null,
          'id_pns': userType == 'pns' ? userId.toString() : null,
          'tipe_user': userType,
        },
      );

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      final result = jsonDecode(response.body);

      if (mounted) {
        if (response.statusCode == 200 && result['status'] == 'success') {
          setState(() {
            _setorData = result['data'] ?? [];
            _isLoading = false;
          });

          if (_highlightedId != null && _setorData.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _scrollToHighlightedItem();
              }
            });
          }
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

  void _scrollToHighlightedItem() {
    if (_highlightedId == null) return;

    final index = _setorData.indexWhere(
      (item) => item['id_transaksi'] == _highlightedId,
    );

    if (index != -1 && _scrollController.hasClients) {
      final offset = (index * 200.0).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );

      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
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
                    // Icon kembali
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
                    // ✅ ICON RECYCLING DI KIRI (PINDAH KE SINI)
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
                        Icons.recycling_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Text di tengah
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Riwayat Setor',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Semua transaksi setoran sampah',
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
                    icon: Icons.calendar_today_rounded,
                    label: '7 Hari',
                    isActive: _filterStatus == '7days',
                    onTap: () => setState(() => _filterStatus = '7days'),
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
                    true,
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
                    onPressed: _fetchRiwayatSetor,
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

    final filteredData = _filterStatus == '7days'
        ? _setorData.where((item) {
            final tanggal = DateTime.tryParse(item['tanggal_transaksi'] ?? '');
            if (tanggal == null) return false;
            return DateTime.now().difference(tanggal).inDays <= 7;
          }).toList()
        : _setorData;

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
                      Icons.recycling_rounded,
                      size: 60,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _filterStatus == '7days'
                        ? 'Tidak ada transaksi'
                        : 'Belum ada riwayat setor',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _filterStatus == '7days'
                        ? 'dalam 7 hari terakhir'
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

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        final item = filteredData[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSetorCard(item),
        );
      },
    );
  }

  Widget _buildSetorCard(Map<String, dynamic> data) {
    final tanggal = _formatTanggal(data['tanggal_transaksi']);
    final jenisSampah = data['jenis_sampah'] ?? 'Umum';

    final berat = _parseToDouble(data['berat'], 0.0);
    final hargaPerKg = _parseToDouble(data['harga_per_kg'], 0.0);
    final totalRupiah = _parseToDouble(data['total_rupiah'], 0.0);

    // AMBIL DATA PETUGAS & WILAYAH (Fallback aman jika struktur JSON berbeda)
    final petugasData = data['petugas'] ?? {};
    final namaPetugas =
        petugasData['nama_lengkap'] ?? data['nama_petugas'] ?? '-';
    final namaWilayah =
        petugasData['nama_wilayah'] ?? data['nama_wilayah'] ?? '';

    // GABUNGKAN NAMA DAN WILAYAH JIKA WILAYAH ADA
    final displayPetugas = (namaWilayah.isNotEmpty && namaWilayah != '-')
        ? '$namaPetugas - $namaWilayah'
        : namaPetugas;

    final status = (data['status'] ?? 'selesai').toString().toLowerCase();

    final isHighlighted =
        _highlightedId != null && data['id_transaksi'] == _highlightedId;

    Color statusColor;
    Color statusBgColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'selesai':
        statusColor = const Color(0xFF2E7D32);
        statusBgColor = const Color(0xFFE8F5E9);
        statusText = 'SELESAI';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'pending':
        statusColor = const Color(0xFFEF6C00);
        statusBgColor = const Color(0xFFFFF3E0);
        statusText = 'PENDING';
        statusIcon = Icons.schedule_rounded;
        break;
      case 'ditolak':
        statusColor = const Color(0xFFC62828);
        statusBgColor = const Color(0xFFFFEBEE);
        statusText = 'DITOLAK';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = const Color(0xFF2E7D32);
        statusBgColor = const Color(0xFFE8F5E9);
        statusText = 'SELESAI';
        statusIcon = Icons.check_circle_rounded;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted
            ? Border.all(color: const Color(0xFFFFA000), width: 3)
            : Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? const Color(0xFFFFA000).withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: isHighlighted ? 16 : 10,
            offset: Offset(0, isHighlighted ? 4 : 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge "BARU DITERIMA" untuk item yang di-highlight
          if (isHighlighted)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFA000), Color(0xFFFF6F00)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFA000).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'BARU DITERIMA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

          // Header: Icon + Info + Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.recycling_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Setoran Sampah',
                      style: TextStyle(
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
                _buildInfoRow(
                  'Jenis Sampah',
                  jenisSampah,
                  Icons.category_rounded,
                ),
                const Divider(height: 16, color: Color(0xFFE8F5E9)),
                _buildInfoRow(
                  'Berat',
                  '${berat.toStringAsFixed(1)} kg',
                  Icons.scale_rounded,
                ),
                const Divider(height: 16, color: Color(0xFFE8F5E9)),
                _buildInfoRow(
                  'Harga/Kg',
                  _formatRupiah(hargaPerKg),
                  Icons.attach_money_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Footer: Total Harga + Petugas
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
            child: Column(
              // ✅ 1. UBAH DARI Row MENJADI Column
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bagian 1: Total Harga
                const Text(
                  'Total Harga',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1B5E20),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatRupiah(totalRupiah),
                  style: const TextStyle(
                    fontSize: 16, // ✅ 2. DIPERBESAR SEDIKIT AGAR LEBIH MENONJOL
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(
                  height: 1,
                  color: Color(0xFFC8E6C9),
                ), // ✅ 3. TAMBAH GARIS PEMISAH
                const SizedBox(height: 10),

                // Bagian 2: Info Petugas
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE3F2FD),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 12,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      // ✅ 4. GUNAKAN Expanded AGAR TIDAK MELUBER KE LUAR
                      child: Text(
                        displayPetugas,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2196F3),
                        ),
                        maxLines: 2, // ✅ 5. BATASI MAKSIMAL 2 BARIS
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
          width: 90,
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

  String _formatTanggal(String? tanggalStr) {
    if (tanggalStr == null || tanggalStr.isEmpty) return '-';
    try {
      DateTime dt = DateTime.parse(tanggalStr);

      // KONVERSI UTC KE WIB (UTC+7)
      if (tanggalStr.endsWith('Z') || tanggalStr.contains('+00:00')) {
        dt = dt.toLocal(); // Otomatis convert ke timezone lokal
      }

      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return tanggalStr;
    }
  }
}
