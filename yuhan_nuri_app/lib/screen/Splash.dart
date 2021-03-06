import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Login.dart';
import 'YuhanNuri.dart';
import 'Introduce.dart';

class SplashApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Color.fromARGB(255, 0, 115, 215)));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Splash(),
    );
  }
}

class Splash extends StatefulWidget {
  @override
  SplashState createState() => SplashState();
}

class SplashState extends State<Splash> {
  void initSetting(SharedPreferences prefs) {
    String cookie = prefs.getString('Cookie') ?? "";
    DateTime expires = prefs.getString('Expires') == null
        ? DateTime.now().subtract(new Duration(days: 1))
        : DateTime.parse(prefs.getString('Expires'));

    if (!expires.isAfter(DateTime.now())) {
      prefs.remove('Token');
      prefs.remove('Cookie');
      prefs.remove('Expires');

      cookie = "";
    }

    if (cookie.isEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (BuildContext context) => LoginApp(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (BuildContext context) => YuhanNuri(
            cookie: cookie,
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    new Timer(new Duration(milliseconds: 2000), () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isFirst = prefs.getBool('intro') ?? true;

      if (isFirst) {
        prefs.setBool('intro', false);
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (BuildContext context) => IntroduceApp()));
      } else {
        initSetting(prefs);
      }
    });
  }

  Widget buildSplash(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              child: new Image(
                image: AssetImage("assets/logo.png"),
              ),
              padding: EdgeInsets.only(bottom: 10.0, left: 90.0, right: 90.0),
            ),
            Container(
              child: new Image(
                image: AssetImage("assets/nuri.png"),
              ),
              padding: EdgeInsets.only(
                  top: 10.0, bottom: 50.0, left: 70.0, right: 70.0),
            ),
            Padding(padding: EdgeInsets.only(top: 30.0)),
            CircularProgressIndicator(
              backgroundColor: Color(0xFFFFFFFF),
              strokeWidth: 3,
            )
          ],
        ),
      ),
      backgroundColor: Color(0xFF0275D7),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildSplash(context),
    );
  }
}
