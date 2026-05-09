import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'qr_barcode_screen.dart';
import 'profile_screen.dart';
import 'withdrawal_screen.dart';
import 'artikel_detail_screen.dart';
import 'artikel_list_screen.dart';
import 'laporan_screen.dart';
import 'riwayat_laporan_screnn.dart';
import 'riwayat_setor_screen.dart';
import 'riwayat_penarikan_screen.dart';
import 'info_tps_screen.dart';

// ✅ TAMBAHKAN IMPORT INI:
import '../shared/jenis_sampah_list_screen.dart';

class HomeUserScreen extends StatefulWidget {
  final double? initialSaldo;
  final double? initialTotalSetoran;

  const HomeUserScreen({
    super.key,
    this.initialSaldo,
    this.initialTotalSetoran,
  });

  @override
  State<HomeUserScreen> createState() => _HomeUserScreenState();
}

class _HomeUserScreenState extends State<HomeUserScreen> {
  int _selectedIndex = 0;

  // ✅ Track bubble set mana yang aktif: 'laporan' | 'bank' | null
  String? _activeBubbleSet;

  // ✅ Track bubble mana yang aktif di dalam set-nya
  String? _activeLaporanBubble; // 'form' | 'riwayat'
  String? _activeBankBubble; // 'setor' | 'penarikan'

  // Variabel & Logic Saldo/Artikel (TETAP SAMA)
  Map<String, dynamic>? _userData;
  String saldoText = "Rp 0";
  String totalSetoranText = "0 Kg";
  bool _isLoadingSaldo = false;
  List<dynamic> _artikelList = [];
  bool _isLoadingArtikel = true;

