import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';
import 'home_admin_screen.dart';
import 'form_penjemputan_screen.dart';
import 'riwayat_penjemputan_admin_screen.dart';
import 'qr_barcode_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/statistik_provider.dart';

class RiwayatSetorAdminScreen extends StatefulWidget {
  const RiwayatSetorAdminScreen({super.key});

  @override
  State<RiwayatSetorAdminScreen> createState() =>
      _RiwayatSetorAdminScreenState();
}

class _RiwayatSetorAdminScreenState extends State<RiwayatSetorAdminScreen> {
  List<dynamic> _allTransactions = [];
  List<dynamic> _filteredTransactions = [];
  List<dynamic> _jenisSampahList = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  int _selectedIndex = 3;
  String _activeBubble = 'setor';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchJenisSampah();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([_fetchStatistics(), _fetchTransactions()]);
      _applyFilter();
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchJenisSampah() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/jenis-sampah-list'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            _jenisSampahList = result['data'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetch jenis sampah: $e');
    }
  }

  Future<void> _fetchStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminData = jsonDecode(prefs.getString('user_data') ?? '{}');
      final adminId = adminData['id_petugas'];

      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/setor-statistics/$adminId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            _statistics = result['data'] ?? {};
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetch statistics: $e');
    }
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminData = jsonDecode(prefs.getString('user_data') ?? '{}');
      final adminId = adminData['id_petugas'];

      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/setor-history/$adminId?status=$_selectedFilter',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          if (result['status'] == 'success') {
            setState(() {
              _allTransactions = result['data'] ?? [];
              _filteredTransactions = _allTransactions;
              _isLoading = false;
            });
          }
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'all') {
        _filteredTransactions = _allTransactions;
      } else if (_selectedFilter == 'pending') {
        _filteredTransactions = _allTransactions
            .where(
              (t) =>
                  !t['is_confirmed'] && t['status_transaksi'] != 'dibatalkan',
            )
            .toList();
      } else if (_selectedFilter == 'selesai') {
        _filteredTransactions = _allTransactions
            .where(
              (t) => t['is_confirmed'] && t['status_transaksi'] != 'dibatalkan',
            )
            .toList();
      } else if (_selectedFilter == 'dibatalkan') {
        _filteredTransactions = _allTransactions
            .where((t) => t['status_transaksi'] == 'dibatalkan')
            .toList();
      }
    });
  }

  void _showEditDialog(Map<String, dynamic> item) async {
    if (!item['can_edit']) {
      String reason = 'Tidak bisa diedit';
      if (item['is_confirmed'])
        reason = 'Sudah dikonfirmasi';
      else if (item['berat_asli'] != null)
        reason = 'Sudah pernah diedit';
      else if (item['is_expired'])
        reason = 'Sudah lebih dari 24 jam';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reason), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_jenisSampahList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading data jenis sampah...'),
          backgroundColor: Colors.blue,
        ),
      );
      await _fetchJenisSampah();
    }

    final beratCtrl = TextEditingController(text: item['berat'].toString());
    int selectedJenisId = item['id_jenis_sampah'];

    final selectedJenis = _jenisSampahList.firstWhere(
      (j) => j['id_jenis_sampah'] == selectedJenisId,
      orElse: () => {'harga': item['harga_per_kg']},
    );
    double hargaPerKg =
        selectedJenis['harga']?.toDouble() ?? item['harga_per_kg'];

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.2),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Edit & Konfirmasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF1F8E9), Color(0xFFE8F5E9)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          size: 16,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pengguna',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['nama_pengguna'] ?? '-',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Jenis Sampah
                if (_jenisSampahList.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jenis Sampah',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<int>(
                          value: selectedJenisId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          items: _jenisSampahList.map((jenis) {
                            final satuan = jenis['satuan'] ?? 'kg';
                            return DropdownMenuItem<int>(
                              value: jenis['id_jenis_sampah'],
                              child: Text(
                                '${jenis['jenis']} (Rp ${jenis['harga']}/$satuan)',
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedJenisId = val!;
                              final selected = _jenisSampahList.firstWhere(
                                (j) => j['id_jenis_sampah'] == val,
                              );
                              hargaPerKg = selected['harga'].toDouble();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // Berat
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Berat (kg)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: beratCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          hintText: '0.0',
                        ),
                        onChanged: (val) {
                          setDialogState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Estimasi Total
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4CAF50)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Estimasi Total:',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRupiah(
                          (double.tryParse(beratCtrl.text) ?? 0) * hargaPerKg,
                        ),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Warning
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Edit hanya bisa dilakukan 1 kali',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final berat = double.tryParse(beratCtrl.text);
                if (berat == null || berat <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Berat harus lebih dari 0'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                _konfirmasiSetor(item['id_transaksi'], selectedJenisId, berat);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Konfirmasi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceBetween,
        ),
      ),
    );
  }

  Future<void> _konfirmasiSetor(
    int idTransaksi,
    int idJenis,
    double berat,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Memproses...'),
        backgroundColor: Colors.blue,
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final adminData = jsonDecode(prefs.getString('user_data') ?? '{}');

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/konfirmasi-setor/$idTransaksi'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_jenis_sampah': idJenis,
          'berat': berat,
          'id_petugas': adminData['id_petugas'],
          'catatan': 'Dikonfirmasi Petugas',
        }),
      );

      final result = jsonDecode(response.body);
      if (mounted) {
        if (result['status'] == 'success') {
          context.read<StatistikProvider>().fetchStatistik();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berhasil dikonfirmasi!'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _tolakSetor(int idTransaksi) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.2),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: Colors.red.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Tolak Transaksi?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.grey.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Transaksi akan dibatalkan dan tidak bisa dikembalikan.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Tidak',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Ya, Tolak',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceBetween,
      ),
    );

    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Membatalkan transaksi...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );

      try {
        final response = await http
            .delete(Uri.parse('${ApiConfig.baseUrl}/tolak-setor/$idTransaksi'))
            .timeout(const Duration(seconds: 10));

        final result = jsonDecode(response.body);

        if (mounted) {
          if (result['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaksi berhasil dibatalkan'),
                backgroundColor: Colors.green,
              ),
            );
            await _loadData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Gagal'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeAdminScreen()),
            (route) => false,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
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
              'Riwayat Setor',
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
      body: Column(
        children: [
          // BUBBLE TABS
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildBubble(
                    'Riwayat Setor',
                    Icons.upload_rounded,
                    _activeBubble == 'setor',
                    () => setState(() => _activeBubble = 'setor'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBubble(
                    'Penjemputan',
                    Icons.local_shipping,
                    _activeBubble == 'penjemputan',
                    () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RiwayatPenjemputanAdminScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // STATISTICS CARDS
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '${_statistics['hari_ini'] ?? 0}',
                  'Transaksi',
                  Icons.receipt_long_rounded,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatItem(
                  _formatRupiah(_statistics['total_nominal_hari_ini'] ?? 0),
                  'Total',
                  Icons.attach_money_rounded,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatItem(
                  '${(_statistics['total_berat_hari_ini'] ?? 0).toStringAsFixed(1)} kg',
                  'Berat',
                  Icons.scale_rounded,
                ),
              ],
            ),
          ),

          // FILTER TABS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Semua', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending', 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Selesai', 'selesai'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Dibatalkan', 'dibatalkan'),
                ],
              ),
            ),
          ),

          // TRANSACTION LIST dengan PULL-TO-REFRESH
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF2E7D32),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredTransactions.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height - 300,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.inbox_rounded,
                                    size: 60,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tidak ada transaksi',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tarik ke bawah untuk refresh',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredTransactions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _buildTransactionCard(_filteredTransactions[index]),
                    ),
            ),
          ),

          // BOTTOM NAV
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.white),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
          _applyFilter();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                )
              : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> item) {
    final bool isPending =
        !item['is_confirmed'] && item['status_transaksi'] != 'dibatalkan';
    final bool isSelesai =
        item['is_confirmed'] && item['status_transaksi'] != 'dibatalkan';
    final bool isDibatalkan = item['status_transaksi'] == 'dibatalkan';
    final bool canEdit = item['can_edit'] ?? false;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isPending) {
      statusColor = Colors.orange;
      statusText = item['is_expired'] ? 'EXPIRED' : 'PENDING';
      statusIcon = Icons.schedule_rounded;
    } else if (isDibatalkan) {
      statusColor = Colors.red;
      statusText = 'DIBATALKAN';
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = const Color(0xFF2E7D32);
      statusText = 'SELESAI';
      statusIcon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? Colors.orange.withOpacity(0.3)
              : Colors.grey.shade200,
          width: isPending ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withOpacity(0.2),
                      statusColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['nama_pengguna'] ?? '-',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTanggal(item['tanggal_transaksi']),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 12),

          // PEKERJAAN
          if (item['pekerjaan'] != null &&
              item['pekerjaan'].toString().isNotEmpty)
            _buildInfoRow(
              'Pekerjaan',
              item['pekerjaan'],
              Icons.work_outline_rounded,
            ),

          // JENIS SAMPAH
          _buildInfoRow(
            'Jenis',
            item['jenis_sampah'] ?? '-',
            Icons.eco_outlined,
          ),

          // BERAT
          _buildInfoRow(
            'Berat',
            _formatBerat(item['berat']),
            Icons.scale_outlined,
          ),

          // BERAT ASLI (jika ada)
          if (item['berat_asli'] != null)
            _buildInfoRow(
              'Berat Asli',
              _formatBerat(item['berat_asli']),
              Icons.history_rounded,
            ),

          // TOTAL
          _buildInfoRow(
            'Total',
            _formatRupiah(item['total_rupiah']),
            Icons.payments_outlined,
            isBold: true,
          ),

          // CATATAN
          if (item['catatan_koreksi'] != null &&
              item['catatan_koreksi'].toString().isNotEmpty)
            _buildInfoRow(
              'Catatan',
              item['catatan_koreksi'],
              Icons.note_alt_outlined,
            ),

          const SizedBox(height: 16),

          // ACTION BUTTONS
          if (isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canEdit ? () => _showEditDialog(item) : null,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: Text(
                      canEdit ? 'Edit' : 'Tidak Bisa Edit',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: canEdit
                          ? const Color(0xFF2E7D32)
                          : Colors.grey,
                      side: BorderSide(
                        color: canEdit ? const Color(0xFF2E7D32) : Colors.grey,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _konfirmasiSetor(
                      item['id_transaksi'],
                      item['id_jenis_sampah'],
                      item['berat'].toDouble(),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text(
                      'Setujui',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: IconButton(
                    onPressed: () => _tolakSetor(item['id_transaksi']),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.red,
                      size: 18,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelesai
                    ? const Color(0xFF2E7D32).withOpacity(0.05)
                    : Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelesai ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: isSelesai ? const Color(0xFF2E7D32) : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isSelesai
                          ? 'Transaksi Selesai'
                          : (isDibatalkan ? 'Transaksi Ditolak' : '-'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelesai ? const Color(0xFF2E7D32) : Colors.red,
                      ),
                    ),
                  ),
                  if (item['tanggal_koreksi'] != null)
                    Text(
                      _formatTanggalKoreksi(item['tanggal_koreksi']),
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 12, color: const Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: isBold
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                )
              : null,
          color: isActive ? null : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : const Color(0xFF2E7D32),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF2E7D32),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'active': Icons.home, 'label': 'Beranda'},
      {'icon': Icons.qr_code_scanner, 'active': Icons.qr_code, 'label': 'Scan'},
      {
        'icon': Icons.local_shipping,
        'active': Icons.local_shipping,
        'label': 'Penjemputan',
      },
      {
        'icon': Icons.history_outlined,
        'active': Icons.history,
        'label': 'Riwayat',
      },
    ];

    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isActive = _selectedIndex == index;
          final item = items[index];
          return GestureDetector(
            onTap: () {
              if (index == 0) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeAdminScreen()),
                  (route) => false,
                );
              } else if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrBarcodeScreen()),
                );
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FormPenjemputanScreen(),
                  ),
                );
              }
              setState(() => _selectedIndex = index);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: isActive
                  ? BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(20),
                    )
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive
                        ? item['active'] as IconData
                        : item['icon'] as IconData,
                    color: isActive ? Colors.white : Colors.grey,
                    size: 22,
                  ),
                  if (isActive) const SizedBox(width: 6),
                  if (isActive)
                    Text(
                      item['label'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// FORMAT RUPIAH DENGAN TITIK
String _formatRupiah(dynamic value) {
  if (value == null) return 'Rp 0';
  double angka = value is num
      ? value.toDouble()
      : double.tryParse(value.toString()) ?? 0;
  return 'Rp ${angka.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
}

// FORMAT BERAT TANPA .0
String _formatBerat(dynamic value) {
  if (value == null) return '0 kg';
  double berat = value is num
      ? value.toDouble()
      : double.tryParse(value.toString()) ?? 0;

  if (berat == berat.toInt()) {
    return '${berat.toInt()} kg';
  }
  return '${berat.toStringAsFixed(1)} kg';
}

// FORMAT TANGGAL TRANSAKSI
String _formatTanggal(String? tanggalStr) {
  if (tanggalStr == null || tanggalStr.isEmpty) return '-';

  try {
    DateTime dt;

    if (tanggalStr.endsWith('Z')) {
      dt = DateTime.parse(tanggalStr);
      dt = dt.add(const Duration(hours: 7));
    } else {
      dt = DateTime.parse(tanggalStr);
    }

    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (e) {
    return tanggalStr;
  }
}

// FORMAT TANGGAL KOREKSI
String _formatTanggalKoreksi(String? tanggalStr) {
  if (tanggalStr == null || tanggalStr.isEmpty) return '-';

  try {
    DateTime dt;

    if (tanggalStr.endsWith('Z')) {
      dt = DateTime.parse(tanggalStr);
      dt = dt.add(const Duration(hours: 7));
    } else {
      dt = DateTime.parse(tanggalStr);
    }

    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (e) {
    return tanggalStr;
  }
}
