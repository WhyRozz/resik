import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/api_config.dart';

class DetailTpsScreen extends StatefulWidget {
  final int tpsId;

  const DetailTpsScreen({super.key, required this.tpsId});

  @override
  State<DetailTpsScreen> createState() => _DetailTpsScreenState();
}

class _DetailTpsScreenState extends State<DetailTpsScreen> {
  Map<String, dynamic>? _tpsData;
  bool _isLoading = true;
  String? _errorMessage;
  late WebViewController _webViewController;
  bool _mapLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchTpsDetail();
  }

  Future<void> _fetchTpsDetail() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.infoTps}/${widget.tpsId}'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            _tpsData = result['data'];
            _isLoading = false;
          });
          _initOpenStreetMap();
        } else {
          setState(() {
            _errorMessage = result['message'];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Koneksi error: $e';
        _isLoading = false;
      });
    }
  }

  // ✅ PAKAI OPENSTREETMAP (Gratis, Stabil, No API Key)
  void _initOpenStreetMap() {
    if (_tpsData != null) {
      final lokasi = _tpsData!['lokasi'] ?? '';

      // ✅ Parse koordinat
      double lat = -7.65492; // Default
      double lng = 111.97055; // Default

      if (lokasi.contains(',')) {
        final coords = lokasi.replaceAll(' ', '').split(',');
        try {
          lat = double.parse(coords[0]);
          lng = double.parse(coords[1]);
        } catch (e) {
          debugPrint("❌ Parse koordinat error: $e");
        }
      }

      // ✅ URL OpenStreetMap dengan marker
      // Format: https://www.openstreetmap.org/export/embed.html?bbox=...&layer=mapnik&marker=...
      final delta = 0.01; // Zoom level
      final bbox =
          '${lng - delta},${lat - delta},${lng + delta},${lat + delta}';
      final mapUrl =
          'https://www.openstreetmap.org/export/embed.html?'
          'bbox=$bbox&layer=mapnik&marker=$lat,$lng';

      debugPrint("🗺️ OpenStreetMap URL: $mapUrl");

      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              debugPrint("✅ Map loaded!");
              setState(() => _mapLoaded = true);
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('❌ Map error: ${error.description}');
            },
          ),
        )
        ..loadRequest(Uri.parse(mapUrl));
    }
  }

  // ✅ TOMBOL BUKA GOOGLE MAPS
  Future<void> _openGoogleMaps() async {
    if (_tpsData == null) return;

    final lokasi = _tpsData!['lokasi'] ?? '';
    final namaTps = _tpsData!['nama_tps'] ?? '';

    String url;
    if (lokasi.contains(',')) {
      final clean = lokasi.replaceAll(' ', '');
      url = 'https://www.google.com/maps/dir/?api=1&destination=$clean';
    } else {
      url =
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$namaTps $lokasi')}';
    }

    debugPrint("🗺️ Opening Google Maps: $url");

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Cannot launch';
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pastikan Google Maps sudah terinstall'),
            backgroundColor: Colors.red,
          ),
        );
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Informasi Lokasi TPS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchTpsDetail,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : _buildDetailContent(),
    );
  }

  Widget _buildDetailContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ MAP DENGAN OPENSTREETMAP
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  WebViewWidget(controller: _webViewController),
                  if (!_mapLoaded)
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF4CAF50)),
                          SizedBox(height: 8),
                          Text(
                            'Memuat peta...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ✅ INFO DETAIL TPS
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
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
                      Text(
                        _tpsData!['nama_tps'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Lokasi', _tpsData!['lokasi']),
                      const SizedBox(height: 12),
                      _buildInfoRow('Alamat', _tpsData!['alamat']),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openGoogleMaps,
                          icon: const Icon(Icons.directions, size: 20),
                          label: const Text(
                            'Buka Rute di Google Maps',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
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
                      const Row(
                        children: [
                          Icon(
                            Icons.storage,
                            color: Color(0xFF4CAF50),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Kapasitas',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _tpsData!['kapasitas'] ?? '-',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_tpsData!['keterangan'] != null &&
                    _tpsData!['keterangan'].isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
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
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFF4CAF50),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Keterangan',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _tpsData!['keterangan'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value ?? '-',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B5E20),
          ),
        ),
      ],
    );
  }
}
