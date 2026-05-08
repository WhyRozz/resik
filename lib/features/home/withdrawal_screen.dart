import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _nomorEWalletCtrl = TextEditingController();
  final _nominalCtrl = TextEditingController();

  String? _selectedEWallet;
  bool _isLoading = false;
  Map<String, dynamic>? _userData;

  final List<String> _eWalletOptions = ['Dana', 'OVO', 'GoPay', 'ShopeePay'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nomorEWalletCtrl.dispose();
    _nominalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null && mounted) {
      setState(() {
        _userData = jsonDecode(userData);
        _namaCtrl.text = _userData?['nama'] ?? '';
      });
    }
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

    setState(() => _isLoading = true);

    try {
      final tipeUser = _userData!['tipe'];
      final userId = _userData!['id_masyarakat'] ?? _userData!['id_pns'];
      final nominalRaw = _nominalCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
      final jumlahUang = double.tryParse(nominalRaw) ?? 0;

      // ✅ DEBUG: Print request yang dikirim
      debugPrint("📤 Request URL: ${ApiConfig.penarikanStore}");
      debugPrint(
        "📤 Request Body: ${jsonEncode({'id_masyarakat': tipeUser == 'masyarakat' ? userId : null, 'id_pns': tipeUser == 'pns' ? userId : null, 'tipe_user': tipeUser, 'nama': _namaCtrl.text, 'jenis_ewallet': _selectedEWallet, 'nomor_ewallet': _nomorEWalletCtrl.text, 'jumlah_uang': jumlahUang})}",
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
              'jenis_ewallet': _selectedEWallet,
              'nomor_ewallet': _nomorEWalletCtrl.text,
              'jumlah_uang': jumlahUang,
            }),
          )
          .timeout(const Duration(seconds: 30));

      // ✅ DEBUG: Print response mentah
      debugPrint("📥 Status Code: ${response.statusCode}");
      debugPrint("📥 RAW Response: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final result = jsonDecode(response.body);

          if (mounted) {
            setState(() => _isLoading = false);

            if (result['status'] == 'success') {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Color(0xFF2E7D32),
                        size: 32,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Berhasil!',
                        style: TextStyle(color: Color(0xFF1B5E20)),
                      ),
                    ],
                  ),
                  content: const Text(
                    'Pengajuan penarikan berhasil diajukan.\n\n'
                    '💰 Saldo Anda telah dikurangi\n'
                    '⏰ Dana akan ditransfer dalam 1-3 hari kerja\n'
                    '📱 Cek status di Riwayat Penarikan',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Back to previous screen
                      },
                      child: const Text(
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
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 20),
                child: Image.asset(
                  'assets/images/withdrawal.png',
                  height: 150,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.money, size: 80, color: Colors.white),
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
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
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
                          const SizedBox(height: 8),
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
                                borderSide: const BorderSide(
                                  color: Color(0xFF4CAF50),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Nama lengkap wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          _buildLabel('E-Wallet'),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedEWallet,
                              decoration: InputDecoration(
                                hintText: 'Pilih E-Wallet',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              items: _eWalletOptions.map((String wallet) {
                                return DropdownMenuItem<String>(
                                  value: wallet,
                                  child: Text(
                                    wallet,
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) =>
                                  setState(() => _selectedEWallet = newValue),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'E-Wallet wajib dipilih'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildLabel('Nomor E-Wallet'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nomorEWalletCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Masukkan nomor e-wallet anda',
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
                                borderSide: const BorderSide(
                                  color: Color(0xFF4CAF50),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Nomor e-wallet wajib diisi';
                              if (value.length < 10) return 'Nomor tidak valid';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildLabel('Nominal Penarikan'),
                          const SizedBox(height: 8),
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
                                borderSide: const BorderSide(
                                  color: Color(0xFF4CAF50),
                                  width: 2,
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
                                return 'Minimal penarikan Rp. 50.000';
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitWithdrawal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Kirim',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Montserrat',
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

  // ✅ PINDAHKAN METHOD INI KE LUAR build() METHOD
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1B5E20),
        fontFamily: 'Montserrat',
      ),
    );
  }
}
