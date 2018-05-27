import 'dart:async';

import 'package:flutter/services.dart';

class FirebaseMlkit {
  static const MethodChannel _channel =
      const MethodChannel('plugins.flutter.io/firebase_mlkit');

  static FirebaseMlkit instance = new FirebaseMlkit._();

  FirebaseMlkit._() {}

  FirebaseVisionTextDetector getVisionTextDetector() {
    return FirebaseVisionTextDetector.instance;
  }
}

class FirebaseVisionTextDetector {
  static const MethodChannel _channel =
      const MethodChannel('plugins.flutter.io/firebase_mlkit/vision_text');

  static FirebaseVisionTextDetector instance =
      new FirebaseVisionTextDetector._();

  FirebaseVisionTextDetector._() {}

  Future<List<String>> detectFromPath(String filepath) async {
    List<dynamic> texts =
        await _channel.invokeMethod("detectFromPath", {'filepath': filepath});
    List<String> ret = [];
    texts.forEach((dynamic text) {
      String t = text;
      ret.add(t);
    });
    print(ret);
    return ret;
  }
}
