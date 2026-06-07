import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class WilayahService {
  // ✅ Ambil semua kecamatan
  static Future<List<Map<String, dynamic>>> getKecamatans() async {
    try {
      // ✅ HAPUS /api/ karena sudah ada di baseUrl
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/kecamatans'),
        headers: {'Content-Type': 'application/json'},
      );

      print('🔵 URL: ${ApiConfig.baseUrl}/kecamatans');
      print('🟢 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final result = List<Map<String, dynamic>>.from(data['data']);
          print('✅ Data count: ${result.length}');
          return result;
        }
      }
      return [];
    } catch (e) {
      print('🔴 Error get kecamatans: $e');
      return [];
    }
  }

  // ✅ Ambil desa berdasarkan kecamatan
  static Future<List<Map<String, dynamic>>> getDesas(int kecamatanId) async {
    try {
      // ✅ HAPUS /api/ karena sudah ada di baseUrl
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/desas?kecamatan_id=$kecamatanId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('🔵 URL: ${ApiConfig.baseUrl}/desas?kecamatan_id=$kecamatanId');
      print('🟢 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final result = List<Map<String, dynamic>>.from(data['data']);
          print('✅ Data count: ${result.length}');
          return result;
        }
      }
      return [];
    } catch (e) {
      print('🔴 Error get desas: $e');
      return [];
    }
  }
}
