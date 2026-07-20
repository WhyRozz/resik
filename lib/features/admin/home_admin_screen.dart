import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'qr_barcode_screen.dart';
import '../home/artikel_detail_screen.dart';
import '../home/artikel_list_screen.dart';
import 'form_penjemputan_screen.dart';
import '../shared/jenis_sampah_list_screen.dart';
import 'riwayat_setor_admin_screen.dart';
import 'riwayat_penjemputan_admin_screen.dart';
import '../auth/login/login_screen.dart';
import 'notification_list_screen_admin.dart';

import 'package:provider/provider.dart';
import '../../providers/statistik_provider.dart';

class HomeAdminScreen extends StatefulWidget {
  const HomeAdminScreen({super.key});

  @override
  State<HomeAdminScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeAdminScreen> {
  int _selectedIndex = 0;
  String? _activeRiwayatBubble;
  Map<String, dynamic>? _adminData;
  List<dynamic> _artikelList = [];
  bool _isLoadingArtikel = true;
  Map<String, dynamic> _statsData = {};
  bool _isLoadingStats = true;
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
    _fetchArtikel();
    _fetchStatistik();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatistikProvider>().fetchStatistik();
    });
  }

  // HANDLE REFRESH (PULL TO REFRESH)
  Future<void> _handleRefresh() async {
    await Future.wait([
      _fetchArtikel(),
      _fetchStatistik(),
      _fetchNotificationCount(),
      context.read<StatistikProvider>().fetchStatistik(),
    ]);
  }

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null && mounted) {
      setState(() => _adminData = jsonDecode(userData));

      // Fetch badge SETELAH _adminData terisi
      _fetchNotificationCount();
    }
  }

  Future<void> _fetchArtikel() async {
    setState(() => _isLoadingArtikel = true);
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.artikel))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 && mounted) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            _artikelList = result['data'] ?? [];
            _isLoadingArtikel = false;
          });
        } else {
          setState(() => _isLoadingArtikel = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingArtikel = false);
    }
  }

  // ✅ FETCH STATISTIK
  Future<void> _fetchStatistik() async {
    if (_adminData == null) return;

    setState(() => _isLoadingStats = true);
    try {
      final adminId = _adminData!['id_petugas'];
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/setor-statistics/$adminId'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && mounted) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            _statsData = result['data'] ?? {};
            _isLoadingStats = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _fetchNotificationCount() async {
    if (_adminData == null) {
      debugPrint("⚠️ _fetchNotificationCount: _adminData masih null!");
      return;
    }

    try {
      final userId = _adminData!['id_petugas'].toString();
      final uri = Uri.parse(
        ApiConfig.baseUrl + '/notifications/unread-count',
      ).replace(queryParameters: {'user_id': userId, 'tipe': 'petugas'});

      debugPrint('🔔 Fetching notif count... userId=$userId');

      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📄 Response: ${response.body}');

      if (response.statusCode == 200 && mounted) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          final count = result['data']['unread_count'] ?? 0;
          debugPrint('✅ Unread count: $count');
          setState(() {
            _notificationCount = count;
          });
        } else {
          debugPrint('❌ Status bukan success: ${result['status']}');
        }
      } else {
        debugPrint('❌ HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error notif count: $e');
    }
  }

  // LOGOUT FUNCTION
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Container dengan Gradient
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5252).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Keluar dari Akun?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Apakah Anda yakin ingin keluar dari sesi petugas?',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  // Tombol Batal
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4CAF50),
                        side: const BorderSide(
                          color: Color(0xFF4CAF50),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Tombol Keluar
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5252),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFFFF5252).withOpacity(0.4),
                      ),
                      child: const Text(
                        'Keluar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 3 && _activeRiwayatBubble == null) {
        _activeRiwayatBubble = 'setor';
      }
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QrBarcodeScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FormPenjemputanScreen()),
      ).then((result) {
        if (result == true) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildHomeContent(),
      bottomNavigationBar: _buildConsistentBottomNavWithBubbles(),
    );
  }

  Widget _buildConsistentBottomNavWithBubbles() {
    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: _selectedIndex == 3
                ? Container(
                    key: const ValueKey<String>('riwayat_bubbles'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: _buildRiwayatBubbles(),
                  )
                : const SizedBox.shrink(),
          ),
          _buildNavItems(),
        ],
      ),
    );
  }

  Widget _buildRiwayatBubbles() {
    return Row(
      children: [
        Expanded(
          child: _buildBubble(
            'Riwayat Setor',
            Icons.upload_rounded,
            _activeRiwayatBubble == 'setor',
            () {
              setState(() => _activeRiwayatBubble = 'setor');
              Navigator.push(
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
            _activeRiwayatBubble == 'penjemputan',
            () {
              setState(() => _activeRiwayatBubble = 'penjemputan');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RiwayatPenjemputanAdminScreen(),
                ),
              );
            },
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
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
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItems() {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isActive = _selectedIndex == index;
          final item = items[index];
          return GestureDetector(
            onTap: () => _onNavTap(index),
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

  Widget _buildHomeContent() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: Colors.white,
                backgroundColor: const Color(0xFF2E7D32),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HEADER - TANPA NAVIGASI PROFILE, TOMBOL LOGOUT
  Widget _buildHeader() {
    final nama = _adminData?['nama_lengkap'] ?? 'Admin';
    final foto = _adminData?['foto'];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            backgroundImage: (foto != null && foto.toString().isNotEmpty)
                ? NetworkImage(foto)
                : null,
            child: (foto == null || foto.toString().isEmpty)
                ? const Icon(Icons.person, size: 40, color: Color(0xFF1B5E20))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Petugas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  nama,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_adminData?['nama_wilayah'] != null)
                  Text(
                    _adminData!['nama_wilayah'].toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ✅ ICON NOTIFIKASI DENGAN BADGE (POLA DARI USER SCREEN - PROVEN WORKS!)
          Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationListScreenAdmin(),
                    ),
                  ).then((_) {
                    // ✅ Refresh badge setelah kembali dari notifikasi
                    if (mounted) _fetchNotificationCount();
                  });
                },
                borderRadius: BorderRadius.circular(30),
                child: Padding(
                  padding: const EdgeInsets.all(8), // ✅ Area tap lebih besar
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: IgnorePointer(
                    // ✅ KUNCI! Badge tidak menghalangi klik!
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        _notificationCount > 99 ? '99+' : '$_notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // TOMBOL LOGOUT
          InkWell(
            onTap: _handleLogout,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STATISTIK SECTION (Langsung di paling atas - Clean!)
            _buildStatistikSection(),
            const SizedBox(height: 24),

            // Artikel Edukasi
            _buildSectionTitle(
              'Artikel Edukasi',
              onViewAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArtikelListScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _isLoadingArtikel
                ? const Center(child: CircularProgressIndicator())
                : _artikelList.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada artikel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : _buildArtikelList(),
            const SizedBox(height: 24),

            // Jenis Sampah
            _buildSectionTitle(
              'Jenis Sampah',
              onViewAll: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const JenisSampahListScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildJenisSampahGrid(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistikSection() {
    return Consumer<StatistikProvider>(
      builder: (context, provider, child) {
        final stats = provider.statistik;

        if (provider.isLoading) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF2196F3)),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE8F5E9),
                Color(0xFFC8E6C9),
                Color(0xFFA5D6A7),
              ], // ← BIRU
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.15), // ← HIJAU
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.date_range_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Statistik 7 Hari Terakhir',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // TAMBAH: Info periode
              if (stats['periode'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Periode: ${stats['periode']['dari']} - ${stats['periode']['sampai']}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              // Grid 2x2
              Row(
                children: [
                  Expanded(
                    child: _buildModernStatCard(
                      '${stats['hari_ini'] ?? 0}',
                      'Transaksi',
                      Icons.receipt_long_rounded,
                      const Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernStatCard(
                      '${stats['selesai'] ?? 0}',
                      'Selesai',
                      Icons.check_circle_outline_rounded,
                      const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildModernStatCard(
                      '${stats['pending'] ?? 0}',
                      'Pending',
                      Icons.access_time_rounded,
                      const Color(0xFFFF9800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernStatCard(
                      '${stats['dibatalkan'] ?? 0}',
                      'Dibatalkan',
                      Icons.cancel_rounded,
                      const Color(0xFFF44336),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Total Nominal & Berat
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTotalItem(
                        'Total Nominal',
                        _formatRupiah(stats['total_nominal_hari_ini'] ?? 0),
                        Icons.attach_money_rounded,
                        const Color(0xFF2E7D32),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: _buildTotalItem(
                        'Total Berat',
                        '${(stats['total_berat_hari_ini'] ?? 0).toStringAsFixed(1)} kg',
                        Icons.scale_rounded,
                        const Color(0xFF7B1FA2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onViewAll}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1B5E20),
        ),
      ),
      TextButton(
        onPressed: onViewAll,
        child: const Text(
          'Lihat Semua',
          style: TextStyle(color: Color(0xFF4CAF50)),
        ),
      ),
    ],
  );

  Widget _buildArtikelList() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _artikelList.length,
        itemBuilder: (context, index) {
          final artikel = _artikelList[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArtikelDetailScreen(
                  artikel: artikel as Map<String, dynamic>,
                ),
              ),
            ),
            child: Container(
              width: 250,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      ApiConfig.imageUrl(artikel['foto']),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(height: 120, color: Colors.grey.shade200),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      artikel['judul'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildJenisSampahGrid() => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 4,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 0.8,
    children: [
      _buildJenisSampahItem('Plastik', Icons.local_drink),
      _buildJenisSampahItem('Kertas', Icons.description),
      _buildJenisSampahItem('Logam', Icons.build),
      _buildJenisSampahItem('Minyak', Icons.opacity),
    ],
  );

  Widget _buildJenisSampahItem(String label, IconData icon) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, size: 32, color: const Color(0xFF4CAF50)),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 10),
        textAlign: TextAlign.center,
      ),
    ],
  );

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF4CAF50), size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title == 'Saldo' ? 'Rp 0' : value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }
}

String _formatRupiah(dynamic value) {
  if (value == null) return 'Rp 0';
  double angka = value is num
      ? value.toDouble()
      : double.tryParse(value.toString()) ?? 0;
  return 'Rp ${angka.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
}
