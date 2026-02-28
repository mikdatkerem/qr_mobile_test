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
      width: double.infinity,
      height: 110,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Kamera önizlemesi
          MobileScanner(
            controller: controller,
            onDetect: onDetect,
          ),

          // Hafif karartma — göze batmasın
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black12],
              ),
            ),
          ),

          // Tarama çerçevesi
          Center(
            child: CustomPaint(
              size: const Size(180, 60),
              painter: _ScannerFramePainter(),
            ),
          ),

          // "QR kodunu okutun" etiketi
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Text(
              isLoading ? 'Kontrol ediliyor...' : 'QR kodunu okutun',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ),

          // Yükleniyor göstergesi
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
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

    const cornerLen = 14.0;
    final w = size.width;
    final h = size.height;

    // Sol üst
    canvas.drawPath(
        Path()
          ..moveTo(0, cornerLen)
          ..lineTo(0, 0)
          ..lineTo(cornerLen, 0),
        paint);
    // Sağ üst
    canvas.drawPath(
        Path()
          ..moveTo(w - cornerLen, 0)
          ..lineTo(w, 0)
          ..lineTo(w, cornerLen),
        paint);
    // Sol alt
    canvas.drawPath(
        Path()
          ..moveTo(0, h - cornerLen)
          ..lineTo(0, h)
          ..lineTo(cornerLen, h),
        paint);
    // Sağ alt
    canvas.drawPath(
        Path()
          ..moveTo(w - cornerLen, h)
          ..lineTo(w, h)
          ..lineTo(w, h - cornerLen),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
