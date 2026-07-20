import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'form_transaksi_setor_screen_v2.dart';
import 'home_admin_screen.dart';

class QrBarcodeScreen extends StatefulWidget {
  const QrBarcodeScreen({super.key});

  @override
  State<QrBarcodeScreen> createState() => _QrBarcodeScreenState();
}

class _QrBarcodeScreenState extends State<QrBarcodeScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    // Animasi garis scan
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context), // ✅ GANTI DENGAN pop
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: const Text(
            'Scan QR Code',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Icon(Icons.flash_on, color: Colors.white, size: 20),
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // KAMERA FULL SCREEN
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (!_isProcessing && barcode.rawValue != null) {
                  _handleScan(barcode.rawValue!);
                }
              }
            },
          ),

          // OVERLAY GELAP DI LUAR FRAME
          AnimatedBuilder(
            animation: _scanLineAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: ScannerOverlayPainter(
                  scanPosition: _scanLineAnimation.value,
                ),
                child: Container(),
              );
            },
          ),

          // PANEL BAWAH
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.95),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status indicator
                  if (_isProcessing)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF4CAF50),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Memproses...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!_isProcessing)
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Arahkan kamera ke QR Code',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // Tombol Input Manual
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showManualInputDialog,
                      icon: const Icon(Icons.keyboard, size: 18),
                      label: const Text(
                        'Input Manual Kode',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1B5E20),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info text
                  Text(
                    'Scan QR Code pengguna untuk memulai transaksi',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleScan(String scannedCode) async {
    setState(() => _isProcessing = true);

    debugPrint("🔍 Scanned code: '$scannedCode'");

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/cari-pengguna'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'kode_qr': scannedCode}),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint("📥 Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success' && mounted) {
          // Get feedback
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FormTransaksiSetorScreenV2(
                userData: result['data'],
                kodeQr: scannedCode,
              ),
            ),
          );
        } else {
          _showInvalidQRDialog(result['message'] ?? 'Pengguna tidak ditemukan');
        }
      } else {
        _showError('Gagal: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      _showError('Koneksi error: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showInvalidQRDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'QR Tidak Valid',
                    style: TextStyle(
                      color: Color(0xFF1B5E20),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Kode QR yang discan tidak terdaftar dalam database.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showManualInputDialog() {
    final kodeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Input Manual Kode',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        content: TextField(
          controller: kodeCtrl,
          decoration: InputDecoration(
            hintText: 'Masukkan kode pengguna',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.qr_code, color: Color(0xFF4CAF50)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () {
              if (kodeCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                _handleScan(kodeCtrl.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Cari',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}

// Custom scanner overlay painter dengan animasi
class ScannerOverlayPainter extends CustomPainter {
  final double scanPosition;

  ScannerOverlayPainter({required this.scanPosition});

  @override
  void paint(Canvas canvas, Size size) {
    final frameSize = Size(280, 280);
    final frameOffset = Offset(
      (size.width - frameSize.width) / 2,
      (size.height - frameSize.height) / 2 - 80,
    );

    // Overlay gelap di luar frame
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Draw overlay dengan hole di tengah
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            frameOffset.dx,
            frameOffset.dy,
            frameSize.width,
            frameSize.height,
          ),
          const Radius.circular(20),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);

    // Corner lines
    final cornerPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final cornerLength = 40.0;
    final radius = 20.0;

    // Top left
    _drawCorner(
      canvas,
      cornerPaint,
      frameOffset,
      cornerLength,
      radius,
      'topLeft',
    );
    // Top right
    _drawCorner(
      canvas,
      cornerPaint,
      Offset(frameOffset.dx + frameSize.width, frameOffset.dy),
      cornerLength,
      radius,
      'topRight',
    );
    // Bottom left
    _drawCorner(
      canvas,
      cornerPaint,
      Offset(frameOffset.dx, frameOffset.dy + frameSize.height),
      cornerLength,
      radius,
      'bottomLeft',
    );
    // Bottom right
    _drawCorner(
      canvas,
      cornerPaint,
      Offset(
        frameOffset.dx + frameSize.width,
        frameOffset.dy + frameSize.height,
      ),
      cornerLength,
      radius,
      'bottomRight',
    );

    // Scan line animasi
    final scanLinePaint = Paint()
      ..shader =
          LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFF4CAF50).withOpacity(0.8),
              const Color(0xFF4CAF50),
              const Color(0xFF4CAF50).withOpacity(0.8),
              Colors.transparent,
            ],
            stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
          ).createShader(
            Rect.fromLTWH(frameOffset.dx, frameOffset.dy, frameSize.width, 3),
          )
      ..strokeWidth = 3;

    final scanLineY = frameOffset.dy + (frameSize.height * scanPosition);
    canvas.drawLine(
      Offset(frameOffset.dx + 10, scanLineY),
      Offset(frameOffset.dx + frameSize.width - 10, scanLineY),
      scanLinePaint,
    );

    // Glow effect di scan line
    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF4CAF50).withOpacity(0.3),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(frameOffset.dx + frameSize.width / 2, scanLineY),
              radius: 60,
            ),
          );

    canvas.drawRect(
      Rect.fromLTWH(frameOffset.dx, scanLineY - 30, frameSize.width, 60),
      glowPaint,
    );
  }

  void _drawCorner(
    Canvas canvas,
    Paint paint,
    Offset center,
    double length,
    double radius,
    String position,
  ) {
    double dx = 0, dy = 0;

    switch (position) {
      case 'topLeft':
        dx = center.dx;
        dy = center.dy;
        canvas.drawArc(
          Rect.fromLTWH(dx, dy, radius * 2, radius * 2),
          3.14159,
          1.5708,
          false,
          paint,
        );
        canvas.drawLine(
          Offset(dx + radius, dy),
          Offset(dx + length, dy),
          paint,
        );
        canvas.drawLine(
          Offset(dx, dy + radius),
          Offset(dx, dy + length),
          paint,
        );
        break;
      case 'topRight':
        dx = center.dx - radius * 2;
        dy = center.dy;
        canvas.drawArc(
          Rect.fromLTWH(dx, dy, radius * 2, radius * 2),
          4.71239,
          1.5708,
          false,
          paint,
        );
        canvas.drawLine(
          Offset(center.dx - radius, dy),
          Offset(center.dx - length, dy),
          paint,
        );
        canvas.drawLine(
          Offset(center.dx, dy + radius),
          Offset(center.dx, dy + length),
          paint,
        );
        break;
      case 'bottomLeft':
        dx = center.dx;
        dy = center.dy - radius * 2;
        canvas.drawArc(
          Rect.fromLTWH(dx, dy, radius * 2, radius * 2),
          1.5708,
          1.5708,
          false,
          paint,
        );
        canvas.drawLine(
          Offset(dx + radius, center.dy),
          Offset(dx + length, center.dy),
          paint,
        );
        canvas.drawLine(
          Offset(dx, center.dy - radius),
          Offset(dx, center.dy - length),
          paint,
        );
        break;
      case 'bottomRight':
        dx = center.dx - radius * 2;
        dy = center.dy - radius * 2;
        canvas.drawArc(
          Rect.fromLTWH(dx, dy, radius * 2, radius * 2),
          0,
          1.5708,
          false,
          paint,
        );
        canvas.drawLine(
          Offset(center.dx - radius, center.dy),
          Offset(center.dx - length, center.dy),
          paint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - radius),
          Offset(center.dx, center.dy - length),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanPosition != scanPosition;
  }
}
