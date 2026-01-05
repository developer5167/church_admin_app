import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;

import '../flavor/flavor_config.dart';

class QrViewScreen extends StatefulWidget {
  final String qrUrl;
  const QrViewScreen({super.key, required this.qrUrl});

  @override
  State<QrViewScreen> createState() => _QrViewScreenState();
}

class _QrViewScreenState extends State<QrViewScreen>
    with SingleTickerProviderStateMixin {
  bool _isDownloading = false;
  bool _isSharing = false;
  bool _showChurchLogo = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _captureQr() async {
    try {
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing QR: $e');
      return null;
    }
  }

  Future<void> _saveQrToGallery() async {
    if (_isDownloading) return;

    HapticFeedback.mediumImpact();
    setState(() => _isDownloading = true);

    try {
      final bytes = await _captureQr();
      if (bytes != null) {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${directory.path}/qr_code_$timestamp.png');
        await file.writeAsBytes(bytes);

        HapticFeedback.selectionClick();
        _showSuccessDialog('QR Code saved successfully!');
      } else {
        throw 'Failed to capture QR code';
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showErrorDialog('Failed to save QR code: $e');
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  // Future<void> _shareQr() async {
  //   if (_isSharing) return;

  //   HapticFeedback.mediumImpact();
  //   setState(() => _isSharing = true);

  //   try {
  //     final bytes = await _captureQr();
  //     if (bytes != null) {
  //       await Share.file(
  //         'Church Service QR Code',
  //         'service_qr.png',
  //         bytes,
  //         'image/png',
  //         text: 'Scan this QR code to register attendance for church service',
  //       );
  //       HapticFeedback.selectionClick();
  //     } else {
  //       throw 'Failed to capture QR code';
  //     }
  //   } catch (e) {
  //     HapticFeedback.heavyImpact();
  //     _showErrorDialog('Failed to share QR code: $e');
  //   } finally {
  //     setState(() => _isSharing = false);
  //   }
  // }

  void _copyQrUrl() {
    Clipboard.setData(ClipboardData(text: widget.qrUrl));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('QR URL copied to clipboard'),
        backgroundColor:  FlavorConfig.instance.values.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title:  Text(
          'Error',
          style: TextStyle(
            color: FlavorConfig.instance.values.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:  FlavorConfig.instance.values.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text(
          'Success',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:  FlavorConfig.instance.values.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8F8F8), Color(0xFFE8E8E8), Color(0xFFF8F8F8)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.black87,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Service QR Code',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[900],
                                fontFamily: 'PlayfairDisplay',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Scan to register attendance',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.qr_code_scanner,
                        color:  FlavorConfig.instance.values.primaryColor,
                        size: 32,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            // QR Code Container
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(30),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Church Logo
                                    if (_showChurchLogo)
                                      Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 20,
                                        ),
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(
                                            0xFF8B0000,
                                          ).withValues(alpha: 0.1),
                                        ),
                                        child: Image.asset(
                                          FlavorConfig.instance.values.logoAsset,
                                          fit: BoxFit.contain,
                                          width: 50,
                                          height: 50,
                                        ),
                                      ),

                                    // QR Code
                                    RepaintBoundary(
                                      key: _qrKey,
                                      child: QrImageView(
                                        data: widget.qrUrl,
                                        version: QrVersions.auto,
                                        size: 280,
                                        eyeStyle:  QrEyeStyle(
                                          eyeShape: QrEyeShape.square,
                                          color: FlavorConfig.instance.values.primaryColor,
                                        ),
                                        dataModuleStyle:
                                            const QrDataModuleStyle(
                                              dataModuleShape:
                                                  QrDataModuleShape.square,
                                              color: Colors.black87,
                                            ),
                                        backgroundColor: Colors.white,
                                        embeddedImage: _showChurchLogo
                                            ?  AssetImage(
                                          FlavorConfig.instance.values.logoAsset,
                                              )
                                            : null,
                                        embeddedImageStyle:
                                            QrEmbeddedImageStyle(
                                              size: const Size(40, 40),
                                            ),
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // QR URL Preview
                                    GestureDetector(
                                      onTap: _copyQrUrl,
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                             Icon(
                                              Icons.link,
                                              color: FlavorConfig.instance.values.primaryColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                widget.qrUrl.length > 40
                                                    ? '${widget.qrUrl.substring(0, 40)}...'
                                                    : widget.qrUrl,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                             Icon(
                                              Icons.content_copy,
                                              color: FlavorConfig.instance.values.primaryColor,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Instructions
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF8B0000,
                                        ).withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color:  FlavorConfig.instance.values.primaryColor,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Instructions',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Members should scan this QR code using the church member app to register their attendance.',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Action Buttons
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Toggle Logo Button
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.image,
                                        color: Colors.grey[600],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Show Church Logo',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ),
                                      Switch(
                                        value: _showChurchLogo,
                                        onChanged: (value) {
                                          HapticFeedback.selectionClick();
                                          setState(
                                            () => _showChurchLogo = value,
                                          );
                                        },
                                        activeColor:  FlavorConfig.instance.values.primaryColor,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  // Share Button
                                  // SizedBox(
                                  //   width: double.infinity,
                                  //   height: 56,
                                  //   child: ElevatedButton.icon(
                                  //     onPressed: _isSharing ? null : _shareQr,
                                  //     icon: _isSharing
                                  //         ? const SizedBox(
                                  //             width: 16,
                                  //             height: 16,
                                  //             child: CircularProgressIndicator(
                                  //               strokeWidth: 2,
                                  //               color: Colors.white,
                                  //             ),
                                  //           )
                                  //         : const Icon(
                                  //             Icons.share,
                                  //             color: Colors.white,
                                  //             size: 22,
                                  //           ),
                                  //     label: Text(
                                  //       _isSharing
                                  //           ? 'Sharing...'
                                  //           : 'Share QR Code',
                                  //       style: const TextStyle(
                                  //         fontSize: 16,
                                  //         fontWeight: FontWeight.w600,
                                  //         color: Colors.white,
                                  //       ),
                                  //     ),
                                  //     style: ElevatedButton.styleFrom(
                                  //       backgroundColor: const Color(
                                  //         0xFF8B0000,
                                  //       ),
                                  //       disabledBackgroundColor:
                                  //           Colors.grey[400],
                                  //       shape: RoundedRectangleBorder(
                                  //         borderRadius: BorderRadius.circular(
                                  //           16,
                                  //         ),
                                  //       ),
                                  //     ),
                                  //   ),
                                  // ),
                                  const SizedBox(height: 16),

                                  // Download Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton.icon(
                                      onPressed: _isDownloading
                                          ? null
                                          : _saveQrToGallery,
                                      icon: _isDownloading
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.download,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                      label: Text(
                                        _isDownloading
                                            ? 'Downloading...'
                                            : 'Download QR Code',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF8B0000,
                                        ),
                                        disabledBackgroundColor:
                                            Colors.grey[400],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Copy URL Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: OutlinedButton.icon(
                                      onPressed: _copyQrUrl,
                                      icon:  Icon(
                                        Icons.content_copy,
                                        color: FlavorConfig.instance.values.primaryColor,
                                        size: 22,
                                      ),
                                      label:  Text(
                                        'Copy QR URL',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: FlavorConfig.instance.values.primaryColor,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        side:  BorderSide(
                                          color: FlavorConfig.instance.values.primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Tips Section
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline,
                                        color:  FlavorConfig.instance.values.primaryColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Quick Tips',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTip(
                                    '1',
                                    'Display this QR code at church entrance',
                                  ),
                                  _buildTip(
                                    '2',
                                    'Ensure good lighting for easy scanning',
                                  ),
                                  _buildTip(
                                    '3',
                                    'Print and post in multiple locations',
                                  ),
                                  _buildTip(
                                    '4',
                                    'Share digitally for remote members',
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Footer
                            Center(
                              child: Text(
                                'The Lords Church Admin Portal © ${DateTime.now().year}',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildTip(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color:  FlavorConfig.instance.values.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style:  TextStyle(
                  color: FlavorConfig.instance.values.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}
