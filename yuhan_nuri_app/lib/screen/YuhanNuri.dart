import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:oktoast/oktoast.dart';
import 'package:vibration/vibration.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FirebaseMessaging fcm = FirebaseMessaging();
CookieManager cm;

// [0] 메인, [1] 예약, [2] 문의, [3] 마이페이지, [4] 채팅, [5] 만족도조사페이지
// urls 배열 외의 외부url을 로드할 시 webview가 아닌 기기의 브라우저(크롬, 사파리)를 이용해 로드(하이퍼링크 등)
const urls = [
  'http://counsel.yuhan.ac.kr/',
  'http://counsel.yuhan.ac.kr/user/reservation',
  'http://counsel.yuhan.ac.kr/user/question',
  'http://counsel.yuhan.ac.kr/user/mypage',
  'http://counsel.yuhan.ac.kr/user/mypage?chatting',
  'http://counsel.yuhan.ac.kr/user/satisfaction',
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
  Map<String, String> header; // 전달받은 Cookie 객체를 string과 합쳐서 header 만듦
  GlobalKey globalKey = new GlobalKey(); // 내비게이션 바 외부에서 접근 가능하게 해줄 Key 변수
  CurvedNavigationBarState navBarState;
  final FirebaseMessaging fcm = FirebaseMessaging();

  YuhanNuriState(String cookieParam) {
    header = {'Cookie': '$cookieParam'};
  }

  void initState() {
    super.initState();
    fcm.configure(
        onMessage: (Map<String, dynamic> message) async {},
        onResume: (Map<String, dynamic> message) async {
          gotoPage(message['data']['page']);
        },
        onLaunch: (Map<String, dynamic> message) async {
          Timer(Duration(milliseconds: 1500), () {
            gotoPage(message['data']['page']);
          });
        });

    cm = new CookieManager();

    KeyboardVisibilityController().onChange.listen((bool visible) {
      if (visible) {
        // 키보드 올라왔을 때
        _webViewController.getUrl().then((url) => {
              if (url != urls[3])
                {
                  _webViewController.evaluateJavascript(
                      source:
                          'document.activeElement.scrollIntoView({block: "center"})')
                }
            });
      } else {
        // 키보드가 내려갈 때
        _webViewController.getUrl().then((url) => {
              if (url != urls[3])
                {
                  _webViewController.evaluateJavascript(
                      source: 'document.activeElement.blur()')
                }
            });
      }
    });
  }

  void gotoPage(String msg) {
    if (msg == "mypage" || msg == "satisfaction") {
      navBarState = globalKey.currentState;
      navBarState.setPage(3);
    } else if (msg == "question") {
      navBarState = globalKey.currentState;
      navBarState.setPage(3);
      Timer(Duration(milliseconds: 500), () {
        _webViewController.evaluateJavascript(
            source: "\$('#reserv').removeClass('active'); " +
                "\$('#quest').addClass('active');" +
                "\$('#reservation').removeClass('active show');" +
                "\$('#question').addClass('active show');");
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
                  appBar: AppBar(
                    title: Container(
                      child: Image(
                        image: AssetImage('assets/nuri.png'),
                        fit: BoxFit.fill,
                        height: 22,
                      ),
                    ),
                    actions: <Widget>[
                      IconButton(
                        icon: Icon(Icons.logout),
                        onPressed: () {
                          showLogoutButtonDialog(context);
                        },
                      )
                    ],
                  ),
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
                        
                        //google form 단축 url일 경우
                        if(url.contains('action=com.google.firebase.dynamiclinks.VIEW_DYNAMIC_LINK;')){                
                          url =url.toString().split(';')[4].toString().split('=')[1].split('viewform')[0]+'viewform';
                        }

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
                      _webViewController.addJavaScriptHandler(
                          // 웹뷰 JavaScript와 통신하는 핸들러
                          handlerName:
                              'PageHandler', // 해당 핸들러를 웹뷰에서 호출(예약 완료 버튼 클릭)할 시 메인으로 돌아감
                          callback: (args) {
                            if (args[0].toString() == "replaceMain") {
                              Future.delayed(Duration(milliseconds: 300), () {
                                navBarState = globalKey.currentState;
                                navBarState.setPage(0);
                              });
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
                      // back 버튼을 눌렀을 때의 시간과 전에 back 버튼을 눌렀을 때의 차이가 2초를 넘었으면
                      currentBackPressTime = now;
                      showToast("뒤로 가기 버튼을 한 번 더      \n 클릭하면 종료합니다.");
                      return Future.value(false); // 종료 안함.
                    }
                    return Future.value(true); // if문이 거짓일 때는 바로 종료
                  }
                  // 마이페이지에서 채팅 창이 활성화되어있는지
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
    Widget continueButton = RaisedButton(
      child: Text("예"),
      color: Color(0xFF0275D7),
      elevation: 5,
      onPressed: () {
        Navigator.pop(context);
        navBarState = globalKey.currentState;
        navBarState.setPage(0);
      },
    );

    Widget cancelButton = RaisedButton(
      child: Text("아니오"),
      elevation: 5,
      onPressed: () {
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

  showLogoutButtonDialog(BuildContext context) {
    Widget continueButton = RaisedButton(
      child: Text("예"),
      color: Color(0xFF0275D7),
      elevation: 5,
      onPressed: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.remove('expires');
        prefs.remove('cookie');
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      },
    );

    Widget cancelButton = RaisedButton(
      child: Text("아니오"),
      elevation: 5,
      onPressed: () {
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("유한누리"),
      content: Text("로그아웃 후 종료합니다."),
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
