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
    // Ekran genişliğini al, tarama penceresini buna göre hesapla
    final screenWidth = MediaQuery.of(context).size.width;
    const height = 110.0;

    // scanWindow: cihaz ekran koordinatlarında taranacak alan.
    // AppBar yüksekliği + kamera bandının başlangıcını hesaba kat.
    final appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
    final scanWindow = Rect.fromLTWH(0, appBarHeight, screenWidth, height);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Kamera — sadece scanWindow içindeki QR'ları okur
          MobileScanner(
            controller: controller,
            onDetect: onDetect,
            scanWindow: scanWindow,
          ),

          // Yükleniyor
          if (isLoading)
            Container(
              color: Colors.black38,
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

          // Alt yazı
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Text(
              isLoading ? 'Kontrol ediliyor...' : 'QR kodunu okutun',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
