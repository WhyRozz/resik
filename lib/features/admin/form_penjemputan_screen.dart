import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/api_config.dart';

class FormPenjemputanScreen extends StatefulWidget {
  const FormPenjemputanScreen({super.key});

  @override
  State<FormPenjemputanScreen> createState() => _FormPenjemputanScreenState();
}

class _FormPenjemputanScreenState extends State<FormPenjemputanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lokasiCtrl = TextEditingController();
  final _beratCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();
  File? _foto;
  bool _isSubmitting = false;
  Map<String, dynamic>? _adminData;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null && mounted) {
      setState(() => _adminData = jsonDecode(userData));
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) {
      setState(() => _foto = File(picked.path));
    }
  }

  Future<void> _submitPenjemputan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final adminData = jsonDecode(prefs.getString('user_data') ?? '{}');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/penjemputan'),
      );

      request.fields['nama_admin'] = adminData['nama_lengkap'] ?? 'Admin';
      request.fields['waktu'] = DateTime.now().toIso8601String();
      request.fields['berat'] = _beratCtrl.text;
      request.fields['lokasi'] = _lokasiCtrl.text;
      request.fields['keterangan'] = _keteranganCtrl.text;
      request.fields['status'] = 'diproses';

      if (_foto != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', _foto!.path));
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (mounted) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          final result = jsonDecode(response.body);
          if (result['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Pengajuan penjemputan berhasil!'),
                backgroundColor: Color(0xFF4CAF50),
              ),
            );
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Gagal'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Server error'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: const Text('Form Penjemputan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Foto Bukti
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _foto != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_foto!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Tap untuk ambil foto', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Lokasi
              TextFormField(
                controller: _lokasiCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lokasi Penjemputan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 2,
                validator: (v) => v == null || v.isEmpty ? 'Lokasi wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // ✅ Estimasi Berat
              TextFormField(
                controller: _beratCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Estimasi Berat (kg)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.scale),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Berat wajib diisi';
                  if (double.tryParse(v) == null) return 'Masukkan angka';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ✅ Keterangan
              TextFormField(
                controller: _keteranganCtrl,
                decoration: const InputDecoration(
                  labelText: 'Keterangan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // ✅ Tombol Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitPenjemputan,
                  icon: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: Text(_isSubmitting ? 'Mengirim...' : 'Ajukan Penjemputan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _lokasiCtrl.dispose();
    _beratCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }
}