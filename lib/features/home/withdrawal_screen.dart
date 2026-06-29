import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'package:intl/intl.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _nomorRekeningCtrl = TextEditingController();
  final _nominalCtrl = TextEditingController();

  String? _selectedJenisLayanan;
  String? _selectedProvider;

  bool _isLoading = false; // ✅ TAMBAH INI (untuk loading button)
  bool _isLoadingSaldo = true; // ✅ Sudah ada
  Map<String, dynamic>? _userData;

  // ✅ TAMBAH: Variabel angka untuk kalkulasi
  double _saldo = 0.0;
  String _saldoText = "Rp 0"; // ✅ Sudah ada (untuk display)

  final List<String> _jenisLayananOptions = ['E-Wallet', 'Bank Transfer'];
  final List<String> _eWalletOptions = ['Dana', 'OVO', 'GoPay', 'ShopeePay'];
  final List<String> _bankOptions = [
    'Bank BCA',
    'Bank BRI',
    'Bank Mandiri',
    'Bank Jatim',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nomorRekeningCtrl.dispose();
    _nominalCtrl.dispose();
    super.dispose();
  }

  // ✅ METHOD FETCH SALDO (sama seperti di dashboard)
  Future<void> _fetchSaldo() async {
    if (_userData == null) {
      debugPrint("⚠️ _fetchSaldo: _userData masih null!");
      return;
    }

    debugPrint("🔄 Fetching saldo untuk user: ${_userData!['nama']}");

    try {
      final userId = (_userData!['id_masyarakat'] ?? _userData!['id_pns'])
          .toString();
      final userType = _userData!['tipe'];

      final uri = Uri.parse(
        ApiConfig.getSaldo,
      ).replace(queryParameters: {'user_id': userId, 'tipe': userType});

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      debugPrint("📥 Status Code: ${response.statusCode}");
      debugPrint("📄 RAW Response Body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final result = jsonDecode(response.body);
          debugPrint("🔍 Parsed Result: $result");

          if (mounted) {
            if (result['status'] == 'success') {
              final data = result['data'];

              if (data.containsKey('saldo')) {
                final saldoRaw = data['saldo'];
                final saldo = saldoRaw is num
                    ? saldoRaw
                    : double.tryParse(saldoRaw.toString()) ?? 0;

                debugPrint("✅ Saldo: $saldo");

                setState(() {
                  // Format saldo: hapus .00 jika bilangan bulat
                  _saldoText = "Rp ${saldo.toStringAsFixed(0)}";
                  _saldo = saldo.toDouble();
                  _isLoadingSaldo = false;
                });
              }
            }
          }
        } catch (jsonError) {
          debugPrint("🚨 JSON Decode Error: $jsonError");
        }
      }
    } catch (e) {
      debugPrint("🚨 Exception: $e");
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');

    if (userData != null && mounted) {
      setState(() {
        _userData = jsonDecode(userData);
        _namaCtrl.text = _userData?['nama'] ?? '';
      });

      // ✅ FETCH SALDO SETELAH USER DATA LOAD
      _fetchSaldo();
    }
  }

  // ✅ Method 1: Validator E-Wallet (TERPISAH)
  String? _validateEWalletNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor e-wallet tidak boleh kosong';
    }
    final phoneRegex = RegExp(r'^08[0-9]{8,11}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Format nomor tidak valid (contoh: 081234567890)';
    }
    return null;
  }

  // ✅ Method 2: Validator Bank (TERPISAH, sejajar dengan method 1)
  String? _validateNomorRekening(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor rekening tidak boleh kosong';
    }
    final rekeningRegex = RegExp(r'^[0-9]{8,16}$');
    if (!rekeningRegex.hasMatch(value.trim())) {
      return 'Format nomor rekening tidak valid (8-16 digit)';
    }
    return null;
  }

  Future<void> _submitWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;

    if (_userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login ulang'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final nominalRaw = _nominalCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
    final jumlahUang = double.tryParse(nominalRaw) ?? 0;

    // ✅ CEK SALDO CUKUP ATAU TIDAK
    if (jumlahUang > _saldo) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Saldo Tidak Mencukupi',
                  style: TextStyle(color: Color(0xFF1B5E20)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Maaf, saldo Anda tidak mencukupi untuk penarikan ini.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Tutup',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tipeUser = _userData!['tipe'];
      final userId = _userData!['id_masyarakat'] ?? _userData!['id_pns'];

      debugPrint("📤 Request URL: ${ApiConfig.penarikanStore}");
      debugPrint(
        "📤 Request Body: ${jsonEncode({'id_masyarakat': tipeUser == 'masyarakat' ? userId : null, 'id_pns': tipeUser == 'pns' ? userId : null, 'tipe_user': tipeUser, 'nama': _namaCtrl.text, 'jenis_layanan': _selectedJenisLayanan, 'jenis_ewallet': _selectedJenisLayanan == 'bank' ? null : _selectedProvider, 'nama_bank': _selectedJenisLayanan == 'bank' ? _selectedProvider : null, 'nomor_ewallet': _nomorRekeningCtrl.text, 'jumlah_uang': jumlahUang})}",
      );

      final response = await http
          .post(
            Uri.parse(ApiConfig.penarikanStore),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id_masyarakat': tipeUser == 'masyarakat' ? userId : null,
              'id_pns': tipeUser == 'pns' ? userId : null,
              'tipe_user': tipeUser,
              'nama': _namaCtrl.text,
              'jenis_layanan': _selectedJenisLayanan ?? 'e-wallet',
              'jenis_ewallet': _selectedJenisLayanan == 'bank'
                  ? null
                  : _selectedProvider,
              'nama_bank': _selectedJenisLayanan == 'bank'
                  ? _selectedProvider
                  : null,
              'nomor_ewallet': _nomorRekeningCtrl.text,
              'jumlah_uang': jumlahUang,
            }),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint("📥 Status Code: ${response.statusCode}");
      debugPrint("📥 RAW Response: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final result = jsonDecode(response.body);

          if (mounted) {
            setState(() => _isLoading = false);

            if (result['status'] == 'success') {
              final prefs = await SharedPreferences.getInstance();

              final penarikanData = {
                'id_penarikan': result['data']?['id'],
                'id': result['data']?['id'],
                'nama': _namaCtrl.text,
                'jenis_layanan': _selectedJenisLayanan,
                'jenis_ewallet': _selectedJenisLayanan == 'bank'
                    ? null
                    : _selectedProvider,
                'nama_bank': _selectedJenisLayanan == 'bank'
                    ? _selectedProvider
                    : null,
                'nomor_ewallet': _nomorRekeningCtrl.text,
                'jumlah_uang': jumlahUang,
                'status': result['data']?['status'] ?? 'Diproses',
                'tanggal_penarikan': DateFormat(
                  'yyyy-MM-dd HH:mm:ss',
                ).format(DateTime.now()),
                'alasan_penolakan': result['data']?['alasan_penolakan'],
                'tanggal_disetujui': result['data']?['tanggal_disetujui'],
              };

              await prefs.setString(
                'last_penarikan_detail',
                jsonEncode(penarikanData),
              );

              // ✅ Update saldo di SharedPreferences
              final newSaldo = _saldo - jumlahUang;
              await prefs.setDouble('saldo', newSaldo);

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Color(0xFF2E7D32),
                        size: 28,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Berhasil!',
                        style: TextStyle(color: Color(0xFF1B5E20)),
                      ),
                    ],
                  ),
                  content: Text(
                    'Pengajuan penarikan berhasil diajukan.\n\n'
                    '💰 Saldo Anda telah dikurangi\n'
                    '⏰ Dana akan ditransfer dalam 1-3 hari kerja\n'
                    '📱 Cek status di Riwayat Penarikan',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Terjadi kesalahan'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          debugPrint("🚨 JSON Parse Error: $e");
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Response bukan JSON valid: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Server error: ${response.statusCode}\n${response.body.substring(0, 200)}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("🚨 Exception: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal terhubung ke server: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pengajuan Penarikan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Ilustrasi
              Container(
                margin: EdgeInsets.only(top: 20),
                child: Image.asset(
                  'assets/images/penarikan-pict.png',
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      margin: EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.money, size: 60, color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            'Ilustrasi Penarikan',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ✅ SALDO CARD - Tampilkan saldo aktual
              // ✅ SALDO CARD - dengan loading state
              Container(
                margin: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo Tersedia',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1B5E20),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Silahkan ajukan penarikan',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                    // ✅ LOADING INDICATOR ATAU SALDO
                    _isLoadingSaldo
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF4CAF50),
                            ),
                          )
                        : Text(
                            _saldoText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                              fontFamily: 'Montserrat',
                            ),
                          ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: 0),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Nama Lengkap'),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _namaCtrl,
                            decoration: InputDecoration(
                              hintText: 'Masukkan nama lengkap anda',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Color(0xFF4CAF50),
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Nama lengkap wajib diisi'
                                : null,
                          ),
                          SizedBox(height: 20),
                          // Dropdown 1: Pilih Jenis Layanan
                          _buildLabel('Jenis Layanan'),
                          SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedJenisLayanan,
                              decoration: InputDecoration(
                                hintText: 'Pilih Jenis Layanan',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              items: _jenisLayananOptions.map((String jenis) {
                                return DropdownMenuItem<String>(
                                  value: jenis.toLowerCase().contains('bank')
                                      ? 'bank'
                                      : 'e-wallet',
                                  child: Text(jenis),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedJenisLayanan = newValue;
                                  _selectedProvider =
                                      null; // Reset provider saat ganti jenis
                                });
                              },
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Jenis layanan wajib dipilih'
                                  : null,
                            ),
                          ),
                          SizedBox(height: 20),

                          // Dropdown 2: Pilih Provider (E-Wallet atau Bank)
                          if (_selectedJenisLayanan != null) ...[
                            _buildLabel(
                              _selectedJenisLayanan == 'bank'
                                  ? 'Pilih Bank'
                                  : 'Pilih E-Wallet',
                            ),
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedProvider,
                                decoration: InputDecoration(
                                  hintText: _selectedJenisLayanan == 'bank'
                                      ? 'Pilih Bank'
                                      : 'Pilih E-Wallet',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                items:
                                    (_selectedJenisLayanan == 'bank'
                                            ? _bankOptions
                                            : _eWalletOptions)
                                        .map((String provider) {
                                          return DropdownMenuItem<String>(
                                            value: provider,
                                            child: Text(provider),
                                          );
                                        })
                                        .toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedProvider = newValue;
                                  });
                                },
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? (_selectedJenisLayanan == 'bank'
                                          ? 'Bank wajib dipilih'
                                          : 'E-Wallet wajib dipilih')
                                    : null,
                              ),
                            ),
                            SizedBox(height: 20),
                          ],
                          _buildLabel(
                            _selectedJenisLayanan == 'bank'
                                ? 'Nomor Rekening'
                                : 'Nomor E-Wallet',
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _nomorRekeningCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: _selectedJenisLayanan == 'bank'
                                  ? 'Contoh: 1234567890'
                                  : 'Contoh: 081234567890',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Color(0xFF4CAF50),
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            validator: _selectedJenisLayanan == 'bank'
                                ? _validateNomorRekening
                                : _validateEWalletNumber,
                          ),
                          SizedBox(height: 20),
                          _buildLabel('Nominal Penarikan'),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _nominalCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Minimal Rp. 50.000',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Color(0xFF4CAF50),
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Nominal wajib diisi';
                              final nominal =
                                  int.tryParse(
                                    value.replaceAll(RegExp(r'[^\d]'), ''),
                                  ) ??
                                  0;
                              if (nominal < 50000)
                                return 'Minimal penarikan Rp. 50.000';
                              return null;
                            },
                          ),
                          SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitWithdrawal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Kirim',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1B5E20),
        fontFamily: 'Montserrat',
      ),
    );
  }
}
