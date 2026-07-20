import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'riwayat_setor_admin_screen.dart';
import 'riwayat_penjemputan_admin_screen.dart';

class NotificationListScreenAdmin extends StatefulWidget {
  const NotificationListScreenAdmin({super.key});

  @override
  State<NotificationListScreenAdmin> createState() =>
      _NotificationListScreenAdminState();
}

class _NotificationListScreenAdminState
    extends State<NotificationListScreenAdmin>
    with SingleTickerProviderStateMixin {
  List<dynamic> _notifications = [];
  List<dynamic> _filteredNotifications = [];
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String _activeFilter = 'all';

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

    setState(() => _isLoading = true);

    try {
      final userId = _userData!['id_petugas'].toString();
      final uri = Uri.parse(
        ApiConfig.baseUrl + '/notifications',
      ).replace(queryParameters: {'user_id': userId, 'tipe': 'petugas'});

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            _notifications = result['data'] ?? [];
            _applyFilter();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetch notifications: $e');
      setState(() => _isLoading = false);
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
      final userId = _userData!['id_petugas'].toString();
      final uri = Uri.parse(
        ApiConfig.baseUrl + '/notifications/mark-all-read',
      ).replace(queryParameters: {'user_id': userId, 'tipe': 'petugas'});

      await http.put(uri);
      setState(() {
        for (var notif in _notifications) {
          notif['is_read'] = true;
        }
        _applyFilter();
      });
    } catch (e) {
      debugPrint('Error mark all as read: $e');
    }
  }

  void _navigateToRelatedHistory(String type, Map<String, dynamic> notif) {
    if (!mounted) return;

    // Tandai sebagai dibaca
    if (notif['is_read'] != true) {
      _markAsRead(notif['id']);
    }

    // Ambil ID dari data notifikasi
    final itemId = notif['data']?['id']?.toString();

    if (type == 'new_deposit' || type == 'deposit_confirmed') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const RiwayatSetorAdminScreen(), // ✅ HAPUS highlightId
        ),
      );
    } else if (type == 'new_pickup' || type == 'pickup_result') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RiwayatPenjemputanAdminScreen(highlightId: itemId), // ✅ TETAP ADA
        ),
      );
    }
  }

  IconData _getIconByType(String type) {
    if (type.contains('deposit')) return Icons.recycling;
    if (type.contains('pickup')) return Icons.local_shipping;
    return Icons.notifications;
  }

  Color _getColorByType(String type) {
    if (type.contains('deposit')) return const Color(0xFF4CAF50);
    if (type.contains('pickup')) return const Color(0xFF2196F3);
    return Colors.grey;
  }

  String _getLabelByType(String type) {
    if (type == 'new_deposit') return 'Setoran Masuk';
    if (type == 'deposit_confirmed') return 'Konfirmasi Setor';
    if (type == 'new_pickup') return 'Penjemputan Baru';
    if (type == 'pickup_result') return 'Status Penjemputan';
    return 'Umum';
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Color(0xFF1B5E20),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Tandai Dibaca',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  text: 'Semua (${_notifications.length})',
                ), // ✅ PAKAI CURLY BRACES
                Tab(text: 'Belum Dibaca ($_unreadCount)'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  )
                : _filteredNotifications.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada notifikasi',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchNotifications,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredNotifications.length,
                      itemBuilder: (context, index) {
                        final notif = _filteredNotifications[index];
                        final isRead = notif['is_read'] == true;
                        final type = notif['type'] ?? 'general';
                        final color = _getColorByType(type);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isRead
                                ? Colors.white
                                : const Color(0xFFF1F8E9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isRead
                                  ? Colors.grey.shade200
                                  : const Color(0xFF4CAF50),
                              width: isRead ? 1 : 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isRead
                                    ? Colors.black.withOpacity(0.03)
                                    : color.withOpacity(0.2),
                                blurRadius: isRead ? 8 : 12,
                                offset: Offset(
                                  0,
                                  isRead ? 2 : 4,
                                ), // ✅ HAPUS const
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () {
                              if (!isRead) _markAsRead(notif['id']);
                              _navigateToRelatedHistory(type, notif);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon dengan background
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getIconByType(type),
                                    color: color,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Konten
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif['title'] ?? '',
                                              style: TextStyle(
                                                fontWeight: isRead
                                                    ? FontWeight.w500
                                                    : FontWeight.bold,
                                                fontSize: 14,
                                                color: isRead
                                                    ? Colors.grey.shade700
                                                    : const Color(0xFF1B5E20),
                                              ),
                                            ),
                                          ),
                                          // Badge "BARU" untuk yang belum dibaca
                                          if (!isRead)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFFFF5252),
                                                    Color(0xFFFF1744),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'BARU',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        notif['body'] ?? '',
                                        style: TextStyle(
                                          color: isRead
                                              ? Colors.grey.shade600
                                              : Colors.grey.shade800,
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      // Waktu
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            notif['created_at'] ?? '',
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Panah untuk yang belum dibaca
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: isRead ? Colors.grey.shade400 : color,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
