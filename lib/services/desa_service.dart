import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class DesaService {
  static final DesaService _instance = DesaService._internal();
  factory DesaService() => _instance;
  DesaService._internal();

  Future<List<Map<String, dynamic>>> getAllDesa() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/desa'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          final data = List<Map<String, dynamic>>.from(result['data']);
          return data;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDesaByKecamatan(int kecamatanId) async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/desa/by-kecamatan/$kecamatanId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['status'] == 'success') {
          return List<Map<String, dynamic>>.from(result['data']);
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllKecamatan() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/kecamatan'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['status'] == 'success') {
          return List<Map<String, dynamic>>.from(result['data']);
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}
