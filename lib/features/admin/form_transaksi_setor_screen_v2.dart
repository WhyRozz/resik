import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import 'home_admin_screen.dart';
import 'package:dio/dio.dart'; // ✅ Tambah import di atas file
import '../../utils/request_manager.dart'; // ✅ Import helper

class FormTransaksiSetorScreenV2 extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String kodeQr;

  const FormTransaksiSetorScreenV2({
    super.key,
    required this.userData,
    required this.kodeQr,
  });

  @override
  State<FormTransaksiSetorScreenV2> createState() =>
      _FormTransaksiSetorScreenV2State();
}

class _FormTransaksiSetorScreenV2State
    extends State<FormTransaksiSetorScreenV2> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedJenisSampah;
  final _beratCtrl = TextEditingController();

  // ✅ FLAG untuk mencegah double submit
  bool _isProcessing = false;

  List<dynamic> _jenisSampahList = [];
  double _hargaPerKg = 0;
  double _totalHarga = 0;

  @override
  void initState() {
    super.initState();
    _fetchJenisSampah();
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

  // ✅ METHOD BARU YANG LEBIH DEFENSIVE
  Future<void> _handleSubmit() async {
    // ✅ GUARD: Cek flag
    if (_isProcessing) {
      debugPrint("⛔ Already processing - ignoring!");
      return;
    }

    // ✅ Validasi form
    if (!_formKey.currentState!.validate()) return;
    if (_selectedJenisSampah == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih jenis sampah'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ✅ SET flag + cancel pending request
    setState(() => _isProcessing = true);
    RequestManager().cancelPending(); // ✅ CANCEL request sebelumnya jika ada

    debugPrint("🔒 Processing locked - ${DateTime.now()}");

    try {
      final prefs = await SharedPreferences.getInstance();
      final petugasData = jsonDecode(prefs.getString('user_data') ?? '{}');

      final body = {
        'id_masyarakat': widget.userData['id_masyarakat'],
        'id_pns': widget.userData['id_pns'],
        'id_petugas': petugasData['id_petugas'],
        'id_jenis_sampah': int.parse(_selectedJenisSampah!),
        'berat': double.parse(_beratCtrl.text),
        'harga_per_kg': _hargaPerKg,
        'total_rupiah': _totalHarga,
        'tanggal_transaksi': DateTime.now().toIso8601String(),
      };

      debugPrint("📡 Sending POST request...");

      // ✅ PAKAI Dio dengan cancel token
      final response = await RequestManager().post(
        '${ApiConfig.baseUrl}/transaksi-setor',
        data: body,
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = response.data;
        if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Berhasil!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeAdminScreen()),
              (route) => false,
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Gagal'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        debugPrint("⚠️ Request cancelled by new request");
        return; // ✅ Jangan tampilkan error kalau di-cancel
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        debugPrint("🔓 Processing unlocked - ${DateTime.now()}");
      }
    }
  }

  String _formatRupiah(double angka) {
    return 'Rp ${angka.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final nama =
        widget.userData['nama'] ??
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
      body: WillPopScope(
        onWillPop: () async {
          // ✅ Prevent back button during processing
          if (_isProcessing) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sedang memproses, mohon tunggu...'),
                backgroundColor: Colors.orange,
              ),
            );
            return false;
          }
          return true;
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Pengguna
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
                      ? [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Memuat data...'),
                          ),
                        ]
                      : _jenisSampahList.map((jenis) {
                          return DropdownMenuItem<String>(
                            value: jenis['id_jenis_sampah'].toString(),
                            child: Text(jenis['jenis']),
                          );
                        }).toList(),
                  onChanged: _isProcessing ? null : _onJenisSampahChanged,
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
                  enabled: !_isProcessing,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
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

                // Harga per Kg
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

                // Total Harga
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

                // ✅ TOMBOL DENGAN PROTEKSI EXTRA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    // ✅ DISABLE jika sedang processing
                    onPressed: _isProcessing ? null : _handleSubmit,

                    // ✅ Force rebuild saat status berubah
                    key: ValueKey<bool>(_isProcessing),

                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _isProcessing ? 'Menyimpan...' : 'Simpan Transaksi',
                    ),
                    style: ElevatedButton.styleFrom(
                      // ✅ Visual feedback yang jelas
                      backgroundColor: _isProcessing
                          ? Colors.grey[400]
                          : const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[400],
                      disabledForegroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: _isProcessing ? 0 : 2,
                    ),
                  ),
                ),

                // ✅ INFO TEXT
                if (_isProcessing)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sedang memproses... Mohon jangan tap tombol lagi!',
                            style: TextStyle(
                              color: Colors.orange[900],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
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
