import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class DetailPenarikanScreen extends StatefulWidget {
  // ✅ TIDAK PERLU PARAMETER!
  const DetailPenarikanScreen({super.key});

  @override
  State<DetailPenarikanScreen> createState() => _DetailPenarikanScreenState();
}

class _DetailPenarikanScreenState extends State<DetailPenarikanScreen> {
  Map<String, dynamic>? _penarikanData;
  bool _isLoading = true;

  // ✅ FORMAT WIB LANGSUNG - TANPA KONVERSI!
  String _formatWIBFromString(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return '-';
    }

    try {
      final String str = value.toString();
      debugPrint("🕐 Raw tanggal: $str");

      DateTime dt;

      // ✅ HANDLE SEMUA FORMAT YANG MUNGKIN:

      // Format 1: "dd-MM-yyyy HH:mm" (contoh: 20-05-2026 03:29)
      if (RegExp(r'^\d{2}-\d{2}-\d{4} \d{2}:\d{2}$').hasMatch(str)) {
        dt = DateFormat('dd-MM-yyyy HH:mm').parse(str);
      }
      // Format 2: "yyyy-MM-dd HH:mm:ss" (contoh: 2026-05-20 14:30:00)
      else if (RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$').hasMatch(str)) {
        dt = DateFormat('yyyy-MM-dd HH:mm:ss').parse(str);
      }
      // Format 3: "yyyy-MM-dd HH:mm" (contoh: 2026-05-20 14:30)
      else if (RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$').hasMatch(str)) {
        dt = DateFormat('yyyy-MM-dd HH:mm').parse(str);
      }
      // Format 4: ISO string dengan Z (UTC)
      else if (str.endsWith('Z')) {
        dt = DateTime.parse(str).add(const Duration(hours: 7));
      }
      // Format 5: ISO string tanpa Z
      else if (str.contains('T')) {
        dt = DateTime.parse(str);
      }
      // Fallback: parse langsung
      else {
        dt = DateTime.parse(str);
      }

      // Format untuk tampilan
      final formatted = DateFormat('dd MMM yyyy, HH:mm').format(dt);
      debugPrint("✅ Format WIB: $formatted");
      return formatted;
    } catch (e) {
      debugPrint("❌ Error parsing tanggal: $e | Value: $value");
      return value.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPenarikanData();
  }

  // ✅ AMBIL DATA DARI SharedPreferences
  Future<void> _loadPenarikanData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString('last_penarikan_detail');

