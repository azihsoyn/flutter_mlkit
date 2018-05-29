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
  File _file = File("");
  List<VisionText> _currentLabels = List<VisionText>(0);

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
        body: _buildSuggestions(),
        //children: <Widget>[
        /*
              Image.file(_file),
              ListView.builder(
                  padding: const EdgeInsets.all(20.0),
                  itemBuilder: (context, i) {
                    return new ListTile(
                      title: new Text(_currentLabels[i]),
                    );
                  })
                  */
        //]),
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

  Widget _buildSuggestions() {
    return new ListView.builder(
        padding: const EdgeInsets.all(16.0),
        // The itemBuilder callback is called once per suggested word pairing,
        // and places each suggestion into a ListTile row.
        // For even rows, the function adds a ListTile row for the word pairing.
        // For odd rows, the function adds a Divider widget to visually
        // separate the entries. Note that the divider may be difficult
        // to see on smaller devices.
        itemBuilder: (context, i) {
          // Add a one-pixel-high divider widget before each row in theListView.
          if (i.isOdd) return new Divider();

          // The syntax "i ~/ 2" divides i by 2 and returns an integer result.
          // For example: 1, 2, 3, 4, 5 becomes 0, 1, 1, 2, 2.
          // This calculates the actual number of word pairings in the ListView,
          // minus the divider widgets.
          final index = i ~/ 2;
          // If you've reached the end of the available word pairings...
          if (index >= _currentLabels.length) {
            // ...then generate 10 more and add them to the suggestions list.
            _currentLabels.addAll(_currentLabels);
          }
          return _buildRow(_currentLabels[index].text);
        });
  }

  Widget _buildRow(String text) {
    return new ListTile(
      title: new Text(
        text,
        //style: _biggerFont,
      ),
    );
  }
}
