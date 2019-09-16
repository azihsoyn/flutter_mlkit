import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:mlkit/mlkit.dart';

class CustomModelWidget extends StatefulWidget {
  @override
  _CustomModelWidgetState createState() => _CustomModelWidgetState();
}

class Box {
  final double top;
  final double left;
  final double bottom;
  final double right;

  Box(this.top, this.left, this.bottom, this.right);
}

class ObjectDetectionLabel {
  String label;
  double confidence;
  Box box;
  Color color;

  ObjectDetectionLabel([this.label, this.confidence, this.box]);
  ObjectDetectionLabel.box(this.box);
}

class _CustomModelWidgetState extends State<CustomModelWidget> {
  List<String> _models = ["mobilenet_quant", "mobilenet_float", "coco"];
  List<String> _localModels = ["mobilenet_quant"];

  File _file;
  int _currentModel = 0;
  List<ObjectDetectionLabel> _currentLabels = <ObjectDetectionLabel>[];

  FirebaseModelInterpreter interpreter = FirebaseModelInterpreter.instance;
  FirebaseModelManager manager = FirebaseModelManager.instance;
  Map<String, List<String>> labels = {
    "mobilenet_quant": null,
    "mobilenet_float": null,
    "coco": null,
  };

  Map<String, FirebaseModelInputOutputOptions> _ioOptions = {
    "mobilenet_quant": FirebaseModelInputOutputOptions([
      FirebaseModelIOOption(FirebaseModelDataType.BYTE, [1, 224, 224, 3])
    ], [
      FirebaseModelIOOption(FirebaseModelDataType.BYTE, [1, 1001])
    ]),
    "mobilenet_float": FirebaseModelInputOutputOptions([
      FirebaseModelIOOption(FirebaseModelDataType.FLOAT32, [1, 224, 224, 3])
    ], [
      FirebaseModelIOOption(FirebaseModelDataType.FLOAT32, [1, 1001])
    ]),
    "coco": FirebaseModelInputOutputOptions([
      FirebaseModelIOOption(FirebaseModelDataType.BYTE, [1, 300, 300, 3])
    ], [
      FirebaseModelIOOption(FirebaseModelDataType.FLOAT32, [1, 10, 4]),
      FirebaseModelIOOption(FirebaseModelDataType.FLOAT32, [1, 10]),
      FirebaseModelIOOption(FirebaseModelDataType.FLOAT32, [1, 10]),
      FirebaseModelIOOption(FirebaseModelDataType.FLOAT32, [1])
    ])
  };

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _models.forEach((model) {
      manager.registerRemoteModelSource(FirebaseRemoteModelSource(
          modelName: model,
          enableModelUpdates: true,
          initialDownloadConditions:
              FirebaseModelDownloadConditions(requireWifi: true),
          updatesDownloadConditions:
              FirebaseModelDownloadConditions(requireWifi: true)));
    });
    _localModels.forEach((model) {
      manager.registerLocalModelSource(FirebaseLocalModelSource(
          modelName: model, assetFilePath: "assets/" + model + ".tflite"));
    });

    rootBundle.loadString('assets/labels_mobilenet.txt').then((string) {
      var _l = string.split('\n');
      _l.removeLast();
      labels["mobilenet_quant"] = _l;
      labels["mobilenet_float"] = _l;
    });

