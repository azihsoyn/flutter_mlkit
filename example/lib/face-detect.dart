import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mlkit/mlkit.dart';

class FaceDetectWidget extends StatefulWidget {
  @override
  _FaceDetectWidgetState createState() => new _FaceDetectWidgetState();
}

class _FaceDetectWidgetState extends State<FaceDetectWidget> {
  File _file;
  List<VisionFace> _currentLabels = <VisionFace>[];

  FirebaseVisionFaceDetector detector = FirebaseVisionFaceDetector.instance;
//  FirebaseVisionFaceDetector

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('face detect'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            tooltip: 'Back',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
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
            : new FutureBuilder<Size>(
                future: _getImageSize(Image.file(_file, fit: BoxFit.fitWidth)),
                builder: (BuildContext context, AsyncSnapshot<Size> snapshot) {
                  if (snapshot.hasData) {
                    return Container(
                        foregroundDecoration:
                            FaceDetectDecoration(_currentLabels, snapshot.data),
                        child: Image.file(_file, fit: BoxFit.fitWidth));
                  } else {
                    return new Text('Detecting...');
                  }
                },
              ),
      ),
    );
  }

  Future<Size> _getImageSize(Image image) {
    Completer<Size> completer = new Completer<Size>();
    image.image.resolve(new ImageConfiguration()).addListener(
        ImageStreamListener((ImageInfo info, bool _) => completer.complete(
            Size(info.image.width.toDouble(), info.image.height.toDouble()))));
    return completer.future;
  }

  Widget _buildBody() {
    return Container(
      child: Column(
        children: <Widget>[
          _buildImage(),
        ],
      ),
    );
  }
}

class FaceDetectDecoration extends Decoration {
  final Size _originalImageSize;
  final List<VisionFace> _faces;
  FaceDetectDecoration(List<VisionFace> texts, Size originalImageSize)
      : _faces = texts,
        _originalImageSize = originalImageSize;

  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    return new _FaceDetectPainter(_faces, _originalImageSize);
  }
}

class _FaceDetectPainter extends BoxPainter {
  final List<VisionFace> _faces;
  final Size _originalImageSize;
  _FaceDetectPainter(texts, originalImageSize)
      : _faces = texts,
        _originalImageSize = originalImageSize;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final paint = new Paint()
      ..strokeWidth = 2.0
      ..color = Colors.red
      ..style = PaintingStyle.stroke;
    print("original Image Size : ${_originalImageSize}");

    final _heightRatio = _originalImageSize.height / configuration.size.height;
    final _widthRatio = _originalImageSize.width / configuration.size.width;
    for (var text in _faces) {
      print("rect : ${text.rect}");
      final _rect = Rect.fromLTRB(
          offset.dx + text.rect.left / _widthRatio,
          offset.dy + text.rect.top / _heightRatio,
          offset.dx + text.rect.right / _widthRatio,
          offset.dy + text.rect.bottom / _heightRatio);
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
