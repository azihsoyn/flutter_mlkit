import 'dart:async';

import 'package:flutter/services.dart';

class VisionText {
  final Map<dynamic, dynamic> _data;

  // final CGRect frame;
  String get text => _data['text'];
  final List<dynamic> cornerPoints;

  VisionText._(this._data);
}

class VisionTextBlock extends VisionText {
  final List<VisionTextLine> lines;

  VisionTextBlock._(Map<dynamic, dynamic> data)
      : lines = data['lines'] == null
            ? null
            : data['lines']
                .map<VisionTextLine>((dynamic item) => VisionTextLine._(item))
                .toList(),
        super._(data);
}

class VisionTextLine extends VisionText {
  final List<VisionTextElement> elements;

  VisionTextLine._(Map<dynamic, dynamic> data)
      : elements = data['elements'] == null
            ? null
            : data['elements']
                .map<VisionTextElement>(
                    (dynamic item) => VisionTextElement._(item))
                .toList(),
        super._(data);
}

class VisionTextElement extends VisionText {
  VisionTextElement._(Map<dynamic, dynamic> data) : super._(data);
}

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

  Future<List<VisionText>> detectFromPath(String filepath) async {
    List<dynamic> features =
        await _channel.invokeMethod("detectFromPath", {'filepath': filepath});
    List<VisionText> ret = [];
    features.forEach((dynamic feature) {
      final VisionTextBlock block = new VisionTextBlock._(feature);
      ret.add(block);
    });
    return ret;
  }
}
