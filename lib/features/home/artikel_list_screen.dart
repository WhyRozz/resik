import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'artikel_detail_screen.dart';

class ArtikelListScreen extends StatefulWidget {
  const ArtikelListScreen({super.key});

  @override
  State<ArtikelListScreen> createState() => _ArtikelListScreenState();
}

class _ArtikelListScreenState extends State<ArtikelListScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _artikelList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _errorMessage;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fetchArtikel();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await _fetchArtikel();
  }

  Future<void> _fetchArtikel() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse(ApiConfig.artikel))
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          if (result['status'] == 'success') {
            setState(() {
              _artikelList = result['data'] ?? [];
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

  List<dynamic> get _filteredArtikel {
    if (_searchQuery.isEmpty) return _artikelList;
    return _artikelList.where((artikel) {
      final judul = artikel['judul']?.toString().toLowerCase() ?? '';
      final kategori = artikel['kategori']?.toString().toLowerCase() ?? '';
      return judul.contains(_searchQuery.toLowerCase()) ||
          kategori.contains(_searchQuery.toLowerCase());
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
                        Icons.menu_book_rounded,
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
                            'Artikel Edukasi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tips & informasi',
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

    if (_artikelList.isEmpty) {
      return _buildEmptyState();
    }

    // Determine apakah tampilkan featured
    final showFeatured = _searchQuery.isEmpty && _filteredArtikel.isNotEmpty;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF4CAF50),
        backgroundColor: Colors.white,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: _buildListItemCount(showFeatured),
          itemBuilder: (context, index) {
            return _buildListItem(index, showFeatured);
          },
        ),
      ),
    );
  }

  int _buildListItemCount(bool showFeatured) {
    int count = 0;
    count += 1; // Search bar
    if (showFeatured) count += 1; // Featured
    count += 1; // Section title
    count += _filteredArtikel.length; // All articles
    return count;
  }

  Widget _buildListItem(int index, bool showFeatured) {
    int current = 0;

    // Search Bar
    if (index == current) return _buildSearchBar();
    current++;

    // Featured
    if (showFeatured) {
      if (index == current) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _buildFeaturedArtikel(_filteredArtikel.first),
        );
      }
      current++;
    }

    // Section Title
    if (index == current) return _buildSectionTitle();
    current++;

    // Articles
    final articleIndex = index - current;
    if (articleIndex < _filteredArtikel.length) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: _buildArtikelCard(_filteredArtikel[articleIndex], articleIndex),
      );
    }

    return const SizedBox.shrink();
  }

  // ===== SKELETON LOADING =====
  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          ...List.generate(
            4,
            (index) => Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== SEARCH BAR =====
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                hintText: 'Cari artikel atau kategori...',
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

  // ===== SECTION TITLE =====
  Widget _buildSectionTitle() {
    final totalArtikel = _filteredArtikel.length;
    final hasFeatured = _searchQuery.isEmpty && _artikelList.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
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
              Icons.article_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _searchQuery.isEmpty
                      ? (hasFeatured ? 'Artikel Lainnya' : 'Semua Artikel')
                      : 'Hasil Pencarian',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                Text(
                  '$totalArtikel artikel, Yuk baca artikel edukasi sekarang!',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== FEATURED ARTICLE =====
  Widget _buildFeaturedArtikel(Map<String, dynamic> artikel) {
    return GestureDetector(
      onTap: () => _navigateToDetail(artikel),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                ApiConfig.imageUrl(artikel['foto']),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.image_outlined,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Featured Badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB347), Color(0xFFFF9500)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9500).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Terbaru',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Kategori Badge
            if (artikel['kategori'] != null &&
                artikel['kategori'].toString().isNotEmpty)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _getKategoriColor(
                      artikel['kategori'],
                    ).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Text(
                    artikel['kategori'].toString().toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            // Content
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artikel['judul'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: Colors.white,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(artikel['tanggal']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF4CAF50),
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== ARTICLE CARD (HORIZONTAL LAYOUT) =====
  Widget _buildArtikelCard(Map<String, dynamic> artikel, int index) {
    return GestureDetector(
      onTap: () => _navigateToDetail(artikel),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      ApiConfig.imageUrl(artikel['foto']),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image_outlined,
                          size: 30,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    if (artikel['kategori'] != null &&
                        artikel['kategori'].toString().isNotEmpty)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getKategoriColor(
                              artikel['kategori'],
                            ).withOpacity(0.95),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            artikel['kategori'].toString().toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      artikel['judul'] ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B5E20),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 10,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(artikel['tanggal']),
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Baca',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== EMPTY STATE =====
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
              Icons.menu_book_rounded,
              size: 60,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum Ada Artikel',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Artikel akan muncul setelah\nadmin menambahkannya'
                : 'Coba kata kunci lain',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchArtikel,
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

  // ===== ERROR STATE =====
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
            onPressed: _fetchArtikel,
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

  void _navigateToDetail(Map<String, dynamic> artikel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArtikelDetailScreen(artikel: artikel),
      ),
    );
  }

  Color _getKategoriColor(String? kategori) {
    if (kategori == null) return const Color(0xFF4CAF50);
    final k = kategori.toLowerCase();
    if (k.contains('lingkungan') || k.contains('hijau'))
      return const Color(0xFF4CAF50);
    if (k.contains('kesehatan')) return const Color(0xFFE91E63);
    if (k.contains('teknologi')) return const Color(0xFF1976D2);
    if (k.contains('pendidikan')) return const Color(0xFF7B1FA2);
    if (k.contains('ekonomi') || k.contains('bisnis'))
      return const Color(0xFFFFA000);
    return const Color(0xFF4CAF50);
  }

  String _estimateReadingTime(String content) {
    final wordCount = content.split(RegExp(r'\s+')).length;
    final minutes = (wordCount / 200).ceil();
    if (minutes < 1) return '<1m';
    return '${minutes}m';
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null || dateString.toString().isEmpty) return '-';
    final dateStr = dateString.toString().trim();

    // ✅ Kalau sudah format "13 Juli 2026", langsung return
    if (RegExp(
      r'^\d{1,2}\s+(Januari|Februari|Maret|April|Mei|Juni|Juli|Agustus|September|Oktober|November|Desember)\s+\d{4}$',
    ).hasMatch(dateStr)) {
      return dateStr;
    }

    try {
      DateTime? date;

      // ✅ CEK 1: Format ISO "2026-07-13" atau "2026-07-13 23:41:00"
      if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(dateStr)) {
        date = DateTime.parse(dateStr.split(' ')[0]);
      }
      // ✅ CEK 2: Format "13-07-2026" (DD-MM-YYYY)
      else if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(dateStr)) {
        final parts = dateStr.split('-');
        date = DateTime(
          int.parse(parts[2]), // tahun
          int.parse(parts[1]), // bulan
          int.parse(parts[0]), // tanggal
        );
      }
      // ✅ CEK 3: Format "2026/07/13"
      else if (RegExp(r'^\d{4}/\d{2}/\d{2}').hasMatch(dateStr)) {
        date = DateTime.parse(dateStr.split(' ')[0].replaceAll('/', '-'));
      }
      // ✅ CEK 4: Format "13/07/2026"
      else if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(dateStr)) {
        final parts = dateStr.split('/');
        date = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
      // ❌ Format tidak dikenali
      else {
        return dateStr;
      }

      // ✅ FORMAT OUTPUT: "13 Juli 2026"
      final months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
