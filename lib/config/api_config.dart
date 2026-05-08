class ApiConfig {
  static const String baseUrl = 'http://172.16.106.144:8000/api';
  static const String storageUrl = 'http://172.16.106.144:8000/storage';

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
  static String get getSaldo => '$baseUrl/get-saldo';
  static String get totalSetoran => '$baseUrl/user/total-setoran';

  // ==================== 📊 DATA PUBLIK ====================
  static String get dinas => '$baseUrl/dinas';
  static String get artikel => '$baseUrl/artikel';
  static String get jenisSampah => '$baseUrl/jenis-sampah'; // ✅ TAMBAH INI

  // ==================== 📝 LAPORAN (SAMPAH ILEGAL) ====================
  static String get laporanStore => '$baseUrl/laporan';
  static String get laporanIndex => '$baseUrl/laporan';

  // ==================== 💰 PENARIKAN (BANK SAMPAH) ====================
  static String get penarikanStore => '$baseUrl/penarikan';
  static String get penarikanIndex => '$baseUrl/penarikan';

  // ==================== 🔄 TRANSAKSI SETOR (PETUGAS) ====================
  static String get cariPengguna => '$baseUrl/cari-pengguna'; // ✅ TAMBAH INI
  static String get transaksiSetorStore =>
      '$baseUrl/transaksi-setor'; // ✅ TAMBAH INI

  // ==================== 📋 RIWAYAT ====================
  static String get riwayatSetorIndex => '$baseUrl/riwayat-setor';
  static String get penjemputanStore => '$baseUrl/penjemputan';
  static String get riwayatPenjemputan => '$baseUrl/riwayat-penjemputan';
  static String get riwayatSetorPetugas => '$baseUrl/riwayat-setor-petugas';

  // ==================== 📍 INFO TPS ====================
  static String get infoTps => '$baseUrl/tps';
}
