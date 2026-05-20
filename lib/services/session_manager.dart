import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class SessionManager with WidgetsBindingObserver {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  GlobalKey<NavigatorState>? navigatorKey;

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
      if (elapsedMs > 10 * 60 * 1000) { // 10 menit = 600.000 ms
        forceLogout = true;
      }
    }
    // ✅ RULE 2: Petugas/Admin → Hanya logout jika pindah hari
    else if (tipe == 'petugas' || tipe == 'admin') {
      if (loginDate != todayStr) {
        forceLogout = true;
      }
    }
    // Fallback: Jika tipe tidak dikenali, anggap aman (tidak logout)
    else {
      forceLogout = false;
    }

    if (forceLogout) {
      debugPrint("🔒 Session expired for tipe: $tipe. Forcing logout...");
      await prefs.remove('user_data');
      await prefs.remove('token');
      await prefs.remove('login_timestamp');
      await prefs.remove('login_date');
      _navigateToLogin();
    } else {
      // ✅ Reset timestamp agar timer berjalan ulang saat app aktif kembali
      await prefs.setInt('login_timestamp', now.millisecondsSinceEpoch);
    }
  }

  void _navigateToLogin() {
    if (navigatorKey?.currentState != null) {
      // ⚠️ GANTI '/login' sesuai route login aplikasi kamu
      navigatorKey!.currentState!.pushNamedAndRemoveUntil(
        '/login', 
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}