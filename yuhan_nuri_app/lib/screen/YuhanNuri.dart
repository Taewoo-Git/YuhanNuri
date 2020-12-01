import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:oktoast/oktoast.dart';
import 'package:vibration/vibration.dart';
import 'package:url_launcher/url_launcher.dart'; // 패키지

final FirebaseMessaging fcm = FirebaseMessaging();
CookieManager cm;

//0 : 홈화면, 1 : 예약, 2 : 문의, 3 : 마페, 4 : 만족도
const urls = [
  'https://yuhannuri.run.goorm.io/',
  'https://yuhannuri.run.goorm.io/user/reservation',
  'https://yuhannuri.run.goorm.io/user/question',
  'https://yuhannuri.run.goorm.io/user/mypage',
  'https://yuhannuri.run.goorm.io/user/mypage?satification=1'
];

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
  CurvedNavigationBarState navBarState;
  final FirebaseMessaging fcm = FirebaseMessaging();

  YuhanNuriState(String cookieParam) {
    header = {'Cookie': '$cookieParam'};
  }

  void initState() {
    super.initState();
    fcm.configure(onMessage: (Map<String, dynamic> message) async {
      // 앱이 켜져있을때는 페이지 안바꿈.
    }, onResume: (Map<String, dynamic> message) async {
      gotoPage(message['data']['page']);
    }, onLaunch: (Map<String, dynamic> message) async {
      Timer(Duration(milliseconds: 1500), () {
        gotoPage(message['data']['page']);
      });
    });

    cm = new CookieManager();
  }

  void gotoPage(String msg) {
    navBarState = globalKey.currentState;
    navBarState.setPage(3);
    if (msg == "question") {
      Timer(Duration(milliseconds: 850), () {
        _webViewController.evaluateJavascript(
            source: "\$('#reserv').removeClass('active'); " +
                "\$('#quest').addClass('active');" +
                "\$('#reservation').removeClass('active show');" +
                "\$('#question').addClass('active show');");
      });
    } else if (msg == 'satification') {
      Timer(Duration(milliseconds: 850), () {
        navBarState = globalKey.currentState;
        navBarState.setPage(3);
        _webViewController.loadUrl(url: urls[4], headers: header);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    return OKToast(
        position: ToastPosition.bottom,
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: WillPopScope(
                child: Scaffold(
                  // appBar: new AppBar(
                  //   title: Text(
                  //     "유한누리",
                  //     style: TextStyle(fontFamily: "jua"),
                  //   ),
                  //   leading: Image(
                  //     image: AssetImage('assets/logo.png'),
                  //   ),
                  // ),
                  body: Center(
                      child: SafeArea(
                          child: InAppWebView(
                    initialOptions: InAppWebViewGroupOptions(
                        crossPlatform: InAppWebViewOptions(
                            debuggingEnabled: true, supportZoom: false)),
                    initialUrl: urls[0],
                    initialHeaders: header,
                    onLoadStart: (_webViewController, String url) {
                      if (!urls.contains(url)) {
                        _webViewController.stopLoading();
                        launch(url, forceWebView: false);
                        navBarState = globalKey.currentState;
                        navBarState.setPage(0);
                      }
                    },
                    onWebViewCreated: (InAppWebViewController controller) {
                      _webViewController = controller;
                      cm.deleteAllCookies();
                      _webViewController.loadUrl(url: urls[0], headers: header);
                      KeyboardVisibility.onChange.listen((bool visible) async {
                        if (visible) {
                          //키보드 올라왔을때
                          if (await _webViewController.getUrl() == urls[3]) {
                            //'https://yuhannuri.run.goorm.io/user/mypage'
                            // 마이페이지 ( 채팅 )
                            Future.delayed(
                                Duration(milliseconds: 300),
                                () async =>
                                    await _webViewController.evaluateJavascript(
                                        source: 'setHeight();'));
                          } else if (await _webViewController.getUrl() ==
                              urls[2]) {
                            //"https://yuhannuri.run.goorm.io/user/question"
                            // 문의페이지면 아무것도안함
                          } else {
                            // 다른페이지 ( 예약페이지 등)
                            await _webViewController.evaluateJavascript(
                                source:
                                    'document.activeElement.scrollIntoView( {block: "center"})'); // 해당 텍스트박스를 화면에 나오게
                          }
                        } else {
                          //키보드가 내려갈때
                          if (await _webViewController.getUrl() == urls[3]) {
                            //'https://yuhannuri.run.goorm.io/user/mypage'
                            //마이페이지 ( 채팅 ) 이면
                            Future.delayed(
                                Duration(milliseconds: 300),
                                () async =>
                                    await _webViewController.evaluateJavascript(
                                        source: 'setHeight();'));
                            await _webViewController.evaluateJavascript(
                                source:
                                    'document.activeElement.blur()'); //해당 텍스트박스의 포커싱을 지움
                          } else {
                            await _webViewController.evaluateJavascript(
                                source:
                                    'document.activeElement.blur()'); //해당 텍스트박스의 포커싱을 지움
                          }
                        }
                      });
                      _webViewController.addJavaScriptHandler(
                          // 웹뷰 JavaScript와 통신하는 핸들러
                          handlerName:
                              'PageHandler', // 해당 핸들러를 웹뷰에서 호출( 예약완료 버튼클릭 )할 시  메인으로 돌아감
                          callback: (args) {
                            if (args[0].toString() == "replaceMain") {
                              navBarState = globalKey.currentState;
                              navBarState.setPage(0);
                            } else if (args[0].toString() == "replaceMypage") {
                              navBarState = globalKey.currentState;
                              navBarState.setPage(3);
                            }
                          });
                    },
                  ))),
                  bottomNavigationBar: CurvedNavigationBar(
                    key: globalKey,
                    index: 0,
                    backgroundColor: Colors.blueAccent[100],
                    items: <Widget>[
                      new Image.asset(
                        'assets/home.png',
                        scale: 1.3,
                      ),
                      new Image.asset(
                        'assets/reservation.png',
                        scale: 1.3,
                      ),
                      new Image.asset(
                        'assets/question.png',
                        scale: 1.3,
                      ),
                      new Image.asset(
                        'assets/mypage.png',
                        scale: 1.3,
                      ),
                    ],
                    animationDuration:
                        const Duration(milliseconds: 300), // trainsition 설정
                    onTap: (int index) {
                      int navigationIndex = index;
                      switch (navigationIndex) {
                        case 0:
                          _webViewController.loadUrl(
                              url: urls[0], headers: header);
                          break;
                        case 1:
                          _webViewController.loadUrl(
                              url: urls[1], headers: header);
                          break;
                        case 2:
                          _webViewController.loadUrl(
                              url: urls[2], headers: header);
                          break;
                        case 3:
                          _webViewController.loadUrl(
                              url: urls[3], headers: header);
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
                  if (await _webViewController.getUrl() == urls[0]) {
                    DateTime now = DateTime.now();
                    if (currentBackPressTime == null ||
                        now.difference(currentBackPressTime) >
                            Duration(seconds: 2)) {
                      // 전에 back 버튼을 누른적이 없거나
                      // back 버튼을 눌렀을때의 시간과 전에 back버튼을 눌렀을때의 차이가 2초를 넘었으면
                      currentBackPressTime = now;
                      print(await fcm.getToken());
                      showToast("뒤로가기 버튼을 한번 더      \n 클릭하면 종료합니다.");
                      return Future.value(false); // 종료 안함.
                    }
                    return Future.value(true); // if문이 거짓일때는 바로 종료
                  }
                  //마이페이지에서 채팅창이 활성화되어있는지
                  bool isChatting = await _webViewController.evaluateJavascript(
                      source:
                          'if(document.getElementById("chattingCard") != null) true;' +
                              'else false;');
                  if (isChatting) {
                    Vibration.vibrate();
                    showBackButtonDialog(context);
                  } else {
                    navBarState = globalKey.currentState;
                    navBarState.setPage(0);
                  }
                  return null;
                })));
  }

  showBackButtonDialog(BuildContext context) {
    Widget continueButton = FlatButton(
      child: Text("예"),
      onPressed: () {
        Navigator.pop(context);
        navBarState = globalKey.currentState;
        navBarState.setPage(0);
      },
    );

    Widget cancelButton = FlatButton(
      child: Text("아니오"),
      onPressed: () {
        //  Navigator.of(context).pop();
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("유한누리"),
      content: Text("현재 채팅이 활성화되어있습니다. \n홈 화면으로 돌아가시겠습니까?"),
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
