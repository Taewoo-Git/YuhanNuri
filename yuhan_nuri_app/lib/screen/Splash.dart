import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Introduce.dart';
import 'YuhanNuri.dart';
import 'Login.dart';

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
  checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool _seen = (prefs.getBool('seen') ?? false);

    if (_seen) {
      checkHavingCookie();
    } else {
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
      prefs.remove('expires');
      prefs.remove('cookie');
      cookieParam = "NoCookie";
    }

    if (cookieParam != "NoCookie") {
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
