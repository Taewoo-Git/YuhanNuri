import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splashscreen/splashscreen.dart';
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
  // 앱이 처음 실행되는지 체크
  checkFirstSeen() async {
    // 간단한 값을 어플리케이션에 파일 형태로 저장하는 클래스
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
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (BuildContext context) => LoginApp()));
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new SplashScreen(
      seconds: 0,
      // seconds이후에 실행할 액션, seconds가 0인 이유는 checkFirstSeen()이 비동기로 실행되기 때문에 0으로 설정해둠
      navigateAfterSeconds:
          new Timer(new Duration(milliseconds: 3000), () => {checkFirstSeen()}),
      title: new Text(
        'YUHAN NURI',
        style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 35.0),
      ),
      image: new Image(
        image: AssetImage("assets/logo.png"),
      ),
      backgroundColor: Colors.white,
      styleTextUnderTheLoader: new TextStyle(),
      photoSize: 100.0,
      //onClick: () => print("Flutter"),
      loaderColor: Colors.lightBlue,
    );
  }
}
