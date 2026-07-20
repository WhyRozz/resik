import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import 'home_admin_screen.dart';
import 'package:dio/dio.dart';
import '../../utils/request_manager.dart';
import 'package:provider/provider.dart';
import '../../providers/statistik_provider.dart';

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

  bool _isProcessing = false;

  List<dynamic> _jenisSampahList = [];
  double _hargaPerKg = 0;
  double _totalHarga = 0;

  bool _isLoadingJenis = true;
  String? _jenisSampahError;

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
    // ✅ 1. Set loading true dan hapus error sebelumnya
    setState(() {
      _isLoadingJenis = true;
      _jenisSampahError = null;
    });

    try {
      final url = '${ApiConfig.baseUrl}/jenis-sampah';
      debugPrint('🔍 Fetching dari: $url');

      // ✅ 2. UBAH TIMEOUT JADI 30 DETIK (Hosting shared butuh waktu "bangun")
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          final data = result['data'] ?? [];
          debugPrint('✅ Loaded ${data.length} jenis sampah');

          setState(() {
            _jenisSampahList = data;
            _isLoadingJenis = false; // ✅ Selesai loading, data ada
          });
        } else {
          setState(() {
            _jenisSampahError = result['message'] ?? 'Gagal memuat data';
            _isLoadingJenis = false; // ✅ Selesai loading, tapi gagal
          });
        }
      } else {
        setState(() {
          _jenisSampahError = 'Server error: ${response.statusCode}';
          _isLoadingJenis = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Exception: $e');
      if (mounted) {
        setState(() {
          _jenisSampahError = 'Koneksi gagal atau timeout. Periksa internet.';
          _isLoadingJenis = false; // ✅ Selesai loading, tapi error
        });
      }
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

  Future<void> _handleSubmit() async {
    if (_isProcessing) {
      debugPrint("Already processing - ignoring!");
      return;
    }

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

    setState(() => _isProcessing = true);
    RequestManager().cancelPending();

    debugPrint("Processing locked - ${DateTime.now()}");

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
        'tanggal_transaksi': _formatDateTimeForBackend(DateTime.now()),
      };

      debugPrint("Sending POST request...");

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
              content: Text('Berhasil!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );

          // TAMBAH INI: Refresh statistik provider
          if (mounted) {
            context.read<StatistikProvider>().fetchStatistik();
          }

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
        debugPrint("Request cancelled by new request");
        return;
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
        debugPrint("Processing unlocked - ${DateTime.now()}");
      }
    }
  }

  String _formatRupiah(double angka) {
    return 'Rp ${angka.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String _formatDateTimeForBackend(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  // TAMBAH METHOD INI
  String _getPekerjaanText() {
    final tipe = widget.userData['tipe'] ?? 'masyarakat';

    if (tipe == 'pns') {
      final namaDinas = widget.userData['nama_dinas'] ?? '-';
      return 'ASN/PNS - $namaDinas';
    } else {
      final namaKecamatan = widget.userData['nama_kecamatan'] ?? '-';
      final namaDesa = widget.userData['nama_desa'] ?? '-';
      return 'Masyarakat - $namaKecamatan, $namaDesa';
    }
  }

  // TAMBAH METHOD INI
  String? _getFotoUrl() {
    final foto = widget.userData['foto'];
    if (foto == null || foto.toString().isEmpty) return null;

    if (foto.toString().startsWith('http')) {
      return foto.toString();
    }

    return '${ApiConfig.baseUrl}/uploads/$foto';
  }

  @override
  Widget build(BuildContext context) {
    final nama =
        widget.userData['nama'] ??
        widget.userData['nama_lengkap'] ??
        widget.userData['kode_anggota'] ??
        '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF2E7D32),
              size: 16,
            ),
          ),
          onPressed: () {
            // ✅ Langsung kembali ke HomeAdminScreen, hapus semua stack di atasnya
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeAdminScreen()),
              (route) => false,
            );
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.recycling_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Form Transaksi Setor',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: WillPopScope(
        onWillPop: () async {
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
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Pengguna Card
                _buildUserCard(nama),
                const SizedBox(height: 24),

                // Section Title
                _buildSectionTitle('Detail Setoran', 'Lengkapi data transaksi'),
                const SizedBox(height: 16),

                // Jenis Sampah Dropdown
                _buildDropdownField(),
                const SizedBox(height: 16),

                // Berat Input
                _buildBeratInput(),
                const SizedBox(height: 20),

                // Price Breakdown
                _buildPriceBreakdown(),
                const SizedBox(height: 24),

                // Submit Button
                _buildSubmitButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(String nama) {
    final fotoUrl = _getFotoUrl();
    final pekerjaan = _getPekerjaanText();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50), Color(0xFF66BB6A)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ HEADER: FOTO PROFIL + NAMA
          Row(
            children: [
              // ✅ FOTO PROFIL
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: fotoUrl != null
                      ? Image.network(
                          fotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.white.withOpacity(0.3),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.white.withOpacity(0.3),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.white.withOpacity(0.3),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Pengguna',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nama,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ PEKERJAAN (PENGGANTI TELEPON)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.work_outline_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pekerjaan,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ✅ QR CODE
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.qr_code_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.kodeQr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jenis Sampah',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B5E20),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),

        // ✅ LOGIKA UI BARU: Cek Loading, Error, atau Sukses

        // KONDISI 1: Sedang Loading
        if (_isLoadingJenis)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Memuat data jenis sampah...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        // KONDISI 2: Terjadi Error (Ada tombol Coba Lagi)
        else if (_jenisSampahError != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              children: [
                Text(
                  _jenisSampahError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _fetchJenisSampah, // ✅ Tombol Retry
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          )
        // KONDISI 3: Sukses (Data ada, tampilkan Dropdown)
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedJenisSampah,
              isExpanded: true,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: Colors.white,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF4CAF50),
              ),
              decoration: const InputDecoration(
                hintText: 'Pilih jenis sampah',
                hintStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFF4CAF50), width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              items: _jenisSampahList.map((jenis) {
                final satuan = jenis['satuan'] ?? 'kg';
                final hargaFormatted =
                    'Rp ${jenis['harga']?.toString() ?? '0'}';
                return DropdownMenuItem<String>(
                  value: jenis['id_jenis_sampah'].toString(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          jenis['jenis'] ?? '-',
                          style: const TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$hargaFormatted/$satuan',
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _isProcessing ? null : _onJenisSampahChanged,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Pilih jenis sampah';
                return null;
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBeratInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Berat Sampah',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B5E20),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _beratCtrl,
            enabled: !_isProcessing,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.scale_rounded, color: Color(0xFF4CAF50)),
              suffixText: 'kg',
              suffixStyle: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
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
        ),
      ],
    );
  }

  Widget _buildPriceBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calculate_rounded,
                  color: Color(0xFF2E7D32),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Rincian Harga',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPriceRow('Harga per Kg', _formatRupiah(_hargaPerKg), false),
          const SizedBox(height: 8),
          _buildPriceRow(
            'Berat',
            '${double.tryParse(_beratCtrl.text)?.toStringAsFixed(1) ?? '0.0'} kg',
            false,
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 12),
          _buildPriceRow('Total Harga', _formatRupiah(_totalHarga), true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14 : 12,
            color: isTotal ? const Color(0xFF1B5E20) : Colors.grey[600],
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 13,
            color: isTotal ? const Color(0xFF2E7D32) : const Color(0xFF1B5E20),
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isProcessing
                  ? Colors.grey[400]
                  : const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[400],
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: _isProcessing ? 0 : 4,
              shadowColor: const Color(0xFF2E7D32).withOpacity(0.4),
            ),
            child: _isProcessing
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Memproses...',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Simpan Transaksi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
        if (_isProcessing)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.orange[700],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sedang memproses... Mohon jangan tap tombol lagi!',
                    style: TextStyle(
                      color: Colors.orange[900],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
