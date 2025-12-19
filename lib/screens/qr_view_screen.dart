import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrViewScreen extends StatelessWidget {
  final String qrUrl;
  const QrViewScreen({super.key, required this.qrUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service QR')),
      body: Center(
        child: QrImageView(
          data: qrUrl,
          size: 300,
        ),
      ),
    );
  }
}
