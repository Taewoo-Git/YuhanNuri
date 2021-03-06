import 'dart:io';
import 'package:flutter/material.dart';
import 'package:yuhan_nuri_app/screen/Splash.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Platform.isAndroid || Platform.isIOS)
      runApp(Phoenix(child: SplashApp()));
  } catch (e) {
    runApp(DummyApp());
  }
}

class DummyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(body: Text("")));
  }
}
