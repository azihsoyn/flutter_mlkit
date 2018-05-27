import 'dart:async';

import 'package:flutter/services.dart';

class Mlkit {
  static const MethodChannel _channel =
      const MethodChannel('mlkit');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
