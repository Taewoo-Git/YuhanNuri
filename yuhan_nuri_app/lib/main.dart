import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:http/http.dart' as http;
import 'package:toast/toast.dart';

String userID = "";
String userPassword = "";
bool isAutoLogin = false;

String myCookie = "";

SharedPreferences _prefs;
String saveCookie = "";
String saveTime = "";
bool isSaveAutoLogin = false;

void main() {
  try {
    if (Platform.isAndroid || Platform.isIOS) runApp(LoginApp());
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

class MainApp extends StatelessWidget {
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
  WebViewController _webviewController; //webviewController 정의
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

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
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          body: Center(
            child: SafeArea(
              child: WebView(
                initialUrl: 'https://yuhannuri.run.goorm.io',
                javascriptMode: JavascriptMode.unrestricted,
                onWebViewCreated: (WebViewController webviewController) {
                  _webviewController = webviewController;
                  _controller
                      .complete(_webviewController); //webviewController 생성

                  print("CCCCCCCCCCCCCookie : " + myCookie);
                },
                onPageFinished: (_) {
                  _webviewController
                      .evaluateJavascript('document.cookie = $myCookie;');

                  KeyboardVisibility.onChange.listen((bool visible) async {
                    if (visible) {
                      int viewHeight = int.parse(
                          await _webviewController.evaluateJavascript(
                              "parseInt(document.activeElement.getBoundingClientRect().y)"));
                      _webviewController.scrollTo(0, viewHeight);
                    }
                  });
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
                    switch (index) {
                      //icon의 순서에 따라 index에 해당하는 url을 요청
                      case 0:
                        controller.data
                            .loadUrl('https://yuhannuri.run.goorm.io');
                        break;
                      case 1:
                        controller.data.loadUrl('https://google.com');
                        break;
                      default:
                        break;
                    }
                  },
                  animationCurve: Curves.easeOut, //transition-animation 설정
                  height: 55.0, //높이
                );
              }
              return CurvedNavigationBar(
                //가지고 있는 데이터가 없을 경우 네비게이션 바를 그대로 줌
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

//Flutter Login Layout Class
class LoginApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YuhanNuri',
      home: Login(title: 'YuhanNuri Login'),
    );
  }
}

class Login extends StatefulWidget {
  Login({this.title});
  final String title;
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  Widget _buildLayoutContainer(BuildContext context) {
    return SingleChildScrollView(
      child: _buildFormWrapper(context),
    );
  }

  Widget _buildFormWrapper(BuildContext context) {
    return Form(
      child: _buildLoginLayout(context),
    );
  }

  void initState() {
    super.initState();
    autoLogin();
  }

  Widget _buildLoginLayout(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 150, left: 20, right: 20), //상, 좌, 우 여백
      child: Column(
        children: <Widget>[
          _userIDTextField(context),
          SizedBox(
            height: 20,
          ), // 위젯들 사이의 여백
          _userPasswordTextField(context),
          SizedBox(
            height: 20,
          ),
          _buildSubmitButton(context),
          SizedBox(
            height: 10,
          ),
          _autoLoginCheckBox(context),
        ],
      ),
    );
  }

  Widget _userIDTextField(BuildContext context) {
    return TextFormField(
        onChanged: (value) => userID = value,
        decoration: InputDecoration(
          labelText: 'Enter ID',
          filled: true,
          fillColor: Colors.white,
        ));
  }

  Widget _userPasswordTextField(BuildContext context) {
    return TextFormField(
      onChanged: (value) => userPassword = value,
      obscureText: true, //Text 암호화 표시
      decoration: InputDecoration(
        labelText: 'Enter Password',
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _autoLoginCheckBox(BuildContext context) {
    return CheckboxListTile(
      controlAffinity: ListTileControlAffinity.leading,
      title: Text('자동 로그인'),
      value: isAutoLogin,
      onChanged: (bool newValue) {
        setState(() {
          isAutoLogin = newValue;
        });
      },
      contentPadding: const EdgeInsets.only(left: 0.00),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return ButtonTheme(
      minWidth: double.infinity,
      child: RaisedButton(
        child: Text(
          "Login",
        ),
        onPressed: () {
          //로그인 버튼 눌렀을 때 실행 될 내용
          portalLogin(userID, userPassword, isAutoLogin);
        },
      ),
    );
  }

  portalLogin(String userID, String userPassword, bool isAutoLogin) async {
    print(
        'userID: $userID, userPassword: $userPassword, autoLogin: $isAutoLogin');

    http.Response res = await http.Client().post(
      Uri.parse('https://yuhannuri.run.goorm.io/user/mobile'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'Accept': 'application/json; charset=utf-8',
      },
      body: {
        'userId': userID.trim(),
        'password': userPassword.trim(),
        'isAutoLogin': isAutoLogin.toString(),
      },
    );

    if (res.statusCode == 200) {
      Map<String, dynamic> stuInfo = jsonDecode(res.body);
      if (stuInfo == null) {
        Toast.show('아이디와 패스워드를 확인하세요.', context,
            duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
      } else {
        print(stuInfo);
        myCookie = res.headers['set-cookie'];
        if (isAutoLogin && !isSaveAutoLogin) {
          setTime();
          setisSaveAutoLogin();
        }
        setCookie(myCookie);
        runApp(MainApp());
      }
    } else {
      throw Exception();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildLayoutContainer(context),
    );
  }
}

void setCookie(String myCookie) async {
  _prefs = await SharedPreferences.getInstance();
  await _prefs.setString('saveCookie', myCookie);
}

Future<String> getCookie() async {
  _prefs = await SharedPreferences.getInstance();
  return _prefs.getString('saveCookie') ?? "No Cookie";
}

void setTime() async {
  _prefs = await SharedPreferences.getInstance();
  await _prefs.setString(
      'saveTime', DateTime.now().add(Duration(days: 30)).toIso8601String());
}

Future<String> getTime() async {
  _prefs = await SharedPreferences.getInstance();
  return _prefs.getString('saveTime') ?? "No Date";
}

void setisSaveAutoLogin() async {
  _prefs = await SharedPreferences.getInstance();
  await _prefs.setBool('saveisAutoLogin', true);
}

Future<bool> getisSaveAutoLogin() async {
  _prefs = await SharedPreferences.getInstance();
  return _prefs.getBool('saveisAutoLogin') ?? false;
}

void autoLogin() async {
  saveCookie = await getCookie();
  saveTime = await getTime();
  isSaveAutoLogin = await getisSaveAutoLogin();
  if (saveTime != "No Date") {
    DateTime dateTime = DateTime.parse(saveTime);
    Duration timeDifference = DateTime.now().difference(dateTime);
    print(timeDifference);
    if (timeDifference.inSeconds >= 0) {
      // 자동로그인 처음 시작한지 30일 지났을 때 관련 데이터 삭제
      _prefs.clear();
      // 이후에 처리할 내용
      print("직접 로그인 Case 1 한달 기간 만료");
    } else {
      print("자동 로그인");
    }
  } else {
    print("직접 로그인 Case 2 isSaveAutoLogin false 값");
  }
}
