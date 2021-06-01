import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:oktoast/oktoast.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'Home.dart';
import 'Reservation.dart';
import 'Question.dart';
import 'Mypage.dart';
import 'Domain.dart';

final FirebaseMessaging fcm = FirebaseMessaging();

class YuhanNuri extends StatefulWidget {
  final String title;
  final String cookie;

  YuhanNuri({Key key, this.title, this.cookie}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    if (Platform.isWindows)
      return DummyState();
    else
      return YuhanNuriState(cookie);
  }
}

class DummyState extends State<YuhanNuri> {
  @override
  Widget build(BuildContext context) {
    return null;
  }
}

class YuhanNuriState extends State<YuhanNuri> {
  static List<String> page = ["홈", "예약", "문의", "MY"];
  String selected = page[0];

  int bodyIndex = 0;
  Widget bodyBuilder;

  Home bodyHome;
  Reservation bodyReservation;
  Question bodyQuestion;
  Mypage bodyMypage;

  bool isExit = false;

  CurvedNavigationBarState nav;
  GlobalKey globalKey = new GlobalKey();

  Map<String, String> header;

  bool isInit = true;

  YuhanNuriState(String cookie) {
    header = {
      "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      "Accept": "*/*; charset=utf-8",
      "Cookie": "$cookie"
    };
  }

  void initState() {
    super.initState();

    const initAndroidSetting =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initIosSetting = IOSInitializationSettings();
    const initSetting = InitializationSettings(
        android: initAndroidSetting, iOS: initIosSetting);
    FlutterLocalNotificationsPlugin().initialize(initSetting);

    const android = AndroidNotificationDetails(
        'channelId', 'channelName', 'channelDescription');
    const iOS = IOSNotificationDetails();
    const platform = NotificationDetails(android: android, iOS: iOS);

    var keyboardVisibilityController = KeyboardVisibilityController();

    fcm.configure(onMessage: (Map<String, dynamic> message) async {
      if (Platform.isIOS) {
        FlutterLocalNotificationsPlugin()
            .show(0, '유한누리', message['aps']['alert']['body'], platform);
        pushClick(message['page']);
      } else if (Platform.isAndroid) {
        FlutterLocalNotificationsPlugin()
            .show(0, '유한누리', message['notification']['body'], platform);
        pushClick(message['data']['page']);
      }
    }, onResume: (Map<String, dynamic> message) async {
      if (Platform.isIOS) {
        pushClick(message['page']);
      } else if (Platform.isAndroid) {
        pushClick(message['data']['page']);
      }
    }, onLaunch: (Map<String, dynamic> message) async {
      Timer(Duration(milliseconds: 1500), () {
        if (Platform.isIOS) {
          pushClick(message['page']);
        } else if (Platform.isAndroid) {
          pushClick(message['data']['page']);
        }
      });
    });

    fcm.requestNotificationPermissions(const IosNotificationSettings(
        sound: true, badge: true, alert: true, provisional: true));

    keyboardVisibilityController.onChange.listen((bool visible) {
      if (!visible &&
          bodyIndex == 1 &&
          bodyReservation != null &&
          bodyReservation.ctx != null) {
        FocusScope.of(bodyReservation.ctx).unfocus();
      }

      if (!visible &&
          bodyIndex == 2 &&
          bodyQuestion != null &&
          bodyQuestion.ctx != null) {
        FocusScope.of(bodyQuestion.ctx).unfocus();
      }
    });
  }

  Future<bool> setWidget(int idx) async {
    if (bodyMypage != null && bodyMypage.socket != null)
      bodyMypage.socket.disconnect();

    switch (idx) {
      case 0:
        bodyHome = new Home();
        bodyBuilder = await bodyHome.getBuild(header);
        break;
      case 1:
        bodyReservation = new Reservation();
        bodyBuilder = await bodyReservation.getBuild(header, globalKey);
        break;
      case 2:
        bodyQuestion = new Question();
        bodyBuilder = await bodyQuestion.getBuild(header);
        break;
      case 3:
        bodyMypage = new Mypage();
        bodyBuilder = await bodyMypage.getBuild(header, globalKey);
        break;
      default:
        break;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    syncToken(context);

    return OKToast(
      position: ToastPosition.bottom,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: WillPopScope(
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Color(0xFF0073D7),
              toolbarHeight: 50,
              title: new Text(selected,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: () {
                    logoutDialog();
                  },
                )
              ],
            ),
            body: FutureBuilder(
              future: setWidget(bodyIndex),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  return bodyBuilder;
                } else {
                  return Container(
                    child: Center(
                      child: CircularProgressIndicator(
                        backgroundColor: Colors.white,
                      ),
                    ),
                  );
                }
              },
            ),
            bottomNavigationBar: CurvedNavigationBar(
              key: globalKey,
              index: 0,
              backgroundColor: Color(0xFF0073D7),
              items: <Widget>[
                Image(
                  image: AssetImage('assets/home.png'),
                  fit: BoxFit.cover,
                  height: 30,
                ),
                Image(
                  image: AssetImage('assets/reservation.png'),
                  fit: BoxFit.cover,
                  height: 30,
                ),
                Image(
                  image: AssetImage('assets/question.png'),
                  fit: BoxFit.cover,
                  height: 30,
                ),
                Image(
                  image: AssetImage('assets/mypage.png'),
                  fit: BoxFit.cover,
                  height: 30,
                ),
              ],
              animationDuration: const Duration(milliseconds: 300),
              onTap: (int index) {
                if ((index == 0 || index == 3) && index == bodyIndex) return;
                setState(() {
                  bodyIndex = index;
                  selected = page[index];
                });
              },
              animationCurve: Curves.easeOut,
              height: 55.0,
            ),
          ),
          onWillPop: () {
            if (bodyIndex == 0) {
              if (!isExit) {
                isExit = true;
                Timer(Duration(milliseconds: 2000), () {
                  isExit = false;
                });
                showToast("뒤로 가기 버튼을 한 번 더\n누르면 앱을 종료합니다.",
                    textPadding: EdgeInsets.all(10));
                return Future.value(false);
              }
              return Future.value(true);
            }
            nav = globalKey.currentState;
            nav.setPage(0);
            return null;
          },
        ),
      ),
    );
  }

  void pushClick(String msg) async {
    if (msg == "reservation" || msg == "satisfaction") {
      nav = globalKey.currentState;
      nav.setPage(1);
    } else if (msg == "mypage") {
      nav = globalKey.currentState;
      nav.setPage(3);
    }
  }

  void removePreferences(SharedPreferences prefs) {
    prefs.remove('Token');
    prefs.remove('Cookie');
    prefs.remove('Expires');
  }

  void logoutDialog() {
    Vibration.vibrate();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("유한누리"),
          content: Text(
            "자동 로그인을 해제하고,\n로그아웃을 하시겠습니까?",
            style: TextStyle(height: 1.3),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();

                http.Client().post(
                  Uri.parse(Domain.url + 'user/get/status'),
                  headers: header,
                  body: {
                    'command': 'logout',
                    'userToken': prefs.getString('Token')
                  },
                );

                removePreferences(prefs);

                if (Platform.isAndroid)
                  SystemNavigator.pop();
                else if (Platform.isIOS) exit(0);
              },
              child: Text("예"),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFF0275D7),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text("아니오"),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFFE6E6E6),
                onPrimary: Colors.black,
              ),
            )
          ],
        );
      },
    );
  }

  void autoLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () => Phoenix.rebirth(context),
          child: AlertDialog(
            title: Text("유한누리"),
            content: Text(
              "다른 기기에서 로그인하여\n자동으로 로그아웃 되었습니다.",
              style: TextStyle(height: 1.3),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Phoenix.rebirth(context);
                },
                child: Text("확인"),
                style: ElevatedButton.styleFrom(
                  primary: Color(0xFF0275D7),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void syncToken(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    http.Response res = await http.Client().post(
      Uri.parse(Domain.url + 'user/get/status'),
      headers: header,
      body: {'command': 'login', 'userToken': prefs.getString('Token')},
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      if (res.body == "again") {
        removePreferences(prefs);
        autoLogoutDialog();
      }
    } else {
      removePreferences(prefs);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () => Phoenix.rebirth(context),
            child: AlertDialog(
              title: Text("유한누리"),
              content: Text(
                "서버 점검 중입니다.\n잠시 후 다시 시도해 주세요.",
                style: TextStyle(height: 1.3),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Phoenix.rebirth(context);
                  },
                  child: Text("확인"),
                  style: ElevatedButton.styleFrom(
                    primary: Color(0xFF0275D7),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
