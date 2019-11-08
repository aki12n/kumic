import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Generated App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: ImagePage(),
      themeMode: ThemeMode.dark,
    );
  }
}

class ImagePage extends StatefulWidget {
  @override
  _ImagePageState createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  File image;
  List _images;
  double _r;
  double _g;
  double _b;

  _MyImagePageState() {
    requestPermission();
  }

  void requestPermission() async {
    await SimplePermissions.requestPermission(Permission.Camera);
    if (Platform.isAndroid &&
        !await SimplePermissions.checkPermission(
            Permission.WriteExternalStorage)) {
      await SimplePermissions.requestPermission(
          Permission.WriteExternalStorage);
    } else if (Platform.isIOS &&
        !await SimplePermissions.checkPermission(Permission.PhotoLibrary)) {
      await SimplePermissions.requestPermission(Permission.PhotoLibrary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Hoge!'),
        ),
        body: Listener(
          child: Container(
            child: CustomPaint(
              child: ConstrainedBox(
                constraints: BoxConstraints.expand(),
              ),
            ),
          ),
        ),
        floatingActionButton: image == null
            ? FloatingActionButton(
                onPressed: _getImages,
                tooltip: 'select pictures!',
                child: Icon(Icons.photo_album),
              )
            : FloatingActionButton(
                onPressed: saveImage,
                tooltip: 'save Image!',
                child: Icon(Icons.save),
              ));
  }

  void _getImages() async {
    _images = await MultiImagePicker.pickImages(
      maxImages: 10,
      enableCamera: true,
    );
    image = _images.first;
  }

  void saveImage() {}
}
