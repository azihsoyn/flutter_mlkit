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
    return SizedBox(
      height: 500.0,
      child: new Center(
        child: _file == null
            ? Text('No Image')
            : Container(
                foregroundDecoration: TextDetectDecoration(_currentLabels),
                child: Image.file(_file, fit: BoxFit.fitWidth),
              ),
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
    return ListTile(
      title: Text(
        "Text: ${text}",
      ),
      dense: true,
    );
  }
}

class TextDetectDecoration extends Decoration {
  final List<VisionText> _texts;
  TextDetectDecoration(List<VisionText> texts) : _texts = texts;

  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    return new _TextDetectPainter(_texts);
  }
}

class _TextDetectPainter extends BoxPainter {
  final List<VisionText> _texts;
  _TextDetectPainter(texts) : _texts = texts;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final paint = new Paint()
      ..strokeWidth = 2.0
      ..color = Colors.red
      ..style = PaintingStyle.stroke;

    for (var text in _texts) {
      print("text : ${text.text}, rect : ${text.rect}");
      final _ratio = 4.9;
      final _rect = Rect.fromLTRB(
          offset.dx + text.rect.left / _ratio,
          offset.dy + text.rect.top / _ratio,
          offset.dx + text.rect.right / _ratio,
          offset.dy + text.rect.bottom / _ratio);
      //final _rect = Rect.fromLTRB(24.0, 115.0, 75.0, 131.2);
      print("_rect : ${_rect}");
      canvas.drawRect(_rect, paint);
    }

    print("offset : ${offset}");
    print("configuration : ${configuration}");

    final rect = offset & configuration.size;

    print("rect container : ${rect}");

    //canvas.drawRect(rect, paint);
    canvas.restore();
  }
}
