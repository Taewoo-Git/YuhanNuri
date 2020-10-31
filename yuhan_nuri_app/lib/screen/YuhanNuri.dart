import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:toast/toast.dart';

<<<<<<< HEAD
=======
final FirebaseMessaging fcm = FirebaseMessaging();
CookieManager cm;
//CurvedNavigationBarState navBarState;
>>>>>>> f2705088c1eac9fa6986962ffde95a84021af2c2

class YuhanNuri extends StatefulWidget {
  final String cookie;
  YuhanNuri({Key key, this.title, this.cookie}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() {
    if (Platform.isWindows)
      return _DummyState();
    else
      return YuhanNuriState(cookie);
  }
}

class _DummyState extends State<YuhanNuri> {
  @override
  Widget build(BuildContext context) {
    return null;
  }
}

class YuhanNuriState extends State<YuhanNuri> {
  InAppWebViewController _webViewController;
  DateTime currentBackPressTime;
  Map<String, String> header; // 전달받은 Cookie객체를 string과 합쳐서 header만듦
  GlobalKey globalKey = new GlobalKey(); //네비게이션 바 외부에서 접근가능하게 해줄 Key변수
<<<<<<< HEAD
  CookieManager cm;
=======
  CurvedNavigationBarState navBarState;
  bool abc = false;
  final FirebaseMessaging fcm = FirebaseMessaging();
>>>>>>> f2705088c1eac9fa6986962ffde95a84021af2c2

  YuhanNuriState(String cookieParam) {
    header = {'Cookie': '$cookieParam'};
    
  }

  void initState() {
    super.initState();
<<<<<<< HEAD
=======

    fcm.configure(onMessage: (Map<String, dynamic> message) async {
      print("onMessage: $message");
      print(message['data']['fileno']);
    }, onResume: (Map<String, dynamic> message) async {
      print("onResume: $message");
      print(message['data']['fileno']);
    }, onLaunch: (Map<String, dynamic> message) async {
      print("onLaunch: $message"); //
      print(message['data']['fileno']);
    });

>>>>>>> f2705088c1eac9fa6986962ffde95a84021af2c2
    cm = new CookieManager();
  }

