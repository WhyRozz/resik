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
  String _selectedFilter = 'all'; // all, pending, selesai, dibatalkan

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

  Widget _buildMiniStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF4CAF50)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
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
        // ✅ FIX: Exclude yang sudah dibatalkan
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
    // Cek apakah bisa edit
    if (!item['can_edit']) {
      String reason = 'Tidak bisa diedit';
      if (item['is_confirmed'])
        reason = 'Sudah dikonfirmasi';
      else if (item['berat_asli'] != null)
        reason = 'Sudah pernah diedit';
      else if (item['is_expired'])
        reason = 'Sudah lebih dari 24 jam';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ $reason'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Pastikan jenis sampah sudah load
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

    // Cari harga dari list
    final selectedJenis = _jenisSampahList.firstWhere(
      (j) => j['id_jenis_sampah'] == selectedJenisId,
      orElse: () => {'harga': item['harga_per_kg']},
    );
    double hargaPerKg =
        selectedJenis['harga']?.toDouble() ?? item['harga_per_kg'];

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental close
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit & Konfirmasi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pengguna: ${item['nama_pengguna']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (_jenisSampahList.isEmpty)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Loading...', style: TextStyle(color: Colors.grey)),
                    ],
                  )
                else
                  DropdownButtonFormField<int>(
                    value: selectedJenisId,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Sampah',
                      border: OutlineInputBorder(),
                    ),
                    items: _jenisSampahList.map((jenis) {
                      return DropdownMenuItem<int>(
                        value: jenis['id_jenis_sampah'],
                        child: Text(
                          '${jenis['jenis']} (Rp ${jenis['harga']}/kg)',
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
                const SizedBox(height: 12),
                TextField(
                  controller: beratCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Berat (kg)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    setDialogState(() {}); // Refresh untuk update total
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Estimasi Total:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'Rp ${((double.tryParse(beratCtrl.text) ?? 0) * hargaPerKg).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⚠️ Edit hanya bisa dilakukan 1 kali',
                          style: TextStyle(fontSize: 11, color: Colors.orange),
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
              child: const Text('Batal'),
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
                backgroundColor: const Color(0xFF4CAF50),
              ),
              child: const Text('Konfirmasi'),
            ),
          ],
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
          'catatan': 'Dikonfirmasi admin',
        }),
      );

      final result = jsonDecode(response.body);
      if (mounted) {
        if (result['status'] == 'success') {
          context.read<StatistikProvider>().fetchStatistik();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Berhasil dikonfirmasi!'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result['message']}'),
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
        title: const Text('Tolak Transaksi?'),
        content: const Text(
          'Transaksi akan dibatalkan dan tidak bisa dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Tolak'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Show loading
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
                content: Text('✅ Transaksi berhasil dibatalkan'),
                backgroundColor: Colors.green,
              ),
            );
            // ✅ Refresh data immediately
            await _loadData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${result['message']}'),
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeAdminScreen()),
            (route) => false,
          ),
        ),
        title: const Text(
          'Riwayat Setor',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          // ✅ BUBBLE TABS
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
                    'Riwayat Penjemputan',
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
          // ✅ STATISTICS CARDS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(
                  '${_statistics['hari_ini'] ?? 0}',
                  'Transaksi',
                  Icons.receipt,
                ),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                _buildMiniStat(
                  'Rp ${(_statistics['total_nominal_hari_ini'] ?? 0).toStringAsFixed(0)}',
                  'Total',
                  Icons.attach_money,
                ),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                _buildMiniStat(
                  '${(_statistics['total_berat_hari_ini'] ?? 0).toStringAsFixed(1)} kg',
                  'Berat',
                  Icons.scale,
                ),
              ],
            ),
          ),

          // ✅ FILTER TABS
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


          // ✅ TRANSACTION LIST
          // ✅ TRANSACTION LIST
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF4CAF50),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredTransactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada transaksi ${_selectedFilter == 'all' ? '' : _selectedFilter}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
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

          // ✅ BOTTOM NAV
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700]),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          _applyFilter();
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF4CAF50),
      checkmarkColor: Colors.white,
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
    if (isPending) {
      statusColor = Colors.orange;
      statusText = item['is_expired'] ? 'EXPIRED' : 'PENDING';
    } else if (isDibatalkan) {
      statusColor = Colors.red;
      statusText = 'DIBATALKAN';
    } else {
      statusColor = Colors.green;
      statusText = 'SELESAI';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.recycling,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setor Sampah',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    Text(
                      item['tanggal_transaksi'] ?? '-',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Pengguna', item['nama_pengguna'] ?? '-'),
          _buildInfoRow('Jenis', item['jenis_sampah'] ?? '-'),
          _buildInfoRow('Berat', '${item['berat']} kg'),
          if (item['berat_asli'] != null)
            _buildInfoRow('Berat Asli', '${item['berat_asli']} kg'),
          _buildInfoRow('Total', 'Rp ${item['total_rupiah']}'),
          if (item['catatan_koreksi'] != null)
            _buildInfoRow('Catatan', item['catatan_koreksi']),
          const SizedBox(height: 16),
          if (isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canEdit ? () => _showEditDialog(item) : null,
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text(canEdit ? 'Edit' : 'Tidak Bisa Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: canEdit ? null : Colors.grey,
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
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Konfirmasi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _tolakSetor(item['id_transaksi']),
                ),
              ],
            )
          else
            // ✅ Jika sudah selesai/dibatalkan, tampilkan status saja
            Row(
              children: [
                Expanded(
                  child: Text(
                    isSelesai
                        ? '✅ Transaksi Selesai'
                        : (isDibatalkan ? '❌ Transaksi Ditolak' : '-'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelesai
                          ? Colors.green
                          : (isDibatalkan ? Colors.red : Colors.grey),
                    ),
                  ),
                ),
                if (item['tanggal_koreksi'] != null)
                  Text(
                    '(${DateFormat('dd/MM HH:mm').format(DateTime.parse(item['tanggal_koreksi']))})',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1B5E20),
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
                  colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                )
              : null,
          color: isActive ? null : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : const Color(0xFF4CAF50),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF4CAF50),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                softWrap: false,
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
