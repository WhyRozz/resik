import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'home_user_screen.dart';
import 'laporan_screen.dart';
import 'riwayat_setor_screen.dart';
import 'info_tps_screen.dart';
import 'detail_penarikan_screen.dart'; // Nanti kita buat

class RiwayatPenarikanScreen extends StatefulWidget {
  const RiwayatPenarikanScreen({super.key});

  @override
  State<RiwayatPenarikanScreen> createState() => _RiwayatPenarikanScreenState();
}

class _RiwayatPenarikanScreenState extends State<RiwayatPenarikanScreen> {
  int _filterIndex = 0; // 0: Semua Transaksi, 1: Diproses
  List<dynamic> _riwayatData = [];
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchRiwayatPenarikan();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null && mounted) {
      setState(() {
        _userData = jsonDecode(userData);
      });
    }
  }

  Future<void> _fetchRiwayatPenarikan() async {
    setState(() => _isLoading = true);

    try {
      // Load user data dulu
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      if (userDataString == null || userDataString.isEmpty) {
        debugPrint("⚠️ User data tidak ada di SharedPreferences");
        if (mounted) {
          setState(() {
            _riwayatData = [];
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Silakan login ulang'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final userData = jsonDecode(userDataString);
      final userId = userData['id_masyarakat'] ?? userData['id_pns'];
      final userType = userData['tipe'];

      if (userId == null || userType == null) {
        debugPrint("⚠️ User ID atau Tipe tidak valid: $userData");
        if (mounted) {
          setState(() {
            _riwayatData = [];
            _isLoading = false;
          });
        }
        return;
      }

      debugPrint("📡 Fetch riwayat untuk User ID: $userId, Tipe: $userType");

      // Build URL dengan parameter yang benar
      final uri = Uri.parse('${ApiConfig.baseUrl}/penarikan');
      final url = uri.replace(
        queryParameters: {
          if (userType == 'masyarakat') 'id_masyarakat': userId.toString(),
          if (userType == 'pns') 'id_pns': userId.toString(),
          'tipe_user': userType,
        },
      );

      debugPrint("🔗 URL: $url");

      final response = await http
          .get(url, headers: ApiConfig.headers)
          .timeout(const Duration(seconds: 10));

      debugPrint("📥 Status: ${response.statusCode}");
      debugPrint("📄 Response: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            if (result['status'] == 'success') {
              _riwayatData = result['data'] ?? [];
              debugPrint("✅ Berhasil! Data: ${_riwayatData.length} item");
            } else {
              _riwayatData = [];
              debugPrint("❌ API Error: ${result['message']}");
            }
            _isLoading = false;
          });
        }
      } else {
        debugPrint("❌ HTTP Error: ${response.statusCode}");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e, stackTrace) {
      debugPrint("🚨 EXCEPTION: $e");
      debugPrint("📋 StackTrace: $stackTrace");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Filter data berdasarkan status
  List<dynamic> get _filteredData {
    if (_filterIndex == 0) return _riwayatData; // Semua
    return _riwayatData.where((item) => item['status'] == 'Diproses').toList();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Riwayat Penarikan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // ✅ FILTER TABS
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterBubble(
                    'Semua Transaksi',
                    _filterIndex == 0,
                    () => setState(() => _filterIndex = 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFilterBubble(
                    'Diproses',
                    _filterIndex == 1,
                    () => setState(() => _filterIndex = 1),
                  ),
                ),
              ],
            ),
          ),

          // ✅ LIST RIWAYAT PENARIKAN
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada riwayat penarikan',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredData.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final data = _filteredData[index];
                      return _buildPenarikanCard(data);
                    },
                  ),
          ),

          // ✅ BUBBLE TABS (BANK SAMPAH)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _buildBubble(
                    'Riwayat Pengajuan',
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
                    true, // Active
                    () {},
                  ),
                ),
              ],
            ),
          ),

          // ✅ BOTTOM NAVIGATION (KONSISTEN)
          _buildConsistentBottomNav(context),
        ],
      ),
    );
  }

  // ✅ FILTER BUBBLE
  Widget _buildFilterBubble(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4CAF50) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF4CAF50) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ✅ CARD RIWAYAT PENARIKAN
  Widget _buildPenarikanCard(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        // ✅ Navigate ke detail penarikan
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPenarikanScreen(data: data),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            // Tanggal
            Text(
              data['tanggal'],
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Nominal
            Text(
              data['nominal'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 12),

            // Info Rows
            _buildInfoRow('Metode Penarikan', data['metode']),
            const SizedBox(height: 6),
            _buildInfoRow('Status Transaksi', data['status']),
            const SizedBox(height: 6),
            _buildInfoRow('Id Transaksi', data['id_penarikan'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 11, color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF1B5E20),
              fontWeight: FontWeight.w600,
            ),
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4CAF50) : const Color(0xFFE8F5E9),
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
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF4CAF50),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ BOTTOM NAVIGATION STYLE KONSISTEN
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
      padding: const EdgeInsets.symmetric(vertical: 12),
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
          final isActive = index == 2; // Bank Sampah aktif
          final item = items[index];

          return GestureDetector(
            onTap: () {
              if (index == 0)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeUserScreen()),
                );
              else if (index == 1)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LaporanScreen()),
                );
              else if (index == 3)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InfoTpsScreen()),
                );
            },
            child: Container(
              padding: isActive
                  ? const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: isActive
                  ? BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(30),
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
                  if (isActive) const SizedBox(width: 8),
                  if (isActive)
                    Text(
                      item['label'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
