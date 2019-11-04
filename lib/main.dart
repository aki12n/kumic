import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Generated App',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        primaryColor: const Color(0xFFfcd6f6),
        accentColor: const Color(0xFF97c9c6),
        canvasColor: const Color(0xFFfdf1be),
      ),
      home: MyImagePage(),
    );
  }
}

class MyImagePage extends StatefulWidget {
  @override
  _MyImagePageState createState() => _MyImagePageState();
}

class _MyImagePageState extends State<MyImagePage> {
  File image;
  GlobalKey _homeStateKey = GlobalKey();
  List<List<Offset>> strokes = new List<List<Offset>>();
  MyPainter _painter;
  ui.Image targetimage;
  Size mediasize;
  double _r = 255.0;
  double _g = 0.0;
  double _b = 0.0;

  _MyImagePageState() {
    requestPermission();
  }

  void requestPermission() async {
    await SimplePermissions.requestPermission(Permission.Camera);
    // await SimplePermissions.requestPermission(Permission.ReadExternalStorage);
    // await SimplePermissions.requestPermission(Permission.WriteExternalStorage);
    if (Platform.isAndroid && !await SimplePermissions.checkPermission(Permission.WriteExternalStorage)) {
      await SimplePermissions.requestPermission(Permission.WriteExternalStorage);
    } else if (Platform.isIOS && !await SimplePermissions.checkPermission(Permission.PhotoLibrary)) {
      await SimplePermissions.requestPermission(Permission.PhotoLibrary);
    }
  }

  @override
  Widget build(BuildContext context) {
    mediasize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Canture Image Drawing!'),
      ),
      body: Listener(
        child: Container(
          child: CustomPaint(
            key: _homeStateKey,
            painter: _painter,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(),
            ),
          ),
        ),
      ),
      floatingActionButton: image == null
          ? FloatingActionButton(
              onPressed: getImage,
              tooltip: 'take a picture!',
              child: Icon(Icons.add_a_photo),
            )
          : FloatingActionButton(
              onPressed: saveImage,
              tooltip: 'save Image',
              child: Icon(Icons.save),
            ),
      drawer: Drawer(
        child: Center(
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Text('Set Color...'),
              ),
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Slider(
                  min: 0.0,
                  max: 255.0,
                  value: _r,
                  onChanged: sliderR,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Slider(
                  min: 0.0,
                  max: 255.0,
                  value: _g,
                  onChanged: sliderG,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Slider(
                  min: 0.0,
                  max: 255.0,
                  value: _b,
                  onChanged: sliderB,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // スライダーの値設定
  void sliderR(double value) {
    setState(() => _r = value);
  }

  void sliderG(double value) {
    setState(() => _g = value);
  }

  void sliderB(double value) {
    setState(() => _b = value);
  }

  // MyPainterの作成
  void createMyPainter() {
    var strokecolor = Color.fromARGB(200, _r.toInt(), _g.toInt(), _b.toInt());
    _painter = MyPainter(targetimage, image, strokes, mediasize, strokecolor);
  }

  // カメラ起動、イメージ読み込み
  void getImage() async {
    File file = await ImagePicker.pickImage(source: ImageSource.camera);
    image = file;
    loadImage(image.path);
  }

  // イメージ保存
  void saveImage() {
    _painter.seveImage();
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: Text("Saved!"),
              content: Text("Save image to file."),
            ));
  }

  // パスからイメージを読み込みui.Imageを作成する
  void loadImage(path) async {
    List<int> byts = await image.readAsBytes();
    Uint8List u8lst = Uint8List.fromList(byts);
    ui.instantiateImageCodec(u8lst).then((codec) {
      codec.getNextFrame().then((frameInfo) {
        targetimage = frameInfo.image;
        setState(() {
          createMyPainter();
        });
      });
    });
  }
}

class MyPainter extends CustomPainter {
  File image;
  ui.Image targetimage;
  Size mediasize;
  Color strokecolor;
  var strokes = new List<List<Offset>>();

  MyPainter(this.targetimage, this.image, this.strokes, this.mediasize,
      this.strokecolor);

  @override
  void paint(Canvas canvas, Size size) async {
    mediasize = size;
    ui.Image im = await drawToCanvas();
    canvas.drawImage(im, Offset(0.0, 0.0), Paint());
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  // 描画イメージをファイルに保存
  void seveImage() async {
    ui.Image img = await drawToCanvas();
    final ByteData bytedata =
        await img.toByteData(format: ui.ImageByteFormat.png);
    int epoch = new DateTime.now().millisecondsSinceEpoch;
    final file = new File(image.parent.path + '/' + epoch.toString() + '.png');
    file.writeAsBytes(bytedata.buffer.asUint8List());
  }

  // イメージを描画したui.Imageを返す
  Future<ui.Image> drawToCanvas(){
    ui.PictureRecorder recorder = ui.PictureRecorder();
    ui.Canvas canvas = Canvas(recorder);

    Paint p1 = Paint();
    p1.color = Colors.white;
    canvas.drawColor(Colors.white, BlendMode.color);

    if (targetimage != null) {
      Rect r1 = Rect.fromPoints(Offset(0.0, 0.0),
          Offset(targetimage.width.toDouble(), targetimage.height.toDouble()));
      Rect r2 = Rect.fromPoints(Offset(0.0, 0.0),
          Offset(mediasize.width.toDouble(), mediasize.height.toDouble()));
      canvas.drawImageRect(targetimage, r1, r2, p1);
    }

    Paint p2 = new Paint();
    p2.color = strokecolor;
    p2.style = PaintingStyle.stroke;
    p2.strokeWidth = 5.0;

    for (var stroke in strokes) {
      Path strokePath = new Path();
      strokePath.addPolygon(stroke, false);
      canvas.drawPath(strokePath, p2);
    }
    ui.Picture picture = recorder.endRecording();
    return picture.toImage(mediasize.width.toInt(), mediasize.height.toInt());
  }
}
