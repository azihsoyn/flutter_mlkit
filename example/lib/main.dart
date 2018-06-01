import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mlkit/mlkit.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File _file;
  List<VisionText> _currentLabels = <VisionText>[];

  FirebaseVisionTextDetector detector = FirebaseVisionTextDetector.instance;

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('Plugin example app'),
        ),
        body: _buildBody(),
        floatingActionButton: new FloatingActionButton(
          onPressed: () async {
            try {
              //var file = await ImagePicker.pickImage(source: ImageSource.camera);
              var file =
                  await ImagePicker.pickImage(source: ImageSource.gallery);
              setState(() {
                _file = file;
              });
              try {
                var currentLabels = await detector.detectFromPath(_file?.path);
                setState(() {
                  _currentLabels = currentLabels;
                });
              } catch (e) {
                print(e.toString());
              }
            } catch (e) {
              print(e.toString());
            }
          },
          child: new Icon(Icons.camera),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return new SizedBox(
      height: 500.0,
      child: new Center(
        child: _file == null
            ? Text('No Image')
            : Image.file(_file, fit: BoxFit.fitWidth),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: <Widget>[
        _buildImage(),
        _buildList(_currentLabels),
      ],
    );
  }

  Widget _buildList(List<VisionText> texts) {
    if (texts.length == 0) {
      return Text('Empty');
    }
    return SizedBox(
      height: 200.0,
      child: ListView.builder(
          padding: const EdgeInsets.all(1.0),
          itemCount: texts.length,
          itemBuilder: (context, i) {
            return _buildRow(texts[i].text);
          }),
    );
  }

  Widget _buildRow(String text) {
    return new ListTile(
      title: new Text(
        text,
      ),
    );
  }
}
