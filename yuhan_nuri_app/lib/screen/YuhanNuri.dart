import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:oktoast/oktoast.dart';

final FirebaseMessaging fcm = FirebaseMessaging();
CookieManager cm;

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
      gotoPage(message['data']['page']);
    }, onResume: (Map<String, dynamic> message) async {
        gotoPage(message['data']['page']);
    }, onLaunch: (Map<String, dynamic> message) async {
      //앱이 꺼진 상태에서 알림을 눌렀을 때 발생, 아래에 loadurl보다 빨리 호출돼서 타이머 달아놈
      Timer(Duration(milliseconds: 2500), () {
        gotoPage(message['data']['page']);    
      });

    });

    cm = new CookieManager();
  }

  void gotoPage(String msg) {

        navBarState = globalKey.currentState;
        navBarState.setPage(3);
        
        if(msg == "question"){
          print("RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR");
          
          _webViewController.injectJavascriptFileFromUrl(urlFile: "https://code.jquery.com/jquery-3.3.1.min.js");   

          Timer(Duration(milliseconds: 2500), () {
            _webViewController.evaluateJavascript(source: 
            "\$('#reserv').removeClass('active'); "+
            "\$('#quest').addClass('active');"+
            "\$('#reservation').removeClass('active show');" +
            "\$('#question').addClass('active show');"
          );

        
          });


        }else{
          print("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
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
                  body: Center(
                      child: SafeArea(
                          child: InAppWebView(
                    initialOptions: InAppWebViewGroupOptions(
                        crossPlatform: InAppWebViewOptions(
                      debuggingEnabled: true,
                      supportZoom: false,
                    )),
                    onWebViewCreated: (InAppWebViewController controller) {
                      _webViewController = controller;
                      // url로드전에 cookie 지워주지 않으면 cookie 안먹는 경우 있음
                      cm.deleteAllCookies(); 
                      _webViewController.loadUrl(
                          url: 'https://yuhannuri.run.goorm.io',
                          headers: header);
                      KeyboardVisibility.onChange.listen((bool visible) async {
                        if (visible) {
                          //키보드 올라왔을때
                          if (await _webViewController.getUrl() ==
                              'https://yuhannuri.run.goorm.io/user/mypage') {
                            // 마이페이지 ( 채팅 )
                            Future.delayed(
                                Duration(milliseconds: 300),
                                () async =>
                                    await _webViewController.evaluateJavascript(
                                        source: 'setHeight();'));
                          } else if (await _webViewController.getUrl() ==
                              "https://yuhannuri.run.goorm.io/user/question") {
                            // 문의페이지면 아무것도안함
                          } else {
                            // 다른페이지 ( 예약페이지 등)
                            await _webViewController.evaluateJavascript(
                                source:
                                    'document.activeElement.scrollIntoView( {block: "center"})'); // 해당 텍스트박스를 화면에 나오게
                          }
                        } else {
                          //키보드가 내려갈때
                          if (await _webViewController.getUrl() ==
                              'https://yuhannuri.run.goorm.io/user/mypage') {
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
                            navBarState = globalKey.currentState;
                            navBarState.setPage(0);
                          });
                    },
                  ))),
                  bottomNavigationBar: CurvedNavigationBar(
                    key: globalKey,
                    index: 0,
                    backgroundColor: Colors.blueAccent[100],
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
                          _webViewController.loadUrl(
                              url: 'https://yuhannuri.run.goorm.io',
                              headers: header);
                          break;
                        case 1:
                          _webViewController.loadUrl(
                              url:
                                  'https://yuhannuri.run.goorm.io/user/reservation',
                              headers: header);
                          break;
                        case 2:
                          _webViewController.loadUrl(
                              url:
                                  'https://yuhannuri.run.goorm.io/user/question',
                              headers: header);
                          break;
                        case 3:
                          _webViewController.loadUrl(
                              url: 'https://yuhannuri.run.goorm.io/user/mypage',
                              headers: header);
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
      content: Text("현재 채팅이 활성화되어있습니다. \n 홈화면으로 돌아가시겠습니까?"),
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
