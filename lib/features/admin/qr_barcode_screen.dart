import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'form_transaksi_setor_screen_v2.dart'; // Form untuk input setoran

class QrBarcodeScreen extends StatefulWidget {
  const QrBarcodeScreen({super.key});

  @override
  State<QrBarcodeScreen> createState() => _QrBarcodeScreenState();
}

class _QrBarcodeScreenState extends State<QrBarcodeScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: const Text(
          'Scan Petugas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: MobileScanner(
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
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Arahkan kamera ke QR barcode pengguna',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Custom scanner overlay
                CustomPaint(
                  size: const Size(250, 250),
                  painter: ScannerOverlayPainter(),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    // Input manual jika scan gagal
                    _showManualInputDialog();
                  },
                  icon: const Icon(Icons.keyboard),
                  label: const Text('Input Manual Kode Pengguna'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
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

  Future<void> _handleScan(String scannedCode) async {
    setState(() => _isProcessing = true);

    // ✅ Debug: Lihat kode yang discan
    debugPrint("🔍 Scanned code: '$scannedCode'");
    debugPrint("🔍 URL: ${ApiConfig.baseUrl}/cari-pengguna");

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/cari-pengguna'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'kode_qr': scannedCode}),
          )
          .timeout(const Duration(seconds: 30));

      // ✅ Debug: Lihat response
      debugPrint("📥 Status: ${response.statusCode}");
      debugPrint("📄 Response: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success' && mounted) {
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
          _showError('Pengguna tidak ditemukan: ${result['message']}');
        }
      } else {
        _showError('Gagal: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      _showError('Koneksi error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showManualInputDialog() {
    final kodeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Input Manual Kode'),
        content: TextField(
          controller: kodeCtrl,
          decoration: const InputDecoration(
            hintText: 'Masukkan kode pengguna',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (kodeCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                _handleScan(kodeCtrl.text);
              }
            },
            child: const Text('Cari'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

// Custom scanner overlay painter
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw corners
    final cornerLength = 30.0;
    final cornerOffset = 20.0;

    // Top left
    canvas.drawLine(
      Offset(cornerOffset, cornerOffset + cornerLength),
      Offset(cornerOffset, cornerOffset),
      paint,
    );
    canvas.drawLine(
      Offset(cornerOffset, cornerOffset),
      Offset(cornerOffset + cornerLength, cornerOffset),
      paint,
    );

    // Top right
    canvas.drawLine(
      Offset(size.width - cornerOffset, cornerOffset),
      Offset(size.width - cornerOffset - cornerLength, cornerOffset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - cornerOffset, cornerOffset),
      Offset(size.width - cornerOffset, cornerOffset + cornerLength),
      paint,
    );

    // Bottom left
    canvas.drawLine(
      Offset(cornerOffset, size.height - cornerOffset),
      Offset(cornerOffset + cornerLength, size.height - cornerOffset),
      paint,
    );
    canvas.drawLine(
      Offset(cornerOffset, size.height - cornerOffset),
      Offset(cornerOffset, size.height - cornerOffset - cornerLength),
      paint,
    );

    // Bottom right
    canvas.drawLine(
      Offset(
        size.width - cornerOffset,
        size.height - cornerOffset - cornerLength,
      ),
      Offset(size.width - cornerOffset, size.height - cornerOffset),
      paint,
    );
    canvas.drawLine(
      Offset(
        size.width - cornerOffset - cornerLength,
        size.height - cornerOffset,
      ),
      Offset(size.width - cornerOffset, size.height - cornerOffset),
      paint,
    );

    // Scanning line animation
    final linePaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
