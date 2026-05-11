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

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null && mounted) {
      setState(() => _adminData = jsonDecode(userData));
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

  // ✅ LOGOUT FUNCTION
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Anda akan keluar dari akun admin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // Background tombol merah
              foregroundColor: Colors
                  .white, // ✅ Teks tombol putih (pindah ke dalam styleFrom)
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear semua data login

      // Kembali ke login screen (sesuaikan dengan nama screen login kamu)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ), // ✅ Ganti dengan screen login kamu
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
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ✅ HEADER - TANPA NAVIGASI PROFILE, TOMBOL LOGOUT
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
                  'Selamat Datang, Admin',
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
                if (_adminData?['level'] != null)
                  Text(
                    _adminData!['level']
                        .toString()
                        .replaceAll('_', ' ')
                        .toUpperCase(),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
              ],
            ),
          ),
          // ✅ TOMBOL LOGOUT (GANTI QR CODE)
          InkWell(
            onTap: _handleLogout,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.logout, color: Colors.white, size: 28),
                SizedBox(height: 2),
                Text(
                  'Keluar',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
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
            // ✅ STATISTIK SECTION (Langsung di paling atas - Clean!)
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

  // ✅ STATISTIK SECTION WIDGET
  Widget _buildStatistikSection() {
    return Consumer<StatistikProvider>(
      builder: (context, provider, child) {
        final stats = provider.statistik;

        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              const Row(
                children: [
                  Icon(Icons.analytics, color: Color(0xFF4CAF50), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Statistik Hari Ini',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '${stats['hari_ini'] ?? 0}',
                      'Transaksi',
                      Icons.receipt,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '${stats['selesai'] ?? 0}',
                      'Selesai',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '${stats['pending'] ?? 0}',
                      'Pending',
                      Icons.pending,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '${stats['dibatalkan'] ?? 0}',
                      'Dibatalkan',
                      Icons.cancel,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInlineStat(
                      'Total Nominal',
                      'Rp ${(stats['total_nominal_hari_ini'] ?? 0).toStringAsFixed(0)}',
                      Icons.attach_money,
                    ),
                    Container(width: 1, height: 30, color: Colors.grey[300]),
                    _buildInlineStat(
                      'Total Berat',
                      '${(stats['total_berat_hari_ini'] ?? 0).toStringAsFixed(1)} kg',
                      Icons.scale,
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

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF1B5E20)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
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
                      '${ApiConfig.storageUrl}/${artikel['foto']}',
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
