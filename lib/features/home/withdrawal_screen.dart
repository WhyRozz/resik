import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaPenerimaCtrl = TextEditingController();
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
    _namaPenerimaCtrl.dispose();
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
                  // ✅ Format saldo dengan pemisah ribuan (titik)
                  final formatRupiah = NumberFormat('#,##0', 'id_ID');
                  _saldoText = "Rp ${formatRupiah.format(saldo)}";
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
        // Jangan auto-fill nama_penerima, biarkan user ketik sendiri
      });

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
        "📤 Request Body: ${jsonEncode({'id_masyarakat': tipeUser == 'masyarakat' ? userId : null, 'id_pns': tipeUser == 'pns' ? userId : null, 'tipe_user': tipeUser, 'nama_pene': _namaPenerimaCtrl.text, 'jenis_layanan': _selectedJenisLayanan, 'jenis_ewallet': _selectedJenisLayanan == 'bank' ? null : _selectedProvider, 'nama_bank': _selectedJenisLayanan == 'bank' ? _selectedProvider : null, 'nomor_ewallet': _nomorRekeningCtrl.text, 'jumlah_uang': jumlahUang})}",
      );

      final response = await http
          .post(
            Uri.parse(ApiConfig.penarikanStore),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id_masyarakat': tipeUser == 'masyarakat' ? userId : null,
              'id_pns': tipeUser == 'pns' ? userId : null,
              'tipe_user': tipeUser,
              'nama_penerima': _namaPenerimaCtrl.text, // GANTI DENGAN INI
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
                'nama_penerima': _namaPenerimaCtrl.text,
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
                barrierDismissible: false,
                builder: (context) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✅ Icon Sukses dengan Background
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF4CAF50).withOpacity(0.3),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ✅ Judul
                        Text(
                          'Pengajuan Berhasil!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ✅ Subtitle
                        Text(
                          'Penarikan dana Anda sedang diproses',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ✅ Info Cards
                        _buildInfoCard(
                          icon: Icons.account_balance_wallet_rounded,
                          title: 'Saldo Dikurangi',
                          subtitle:
                              'Saldo Anda telah dikurangi secara otomatis',
                          iconColor: Color(0xFF2196F3),
                        ),

                        const SizedBox(height: 12),

                        _buildInfoCard(
                          icon: Icons.access_time_rounded,
                          title: 'Estimasi Transfer',
                          subtitle: '1-3 hari kerja',
                          iconColor: Color(0xFFFF9800),
                        ),

                        const SizedBox(height: 12),

                        _buildInfoCard(
                          icon: Icons.history_rounded,
                          title: 'Cek Status',
                          subtitle: 'Pantau status di menu Riwayat Penarikan',
                          iconColor: Color(0xFF9C27B0),
                        ),

                        const SizedBox(height: 28),

                        // ✅ Tombol OK
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4CAF50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Mengerti',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
        leading: Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Pengajuan Penarikan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
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

              // SALDO CARD - Tampilkan saldo aktual
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
                          // ===== DATA PRIBADI =====
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2E7D32),
                                      Color(0xFF4CAF50),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF4CAF50,
                                      ).withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_outline_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Data Pribadi',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Informasi penerima penarikan',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildInputField(
                            controller: _namaPenerimaCtrl, // GANTI CONTROLLER
                            label: 'Nama Penerima', // GANTI LABEL
                            hint: 'Masukkan nama penerima', // GANTI HINT
                            prefixIcon: Icons.person_outline_rounded,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Nama penerima wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 8),

                          const SizedBox(height: 8),
                          _buildDropdownField(
                            label: 'Jenis Layanan',
                            hint: 'Pilih jenis layanan',
                            prefixIcon: Icons.category_rounded,
                            value: _selectedJenisLayanan,
                            items: _jenisLayananOptions.map((jenis) {
                              return DropdownMenuItem<String>(
                                value: jenis.toLowerCase().contains('bank')
                                    ? 'bank'
                                    : 'e-wallet',
                                child: Text(jenis),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedJenisLayanan = newValue;
                                _selectedProvider = null;
                              });
                            },
                            validator: (value) => value == null || value.isEmpty
                                ? 'Jenis layanan wajib dipilih'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          if (_selectedJenisLayanan != null) ...[
                            _buildDropdownField(
                              label: _selectedJenisLayanan == 'bank'
                                  ? 'Pilih Bank'
                                  : 'Pilih E-Wallet',
                              hint: _selectedJenisLayanan == 'bank'
                                  ? 'Pilih Bank'
                                  : 'Pilih E-Wallet',
                              prefixIcon: _selectedJenisLayanan == 'bank'
                                  ? Icons.account_balance_rounded
                                  : Icons.account_balance_wallet_rounded,
                              value: _selectedProvider,
                              items:
                                  (_selectedJenisLayanan == 'bank'
                                          ? _bankOptions
                                          : _eWalletOptions)
                                      .map((provider) {
                                        return DropdownMenuItem<String>(
                                          value: provider,
                                          child: Text(provider),
                                        );
                                      })
                                      .toList(),
                              onChanged: (newValue) {
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
                            const SizedBox(height: 16),
                          ],

                          _buildInputField(
                            controller: _nomorRekeningCtrl,
                            label: _selectedJenisLayanan == 'bank'
                                ? 'Nomor Rekening'
                                : 'Nomor E-Wallet',
                            hint: _selectedJenisLayanan == 'bank'
                                ? 'Contoh: 1234567890'
                                : 'Contoh: 081234567890',
                            prefixIcon: _selectedJenisLayanan == 'bank'
                                ? Icons.credit_card_rounded
                                : Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone,
                            validator: _selectedJenisLayanan == 'bank'
                                ? _validateNomorRekening
                                : _validateEWalletNumber,
                          ),
                          const SizedBox(height: 16),

                          // ===== NOMINAL PENARIKAN =====
                          Text(
                            'Nominal Penarikan',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          const SizedBox(height: 8),

                          const SizedBox(height: 1),
                          TextFormField(
                            controller: _nominalCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              _RupiahFormatter(),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Nominal',
                              labelStyle: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1B5E20),
                                fontWeight: FontWeight.w600,
                              ),
                              hintText: 'Minimal Rp 50.000',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FBF9),
                              prefixIcon: Container(
                                margin: const EdgeInsets.only(
                                  left: 12,
                                  right: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.attach_money_rounded,
                                      size: 16,
                                      color: Color(0xFF2E7D32),
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      'Rp',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 0,
                                minHeight: 0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4CAF50),
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
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
                                return 'Minimal penarikan Rp 50.000';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // ===== TOMBOL SUBMIT =====
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitWithdrawal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                disabledBackgroundColor: Colors.grey[400],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                                shadowColor: const Color(
                                  0xFF2E7D32,
                                ).withOpacity(0.4),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Ajukan Penarikan',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
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

  // ===== SECTION HEADER =====
  Widget _buildSectionHeader({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===== INPUT FIELD =====
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF1B5E20),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF9FBF9),
            prefixIcon: Icon(
              prefixIcon,
              color: const Color(0xFF4CAF50),
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  // ===== DROPDOWN FIELD =====
  Widget _buildDropdownField({
    required String label,
    required String hint,
    required IconData prefixIcon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF1B5E20),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF9FBF9),
            prefixIcon: Icon(
              prefixIcon,
              color: const Color(0xFF4CAF50),
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: items,
          onChanged: onChanged,
          validator: validator,
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  // ===== INFO CARD HELPER (UNTUK NOTIFIKASI SUKSES) =====
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// CLASS: Formatter untuk format Rupiah dengan titik
class _RupiahFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Ambil hanya angka
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (newText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Format dengan titik sebagai pemisah ribuan
    String formattedText = '';
    int counter = 0;

    for (int i = newText.length - 1; i >= 0; i--) {
      formattedText = newText[i] + formattedText;
      counter++;
      if (counter % 3 == 0 && i != 0) {
        formattedText = '.$formattedText';
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
