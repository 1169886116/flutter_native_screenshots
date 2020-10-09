import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

///平台信道
final MethodChannel _channel =
    const MethodChannel('flutter_native_screenshots');

///监测截屏回调
typedef resultCallBack = Function(Uint8List result);

///类
class FlutterNativeScreenshots {
  ///监测原生截屏
  static listeningNativeScreenshots(resultCallBack endResultCall) {
    _channel.setMethodCallHandler((call) {
      if (call.method == "listeningNativeScreenshots") {
        Map map = call.arguments;
        Uint8List result = map["image"];
        endResultCall(result);
      }
      return null;
    });
  }

  ///发起原生截屏
  static Future<Uint8List> get initiateNativeScreenshots async {
    final Uint8List startResult =
        await _channel.invokeMethod('initiateNativeScreenshots');
    return startResult;
  }
}
