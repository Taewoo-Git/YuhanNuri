import 'dart:io';
import 'package:flutter/material.dart';
import 'package:yuhan_nuri_app/screen/Splash.dart';

void main() {
  try {
    //처음 loading화면 실행, Splash.dart
    if (Platform.isAndroid || Platform.isIOS) runApp(SplashApp());
  } catch (e) {
    runApp(DummyApp());
  }
}

class DummyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(body: Text('')));
  }
}
