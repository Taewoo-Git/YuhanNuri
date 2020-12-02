import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Introduce.dart';
import 'YuhanNuri.dart';
import 'Login.dart';

class SplashApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
  checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // 봤는지 확인하는 변수
    bool _seen = (prefs.getBool('seen') ?? false);

    if (_seen) {
      // 봤으면 Cookie가지고 있는지 확인
      checkHavingCookie();
    } else {
      // 안 봤으면 앱 소개 스크린 실행, introduce.dart
      prefs.setBool('seen', true);
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (BuildContext context) => IntroduceScreenApp()));
    }
  }

  checkHavingCookie() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String cookieParam = (prefs.getString('cookie') ?? "NoCookie");
    String str = (prefs.getString('expires') ?? DateTime.now().toString());
    DateTime resetDay = DateTime.parse(str);

    if (!resetDay.isAfter(DateTime.now())) {
      // 지금이 초기화 지정 날짜이후이면 쿠키 만료일자와 쿠키 값 지움
      prefs.remove('expires');
      prefs.remove('cookie');
      cookieParam = "NoCookie";
    }

    // 만료일자가 지나지 않았음, cookie string 확인
    if (cookieParam != "NoCookie") {
      // cookie에 정상적인 값이 있으면 바로 webView가있는 페이지로 이동, YuhanNuri.dart
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (BuildContext context) => YuhanNuri(
                cookie: cookieParam,
              )));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => LoginApp()));
    }
  }

  @override
  void initState() {
    super.initState();
    new Timer(new Duration(milliseconds: 3000), () => {checkFirstSeen()});
  }

  splashScreen(BuildContext context) {
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
      body: splashScreen(context),
    );
  }
}
