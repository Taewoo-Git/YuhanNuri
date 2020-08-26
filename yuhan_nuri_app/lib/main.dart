import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

void main() {
  try {
    if (Platform.isAndroid || Platform.isIOS) runApp(MyApp());
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

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Notification(title: 'YuhanNuri');
  }
}

class Notification extends StatefulWidget {
  Notification({Key key, this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() {
    if (Platform.isWindows)
      return _DummyState();
    else
      return _NotificationState();
  }
}

class _DummyState extends State<Notification> {
  @override
  Widget build(BuildContext context) {
    return null;
  }
}

class _NotificationState extends State<Notification> {
  FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final Completer<WebViewController> _controller =
      Completer<WebViewController>(); //webviewController 정의

  void initState() {
    super.initState();

    var initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); //안드로이드 초기 세팅값
    var initializationSettingsIOS = IOSInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    ); //IOS 초기 세팅 값
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS); //안드,IOS 묶음

    _flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin(); //실제 일어날 Notification플러그인 객체 생성
    _flutterLocalNotificationsPlugin
        .initialize(initializationSettings); //세팅 값 설정
  }

  Future _showNotification() async {
    //Detail에는 icon이나 push 알람이 일어났을 때의 알람소리등의 디테일 부분을 설정
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        '앱 아이디?', '앱 이름', '앱의 주소',
        importance: Importance.Max, priority: Priority.High);

    var iosPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iosPlatformChannelSpecifics);
    var scheduledNotificationDateTime =
        DateTime.now().add(Duration(seconds: 5));

    await _flutterLocalNotificationsPlugin.schedule(
      0, //해당 notification의 id를 나타내며 이 id값을 통해 Notication을 취소한다.
      'Notification 제목',
      'Notification 내용',
      scheduledNotificationDateTime,
      platformChannelSpecifics,
      payload: 'Notification Test',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          body: Center(
            child: SafeArea(
              child: WebView(
                initialUrl: 'https://yuhannuri.run.goorm.io',
                javascriptMode: JavascriptMode.unrestricted,
                onWebViewCreated: (WebViewController webviewController) {
                  _controller.complete(webviewController); //webviewController 생성
                },
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showNotification,
            tooltip: 'Increment',
            child: Icon(Icons.access_alarms),
          ),
          bottomNavigationBar: FutureBuilder<WebViewController>(
            future: _controller.future,
            builder: (BuildContext context,
                AsyncSnapshot<WebViewController> controller) {
              if (controller.hasData) {
                return CurvedNavigationBar(
                  backgroundColor: Colors.blueAccent,
                  items: <Widget>[
                    Icon(Icons.add, size: 25),
                    Icon(Icons.list, size: 25),
                    Icon(Icons.person, size: 25),
                    Icon(Icons.chat_bubble, size: 25),
                  ],
                  animationDuration:
                      const Duration(milliseconds: 300), //trainsition 설정
                  onTap: (index) {
                    switch (index) { //icon의 순서에 따라 index에 해당하는 url을 요청
                      case 0:
                        controller.data
                            .loadUrl('https://yuhannuri.run.goorm.io');
                        break;
                      case 1:
                        controller.data.loadUrl('https://youtube.com');
                        break;
                      default:
                        break;
                    }
                  },
                  animationCurve: Curves.easeOut, //transition-animation 설정
                  height: 55.0, //높이
                );
              }
              return CurvedNavigationBar( //가지고 있는 데이터가 없을 경우 네비게이션 바를 그대로 줌
                backgroundColor: Colors.blueAccent,
                items: <Widget>[
                  Icon(Icons.add, size: 25),
                  Icon(Icons.list, size: 25),
                  Icon(Icons.person, size: 25),
                  Icon(Icons.chat_bubble, size: 25),
                ],
                animationDuration:
                    const Duration(milliseconds: 300), //trainsition 설정
                onTap: (index) {
                  print(index);
                },
                animationCurve: Curves.easeOut, //transition-animation 설정
                height: 55.0, //높이
              );
            },
          )),
    );
  }
}
