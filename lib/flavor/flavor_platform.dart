import 'package:flutter/services.dart';

class FlavorPlatform {
  static const _channel = MethodChannel('church_flavor');

  static Future<String> getFlavor() async {
    final flavor = await _channel.invokeMethod<String>('getFlavor');
    return flavor ?? 'lordsChurchAdmin';
  }
}
