
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart'; // Sesuaikan path jika perlu

class StatistikProvider with ChangeNotifier {
  Map<String, dynamic> _statistik = {};
  bool _isLoading = false;

  Map<String, dynamic> get statistik => _statistik;
  bool get isLoading => _isLoading;

  Future<void> fetchStatistik() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final adminData = jsonDecode(prefs.getString('user_data') ?? '{}');
      final adminId = adminData['id_petugas'];

      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/setor-statistics/$adminId'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          _statistik = result['data'] ?? {};
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetch statistik: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}