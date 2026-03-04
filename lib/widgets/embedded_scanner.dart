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
    const height = 72.0;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: controller,
            onDetect: onDetect,
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
