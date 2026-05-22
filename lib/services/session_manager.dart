import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';

class SessionManager with WidgetsBindingObserver {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  GlobalKey<NavigatorState>? navigatorKey;
  Timer? _countdownTimer; // ✅ Timer untuk countdown
  int _remainingSeconds = 10; // ✅ Default 10 detik

  // 1. Inisialisasi & pasang observer lifecycle
  void init(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
    WidgetsBinding.instance.addObserver(this);
  }

  // 2. Pantau saat app kembali ke foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSessionTimeout();
    }
  }

  Future<void> _checkSessionTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString('user_data');
    if (userDataStr == null) return; // Belum login

    final userData = jsonDecode(userDataStr);
    final tipe = userData['tipe']?.toString().toLowerCase() ?? '';
    final loginTimestamp = prefs.getInt('login_timestamp') ?? 0;
    final loginDate = prefs.getString('login_date');

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    bool forceLogout = false;

    // ✅ RULE 1: Masyarakat & PNS → Timeout 10 menit
    if (tipe == 'masyarakat' || tipe == 'pns') {
      final elapsedMs = now.millisecondsSinceEpoch - loginTimestamp;
      if (elapsedMs > 10 * 60 * 1000) {
        // 10 menit = 600.000 ms
        forceLogout = true;
      }
    }
    // ✅ RULE 2: Petugas/Admin → Hanya logout jika pindah hari
    else if (tipe == 'petugas' || tipe == 'admin') {
      if (loginDate != todayStr) {
        forceLogout = true;
      }
    }

    if (forceLogout) {
      debugPrint("🔒 Session expired for tipe: $tipe. Showing dialog...");
      _showSessionExpiredDialog();
    } else {
      // ✅ Reset timestamp agar timer berjalan ulang saat app aktif kembali
      await prefs.setInt('login_timestamp', now.millisecondsSinceEpoch);
    }
  }

  // ✅ SHOW DIALOG SESI HABIS DENGAN COUNTDOWN
  // ✅ SHOW DIALOG SESI HABIS DENGAN COUNTDOWN
  void _showSessionExpiredDialog() {
    _remainingSeconds = 10; // Reset countdown

    if (navigatorKey?.currentState?.context != null) {
      // ✅ Buat dialog dengan StreamBuilder untuk update real-time
      final Stream<int> countdownStream = Stream.periodic(
        const Duration(seconds: 1),
        (x) => 10 - x,
      ).take(11);

      showDialog(
        context: navigatorKey!.currentState!.context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: StreamBuilder<int>(
              stream: countdownStream,
              builder: (context, snapshot) {
                final remaining = snapshot.data ?? 10;

                // Auto close saat countdown habis
                if (remaining <= 0) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pop();
                    _doLogout();
                  });
                }

                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Sesi Sudah Habis',
                        style: TextStyle(color: Color(0xFF1B5E20)),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Untuk keamanan, sesi Anda telah berakhir.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Redirect otomatis dalam ',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              '$remaining',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const Text(
                              ' detik...',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _doLogout();
                      },
                      child: const Text(
                        'Oke',
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
    }
  }

  // ✅ DO LOGOUT - Hapus data & navigasi ke login
  Future<void> _doLogout() async {
    _countdownTimer?.cancel();

    // Tutup dialog jika masih terbuka
    if (navigatorKey?.currentState?.context != null) {
      Navigator.of(navigatorKey!.currentState!.context).pop();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('token');
    await prefs.remove('login_timestamp');
    await prefs.remove('login_date');

    debugPrint("🔐 User logged out due to session timeout");
    _navigateToLogin();
  }

  void _navigateToLogin() {
    if (navigatorKey?.currentState != null) {
      navigatorKey!.currentState!.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  // ✅ CLEANUP TIMER
  void dispose() {
    _countdownTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
