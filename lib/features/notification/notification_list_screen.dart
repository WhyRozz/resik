import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../home/riwayat_laporan_screnn.dart';
import '../home/riwayat_setor_screen.dart';
import '../home/riwayat_penarikan_screen.dart';
import '../home/detail_penarikan_screen.dart';
import '../home/detail_laporan_screen.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _notifications = [];
  List<dynamic> _filteredNotifications = [];
  bool _isLoading = true;
  bool _isFirstLoad = true;
  Map<String, dynamic>? _userData;
  String _activeFilter = 'all'; // 'all' atau 'unread'

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _activeFilter = _tabController.index == 0 ? 'all' : 'unread';
      _applyFilter();
    });
  }

  void _applyFilter() {
    if (_activeFilter == 'all') {
      _filteredNotifications = List.from(_notifications);
    } else {
      _filteredNotifications = _notifications
          .where((n) => n['is_read'] != true)
          .toList();
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      setState(() => _userData = jsonDecode(userData));
      _fetchNotifications();
    }
  }

  Future<void> _fetchNotifications() async {
    if (_userData == null) return;

    if (_isFirstLoad) {
      setState(() => _isLoading = true);
    }

    try {
      final userId = (_userData!['id_masyarakat'] ?? _userData!['id_pns'])
          .toString();
      final userType = _userData!['tipe'];

      final uri = Uri.parse(
        ApiConfig.baseUrl + '/notifications',
      ).replace(queryParameters: {'user_id': userId, 'tipe': userType});

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            _notifications = result['data'] ?? [];
            _applyFilter();
            _isLoading = false;
            _isFirstLoad = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetch notifications: $e');
      setState(() {
        _isLoading = false;
        _isFirstLoad = false;
      });
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      final uri = Uri.parse(ApiConfig.baseUrl + '/notifications/$id/read');
      await http.put(uri);

      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == id);
        if (index != -1) {
          _notifications[index]['is_read'] = true;
          _applyFilter();
        }
      });
    } catch (e) {
      debugPrint('Error mark as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    if (_userData == null) return;

    try {
      final userId = (_userData!['id_masyarakat'] ?? _userData!['id_pns'])
          .toString();
      final userType = _userData!['tipe'];

      final uri = Uri.parse(
        ApiConfig.baseUrl + '/notifications/mark-all-read',
      ).replace(queryParameters: {'user_id': userId, 'tipe': userType});

      await http.put(uri);

      setState(() {
        for (var notif in _notifications) {
          notif['is_read'] = true;
        }
        _applyFilter();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua notifikasi ditandai telah dibaca'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error mark all as read: $e');
    }
  }

  // ✅ NAVIGASI KE RIWAYAT YANG SESUAI BERDASARKAN TYPE NOTIFIKASI
  void _navigateToRelatedHistory(
    String type,
    Map<String, dynamic> notif,
  ) async {
    Widget targetScreen;
    String contextMessage = '';

    switch (type) {
      case 'report_result':
        // KHUSUS LAPORAN: Fetch detail dulu, baru buka DetailLaporanScreen
        contextMessage = 'Memuat detail laporan...';

        // Tampilkan loading snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Memuat detail laporan...',
                    style: TextStyle(fontFamily: 'Montserrat'),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF4CAF50),
              duration: Duration(seconds: 1),
            ),
          );
        }

        // Fetch detail laporan dari API
        final laporanData = await _fetchLaporanDetail(notif);

        if (laporanData != null) {
          targetScreen = DetailLaporanScreen(laporan: laporanData);
        } else {
          // Fallback ke riwayat jika gagal fetch
          targetScreen = const RiwayatLaporanScreen();
          contextMessage = 'Gagal memuat detail, diarahkan ke Riwayat Laporan';
        }
        break;

      case 'withdrawal_result':
        // ✅ KHUSUS PENARIKAN: Fetch detail dulu, baru buka DetailPenarikanScreen
        contextMessage = 'Memuat detail penarikan...';

        // Tampilkan loading snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Memuat detail penarikan...',
                    style: TextStyle(fontFamily: 'Montserrat'),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF4CAF50),
              duration: Duration(seconds: 1),
            ),
          );
        }

        // ✅ Fetch detail penarikan dari API
        final penarikanData = await _fetchPenarikanDetail(notif);

        if (penarikanData != null) {
          targetScreen = DetailPenarikanScreen(penarikanData: penarikanData);
        } else {
          // Fallback ke riwayat jika gagal fetch
          targetScreen = const RiwayatPenarikanScreen();
          contextMessage =
              'Gagal memuat detail, diarahkan ke Riwayat Penarikan';
        }
        break;

      case 'deposit_result':
      case 'deposit_rejected':
        // KHUSUS SETOR: Fetch detail dulu, baru buka RiwayatSetorScreen dengan highlight
        contextMessage = 'Memuat detail setoran...';

        // Tampilkan loading snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Memuat detail setoran...',
                    style: TextStyle(fontFamily: 'Montserrat'),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF4CAF50),
              duration: Duration(seconds: 1),
            ),
          );
        }

        // Fetch detail setoran dari API
        final setorData = await _fetchSetorDetail(notif);

        if (setorData != null) {
          // Buka RiwayatSetorScreen dengan highlight ID
          final idTransaksi = setorData['id_transaksi'];
          targetScreen = RiwayatSetorScreen(highlightId: idTransaksi);
        } else {
          // Fallback ke riwayat biasa jika gagal fetch
          targetScreen = const RiwayatSetorScreen();
          contextMessage = 'Gagal memuat detail, diarahkan ke Riwayat Setor';
        }
        break;

      case 'pickup_result':
        targetScreen = const RiwayatSetorScreen();
        contextMessage = 'Mengarahkan ke Riwayat Penjemputan';
        break;

      default:
        contextMessage = 'Notifikasi umum';
        return;
    }

    if (!mounted) return;

    Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));

    // ✅ Tampilkan SnackBar dengan konteks
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  contextMessage,
                  style: const TextStyle(fontFamily: 'Montserrat'),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ✅ METHOD BARU: Fetch detail penarikan berdasarkan ID dari notifikasi
  Future<Map<String, dynamic>?> _fetchPenarikanDetail(
    Map<String, dynamic> notif,
  ) async {
    if (_userData == null) return null;

    try {
      // Ambil ID penarikan dari notifikasi
      int? idPenarikan;

      // ✅ PRIORITAS 1: Ambil dari field 'data'
      if (notif['data'] != null) {
        if (notif['data'] is Map) {
          final dataId = notif['data']['id'];
          if (dataId != null) {
            idPenarikan = int.tryParse(dataId.toString());
          }
        } else if (notif['data'] is String) {
          // Handle jika data berupa JSON string
          try {
            final dataMap = jsonDecode(notif['data']);
            if (dataMap is Map && dataMap['id'] != null) {
              idPenarikan = int.tryParse(dataMap['id'].toString());
            }
          } catch (e) {
            debugPrint("❌ Gagal parse data string: $e");
          }
        }
      }

      // ✅ PRIORITAS 2: Fallback cari ID di body (format: #TRX-00062)
      if (idPenarikan == null) {
        final body = notif['body']?.toString() ?? '';
        final match = RegExp(r'#TRX-(\d+)').firstMatch(body);
        if (match != null) {
          idPenarikan = int.tryParse(match.group(1)!);
        }
      }

      if (idPenarikan == null) {
        debugPrint("❌ ID penarikan tidak ditemukan di notifikasi");
        debugPrint("📋 Notif data: ${notif['data']}");
        debugPrint(" Notif body: ${notif['body']}");
        return null;
      }

      debugPrint("🔍 Fetch detail penarikan ID: $idPenarikan");

      final userId = (_userData!['id_masyarakat'] ?? _userData!['id_pns'])
          .toString();
      final userType = _userData!['tipe'];

      // ✅ PANGGIL ENDPOINT BARU: /api/penarikan/{id}
      final uri = Uri.parse('${ApiConfig.baseUrl}/penarikan/$idPenarikan')
          .replace(
            queryParameters: {
              'id_masyarakat': userType == 'masyarakat' ? userId : null,
              'id_pns': userType == 'pns' ? userId : null,
              'tipe_user': userType,
            },
          );

      debugPrint("🌐 API URL: $uri");

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      debugPrint("📥 Response status: ${response.statusCode}");
      debugPrint("📥 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success' && result['data'] != null) {
          debugPrint("✅ Detail penarikan ditemukan!");
          return result['data'];
        }
      }
    } catch (e) {
      debugPrint(" Error fetch detail penarikan: $e");
    }

    return null;
  }

  // ✅ METHOD BARU: Fetch detail laporan berdasarkan ID dari notifikasi
  Future<Map<String, dynamic>?> _fetchLaporanDetail(
    Map<String, dynamic> notif,
  ) async {
    if (_userData == null) return null;

    try {
      // Ambil ID laporan dari notifikasi
      int? idLaporan;

      // PRIORITAS 1: Ambil dari field 'data'
      if (notif['data'] != null) {
        if (notif['data'] is Map) {
          final dataId = notif['data']['id'];
          if (dataId != null) {
            idLaporan = int.tryParse(dataId.toString());
          }
        } else if (notif['data'] is String) {
          // Handle jika data berupa JSON string
          try {
            final dataMap = jsonDecode(notif['data']);
            if (dataMap is Map && dataMap['id'] != null) {
              idLaporan = int.tryParse(dataMap['id'].toString());
            }
          } catch (e) {
            debugPrint("❌ Gagal parse data string: $e");
          }
        }
      }

      if (idLaporan == null) {
        debugPrint("❌ ID laporan tidak ditemukan di notifikasi");
        debugPrint("📋 Notif data: ${notif['data']}");
        debugPrint("📋 Notif body: ${notif['body']}");
        return null;
      }

      debugPrint("🔍 Fetch detail laporan ID: $idLaporan");

      final userId = (_userData!['id_masyarakat'] ?? _userData!['id_pns'])
          .toString();
      final userType = _userData!['tipe'];

      // PANGGIL ENDPOINT BARU: /api/laporan/{id}
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/laporan/$idLaporan',
      ).replace(queryParameters: {'user_id': userId, 'tipe': userType});

      debugPrint("🌐 API URL: $uri");

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      debugPrint("📥 Response status: ${response.statusCode}");
      debugPrint("📥 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success' && result['data'] != null) {
          debugPrint("✅ Detail laporan ditemukan!");
          return result['data'];
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetch detail laporan: $e");
    }

    return null;
  }

  // ✅ METHOD BARU: Fetch detail setoran berdasarkan ID dari notifikasi
  Future<Map<String, dynamic>?> _fetchSetorDetail(
    Map<String, dynamic> notif,
  ) async {
    if (_userData == null) return null;

    try {
      // Ambil ID transaksi dari notifikasi
      int? idTransaksi;

      // ✅ PRIORITAS 1: Ambil dari field 'data'
      if (notif['data'] != null) {
        if (notif['data'] is Map) {
          final dataId = notif['data']['id'];
          if (dataId != null) {
            idTransaksi = int.tryParse(dataId.toString());
          }
        } else if (notif['data'] is String) {
          try {
            final dataMap = jsonDecode(notif['data']);
            if (dataMap is Map && dataMap['id'] != null) {
              idTransaksi = int.tryParse(dataMap['id'].toString());
            }
          } catch (e) {
            debugPrint("❌ Gagal parse data string: $e");
          }
        }
      }

      if (idTransaksi == null) {
        debugPrint("❌ ID transaksi tidak ditemukan di notifikasi");
        debugPrint("📋 Notif data: ${notif['data']}");
        debugPrint("📋 Notif body: ${notif['body']}");
        return null;
      }

      debugPrint("🔍 Fetch detail setoran ID: $idTransaksi");

      final userId = (_userData!['id_masyarakat'] ?? _userData!['id_pns'])
          .toString();
      final userType = _userData!['tipe'];

      // ✅ PANGGIL ENDPOINT BARU: /api/transaksi-setor/{id}
      final uri = Uri.parse('${ApiConfig.baseUrl}/transaksi-setor/$idTransaksi')
          .replace(
            queryParameters: {
              'id_masyarakat': userType == 'masyarakat' ? userId : null,
              'id_pns': userType == 'pns' ? userId : null,
              'tipe_user': userType,
            },
          );

      debugPrint("🌐 API URL: $uri");

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      debugPrint("📥 Response status: ${response.statusCode}");
      debugPrint("📥 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success' && result['data'] != null) {
          debugPrint("✅ Detail setoran ditemukan!");
          return result['data'];
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetch detail setoran: $e");
    }

    return null;
  }

  // ✅ CEK APAKAH NOTIFIKASI BARU (< 1 jam)
  bool _isNewNotification(String? createdAt) {
    if (createdAt == null) return false;
    try {
      final parts = createdAt.split(' ');
      if (parts.length < 2) return false;
      final dateParts = parts[0].split('-');
      final timeParts = parts[1].split(':');
      if (dateParts.length != 3 || timeParts.length != 2) return false;

      final notifTime = DateTime(
        int.parse(dateParts[2]),
        int.parse(dateParts[1]),
        int.parse(dateParts[0]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      final now = DateTime.now();
      return now.difference(notifTime).inHours < 1;
    } catch (e) {
      return false;
    }
  }

  IconData _getIconByType(String type) {
    switch (type) {
      case 'report_result':
        return Icons.assignment;
      case 'withdrawal_result':
        return Icons.account_balance_wallet;
      case 'deposit_result':
        return Icons.recycling;
      case 'deposit_rejected':
        return Icons.cancel;
      case 'pickup_result':
        return Icons.local_shipping;
      default:
        return Icons.notifications;
    }
  }

  LinearGradient _getGradientByType(String type) {
    switch (type) {
      case 'report_result':
        return const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'withdrawal_result':
        return const LinearGradient(
          colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'deposit_result':
        return const LinearGradient(
          colors: [Color(0xFFFFA726), Color(0xFFEF6C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'deposit_rejected':
        return const LinearGradient(
          colors: [Color(0xFFEF5350), Color(0xFFC62828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'pickup_result':
        return const LinearGradient(
          colors: [Color(0xFFAB47BC), Color(0xFF7B1FA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF9E9E9E), Color(0xFF616161)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  String _getLabelByType(String type) {
    switch (type) {
      case 'report_result':
        return 'Laporan';
      case 'withdrawal_result':
        return 'Penarikan';
      case 'deposit_result':
        return 'Setoran';
      case 'deposit_rejected':
        return 'Setoran Ditolak';
      case 'pickup_result':
        return 'Penjemputan';
      default:
        return 'Umum';
    }
  }

  int get _unreadCount =>
      _notifications.where((n) => n['is_read'] != true).length;

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
            child: const Icon(Icons.arrow_back, color: Color(0xFF4CAF50)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Color(0xFF1B5E20),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        centerTitle: false,
        actions: [
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _markAllAsRead,
                icon: const Icon(Icons.done_all, size: 18),
                label: Text(
                  'Tandai semua ($_unreadCount)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ✅ TABS FILTER
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mark_email_unread_outlined, size: 16),
                      const SizedBox(width: 6),
                      const Text('Semua'),
                      if (_notifications.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_notifications.length}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mark_email_unread_outlined, size: 16),
                      const SizedBox(width: 6),
                      const Text('Belum Dibaca'),
                      if (_unreadCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_unreadCount',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ✅ BODY CONTENT
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  )
                : _filteredNotifications.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _fetchNotifications,
                    color: const Color(0xFF4CAF50),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredNotifications.length,
                      itemBuilder: (context, index) {
                        final notif = _filteredNotifications[index];
                        return _buildNotificationCard(notif, index);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ✅ EMPTY STATE MODERN
  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      color: const Color(0xFF4CAF50),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 200,
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
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      size: 64,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _activeFilter == 'all'
                        ? 'Belum ada notifikasi'
                        : 'Tidak ada notifikasi belum dibaca',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tarik ke bawah untuk refresh',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontFamily: 'Montserrat',
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

  // ✅ NOTIFICATION CARD MODERN
  Widget _buildNotificationCard(Map<String, dynamic> notif, int index) {
    final isRead = notif['is_read'] == true;
    final type = notif['type'] ?? 'general';
    final isNew = _isNewNotification(notif['created_at']);
    final gradient = _getGradientByType(type);
    final icon = _getIconByType(type);
    final label = _getLabelByType(type);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16),
        border: isRead
            ? Border.all(color: Colors.grey.shade200, width: 1)
            : Border.all(color: const Color(0xFF2196F3), width: 1),
        boxShadow: [
          BoxShadow(
            color: isRead
                ? Colors.black.withOpacity(0.03)
                : const Color(0xFF2196F3).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        // ← PERBAIKI INDENTASI
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!isRead) {
              _markAsRead(notif['id']);
            }
            _navigateToRelatedHistory(type, notif);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ ICON DENGAN GRADIENT
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.last.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),

                // ✅ KONTEN
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Label + Badge "BARU"
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: gradient.colors.first.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: gradient.colors.last,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                          if (isNew && !isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2196F3), // ← Biru
                                    Color(0xFF1976D2), // ← Biru tua
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'BARU',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2196F3), // ← Biru
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        notif['title'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isRead
                              ? FontWeight.w600
                              : FontWeight.bold,
                          color: isRead
                              ? Colors.grey[700]
                              : const Color(0xFF1B5E20),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Body
                      Text(
                        notif['body'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'Montserrat',
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Footer: Icon jam + waktu + arrow
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_filled,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notif['created_at'] ?? '',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: const Color(0xFF4CAF50).withOpacity(0.6),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
