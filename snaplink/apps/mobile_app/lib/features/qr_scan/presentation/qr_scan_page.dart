import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:mobile_app/core/providers/app_providers.dart';

class QrScanPage extends ConsumerStatefulWidget {
  const QrScanPage({super.key});

  @override
  ConsumerState<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends ConsumerState<QrScanPage> {
  bool _handling = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Desktop QR')),
      body: Stack(
        children: <Widget>[
          MobileScanner(
            onDetect: (BarcodeCapture capture) async {
              if (_handling) {
                return;
              }
              final value = capture.barcodes.first.rawValue;
              if (value == null || value.isEmpty) {
                return;
              }
              setState(() => _handling = true);
              try {
                await ref.read(mobileConnectionServiceProvider).pairFromQr(value);
                if (mounted) {
                  context.go('/connect');
                }
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.toString())),
                  );
                }
                setState(() => _handling = false);
              }
            },
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  _handling
                      ? 'Pairing in progress...'
                      : 'Align the QR shown on the Windows app inside the frame.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
