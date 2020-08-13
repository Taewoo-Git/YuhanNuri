import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
      '앱 아이디?',
      '앱 이름',
      '앱의 주소',
    );

    var iosPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iosPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0, //해당 notification의 id를 나타내며 이 id값을 통해 Notication을 취소한다.
      'Notification 제목',
      'Notification 내용',
      platformChannelSpecifics,
      payload: 'Notification Test',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: SafeArea(
            child: WebView(
              initialUrl: 'http://yuhannuri.run.goorm.io',
              javascriptMode: JavascriptMode.unrestricted,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showNotification,
          tooltip: 'Increment',
          child: Icon(Icons.access_alarms),
        ),
      ),
    );
  }
}