  Future<void> _handleRefresh() async {
    await _fetchSaldo();
    await _fetchArtikel();
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchSaldo();
    _fetchArtikel();
    // ✅ Jika ada data awal dari login, langsung set
    if (widget.initialSaldo != null) {
      setState(() {
        saldoText = "Rp ${widget.initialSaldo!.toInt()}";
        totalSetoranText =
            "${widget.initialTotalSetoran!.toStringAsFixed(1)} Kg";
      });
    } else {
      // Jika tidak, fetch seperti biasa
      _fetchSaldo();
    }
    _fetchArtikel();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _navigateToPage(String page) {
    Widget targetScreen;
    if (page == 'form') {
      targetScreen = const LaporanScreen();
    } else if (page == 'riwayat') {
      targetScreen = const RiwayatLaporanScreen();
    } else if (page == 'setor') {
      targetScreen = const RiwayatSetorScreen();
    } else if (page == 'penarikan') {
      targetScreen = const RiwayatPenarikanScreen();
    } else {
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null && mounted) {
      setState(() => _userData = jsonDecode(userData));

      _fetchSaldo();
      _fetchArtikel();
    }
  }

  Future<void> _fetchSaldo() async {
    if (_userData == null) {
      debugPrint("⚠️ _fetchSaldo: _userData masih null!");
      return;
    }

    debugPrint("🔄 Fetching saldo untuk user: ${_userData!['nama']}");

    try {
      final userId = (_userData!['id_masyarakat'] ?? _userData!['id_pns'])
          .toString();
      final userType = _userData!['tipe'];

      final uri = Uri.parse(
        ApiConfig.getSaldo,
      ).replace(queryParameters: {'user_id': userId, 'tipe': userType});

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      // ✅ LOG INI WAJIB ADA - biar kita tahu isi response-nya
      debugPrint("📥 Status Code: ${response.statusCode}");
      debugPrint("📄 RAW Response Body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final result = jsonDecode(response.body);
          debugPrint("🔍 Parsed Result: $result");

          if (mounted) {
            if (result['status'] == 'success') {
              final data = result['data'];

              // ✅ Cek apakah kunci 'saldo' dan 'total_setoran' ada
              if (data.containsKey('saldo') &&
                  data.containsKey('total_setoran')) {
                // ✅ FIX 1: Parse saldo ke double (bisa String atau num dari JSON)
                final saldoRaw = data['saldo'];
                final saldo = saldoRaw is num
                    ? saldoRaw
                    : double.tryParse(saldoRaw.toString()) ?? 0;

                // ✅ FIX 2: Parse total_setoran ke double (INI YANG ERROR SEBELUMNYA)
                final totalSetoranRaw = data['total_setoran'];
                final totalSetoran = totalSetoranRaw is num
                    ? totalSetoranRaw
                    : double.tryParse(totalSetoranRaw.toString()) ?? 0;

                debugPrint("✅ Saldo: $saldo, Total Setoran: $totalSetoran");

                setState(() {
                  // ✅ Format saldo: hapus .00 jika bilangan bulat
                  saldoText =
                      "Rp ${saldo.toStringAsFixed(0).replaceAll(RegExp(r'(?<=\.\d*?)0+$'), '')}";

                  // ✅ Format total_setoran: 1 desimal + "Kg" (sekarang aman karena sudah double)
                  totalSetoranText = "${totalSetoran.toStringAsFixed(1)} Kg";
                });
              } else {
                debugPrint(
                  "❌ Kunci 'saldo' atau 'total_setoran' tidak ada di response!",
                );
                debugPrint("🔑 Keys yang ada: ${data.keys.toList()}");
              }
            } else {
              debugPrint(
                "❌ API Error: ${result['message'] ?? 'Unknown error'}",
              );
            }
          } else {
            debugPrint("⚠️ Widget tidak mounted, setState() dilewati");
          }
        } catch (jsonError) {
          debugPrint("🚨 JSON Decode Error: $jsonError");
          debugPrint("📄 Response yang gagal di-parse: ${response.body}");
        }
      }
    } catch (e) {
      debugPrint("🚨 Exception: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal refresh saldo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchArtikel() async {
    setState(() => _isLoadingArtikel = true);
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.artikel))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200 && mounted) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            _artikelList = result['data'] ?? [];
            _isLoadingArtikel = false;
          });
        } else {
          if (mounted)
            setState(() {
              _artikelList = [];
              _isLoadingArtikel = false;
            });
        }
      }
    } on TimeoutException {
      debugPrint("⏳ Timeout fetch artikel");
      if (mounted) setState(() => _isLoadingArtikel = false);
    } catch (e) {
      debugPrint("❌ Error fetch artikel: $e");
      if (mounted) setState(() => _isLoadingArtikel = false);
    }
  }

  // ✅ Navigasi Bawah: Ubah state + tampilkan bubble yang sesuai
  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;

      if (index == 1) {
        // Tab Laporan
        _activeBubbleSet = 'laporan';
        _activeBankBubble = null; // Reset bubble bank
      } else if (index == 2) {
        // Tab Bank Sampah
        _activeBubbleSet = 'bank';
        _activeLaporanBubble = null; // Reset bubble laporan
      } else {
        // Tab lain: hide semua bubble
        _activeBubbleSet = null;
        _activeLaporanBubble = null;
        _activeBankBubble = null;
      }
    });

    // ✅ TAMBAHKAN INI: Navigasi ke Info TPS
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InfoTpsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildHomeContent(), // ✅ Konten tetap beranda
      bottomNavigationBar: _buildBottomNavWithBubbles(),
    );
  }

  // ==================== BUBBLE TABS & BOTTOM NAV ====================
  Widget _buildBottomNavWithBubbles() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ Animated Switcher untuk transisi bubble yang smooth
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
            child: _activeBubbleSet != null
                ? Container(
                    key: ValueKey<String>(
                      _activeBubbleSet!,
                    ), // ✅ Key penting untuk animasi
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: _activeBubbleSet == 'laporan'
                        ? _buildLaporanBubbles()
                        : _buildBankSampahBubbles(),
                  )
                : const SizedBox.shrink(),
          ),
          // ✅ Navigasi Utama
          _buildNavItems(),
        ],
      ),
    );
  }

  // ✅ Bubble Tabs untuk Laporan
  Widget _buildLaporanBubbles() {
    return Row(
      children: [
        Expanded(
          child: _buildBubble(
            'Sampah Ilegal',
            Icons.add_circle_outline,
            _activeLaporanBubble == 'form',
            () {
              setState(() => _activeLaporanBubble = 'form');
              _navigateToPage('form');
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildBubble(
            'Riwayat',
            Icons.history,
            _activeLaporanBubble == 'riwayat',
            () {
              setState(() => _activeLaporanBubble = 'riwayat');
              _navigateToPage('riwayat');
            },
          ),
        ),
      ],
    );
  }

  // ✅ Bubble Tabs untuk Bank Sampah
  Widget _buildBankSampahBubbles() {
    return Row(
      children: [
        Expanded(
          child: _buildBubble(
            'Riwayat Setor',
            Icons.upload_rounded,
            _activeBankBubble == 'setor',
            () {
              setState(() => _activeBankBubble = 'setor');
              _navigateToPage('setor');
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildBubble(
            'Riwayat Penarikan',
            Icons.download_rounded,
            _activeBankBubble == 'penarikan',
            () {
              setState(() => _activeBankBubble = 'penarikan');
              _navigateToPage('penarikan');
            },
          ),
        ),
      ],
    );
  }

  // ✅ Widget Bubble (Reusable)
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

  // ✅ Navigasi Bawah (Items)
  Widget _buildNavItems() {
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

  // ==================== KONTEN BERANDA (TIDAK DIUBAH) ====================
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

  Widget _buildHeader() {
    return GestureDetector(
      onTap: () async {
        // ✅ TUNGGU result dari ProfileScreen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );

        // ✅ Jika result true (profil diupdate), reload data
        if (result == true && mounted) {
          debugPrint("🔄 Profile updated, reloading home data...");
          _loadUserData(); // ← Reload data dari SharedPreferences
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              backgroundImage: _userData?['foto'] != null
                  ? NetworkImage(_userData!['foto'])
                  : null,
              child: _userData?['foto'] == null
                  ? const Icon(Icons.person, size: 40, color: Color(0xFF1B5E20))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selamat Datang',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    _userData?['nama'] ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrBarcodeScreen()),
              ),
              child: const Icon(Icons.qr_code, color: Colors.white, size: 30),
            ),
          ],
        ),
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
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF4CAF50),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'Saldo',
                      'Rp 0',
                      Icons.account_balance_wallet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      'Total Setoran',
                      '0 Kg',
                      Icons.shopping_bag,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WithdrawalScreen(),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.money, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Tarik Tunai',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ✅ ARTIKEL EDUKASI - dengan callback onViewAll
              _buildSectionTitle(
                'Artikel Edukasi',
                onViewAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ArtikelListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _isLoadingArtikel
                  ? const Center(child: CircularProgressIndicator())
                  : _buildArtikelList(),

              const SizedBox(height: 24),

              // ✅ JENIS SAMPAH - dengan callback onViewAll
              _buildSectionTitle(
                'Jenis Sampah',
                onViewAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const JenisSampahListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildJenisSampahGrid(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

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
          _isLoadingSaldo
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  title == 'Saldo' ? saldoText : totalSetoranText,
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

  // ✅ FIX: Method ini sekarang menerima callback onViewAll
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
        onPressed: onViewAll, // ✅ Gunakan callback dari parameter
        child: const Text(
          'Lihat Semua',
          style: TextStyle(color: Color(0xFF4CAF50)),
        ),
      ),
    ],
  );

  Widget _buildArtikelList() {
    if (_artikelList.isEmpty) {
      return const Center(
        child: Text('Belum ada artikel', style: TextStyle(color: Colors.grey)),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _artikelList.length,
        itemBuilder: (context, index) {
          final artikel = _artikelList[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArtikelDetailScreen(
                    artikel: artikel as Map<String, dynamic>,
                  ),
                ),
              );
            },
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
                      errorBuilder: (context, error, stackTrace) =>
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
      _buildJenisSampahItem('Minyak', Icons.local_drink),
      _buildJenisSampahItem('Kertas', Icons.description),
      _buildJenisSampahItem('Logam', Icons.build),
      _buildJenisSampahItem('Kaca', Icons.camera),
      _buildJenisSampahItem('Organik', Icons.eco),
      _buildJenisSampahItem('Kardus', Icons.inventory),
      _buildJenisSampahItem('Lainnya', Icons.category),
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
}
