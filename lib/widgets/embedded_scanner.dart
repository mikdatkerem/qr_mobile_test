import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EmbeddedScanner extends StatelessWidget {
  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;
  final bool isLoading;

  const EmbeddedScanner({
    super.key,
    required this.controller,
    required this.onDetect,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Kamera önizlemesi
            MobileScanner(
              controller: controller,
              onDetect: onDetect,
            ),

            // Köşe çerçeve overlay
            CustomPaint(
              painter: _ScannerFramePainter(),
            ),

            // Yükleniyor göstergesi
            if (isLoading)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 10.0;
    final w = size.width;
    final h = size.height;

    // Sol üst
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLen)
        ..lineTo(0, 0)
        ..lineTo(cornerLen, 0),
      paint,
    );
    // Sağ üst
    canvas.drawPath(
      Path()
        ..moveTo(w - cornerLen, 0)
        ..lineTo(w, 0)
        ..lineTo(w, cornerLen),
      paint,
    );
    // Sol alt
    canvas.drawPath(
      Path()
        ..moveTo(0, h - cornerLen)
        ..lineTo(0, h)
        ..lineTo(cornerLen, h),
      paint,
    );
    // Sağ alt
    canvas.drawPath(
      Path()
        ..moveTo(w - cornerLen, h)
        ..lineTo(w, h)
        ..lineTo(w, h - cornerLen),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
