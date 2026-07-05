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

class _ArtikelListScreenState extends State<ArtikelListScreen> {
  List<dynamic> _artikelList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchArtikel();
  }

  Future<void> _handleRefresh() async {
    await _fetchArtikel();
  }

  Future<void> _fetchArtikel() async {
    setState(() => _isLoading = true);
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.artikel))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success' && mounted) {
          setState(() {
            _artikelList = result['data'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetch artikel: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredArtikel {
    if (_searchQuery.isEmpty) return _artikelList;
    return _artikelList.where((artikel) {
      final judul = artikel['judul']?.toLowerCase() ?? '';
      return judul.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 16,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.newspaper, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'Artikel Edukasi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // ✅ SEARCH BAR
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Cari artikel...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // ✅ LIST ARTIKEL
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: const Color(0xFF4CAF50),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4CAF50),
                      ),
                    )
                  : _filteredArtikel.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 60,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Belum ada artikel'
                                : 'Artikel tidak ditemukan',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _filteredArtikel.length,
                      itemBuilder: (context, index) {
                        final artikel = _filteredArtikel[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildArtikelCard(artikel),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FEATURED ARTICLE (Artikel Pertama - Lebih Besar)
  Widget _buildFeaturedArtikel(Map<String, dynamic> artikel) {
    return GestureDetector(
      onTap: () => _navigateToDetail(artikel),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
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
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Featured Badge
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB347),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.white, size: 11),
                    SizedBox(width: 4),
                    Text(
                      'FEATURED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (artikel['kategori'] != null &&
                      artikel['kategori'].toString().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        artikel['kategori'].toString().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    artikel['judul'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white70,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(artikel['tanggal']),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.access_time_rounded,
                        color: Colors.white70,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _estimateReadingTime(
                          artikel['konten'] ?? artikel['judul'] ?? '',
                        ),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF4CAF50),
                          size: 12,
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

  // ✅ ARTICLE CARD - COMPACT
  Widget _buildArtikelCard(Map<String, dynamic> artikel) {
    return GestureDetector(
      onTap: () => _navigateToDetail(artikel),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    ApiConfig.imageUrl(artikel['foto']),
                    width: double.infinity,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 100,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image_outlined,
                        size: 35,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                if (artikel['kategori'] != null &&
                    artikel['kategori'].toString().isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getKategoriColor(
                          artikel['kategori'],
                        ).withOpacity(0.95),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        artikel['kategori'].toString().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: Colors.white,
                          size: 10,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _estimateReadingTime(
                            artikel['konten'] ?? artikel['judul'] ?? '',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Color(0xFF7B1FA2),
                          size: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _formatDate(artikel['tanggal']),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                          ),
                          borderRadius: BorderRadius.circular(8),
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
    final dateStr = dateString.toString();

    if (RegExp(
      r'^\d{1,2}\s+(Januari|Februari|Maret|April|Mei|Juni|Juli|Agustus|September|Oktober|November|Desember)\s+\d{4}$',
    ).hasMatch(dateStr)) {
      return dateStr;
    }

    try {
      DateTime date;
      if (dateStr.contains(' ') || dateStr.contains('T')) {
        date = DateTime.parse(dateStr);
      } else if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        } else {
          return dateStr;
        }
      } else if (int.tryParse(dateStr) != null) {
        date = DateTime.fromMillisecondsSinceEpoch(int.parse(dateStr));
      } else {
        return dateStr;
      }

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
