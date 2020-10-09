import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_screenshots/flutter_native_screenshots.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //是否有图片
  bool _image = false;

  //截图数据
  Uint8List _image8List;

  @override
  void initState() {
    //监测截屏
    _listeningIosEndScreenshots();
    super.initState();
  }

  ///监测截屏
  void _listeningIosEndScreenshots() {
    FlutterNativeScreenshots.listeningNativeScreenshots((Uint8List endResult) {
      _image = true;
      _image8List = endResult;
      setState(() {});
    });
  }

  ///获取截屏
  Future<void> _getIosStartScreenshots() async {
    try {
      _image8List = await FlutterNativeScreenshots.initiateNativeScreenshots;
      _image = true;
    } on PlatformException {
      _image8List = null;
      _image = false;
    }
    if (!mounted) return;
    setState(() {});
  }

  ///build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("iOS原生截屏"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            OutlineButton(
              //发起截屏
              onPressed: _getIosStartScreenshots,
              child: Text("发起截屏"),
            ),
            Expanded(
              child: _image
                  ? Image.memory(
                      _image8List,
                      fit: BoxFit.cover,
                    )
                  : Container(),
            ),
          ],
        ),
      ),
    );
  }
}
