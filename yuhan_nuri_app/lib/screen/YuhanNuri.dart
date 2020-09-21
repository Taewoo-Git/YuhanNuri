import 'dart:async';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:yuhan_nuri_app/Notification.dart';


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

class YuhanNuriState extends State<YuhanNuri>{

  //FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  WebViewController _webviewController; //webviewController 정의

  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  CustomNotification _notification;

  Map<String, String> header; //전달받은 Cookie객체를 string과 합쳐서 header만듦

  YuhanNuriState(String cookieParam){
    // header = {'Cookie': '$cookieParam'};
    header = {'Cookie': '$cookieParam'};
  }

  void initState() {
    super.initState();
    _notification = new CustomNotification();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WillPopScope(
        child:Scaffold(
          body: Center(
            child: SafeArea(
              child: WebView(
                // initialUrl: 'https://yuhannuri.run.goorm.io',
                javascriptMode: JavascriptMode.unrestricted,
                onWebViewCreated: (WebViewController webviewController) {          
                  _webviewController = webviewController;
                  //기존의 쿠키를 안지우면 적용이 안됨
                  CookieManager cookieManager = CookieManager();
                  cookieManager.clearCookies();
                  _webviewController.loadUrl('https://yuhannuri.run.goorm.io',headers: header);
                  _controller
                      .complete(_webviewController); //webviewController 생성
                
                },
                onPageFinished: (_) {
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
            onPressed: ()=> _notification.showNotification(),
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
          )
        ),
        onWillPop: (){
          var future = _webviewController.canGoBack();
          future.then((value){
            if(value){
              _webviewController.goBack();
            }
          });
          return null;
        })
    );
  }

  


}