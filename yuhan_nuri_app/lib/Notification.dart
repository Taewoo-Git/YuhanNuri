import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class CustomNotification {
  FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  CustomNotification() {
    var initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // 안드로이드 초기 세팅값
    var initializationSettingsIOS = IOSInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    ); // IOS 초기 세팅 값
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS); // 안드,IOS 묶음

    _flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin(); // 실제 일어날 Notification플러그인 객체 생성
    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void showNotification() async {
    // Detail에는 icon이나 push 알람이 일어났을 때의 알람소리등의 디테일 부분을 설정
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        '앱 아이디?', '앱 이름', '앱의 주소',
        importance: Importance.Max, priority: Priority.High);

    var iosPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iosPlatformChannelSpecifics);
    var scheduledNotificationDateTime =
        DateTime.now().add(Duration(seconds: 5));

    _flutterLocalNotificationsPlugin.schedule(
      0, // 해당 notification의 id를 나타내며 이 id값을 통해 Notication을 취소한다.
      'Notification 제목',
      'Notification 내용',
      scheduledNotificationDateTime,
      platformChannelSpecifics,
      payload: 'Notification Test',
    );
  }
}
