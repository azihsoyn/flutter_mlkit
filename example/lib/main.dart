import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mlkit/mlkit.dart';

import 'custom-models.dart';
import 'vision-text.dart';
import 'face-detect.dart';
import 'label-image.dart';

void main() {
  runApp(MaterialApp(
    title: 'Named Routes Demo',
    // Start the app with the "/" named route. In our case, the app will start
    // on the FirstScreen Widget
    initialRoute: '/',
    routes: {
      '/': (context) => StartScreen(),
      '/vision-text': (context) => VisionTextWidget(),
      '/custom-model': (context) => CustomModelWidget(),
      '/face-detect': (context) => FaceDetectWidget(),
      '/label-image': (context) => LabelImageWidget(),
    },
  ));
}

class StartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('MLKit Demo'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Center(
              child: RaisedButton(
                child: Text('MLKit vision text detection'),
                onPressed: () {
                  // Navigate to the second screen using a named route
                  Navigator.pushNamed(context, '/vision-text');
                },
              ),
            ),
            Center(
              child: RaisedButton(
                child: Text('Object detection with custom model'),
                onPressed: () {
                  // Navigate to the second screen using a named route
                  Navigator.pushNamed(context, '/custom-model');
                },
              ),
            ),
            Center(
              child: RaisedButton(
                child: Text('Face detection'),
                onPressed: () {
                  // Navigate to the second screen using a named route
                  Navigator.pushNamed(context, '/face-detect');
                },
              ),
            ),
            Center(
              child: RaisedButton(
                child: Text('Label Images'),
                onPressed: () {
                  // Navigate to the second screen using a named route
                  Navigator.pushNamed(context, '/label-image');
                },
              ),
            ),
          ],
        ));
  }
}
