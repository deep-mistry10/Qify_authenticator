import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen
    extends StatefulWidget {
  const QrScannerScreen({
    super.key,
  });

  @override
  State<QrScannerScreen> createState() =>
      _QrScannerScreenState();
}

class _QrScannerScreenState
    extends State<QrScannerScreen> {
  final MobileScannerController
  _controller =
  MobileScannerController();

  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(
      BarcodeCapture capture,
      ) {
    if (_handled) {
      return;
    }

    for (final barcode
    in capture.barcodes) {
      final value = barcode.rawValue;

      if (value == null ||
          value.trim().isEmpty) {
        continue;
      }

      final normalized =
      value.trim();

      if (!normalized
          .toLowerCase()
          .startsWith(
        'otpauth://totp/',
      )) {
        continue;
      }

      _handled = true;

      Navigator.of(context).pop(
        normalized,
      );

      return;
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan QR code',
        ),
        actions: [
          IconButton(
            tooltip: 'Flash',
            onPressed: () {
              _controller.toggleTorch();
            },
            icon: const Icon(
              Icons.flash_on_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Switch camera',
            onPressed: () {
              _controller.switchCamera();
            },
            icon: const Icon(
              Icons.cameraswitch_outlined,
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  borderRadius:
                  BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: Container(
              padding:
              const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black
                    .withValues(
                  alpha: 0.65,
                ),
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
              ),
              child: const Text(
                'Place the authenticator QR code inside the frame.',
                textAlign: TextAlign.center,
                style: TextStyle(
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