    if (mounted) {
      if (dataStr != null) {
        final data = jsonDecode(dataStr);

        debugPrint(
          "🔍 Raw nama from storage: '${data['nama']}' (type: ${data['nama']?.runtimeType})",
        );

        // ✅ FIX: Jika nama kosong/null, ambil dari user_data SharedPreferences
        if (data['nama'] == null ||
            data['nama'].toString().trim().isEmpty ||
            data['nama'].toString().toLowerCase() == 'null' ||
            data['nama'].toString() == '-' ||
            data['nama'].toString() == 'User') {
          final userDataStr = prefs.getString('user_data');

          if (userDataStr != null) {
            try {
              final userData = jsonDecode(userDataStr);
              data['nama'] = userData['nama'] ?? 'User';

              final fallbackNama = userData['nama']?.toString()?.trim();
              if (fallbackNama != null && fallbackNama.isNotEmpty) {
                data['nama'] = fallbackNama;
                debugPrint("✅ Fallback sukses: nama = '${data['nama']}'");
              }

              // Debug log
              debugPrint("🔄 Nama fallback dari user_data: ${data['nama']}");
            } catch (e) {
              debugPrint("❌ Gagal parse user_data: $e");
            }
          }
        }

        setState(() {
          _penarikanData = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ LOADING STATE
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_penarikanData != null) {
      debugPrint("🔍 Detail Penarikan Debug:");
      debugPrint("   nama: '${_penarikanData!['nama']}'");
      debugPrint("   status: '${_penarikanData!['status']}'");
    }

    // ✅ EMPTY STATE
    if (_penarikanData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF4CAF50),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Detail Penarikan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(
          child: Text(
            'Tidak ada data penarikan',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // ✅ NULL SAFETY UNTUK SEMUA FIELD
    final int idPenarikan =
        _penarikanData!['id_penarikan'] ?? _penarikanData!['id'] ?? 0;
    final String idTransaksi = '#TRX-${idPenarikan.toString().padLeft(5, '0')}';

    final String status = (_penarikanData!['status'] ?? 'Unknown').toString();
    final String tanggal = _formatWIBFromString(
      _penarikanData!['tanggal_penarikan'],
    );
    final String jenisEWallet = (_penarikanData!['jenis_ewallet'] ?? '-')
        .toString();
    final String nomorEWallet = (_penarikanData!['nomor_ewallet'] ?? '-')
        .toString();
    final double jumlahUang = (_penarikanData!['jumlah_uang'] ?? 0).toDouble();
    final String? alasanPenolakan = _penarikanData!['alasan_penolakan']
        ?.toString();
    final String? tanggalDisetujui = _penarikanData!['tanggal_disetujui']
        ?.toString();

    // ✅ TAMBAHKAN 2 BARIS INI DI SINI (di luar Column)
    final String jenisLayanan = (_penarikanData!['jenis_layanan'] ?? 'e-wallet')
        .toString();
    final String namaBank = (_penarikanData!['nama_bank'] ?? '-').toString();

    // ✅ FIX NAMA: Fallback ke user_data jika null
    String nama = (_penarikanData!['nama'] ?? '').toString();
    if (nama.isEmpty || nama == '-' || nama == 'null') {
      nama = 'User';
    }
    // Tentukan warna & icon status
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status.toLowerCase()) {
      case 'berhasil':
        statusColor = const Color(0xFF4CAF50);
        statusIcon = Icons.check_circle;
        statusText = 'Berhasil';
        break;
      case 'proses':
      case 'pending':
      case 'diproses':
        statusColor = const Color(0xFFFFC107);
        statusIcon = Icons.schedule;
        statusText = 'Diproses';
        break;
      case 'ditolak':
        statusColor = const Color(0xFFF44336);
        statusIcon = Icons.cancel;
        statusText = 'Ditolak';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = status;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Penarikan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ✅ STATUS BADGE BESAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: statusColor, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 24, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ✅ CARD INFO DETAIL
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    // ✅ ID TRANSAKSI (BARU - FORMAT #TRX-00062)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF4CAF50),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.confirmation_number,
                                size: 18,
                                color: Color(0xFF4CAF50),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'ID Transaksi',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            idTransaksi, // ✅ Format: #TRX-00062
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tanggal Pengajuan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tanggal Pengajuan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tanggal,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 32),

                    // Informasi Penarik
                    const Text(
                      'Informasi Penarik',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Nama',
                      nama,
                    ), // ✅ Nama sekarang tidak kosong
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Jenis Layanan',
                      jenisLayanan == 'bank' ? namaBank : jenisEWallet,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      jenisLayanan == 'bank'
                          ? 'Nomor Rekening'
                          : 'Nomor E-Wallet',
                      nomorEWallet,
                    ),

                    const Divider(height: 32),

                    // Nominal Penarikan
                    const Text(
                      'Detail Penarikan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Jumlah Penarikan',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          Text(
                            'Rp ${jumlahUang.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tanggal Disetujui (jika ada)
                    if (tanggalDisetujui != null &&
                        tanggalDisetujui.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow('Tanggal Disetujui', tanggalDisetujui),
                    ],

                    // Alasan Penolakan (jika ditolak)
                    if (status.toLowerCase() == 'ditolak' &&
                        alasanPenolakan != null &&
                        alasanPenolakan.isNotEmpty) ...[
                      const Divider(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Alasan Penolakan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              alasanPenolakan,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
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
    );
  }
}
