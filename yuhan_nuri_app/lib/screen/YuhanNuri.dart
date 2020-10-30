import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:toast/toast.dart';

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

  YuhanNuriState(String cookieParam) {
    header = {'Cookie': '$cookieParam'};
  }

  void initState() {
    super.initState();
  }

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
                onWebViewCreated: (InAppWebViewController controller) {
                  _webViewController = controller;
                  // url로드전에 cookie 지워주지 않으면 cookie 안먹는 경우 있음
                  CookieManager cm = new CookieManager();
                  cm.deleteAllCookies();
                  _webViewController.loadUrl(
                      url: 'https://yuhannuri.run.goorm.io', headers: header);

                  KeyboardVisibility.onChange.listen((bool visible) async {
                    if (visible) {
                      print(await fcm.getToken());
                      if (await _webViewController.getUrl() !=
                          "https://yuhannuri.run.goorm.io/chat") {
                        await _webViewController.evaluateJavascript(
                            source:
                                'document.activeElement.scrollIntoView( {block: "center"})');
                      } else {
                        int viewHeight = int.parse(
                            await _webViewController.evaluateJavascript(
                                source:
                                    "parseInt(document.activeElement.getBoundingClientRect().y)"));
                        _webViewController.scrollTo(x: 0, y: viewHeight);
                      }
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
                  Icon(Icons.add, size: 25),
                  Icon(Icons.list, size: 25),
                  Icon(Icons.person, size: 25),
                  Icon(Icons.chat_bubble, size: 25),
                ],
                animationDuration:
                    const Duration(milliseconds: 300), // trainsition 설정
                onTap: (int index) {
                  int navigationIndex = index;
                  switch (navigationIndex) {
                    case 0:
                      _webViewController.loadUrl(
                          url: 'https://yuhannuri.run.goorm.io');
                      break;
                    case 1:
                      _webViewController.loadUrl(url: 'https://google.com');
                      break;
                    case 2:
                      _webViewController.loadUrl(
                          url: 'https://yuhannuri.run.goorm.io/user/fcmEx/' +
                              fcm.getToken().toString());
                      break;
                    case 3:
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

              var future = _webViewController.canGoBack();
              future.then((value) {
                if (value) {
                  final CurvedNavigationBarState navBarState =
                      globalKey.currentState;
                  navBarState.setPage(0);
                }
              });
              return null;
            }));
  }

  final FirebaseMessaging fcm = FirebaseMessaging();
  void asd() {
    fcm.configure(onMessage: (Map<String, dynamic> message) async {
      print("onMessage: $message");
    }, onResume: (Map<String, dynamic> message) async {
      print("onResume: $message");
    }, onLaunch: (Map<String, dynamic> message) async {
      print("onLaunch: $message"); //
    });
  }
}
