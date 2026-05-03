import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart'; // ✅ Import config

class DinasService {
  Future<List<Map<String, dynamic>>> getDinasList() async {
    try {
      // ✅ Pakai ApiConfig.dinas (bukan URL hardcoded .php)
      final response = await http.get(Uri.parse(ApiConfig.dinas));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        if (result['status'] == 'success') {
          // Return data dinas dari Laravel
          return List<Map<String, dynamic>>.from(result['data']);
        }
      }
      return [];
    } catch (e) {
      print(' Error fetch dinas: $e');
      return [];
    }
  }
}