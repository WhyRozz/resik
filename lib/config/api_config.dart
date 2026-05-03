class ApiConfig {
  // GANTI DI SINI SAJA!
  static const String baseUrl = 'http://192.168.100.206:8000/api';
  
  // Semua endpoint
  static String get login => '$baseUrl/login';
  static String get register => '$baseUrl/register';
  static String get dinas => '$baseUrl/dinas';
  static String get forgotPassword => '$baseUrl/forgot-password';
  static String get verifyOtp => '$baseUrl/verify-otp';        
  static String get resetPassword => '$baseUrl/reset-password'; 
}