  // static Future<void> onBackgroundMessage(Map<String, dynamic> message) async {
  //   if (message.containsKey('data')) {
  //     //final dynamic data = message['data'];
  //     CustomNotification test = new CustomNotification();
  //     test.showNotification(5);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: WillPopScope(
            child: Scaffold(
              body: Center(
                  child: SafeArea(
                      child: InAppWebView(
                initialOptions: InAppWebViewGroupOptions(
                    crossPlatform: InAppWebViewOptions(
                  debuggingEnabled: true,
                )),
                onWebViewCreated: (InAppWebViewController controller) async{
                  
                  _webViewController = controller;
                  // url로드전에 cookie 지워주지 않으면 cookie 안먹는 경우 있음

                  cm.deleteAllCookies();
                  print( "//////////print header in Yuhannuri before loadUrl////////"+header.toString()+ "//////");
                  _webViewController.loadUrl(
                      url: 'https://yuhannuri.run.goorm.io', headers: header);

                  KeyboardVisibility.onChange.listen((bool visible) async {
                    if (visible) {
<<<<<<< HEAD
                      //print( "//////////////////////////////////////"+await fcm.getToken() + "//////"+header.toString());
                      // if (await _webViewController.getUrl() !=
                      //     "https://yuhannuri.run.goorm.io/chat") {
                      //   await _webViewController.evaluateJavascript(
                      //       source:
                      //           'document.activeElement.scrollIntoView( {block: "center"})');
                      // } else {
                      //   int viewHeight = int.parse(
                      //       await _webViewController.evaluateJavascript(
                      //           source:
                      //               "parseInt(document.activeElement.getBoundingClientRect().y)"));
                      //   _webViewController.scrollTo(x: 0, y: viewHeight);
                      // }
                      // if (await _webViewController.getUrl() ==
                      //     "https://yuhannuri.run.goorm.io/user/application") {
                      //   print(
                      //       '여기는 application @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@2');
                      //   await _webViewController.evaluateJavascript(
                      //       source:
                      //           'document.activeElement.scrollIntoView( {block: "center"})');
                      // }
=======
                      sleep(const Duration(milliseconds: 250));
                      if (await _webViewController.getUrl() ==
                          'https://yuhannuri.run.goorm.io/user/mypage') {
                        await _webViewController.evaluateJavascript(
                            source:
                                'document.activeElement.scrollIntoView( {block: "center"})');
                      } else {
                        await _webViewController.evaluateJavascript(
                            source:
                                'document.activeElement.scrollIntoView( {block: "center"})');
                      }
>>>>>>> f2705088c1eac9fa6986962ffde95a84021af2c2
                    } else {
                      await _webViewController.evaluateJavascript(
                          source: 'document.activeElement.blur()');
                    }
                  });
                },
              ))),
              bottomNavigationBar: CurvedNavigationBar(
                key: globalKey,
                index: 0,
                backgroundColor: Colors.blueAccent,
                items: <Widget>[
                  Icon(Icons.home, size: 25),
                  Icon(Icons.insert_invitation, size: 25),
                  Icon(Icons.headset_mic, size: 25),
                  Icon(Icons.person, size: 25),
                ],
                animationDuration:
                    const Duration(milliseconds: 300), // trainsition 설정
                onTap: (int index) {
                  int navigationIndex = index;
                  switch (navigationIndex) {
                    case 0:
<<<<<<< HEAD
                    cm.deleteAllCookies();
                    print( "/////////case0///////case0///////////"+header.toString());
=======
                      cm.deleteAllCookies();
>>>>>>> f2705088c1eac9fa6986962ffde95a84021af2c2
                      _webViewController.loadUrl(
                          url: 'https://yuhannuri.run.goorm.io', headers: header);
                      break;
                    case 1:
                      cm.deleteAllCookies();
<<<<<<< HEAD
                      print( "/////////case1///////case1///////////"+header.toString());
                      _webViewController.loadUrl(
                        url: 'https://yuhannuri.run.goorm.io/fcm', headers: header
                      );
                      break;
                    case 2:
                      cm.deleteAllCookies();
                      // _webViewController.loadUrl(
                      //     url: 'https://yuhannuri.run.goorm.io/user/fcmEx/' +
                              
=======
                      _webViewController.loadUrl(url: 'https://google.com');
                      break;
                    case 2:
                      cm.deleteAllCookies();
                      _webViewController.loadUrl(
                          url: 'https://yuhannuri.run.goorm.io/user/fcmEx/' +
                              fcm.getToken().toString());
>>>>>>> f2705088c1eac9fa6986962ffde95a84021af2c2
                      break;
                    case 3:
                      cm.deleteAllCookies();
                      _webViewController.loadUrl(
                          url: 'https://waveon.run.goorm.io');
                      break;
                    default:
                      break;
                  }
                },
                animationCurve: Curves.easeOut, // transition-animation 설정
                height: 55.0, // 높이
              ),
              resizeToAvoidBottomInset: true,
              // resizeToAvoidBottomInset = true;
            ),
            onWillPop: () async {
              if (await _webViewController.getUrl() ==
                  "https://yuhannuri.run.goorm.io/") {
                DateTime now = DateTime.now();
                if (currentBackPressTime == null ||
                    now.difference(currentBackPressTime) >
                        Duration(seconds: 2)) {
                  // 전에 back 버튼을 누른적이 없거나
                  // back 버튼을 눌렀을때의 시간과 전에 back버튼을 눌렀을때의 차이가 2초를 넘었으면
                  currentBackPressTime = now;
                  Toast.show('뒤로가기 버튼을 한번 더 클릭하면 종료합니다.', context,
                      duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
                  return Future.value(false); // 종료 안함.
                }
                return Future.value(true); // if문이 거짓일때는 바로 종료
              }
              abc = await _webViewController.evaluateJavascript(
                  source: //'let obj = document.getElementById("chattingCard");' +
                      'if(document.getElementById("chattingCard") != null) true;' +
                          'else false;');
              print(abc);
              print(await fcm.getToken());
              if (abc) {
                showBackButtonDialog(context);
              } else {
                navBarState = globalKey.currentState;
                navBarState.setPage(0);
              }
              return null;
            }));
  }

  showBackButtonDialog(BuildContext context) {
    Widget continueButton = FlatButton(
      child: Text("예"),
      onPressed: () {
        Navigator.of(context).pop();

        navBarState = globalKey.currentState;
        navBarState.setPage(0);
      },
    );

    Widget cancelButton = FlatButton(
      child: Text("아니오"),
      onPressed: () async {
        //  Navigator.of(context).pop();
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("유한누리"),
      content: Text("메인화면으로 돌아가시겠습니까?"),
      actions: [
        continueButton,
        cancelButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
