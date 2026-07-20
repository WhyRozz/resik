class ApiConfig {
  // 🔧 KONTROL MODE: false = Local/Maintenance, true = Production
  static const bool isProduction = true;

  // 🌐 Base URL dinamis berdasarkan mode
  static String get _baseUrl {
    if (isProduction) {
      return 'https://resik.pbltifnganjuk.com';
    } else {
      // 📱 Android Emulator  → 'http://10.0.2.2:8000'
      // 🍎 iOS Simulator/Web → 'http://localhost:8000'
      // 📱 HP Fisikal (WiFi) → 'http://192.168.1.xx:8000' (ganti xx dengan IP Laptop)
      return 'http://192.168.0.34:8000';
    }
  }

  static String get baseUrl => '$_baseUrl/api';
  static String get storageUrl => '$_baseUrl/uploads';

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ==================== 🔐 AUTH ENDPOINTS ====================
  static String get register => '$baseUrl/register';
  static String get login => '$baseUrl/login';
  static String get logout => '$baseUrl/logout';
  static String get forgotPassword => '$baseUrl/forgot-password';
  static String get verifyOtp => '$baseUrl/verify-otp';
  static String get resetPassword => '$baseUrl/reset-password';

  // ==================== 👤 PROFILE & USER ====================
  static String get profile => '$baseUrl/profile';
  static String get profileUpdate => '$baseUrl/profile';

  /// FOTO
  static String get updateFoto => '$baseUrl/profile';

  /// EMAIL
  static String get sendEmailOtp => '$baseUrl/send-email-otp';
  static String get sendPasswordOtp => '$baseUrl/send-password-otp';
  static String get verifyEmailOtp => '$baseUrl/verify-email-otp';
  static String get updateEmail => '$baseUrl/update-email';

  /// PASSWORD
  static String get updatePassword => '$baseUrl/update-password';

  /// FCM
  static String get saveFcmToken => '$baseUrl/save-fcm-token';

  /// SALDO
  static String get getSaldo => '$baseUrl/get-saldo';
  static String get totalSetoran => '$baseUrl/user/total-setoran';

  // ==================== 📊 DATA PUBLIK ====================
  static String get dinas => '$baseUrl/dinas';
  static String get artikel => '$baseUrl/artikel';
  static String get jenisSampah => '$baseUrl/jenis-sampah';

  // ==================== 📝 LAPORAN (SAMPAH ILEGAL) ====================
  static String get laporanStore => '$baseUrl/laporan';
  static String get laporanIndex => '$baseUrl/laporan';

  // ==================== 💰 PENARIKAN (BANK SAMPAH) ====================
  static String get penarikanStore => '$baseUrl/penarikan';
  static String get penarikanIndex => '$baseUrl/penarikan';

  // ==================== 🔄 TRANSAKSI SETOR (PETUGAS) ====================
  static String get cariPengguna => '$baseUrl/cari-pengguna';
  static String get transaksiSetorStore => '$baseUrl/transaksi-setor';

  // ==================== 🗂️ JENIS SAMPAH ====================
  static String get jenisSampahList => '$baseUrl/jenis-sampah';

  // ==================== 📋 RIWAYAT ====================
  static String get riwayatSetorIndex => '$baseUrl/riwayat-setor';
  static String get penjemputanStore => '$baseUrl/penjemputan/store';
  static String riwayatPenjemputan(int adminId) =>
      '$baseUrl/riwayat-penjemputan/$adminId';
  static String riwayatSetorPetugas(int idPetugas) =>
      '$baseUrl/riwayat-setor-admin/$idPetugas';

  // ==================== 📍 INFO TPS ====================
  static String get infoTps => '$baseUrl/tps';

  // ✅ HELPER GAMBAR (Otomatis ikut base URL local/prod)
  static String imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    String cleanPath = path.replaceFirst(RegExp(r'^storage/|^uploads/'), '');
    return '$storageUrl/$cleanPath';
  }
}
