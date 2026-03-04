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
    const double width = 385.0;
    const double height = 100.0;
    const double radius = 10.0;
    final color = Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: color.withOpacity(0.25), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: onDetect,
                ),

                if (isLoading)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // Köşe çerçevesi
                CustomPaint(painter: _CornerFrame(color: Colors.white70)),

                // Alt yazı — kamera içinde
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: Text(
                    isLoading ? 'Kontrol ediliyor...' : 'QR kodunu okutun',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CornerFrame extends CustomPainter {
  final Color color;
  const _CornerFrame({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 16.0;
    const pad = 10.0;

    // Sol üst
    canvas.drawPath(
        Path()
          ..moveTo(pad, pad + len)
          ..lineTo(pad, pad)
          ..lineTo(pad + len, pad),
        paint);
    // Sağ üst
    canvas.drawPath(
        Path()
          ..moveTo(size.width - pad - len, pad)
          ..lineTo(size.width - pad, pad)
          ..lineTo(size.width - pad, pad + len),
        paint);
    // Sol alt
    canvas.drawPath(
        Path()
          ..moveTo(pad, size.height - pad - len)
          ..lineTo(pad, size.height - pad)
          ..lineTo(pad + len, size.height - pad),
        paint);
    // Sağ alt
    canvas.drawPath(
        Path()
          ..moveTo(size.width - pad - len, size.height - pad)
          ..lineTo(size.width - pad, size.height - pad)
          ..lineTo(size.width - pad, size.height - pad - len),
        paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
