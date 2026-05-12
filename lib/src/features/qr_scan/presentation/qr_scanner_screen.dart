import 'package:chargego/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum QrScanMode { startRental, returnStation }

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key, this.mode = QrScanMode.startRental});

  final QrScanMode mode;

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  final TextEditingController _manualCodeController = TextEditingController();
  bool _isScanning = true;

  @override
  void dispose() {
    controller.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  void _submitManualCode() {
    final code = _manualCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introduce el codigo de estacion o bateria.'),
        ),
      );
      return;
    }

    setState(() {
      _isScanning = false;
    });
    _completeScan(code);
  }

  void _completeScan(String code) {
    switch (widget.mode) {
      case QrScanMode.startRental:
        context.pushReplacement('/active-rental', extra: code);
      case QrScanMode.returnStation:
        context.pop(code);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        debugPrint('Codigo encontrado: $code');
        setState(() {
          _isScanning = false;
        });

        _completeScan(code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == QrScanMode.returnStation
              ? 'Escanear devolucion'
              : 'Escanear codigo QR',
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: _onDetect),
          // Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: ChargeGoColors.electric, width: 5),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: ChargeGoColors.electric.withValues(alpha: 0.28),
                    blurRadius: 26,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ChargeGoColors.navy, ChargeGoColors.royal],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Text(
                  widget.mode == QrScanMode.returnStation
                      ? 'Escanea el QR de la estacion de devolucion'
                      : 'Apunta la camara al codigo QR',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 150,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Codigo manual',
                        hintText: widget.mode == QrScanMode.returnStation
                            ? 'Codigo de estacion'
                            : 'Codigo de estacion o bateria',
                        prefixIcon: const Icon(Icons.pin_outlined),
                      ),
                      onSubmitted: (_) => _submitManualCode(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    tooltip: 'Introducir codigo',
                    onPressed: _submitManualCode,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
