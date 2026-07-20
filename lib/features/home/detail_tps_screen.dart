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

  // METHOD ZOOM - PANGGIL JAVASCRIPT DARI FLUTTER
  void _zoomIn() {
    _webViewController.runJavaScript('map.zoomIn(1, {animate: true});');
  }

  void _zoomOut() {
    _webViewController.runJavaScript('map.zoomOut(1, {animate: true});');
  }

  Future<void> _fetchTpsDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
            _errorMessage = result['message'] ?? 'Gagal memuat data';
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

  // PAKAI OPENSTREETMAP (Gratis, Stabil, No API Key)
  void _initOpenStreetMap() {
    if (_tpsData == null) return;

    final lokasi = (_tpsData!['lokasi'] ?? '').toString();
    final namaTps = (_tpsData!['nama_tps'] ?? _tpsData!['nama'] ?? 'TPS')
        .toString();

    double lat = -7.65492;
    double lng = 111.97055;

    if (lokasi.contains(',')) {
      final coords = lokasi.replaceAll(' ', '').split(',');
      if (coords.length >= 2) {
        try {
          lat = double.parse(coords[0]);
          lng = double.parse(coords[1]);
        } catch (e) {
          debugPrint("❌ Parse koordinat error: $e");
        }
      }
    }

    // ✅ PAKAI LEAFLET.JS - ZOOM PASTI BERFUNGSI!
    final mapHtml =
        '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
      <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
      <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body, html { width: 100%; height: 100%; overflow: hidden; }
        #map { width: 100%; height: 100vh; }
        
        .leaflet-control-zoom { display: none !important; }
   
      </style>
    </head>
    <body>
      <div id="map"></div>
      
      <script>
        var map = L.map('map', {
          zoomControl: false,
          scrollWheelZoom: true,
          doubleClickZoom: true,
          touchZoom: true,
          dragging: true,
          maxZoom: 19,
          minZoom: 3
        }).setView([$lat, $lng], 16);
        
        L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', {
          attribution: '© OpenStreetMap © CARTO',
          maxZoom: 19
        }).addTo(map);
        
        var marker = L.marker([$lat, $lng]).addTo(map);
        marker.bindPopup('<b>$namaTps</b>').openPopup();
        
      </script>
    </body>
    </html>
    ''';

    debugPrint("🗺️ Leaflet Map initialized");

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFE8F5E9))
      ..addJavaScriptChannel(
        'ZoomChannel',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint("🗺️ Zoom: ${message.message}");
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            debugPrint("✅ Map loaded!");
            if (mounted) setState(() => _mapLoaded = true);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('❌ Map error: ${error.description}');
          },
        ),
      )
      ..loadHtmlString(mapHtml);
  }

  // ✅ TOMBOL BUKA GOOGLE MAPS
  Future<void> _openGoogleMaps() async {
    if (_tpsData == null) return;

    final lokasi = (_tpsData!['lokasi'] ?? '').toString();
    final namaTps = (_tpsData!['nama_tps'] ?? _tpsData!['nama'] ?? '')
        .toString();
    final alamat = (_tpsData!['alamat'] ?? '').toString();

    String url;
    if (lokasi.contains(',')) {
      final clean = lokasi.replaceAll(' ', '');
      url = 'https://www.google.com/maps/dir/?api=1&destination=$clean';
    } else {
      final query = '$namaTps $alamat'.trim();
      url =
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
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
          SnackBar(
            content: const Text('Gagal membuka Google Maps'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // ============ CUSTOM APPBAR ============
          _buildCustomAppBar(),

          // ============ CONTENT ============
          Expanded(
            child: _isLoading
                ? _buildSkeletonLoading()
                : _errorMessage != null
                ? _buildErrorState()
                : _buildDetailContent(),
          ),
        ],
      ),
    );
  }

  // ============ CUSTOM APPBAR ============
  Widget _buildCustomAppBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail TPS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Informasi lengkap lokasi',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ SKELETON LOADING ============
  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map skeleton
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey.shade200),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                Container(
                  height: 20,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 20),
                // Button skeleton
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(height: 16),
                // Info cards skeleton
                ...List.generate(
                  3,
                  (index) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ ERROR STATE ============
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Gagal Memuat Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchTpsDetail,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ DETAIL CONTENT ============
  Widget _buildDetailContent() {
    final namaTps = (_tpsData!['nama_tps'] ?? _tpsData!['nama'] ?? '-')
        .toString();
    final alamat = (_tpsData!['alamat'] ?? '-').toString();
    final lokasi = (_tpsData!['lokasi'] ?? '-').toString();
    final kapasitas = (_tpsData!['kapasitas'] ?? '-').toString();
    final keterangan = (_tpsData!['keterangan'] ?? '').toString();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ============ MAP SECTION ============
          Container(
            height: 240,
            width: double.infinity,
            color: const Color(0xFFE8F5E9),
            child: Stack(
              children: [
                // WebView Map
                if (_webViewController != null)
                  WebViewWidget(controller: _webViewController),

                // Loading overlay
                if (!_mapLoaded)
                  Container(
                    color: const Color(0xFFE8F5E9),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF4CAF50),
                            strokeWidth: 2.5,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Memuat peta...',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Top gradient overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // ✅ TOMBOL ZOOM DI POJOK KANAN ATAS
                Positioned(
                  top: 12,
                  right: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol Zoom In
                      _buildZoomButton(icon: Icons.add, onTap: _zoomIn),
                      const SizedBox(height: 6),
                      // Tombol Zoom Out
                      _buildZoomButton(icon: Icons.remove, onTap: _zoomOut),
                    ],
                  ),
                ),

                // TOMBOL GOOGLE MAPS DI POJOK KANAN BAWAH
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _openGoogleMaps,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/thumb/a/aa/Google_Maps_icon_%282020%29.svg/1024px-Google_Maps_icon_%282020%29.svg.png',
                              width: 16,
                              height: 16,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.map_rounded,
                                size: 16,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Google Maps',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Koordinat badge di pojok kiri bawah
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.my_location_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lokasi.length > 25
                              ? '${lokasi.substring(0, 25)}...'
                              : lokasi,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ============ INFO DETAIL ============
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ MAIN INFO CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama TPS
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  namaTps,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1B5E20),
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'TPS Aktif',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2E7D32),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Container(height: 1, color: Colors.grey.shade100),
                      const SizedBox(height: 20),

                      // Alamat
                      _buildInfoDetailRow(
                        icon: Icons.place_rounded,
                        iconColor: const Color(0xFF1976D2),
                        label: 'Alamat Lengkap',
                        value: alamat,
                      ),

                      const SizedBox(height: 16),

                      // Lokasi Koordinat
                      _buildInfoDetailRow(
                        icon: Icons.explore_rounded,
                        iconColor: const Color(0xFFFFA000),
                        label: 'Koordinat GPS',
                        value: lokasi,
                        isMono: true,
                      ),

                      const SizedBox(height: 16),

                      // Kapasitas
                      _buildInfoDetailRow(
                        icon: Icons.storage_rounded,
                        iconColor: const Color(0xFFFFA000),
                        label: 'Kapasitas TPS',
                        value: kapasitas,
                      ),

                      // Keterangan (jika ada)
                      if (keterangan.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildInfoDetailRow(
                          icon: Icons.info_outline_rounded,
                          iconColor: const Color(0xFF7B1FA2),
                          label: 'Keterangan',
                          value: keterangan,
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Tombol Buka Rute
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openGoogleMaps,
                          icon: const Icon(Icons.navigation_rounded, size: 18),
                          label: const Text(
                            'Buka Rute di Google Maps',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                            shadowColor: const Color(
                              0xFF4CAF50,
                            ).withOpacity(0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // FOOTER INFO
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFC8E6C9),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: Color(0xFF4CAF50),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RESIK - Peduli Lingkungan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Buang sampah pada tempatnya!',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ INFO DETAIL ROW ============
  Widget _buildInfoDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isMono = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  fontFamily: isMono ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ WIDGET TOMBOL ZOOM
  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF4CAF50), size: 22),
        ),
      ),
    );
  }

  // ============ INFO CARD (KAPASITAS / KETERANGAN) ============
  Widget _buildInfoCard({
    required IconData icon,
    required List<Color> iconGradient,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
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
                  gradient: LinearGradient(colors: iconGradient),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 14),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
