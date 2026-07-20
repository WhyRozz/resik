import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class JenisSampahListScreen extends StatefulWidget {
  const JenisSampahListScreen({super.key});

  @override
  State<JenisSampahListScreen> createState() => _JenisSampahListScreenState();
}

class _JenisSampahListScreenState extends State<JenisSampahListScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _jenisSampahList = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fetchJenisSampah();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ===== SKELETON LOADING =====
  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // Summary Skeleton
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerBox(width: 80, height: 10),
                      const SizedBox(height: 8),
                      _buildShimmerBox(width: 100, height: 20),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerBox(width: 100, height: 10),
                      const SizedBox(height: 8),
                      _buildShimmerBox(width: 120, height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Bar Skeleton
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                _buildShimmerBox(width: 20, height: 20, isCircle: true),
                const SizedBox(width: 10),
                _buildShimmerBox(width: 150, height: 14),
              ],
            ),
          ),

          // Grid Skeleton (6 card placeholder)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.75,
              children: List.generate(6, (index) => _buildSkeletonCard()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image area skeleton
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: Center(
                child: _buildShimmerBox(width: 70, height: 70, isCircle: true),
              ),
            ),
          ),
          // Info area skeleton
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildShimmerBox(width: double.infinity, height: 12),
                  const SizedBox(height: 8),
                  _buildShimmerBox(width: 60, height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    bool isCircle = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(value),
            borderRadius: isCircle
                ? BorderRadius.circular(width / 2)
                : BorderRadius.circular(6),
          ),
        );
      },
    );
  }

  Future<void> _handleRefresh() async {
    await _fetchJenisSampah();
  }

  Future<void> _fetchJenisSampah() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse(ApiConfig.jenisSampahList))
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          if (result['status'] == 'success') {
            setState(() {
              _jenisSampahList = result['data'] ?? [];
              _isLoading = false;
            });
            _fadeController.forward();
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Koneksi error: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _formatRupiah(double angka) {
    return 'Rp ${angka.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  List<dynamic> get _filteredData {
    if (_searchQuery.isEmpty) return _jenisSampahList;
    return _jenisSampahList.where((item) {
      final nama = (item['jenis'] ?? '').toString().toLowerCase();
      return nama.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // ============ CUSTOM APPBAR ============
          Container(
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
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
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
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.recycling_rounded,
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
                            'Jenis Sampah',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Kategori & harga sampah',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ============ CONTENT ============
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildSkeletonLoading();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_jenisSampahList.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF4CAF50),
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Summary Card
            SliverToBoxAdapter(child: _buildSummaryCard()),
            // Search Bar
            SliverToBoxAdapter(child: _buildSearchBar()),
            // Grid
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = _filteredData[index];
                  return _buildJenisSampahCard(item, index);
                }, childCount: _filteredData.length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalJenis = _jenisSampahList.length;
    double maxHarga = 0.0;
    String namaTertinggi = '-';

    if (_jenisSampahList.isNotEmpty) {
      // Cari harga tertinggi
      maxHarga = _jenisSampahList
          .map((e) => (e['harga'] ?? 0).toDouble())
          .reduce((a, b) => a > b ? a : b);

      // Cari nama jenis sampah dengan harga tertinggi
      final itemTertinggi = _jenisSampahList.firstWhere(
        (e) => (e['harga'] ?? 0).toDouble() == maxHarga,
        orElse: () => _jenisSampahList.first,
      );
      namaTertinggi = itemTertinggi['jenis'] ?? '-';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50), Color(0xFF66BB6A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Kategori',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalJenis Jenis',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Harga Tertinggi',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatRupiah(maxHarga),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                // nama jenis sampah di bawah harga
                Text(
                  '($namaTertinggi)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: Colors.grey[400], size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Cari jenis sampah...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              onPressed: () => setState(() => _searchQuery = ''),
              icon: Icon(Icons.close, color: Colors.grey[400], size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildJenisSampahCard(Map<String, dynamic> item, int index) {
    final String namaJenis = item['jenis'] ?? 'Umum';
    final String satuan = item['satuan'] ?? 'kg';
    final double harga = (item['harga'] ?? 0).toDouble();
    final String? gambarUrl = item['gambar'];

    final iconMap = {
      'plastik': Icons.local_drink,
      'kertas': Icons.description,
      'kardus': Icons.inventory,
      'logam': Icons.build,
      'besi': Icons.hardware,
      'kaca': Icons.camera,
      'organik': Icons.eco,
      'minyak': Icons.opacity,
      'elektronik': Icons.devices,
      'lainnya': Icons.category,
    };
    final iconKey = namaJenis.toLowerCase().replaceAll(' ', '');
    final IconData icon = iconMap.entries
        .firstWhere(
          (e) => iconKey.contains(e.key),
          orElse: () => MapEntry('lainnya', Icons.category_rounded),
        )
        .value;

    // Warna gradient berdasarkan index
    final gradients = [
      const [Color(0xFF4CAF50), Color(0xFF81C784)],
      const [Color(0xFF2196F3), Color(0xFF64B5F6)],
      const [Color(0xFFFF9800), Color(0xFFFFB74D)],
      const [Color(0xFF9C27B0), Color(0xFFBA68C8)],
      const [Color(0xFFE91E63), Color(0xFFF06292)],
      const [Color(0xFF00BCD4), Color(0xFF4DD0E1)],
    ];
    final gradientColors = gradients[index % gradients.length];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () {
          // Bisa tambahkan aksi saat card di-tap
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image/Icon Area
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors.cast<Color>(),
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background pattern
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Icon(
                          icon,
                          size: 120,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      // Main icon/image
                      Center(
                        child: (gambarUrl != null && gambarUrl.isNotEmpty)
                            ? // JIKA ADA GAMBAR: Langsung gambar tanpa lingkaran putih
                              ClipOval(
                                child: Image.network(
                                  gambarUrl,
                                  width: 80, // Diperbesar agar full
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      icon,
                                      size: 40,
                                      color: gradientColors[0],
                                    ),
                                  ),
                                  loadingBuilder: (_, child, progress) {
                                    if (progress == null) return child;
                                    return SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              progress.expectedTotalBytes !=
                                                  null
                                              ? progress.cumulativeBytesLoaded /
                                                    progress.expectedTotalBytes!
                                              : null,
                                          color: gradientColors[0],
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : // JIKA TIDAK ADA GAMBAR: Icon dengan lingkaran putih
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  icon,
                                  size: 40,
                                  color: gradientColors[0],
                                ),
                              ),
                      ),
                      // Badge harga di pojok
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.attach_money_rounded,
                                size: 12,
                                color: gradientColors[0],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                _formatRupiah(harga),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: gradientColors[0],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Info Area
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(18),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaJenis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.scale_rounded,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Per $satuan',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CAF50).withOpacity(0.1),
                  const Color(0xFF81C784).withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.category_outlined,
              size: 60,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum Ada Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jenis sampah akan muncul setelah\nadmin menambahkannya',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchJenisSampah,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchJenisSampah,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