    rootBundle.loadString('assets/labels_coco.txt').then((string) {
      var _l = string.split('\n');
      _l.removeLast();
      labels["coco"] = _l;
    });

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Object Detection'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            tooltip: 'Back',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            try {
              var options = _ioOptions[_models[_currentModel]];
              var dim = options.inputOptions[0].dims[1];
              // Use gallery for simulators
              var file = await ImagePicker.pickImage(
                  //source: ImageSource.camera);
                  source: ImageSource.gallery);
              setState(() {
                _file = file;
              });
              try {
                List<dynamic> results;
                var factor = 0.01;

                if (options.inputOptions[0].dataType ==
                    FirebaseModelDataType.BYTE) {
                  var bytes = await imageToByteListInt(_file, dim);
                  results = await interpreter.run(
                      localModelName: _localModels[_currentModel],
                      inputOutputOptions: options,
                      inputBytes: bytes);
                  factor = 2.55;
                } else {
                  var bytes = await imageToByteListFloat(_file, dim);
                  results = await interpreter.run(
                      localModelName: _localModels[_currentModel],
                      inputOutputOptions: options,
                      inputBytes: bytes);
                }

                print(results);

                List<ObjectDetectionLabel> currentLabels = [];
                if (_currentModel == 2) {
                  for (var i = 0; i < results[0][0].length; i++) {
                    currentLabels.add(new ObjectDetectionLabel.box(Box(
                        results[0][0][i][0],
                        results[0][0][i][1],
                        results[0][0][i][2],
                        results[0][0][i][3])));
                  }
                  for (var i = 0; i < results[1][0].length; i++) {
                    currentLabels[i].label = labels[_models[_currentModel]]
                        [results[1][0][i].round() + 1];
                  }
                  for (var i = 0; i < results[2][0].length; i++) {
                    currentLabels[i].confidence = results[2][0][i];
                  }
                } else {
                  for (var i = 0; i < results[0][0].length; i++) {
                    if (results[0][0][i] > 0) {
                      currentLabels.add(new ObjectDetectionLabel(
                          labels[_models[_currentModel]][i],
                          results[0][0][i] / factor));
                    }
                  }
                }

                currentLabels.sort((l1, l2) {
                  return (l2.confidence - l1.confidence).floor();
                });

                currentLabels.removeWhere((label) {
                  return label.confidence < 0.4;
                });

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
          child: Icon(Icons.camera),
        ),
      ),
    );
  }

  Future<Uint8List> imageToByteListInt(File file, int _inputSize) async {
    File compressedFile = await FlutterNativeImage.compressImage(file.path,
        quality: 80, targetWidth: _inputSize, targetHeight: _inputSize);
    var bytes = compressedFile.readAsBytesSync();
    var decoder = img.findDecoderForData(bytes);
    img.Image image = decoder.decodeImage(bytes);
    var convertedBytes = new Uint8List(1 * _inputSize * _inputSize * 3);
    var buffer = new ByteData.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < _inputSize; i++) {
      for (var j = 0; j < _inputSize; j++) {
        var pixel = image.getPixel(j, i);
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

  Future<Uint8List> imageToByteListFloat(File file, int _inputSize) async {
    File compressedFile = await FlutterNativeImage.compressImage(file.path,
        quality: 80, targetWidth: _inputSize, targetHeight: _inputSize);
    var bytes = compressedFile.readAsBytesSync();
    var decoder = img.findDecoderForData(bytes);
    img.Image image = decoder.decodeImage(bytes);
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

  Widget _buildImage() {
    return SizedBox(
      height: 500.0,
      child: Center(
        child: _file == null
            ? Text('No Image')
            : FutureBuilder<Size>(
                future: _getImageSize(Image.file(_file, fit: BoxFit.fitWidth)),
                builder: (BuildContext context, AsyncSnapshot<Size> snapshot) {
                  if (snapshot.hasData) {
                    return Container(
                        foregroundDecoration:
                            TextDetectDecoration(_currentLabels, snapshot.data),
                        child: Image.file(_file, fit: BoxFit.fitWidth));
                  } else {
                    return Text('Detecting...');
                  }
                },
              ),
      ),
    );
  }

  Future<Size> _getImageSize(Image image) {
    Completer<Size> completer = Completer<Size>();
    image.image
        .resolve(ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, _) {
      completer.complete(
          Size(info.image.width.toDouble(), info.image.height.toDouble()));
    }));
    return completer.future;
  }

  Widget _buildBody() {
    return Container(
      child: Column(
        children: <Widget>[
          _buildImage(),
          _buildList(_currentLabels),
        ],
      ),
    );
  }

  Widget _buildList(List<ObjectDetectionLabel> texts) {
    if (texts.length == 0) {
      return Text('Empty');
    }
    return Expanded(
      child: Container(
        child: ListView.builder(
            padding: const EdgeInsets.all(1.0),
            itemCount: texts.length,
            itemBuilder: (context, i) {
              return _buildRow(
                  texts[i].label, texts[i].confidence, texts[i].color);
            }),
      ),
    );
  }

  Widget _buildRow(String text, double confidence, Color color) {
    return ListTile(
      title: Text(
        "Text: ${text}, Confidence: ${confidence}",
      ),
      dense: true,
    );
  }
}

class TextDetectDecoration extends Decoration {
  final Size _originalImageSize;
  final List<ObjectDetectionLabel> _texts;
  TextDetectDecoration(List<ObjectDetectionLabel> texts, Size originalImageSize)
      : _texts = texts,
        _originalImageSize = originalImageSize;

  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    return _TextDetectPainter(_texts, _originalImageSize);
  }
}

class _TextDetectPainter extends BoxPainter {
  final List<ObjectDetectionLabel> _texts;
  final Size _originalImageSize;
  _TextDetectPainter(texts, originalImageSize)
      : _texts = texts,
        _originalImageSize = originalImageSize;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    var paint = Paint()
      ..strokeWidth = 1.0
      ..color = Colors.red
      ..style = PaintingStyle.stroke;
    print("original Image Size : ${_originalImageSize}");

    var c = 0;
    var i = 900;
    Color color;

    for (var text in _texts) {
      var c1 = c % 3;
      switch (c1) {
        case 0:
          color = Colors.red[i];
          break;
        case 1:
          color = Colors.green[i];
          break;
        case 2:
          color = Colors.blue[i];
          i -= 200;
          if (i < 0) {
            i = 900;
          }
          break;
        default:
      }
      text.color = color;

      TextSpan span =
          new TextSpan(text: text.label, style: TextStyle(color: color));
      TextPainter tp = new TextPainter(
          text: span,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr);
      tp.layout();
      print("text : ${text.label}, rect : ${text.box}");
      final _rect = Rect.fromLTRB(
          offset.dx + text.box.left * configuration.size.width,
          offset.dy + text.box.top * configuration.size.height,
          offset.dx + text.box.right * configuration.size.width,
          offset.dy + text.box.bottom * configuration.size.height);
      //final _rect = Rect.fromLTRB(24.0, 115.0, 75.0, 131.2);
      paint.color = color;
      canvas.drawRect(_rect, paint);
      tp.paint(canvas, _rect.topCenter);
      c++;
    }

    print("offset : ${offset}");
    print("configuration : ${configuration}");

    final rect = offset & configuration.size;

    print("rect container : ${rect}");

    //canvas.drawRect(rect, paint);
    canvas.restore();
  }
}
