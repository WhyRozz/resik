import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_user_screen.dart';
import 'riwayat_setor_screen.dart';
import 'info_tps_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailLaporanScreen extends StatelessWidget {
  final Map<String, dynamic> laporan;

  const DetailLaporanScreen({super.key, required this.laporan});

  // ✅ FUNGSI POP-UP FOTO
  void _showImagePopup(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 80,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(dialogContext),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ BUKA GOOGLE MAPS
  Future<void> _openGoogleMaps(BuildContext context, String address) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      // Fallback: Copy ke clipboard
      await Clipboard.setData(ClipboardData(text: address));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lokasi disalin: $address')));
    }
  }

  // ✅ COPY LOKASI
  void _copyToClipboard(String text, BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lokasi berhasil disalin!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8F4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF2E7D32),
              size: 16,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF2E7D32), const Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.assignment_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Detail Laporan',
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ HERO IMAGE SECTION
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(color: Colors.grey.shade300),
                  child:
                      laporan['foto'] != null &&
                          laporan['foto'].toString().isNotEmpty
                      ? GestureDetector(
                          onTap: () =>
                              _showImagePopup(context, laporan['foto']),
                          child: Image.network(
                            laporan['foto'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        color: Color(0xFF2E7D32),
                                        strokeWidth: 3,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'Memuat foto...',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image_outlined,
                                        size: 70,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'Foto tidak tersedia',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Silakan cek koneksi internet',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 70,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Tidak ada foto',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                // Gradient Overlay
                IgnorePointer(
                  child: Container(
                    height: 300,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Photo Counter Badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_camera_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '1 Foto',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Status Badge di atas foto
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: _buildHeroStatusBadge(laporan['status']),
                ),
              ],
            ),

            // ✅ CONTENT SECTION
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ INFORMASI LAPORAN CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header dengan icon
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFE8F5E9),
                                    const Color(0xFFF1F8F4),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFC8E6C9),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFF2E7D32),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Informasi Laporan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A1A),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Detail lengkap laporan Anda',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Divider dengan decorative dot
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade200,
                                thickness: 1,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2E7D32),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade200,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Info Rows
                        _buildPremiumInfoRow(
                          context: context,
                          icon: Icons.person_outline_rounded,
                          iconColor: const Color(0xFF1976D2),
                          iconBgColor: const Color(0xFFE3F2FD),
                          label: 'Pelapor',
                          value: laporan['nama'] ?? '-',
                          showDivider: true,
                        ),
                        const SizedBox(height: 16),
                        _buildPremiumInfoRow(
                          context: context,
                          icon: Icons.location_on_outlined,
                          iconColor: const Color(0xFFE65100),
                          iconBgColor: const Color(0xFFFFF3E0),
                          label: 'Lokasi',
                          value: laporan['lokasi'] ?? laporan['alamat'] ?? '-',
                          showDivider: true,
                        ),
                        const SizedBox(height: 16),
                        _buildPremiumInfoRow(
                          context: context,
                          icon: Icons.calendar_today_outlined,
                          iconColor: const Color(0xFF7B1FA2),
                          iconBgColor: const Color(0xFFF3E5F5),
                          label: 'Tanggal',
                          value: laporan['tanggal'] ?? '-',
                          showDivider: true,
                        ),
                        const SizedBox(height: 16),
                        _buildPremiumInfoRow(
                          context: context,
                          icon: Icons.notes_outlined,
                          iconColor: const Color(0xFF2E7D32),
                          iconBgColor: const Color(0xFFE8F5E9),
                          label: 'Keterangan',
                          value:
                              laporan['keterangan'] ?? laporan['judul'] ?? '-',
                          isMultiline: true,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ✅ RESPON ADMIN CARD (Conditional)
                  if (laporan['balasan'] != null &&
                      laporan['balasan'].toString().isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, const Color(0xFFF9FBE7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFDCEDC8),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header dengan badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF2E7D32),
                                      const Color(0xFF4CAF50),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF2E7D32,
                                      ).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.account_circle_rounded,
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
                                      'Respon Petugas',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A1A1A),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Balasan dari petugas',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: const Color(0xFFDCEDC8),
                                  thickness: 1,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2E7D32),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: const Color(0xFFDCEDC8),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Foto Balasan
                          if (laporan['foto_balasan'] != null &&
                              laporan['foto_balasan']
                                  .toString()
                                  .isNotEmpty) ...[
                            // Label dengan icon
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.photo_library_outlined,
                                    color: Color(0xFF2E7D32),
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Foto Balasan',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Image dengan frame
                            // Image dengan frame (Bisa di-klik)
                            GestureDetector(
                              onTap: () => _showImagePopup(
                                context,
                                laporan['foto_balasan'],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFC8E6C9),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    laporan['foto_balasan'],
                                    width: double.infinity,
                                    height: 220,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 220,
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.broken_image_outlined,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Foto tidak dapat dimuat',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Pesan Admin
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: Color(0xFF2E7D32),
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Pesan Admin',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Message Box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFF1F8F4),
                                  const Color(0xFFE8F5E9),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFC8E6C9),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.format_quote_rounded,
                                    color: Color(0xFF2E7D32),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    laporan['balasan'],
                                    textAlign: TextAlign.justify,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1B5E20),
                                      height: 1.6,
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
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildPremiumBottomNav(context),
    );
  }

  Widget _buildHeroStatusBadge(String? status) {
    final statusLower = status?.toLowerCase() ?? '';
    Color bgColor;
    Color textColor;
    IconData icon;
    String subtitle;

    switch (statusLower) {
      case 'diproses':
      case 'proses':
        bgColor = Colors.amber.shade700;
        textColor = Colors.white;
        icon = Icons.schedule_rounded;
        subtitle = 'Sedang ditinjau';
        break;
      case 'diterima':
      case 'berhasil':
      case 'selesai':
        bgColor = const Color(0xFF2E7D32);
        textColor = Colors.white;
        icon = Icons.check_circle_rounded;
        subtitle = 'Telah selesai';
        break;
      case 'ditolak':
        bgColor = const Color(0xFFC62828);
        textColor = Colors.white;
        icon = Icons.cancel_rounded;
        subtitle = 'Perlu perbaikan';
        break;
      case 'ditarik':
        bgColor = Colors.grey.shade700;
        textColor = Colors.white;
        icon = Icons.archive_outlined;
        subtitle = 'Laporan ditarik';
        break;
      default:
        bgColor = Colors.grey.shade600;
        textColor = Colors.white;
        icon = Icons.help_outline_rounded;
        subtitle = 'Status tidak diketahui';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: textColor, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                status ?? '-',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  color: textColor.withOpacity(0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumInfoRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
    bool isMultiline = false,
    bool showDivider = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: iconColor.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (label == 'Lokasi')
                        GestureDetector(
                          onTap: () => _copyToClipboard(value, context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  label == 'Lokasi'
                      ? GestureDetector(
                          onTap: () => _openGoogleMaps(context, value),
                          child: Text(
                            value,
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: isMultiline ? 13 : 14,
                              color: const Color(0xFF1976D2),
                              fontWeight: FontWeight.w600,
                              height: isMultiline ? 1.5 : 1.3,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        )
                      : Text(
                          value,
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: isMultiline ? 13 : 14,
                            color: const Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w600,
                            height: isMultiline ? 1.5 : 1.3,
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200, thickness: 1, height: 1),
        ],
      ],
    );
  }

  Widget _buildPremiumBottomNav(BuildContext context) {
    final items = [
      {
        'icon': Icons.home_outlined,
        'active': Icons.home_rounded,
        'label': 'Home',
      },
      {
        'icon': Icons.assignment_outlined,
        'active': Icons.assignment_rounded,
        'label': 'Laporan',
      },
      {
        'icon': Icons.store_outlined,
        'active': Icons.store_rounded,
        'label': 'Bank Sampah',
      },
      {
        'icon': Icons.location_on_outlined,
        'active': Icons.location_on_rounded,
        'label': 'Info TPS',
      },
    ];

    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (index) {
          final isActive = index == 1;
          final item = items[index];

          return GestureDetector(
            onTap: () {
              if (index == 0)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeUserScreen()),
                );
              else if (index == 2)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RiwayatSetorScreen()),
                );
              else if (index == 3)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const InfoTpsScreen()),
                );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: isActive
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2E7D32),
                          const Color(0xFF4CAF50),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    )
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive
                        ? item['active'] as IconData
                        : item['icon'] as IconData,
                    color: isActive ? Colors.white : const Color(0xFF9E9E9E),
                    size: 22,
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    const Text(
                      'Laporan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
