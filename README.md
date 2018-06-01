# mlkit

[![pub package](https://img.shields.io/pub/v/mlkit.svg)](https://pub.dartlang.org/packages/mlkit)

A Flutter plugin to use the Firebase ML Kit.

*Note*: This plugin is still under development, and some APIs might not be available yet. [Feedback](https://github.com/azihsoyn/flutter_mlkit/issues) and [Pull Requests](https://github.com/azihsoyn/flutter_mlkit/pulls) are most welcome!

## Features

| Feature                        | Android | iOS |
|--------------------------------|---------|-----|
| Recognize text(on device)      | ✅       | ✅   |
| Recognize text(cloud)          | yet     | yet |
| Detect faces(on device)        | yet     | yet |
| Detect faces(cloud)            | yet     | yet |
| Scan barcodes(on device)       | yet     | yet |
| Scan barcodes(cloud)           | yet     | yet |
| Label Images(on device)        | yet     | yet |
| Label Images(cloud)            | yet     | yet |
| Recognize landmarks(on device) | yet     | yet |
| Recognize landmarks(cloud)     | yet     | yet |
| Custom model                   | yet     | yet |

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

var currentLabels = await detector.detectFromPath(_file?.path);
```
