class ApiConfig {
  // GANTI DI SINI SAJA!
  static const String baseUrl = 'http://192.168.100.206:8000/api';
 
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ✅ Auth Endpoints
  static String get login => '$baseUrl/login';
  static String get register => '$baseUrl/register';
  static String get forgotPassword => '$baseUrl/forgot-password';
  static String get verifyOtp => '$baseUrl/verify-otp';        
  static String get resetPassword => '$baseUrl/reset-password'; 
  
  // ✅ Data Endpoints
  static String get dinas => '$baseUrl/dinas';
  static String get artikel => '$baseUrl/artikel';
  
  // ✅ Profile Endpoints (baru)
  static String get profile => '$baseUrl/profile';           
  static String get profileUpdate => '$baseUrl/profile';
  static String get getSaldo => '$baseUrl/get-saldo';     
  
  // ✅ User Stats Endpoints (baru)
  static String get totalSetoran => '$baseUrl/user/total-setoran';

    // ✅ PENARIKAN ENDPOINTS (BARU) ⬇️
  static String get penarikanStore => '$baseUrl/penarikan';        // POST: Submit penarikan
  static String get penarikanIndex => '$baseUrl/penarikan';  
  
  
  // ✅ Storage URL untuk gambar (baru)
  static String get storageUrl => 'http://192.168.100.206:8000/storage';
}