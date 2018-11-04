# mlkit

[![pub package](https://img.shields.io/pub/v/mlkit.svg)](https://pub.dartlang.org/packages/mlkit)

A Flutter plugin to use the Firebase ML Kit.

:star:*Only your star motivate me!*:star:

## this is *not official* package
The flutter team now has the [firebase_ml_vision](https://pub.dartlang.org/packages/firebase_ml_vision) package for Firebase ML Kit. Please consider trying to use firebase_ml_vision. 

*Note*: This plugin is still under development, and some APIs might not be available yet. [Feedback](https://github.com/azihsoyn/flutter_mlkit/issues) and [Pull Requests](https://github.com/azihsoyn/flutter_mlkit/pulls) are most welcome!

## Features

| Feature                        | Android | iOS |
|--------------------------------|---------|-----|
| Recognize text(on device)      | ✅      | ✅  |
| Recognize text(cloud)          | yet     | yet |
| Detect faces(on device)        | ✅      | ✅  |
| Scan barcodes(on device)       | ✅      | ✅  |
| Label Images(on device)        | ✅      | ✅  |
| Label Images(cloud)            | yet     | yet |
| Recognize landmarks(cloud)     | yet     | yet |
| Custom model                   | ✅      | ✅  |

[What features are available on device or in the cloud?](https://firebase.google.com/docs/ml-kit/)

## Usage
To use this plugin, add `mlkit` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

## Getting Started

Check out the `example` directory for a sample app using Firebase Cloud Messaging.

### Android Integration

To integrate your plugin into the Android part of your app, follow these steps:

1. Using the [Firebase Console](https://console.firebase.google.com/) add an Android app to your project: Follow the assistant, download the generated `google-services.json` file and place it inside `android/app`. Next, modify the `android/build.gradle` file and the `android/app/build.gradle` file to add the Google services plugin as described by the Firebase assistant.

### iOS Integration

To integrate your plugin into the iOS part of your app, follow these steps:

1. Using the [Firebase Console](https://console.firebase.google.com/) add an iOS app to your project: Follow the assistant, download the generated `GoogleService-Info.plist` file, open `ios/Runner.xcworkspace` with Xcode, and within Xcode place the file inside `ios/Runner`. **Don't** follow the steps named "Add Firebase SDK" and "Add initialization code" in the Firebase assistant.

1. Remove the `use_frameworks!` line from `ios/Podfile` (workaround for [flutter/flutter#9694](https://github.com/flutter/flutter/issues/9694)).

### Dart/Flutter Integration

From your Dart code, you need to import the plugin and instantiate it:

```dart
import 'package:mlkit/mlkit.dart';

FirebaseVisionTextDetector detector = FirebaseVisionTextDetector.instance;

// Detect form file/image by path
var currentLabels = await detector.detectFromPath(_file?.path);

// Detect from binary data of a file/image
var currentLabels = await detector.detectFromBinary(_file?.readAsBytesSync());
```

#### custom model interpreter

[native sample code](https://github.com/googlecodelabs/mlkit-android/blob/master/custom-model/final/app/src/main/java/com/google/firebase/codelab/mlkit_custommodel/MainActivity.java)

```dart
import 'package:mlkit/mlkit.dart';
import 'package:image/image.dart' as img;

FirebaseModelInterpreter interpreter = FirebaseModelInterpreter.instance;
FirebaseModelManager manager = FirebaseModelManager.instance;
manager.registerCloudModelSource(
        FirebaseCloudModelSource(modelName: "mobilenet_v1_224_quant"));

var imageBytes = (await rootBundle.load("assets/mountain.jpg")).buffer;
img.Image image = img.decodeJpg(imageBytes.asUint8List());
image = img.copyResize(image, 224, 224);
var results = await interpreter.run(
                    "mobilenet_v1_224_quant",
                    FirebaseModelInputOutputOptions(
                        0,
                        FirebaseModelDataType.BYTE,
                        [1, 224, 224, 3],
                        0,
                        FirebaseModelDataType.BYTE,
                        [1, 1001]),
                    imageToByteList(image));

// int model
Uint8List imageToByteList(img.Image image) {
    var _inputSize = 224;
    var convertedBytes = new Uint8List(1 * _inputSize * _inputSize * 3);
    var buffer = new ByteData.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < _inputSize; i++) {
      for (var j = 0; j < _inputSize; j++) {
        var pixel = image.getPixel(i, j);
        buffer.setUint8(pixelIndex, (pixel >> 16) & 0xFF);
        pixelIndex++;
        buffer.setUint8(pixelIndex, (pixel >> 8) & 0xFF);
        pixelIndex++;
        buffer.setUint8(pixelIndex, (pixel) & 0xFF);
        pixelIndex++;
      }
    }
    return convertedBytes;
  }

// float model
Uint8List imageToByteList(img.Image image) {
  var _inputSize = 224;
  var convertedBytes = Float32List(1 * _inputSize * _inputSize * 3);
  var buffer = Float32List.view(convertedBytes.buffer);
  int pixelIndex = 0;
  for (var i = 0; i < _inputSize; i++) {
    for (var j = 0; j < _inputSize; j++) {
      var pixel = image.getPixel(i, j);
      buffer[pixelIndex] = ((pixel >> 16) & 0xFF) / 255;
      pixelIndex += 1;
      buffer[pixelIndex] = ((pixel >> 8) & 0xFF) / 255;
      pixelIndex += 1;
      buffer[pixelIndex] = ((pixel) & 0xFF) / 255;
      pixelIndex += 1;
    }
  }
  return convertedBytes.buffer.asUint8List();
}
```
