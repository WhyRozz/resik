import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';

class RiwayatAdminScreen extends StatefulWidget {
  const RiwayatAdminScreen({super.key});

  @override
  State<RiwayatAdminScreen> createState() => _RiwayatAdminScreenState();
}

class _RiwayatAdminScreenState extends State<RiwayatAdminScreen> {
  String _activeBubble = 'setor'; // 'setor' atau 'penjemputan'
  List<dynamic> _riwayatSetor = [];
  List<dynamic> _riwayatPenjemputan = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllRiwayat();
  }

  Future<void> _fetchAllRiwayat() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final adminData = jsonDecode(prefs.getString('user_data') ?? '{}');
    final adminId = adminData['id_petugas'];

    try {
      // Fetch Riwayat Setor
      final responseSetor = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/riwayat-setor-petugas/$adminId'),
      ).timeout(const Duration(seconds: 10));

      // Fetch Riwayat Penjemputan
      final responsePenjemputan = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/riwayat-penjemputan/$adminId'),
      ).timeout(const Duration(seconds: 10));

      if (mounted) {
        if (responseSetor.statusCode == 200) {
          final result = jsonDecode(responseSetor.body);
          if (result['status'] == 'success') {
            _riwayatSetor = result['data'] ?? [];
          }
        }
        if (responsePenjemputan.statusCode == 200) {
          final result = jsonDecode(responsePenjemputan.body);
          if (result['status'] == 'success') {
            _riwayatPenjemputan = result['data'] ?? [];
          }
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: const Text('Riwayat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          // ✅ BUBBLE NAVIGATION
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(child: _buildBubble('Riwayat Setor', Icons.upload_rounded, _activeBubble == 'setor')),
                const SizedBox(width: 12),
                Expanded(child: _buildBubble('Riwayat Penjemputan', Icons.local_shipping, _activeBubble == 'penjemputan')),
              ],
            ),
          ),
          // ✅ CONTENT
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _activeBubble == 'setor'
                    ? _buildRiwayatSetorList()
                    : _buildRiwayatPenjemputanList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(String label, IconData icon, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => _activeBubble = isActive ? _activeBubble : (label.contains('Setor') ? 'setor' : 'penjemputan')),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isActive ? const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF81C784)]) : null,
          color: isActive ? null : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.white : const Color(0xFF4CAF50)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: isActive ? Colors.white : const Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatSetorList() {
    if (_riwayatSetor.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.history, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('Belum ada riwayat setoran'),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _riwayatSetor.length,
      itemBuilder: (context, index) {
        final item = _riwayatSetor[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
          ]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.recycling, color: Color(0xFF4CAF50), size: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Setor Sampah', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                Text(item['tanggal_transaksi'] ?? '-', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ])),
            ]),
            const SizedBox(height: 12),
            _buildInfoRow('Jenis', item['jenis_sampah'] ?? '-'),
            _buildInfoRow('Berat', '${item['berat']} kg'),
            _buildInfoRow('Total', 'Rp ${item['total_rupiah']}'),
          ]),
        );
      },
    );
  }

  Widget _buildRiwayatPenjemputanList() {
    if (_riwayatPenjemputan.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.local_shipping, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('Belum ada riwayat penjemputan'),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _riwayatPenjemputan.length,
      itemBuilder: (context, index) {
        final item = _riwayatPenjemputan[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
          ]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.local_shipping, color: Color(0xFF2196F3), size: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Penjemputan', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                Text(item['waktu'] ?? '-', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ])),
              _buildStatusBadge(item['status']),
            ]),
            const SizedBox(height: 12),
            _buildInfoRow('Lokasi', item['lokasi'] ?? '-'),
            _buildInfoRow('Berat', '${item['berat']} kg'),
            if (item['keterangan'] != null && item['keterangan'].isNotEmpty) _buildInfoRow('Keterangan', item['keterangan']),
          ]),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1B5E20)))),
      ],
    ));
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'disetujui': color = Colors.green; break;
      case 'ditolak': color = Colors.red; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}