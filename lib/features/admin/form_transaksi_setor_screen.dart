import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';

class FormTransaksiSetorScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String kodeQr;

  const FormTransaksiSetorScreen({
    super.key,
    required this.userData,
    required this.kodeQr,
  });

  @override
  State<FormTransaksiSetorScreen> createState() => _FormTransaksiSetorScreenState();
}

class _FormTransaksiSetorScreenState extends State<FormTransaksiSetorScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedJenisSampah;
  final _beratCtrl = TextEditingController();
  bool _isSubmitting = false;
  
  List<dynamic> _jenisSampahList = [];
  double _hargaPerKg = 0;
  double _totalHarga = 0;

  @override
  void initState() {
    super.initState();
    _fetchJenisSampah();
    
    // Listen untuk perubahan berat
    _beratCtrl.addListener(_hitungTotal);
  }

  @override
  void dispose() {
    _beratCtrl.removeListener(_hitungTotal);
    _beratCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchJenisSampah() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/jenis-sampah'))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success' && mounted) {
          setState(() {
            _jenisSampahList = result['data'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetch jenis sampah: $e');
    }
  }

  void _hitungTotal() {
    final berat = double.tryParse(_beratCtrl.text) ?? 0;
    setState(() {
      _totalHarga = berat * _hargaPerKg;
    });
  }

  void _onJenisSampahChanged(String? value) {
    setState(() {
      _selectedJenisSampah = value;
      
      // Cari harga dari jenis sampah yang dipilih
      final selected = _jenisSampahList.firstWhere(
        (item) => item['id_jenis_sampah'].toString() == value,
        orElse: () => null,
      );
      
      if (selected != null) {
        _hargaPerKg = double.tryParse(selected['harga'].toString()) ?? 0;
        _hitungTotal();
      }
    });
  }

  Future<void> _submitTransaksi() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedJenisSampah == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jenis sampah terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Ambil data petugas dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final petugasData = jsonDecode(prefs.getString('user_data') ?? '{}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/transaksi-setor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_masyarakat': widget.userData['id_masyarakat'],
          'id_pns': widget.userData['id_pns'],
          'id_petugas': petugasData['id_petugas'],
          'id_jenis_sampah': int.parse(_selectedJenisSampah!),
          'berat': double.parse(_beratCtrl.text),
          'harga_per_kg': _hargaPerKg,
          'total_rupiah': _totalHarga,
          'tanggal_transaksi': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success' && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Transaksi setoran berhasil!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Gagal menyimpan transaksi')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Koneksi error: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  String _formatRupiah(double angka) {
    return 'Rp ${angka.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final nama = widget.userData['nama'] ?? 
                 widget.userData['nama_lengkap'] ?? 
                 widget.userData['kode_anggota'] ?? 
                 '-';
    final telepon = widget.userData['no_telepon'] ?? '-';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: const Text(
          'Form Transaksi Setor',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Info Pengguna
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person, color: Color(0xFF4CAF50)),
                        SizedBox(width: 8),
                        Text(
                          'Data Pengguna',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Nama', nama),
                    _buildInfoRow('No. Telepon', telepon),
                    _buildInfoRow('Kode QR', widget.kodeQr),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ✅ Form Transaksi
              const Text(
                'Detail Setoran',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 12),
              
              // Jenis Sampah
              DropdownButtonFormField<String>(
                value: _selectedJenisSampah,
                decoration: const InputDecoration(
                  labelText: 'Jenis Sampah',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                hint: const Text('Pilih jenis sampah'),
                items: _jenisSampahList.isEmpty
                    ? [const DropdownMenuItem(value: null, child: Text('Memuat data...'))]
                    : _jenisSampahList.map((jenis) {
                        return DropdownMenuItem<String>(
                          value: jenis['id_jenis_sampah'].toString(),
                          child: Text(jenis['jenis']),
                        );
                      }).toList(),
                onChanged: _jenisSampahList.isEmpty ? null : _onJenisSampahChanged,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Pilih jenis sampah';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Berat
              TextFormField(
                controller: _beratCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Berat (kg)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.scale),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Masukkan berat sampah';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Masukkan angka yang valid';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Berat harus lebih dari 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ✅ Harga per Kg (Read Only)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Harga per Kg',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      _formatRupiah(_hargaPerKg),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Total Harga (Read Only - Auto Calculate)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4CAF50)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Harga',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    Text(
                      _formatRupiah(_totalHarga),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ✅ Tombol Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitTransaksi,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSubmitting ? 'Menyimpan...' : 'Simpan Transaksi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 13, color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B5E20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}