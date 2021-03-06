import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:oktoast/oktoast.dart';
import 'package:vibration/vibration.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

final FirebaseMessaging fcm = FirebaseMessaging();

// [0] 메인, [1] 예약, [2] 문의, [3] 마이페이지, [4] 채팅, [5] 만족도조사
// urls 배열 외의 외부url을 로드할 시 webview가 아닌 기기의 브라우저(크롬, 사파리)를 이용해 로드(하이퍼링크 등)
const Domain = 'https://yuhannuri.run.goorm.io/';
const urls = [
  Domain,
  Domain + 'user/reservation',
  Domain + 'user/question',
  Domain + 'user/mypage',
  Domain + 'user/mypage?question',
  Domain + 'user/mypage?chatting',
  Domain + 'user/satisfaction',
];

class YuhanNuri extends StatefulWidget {
  final String title;
  final String cookie;

  YuhanNuri({Key key, this.title, this.cookie}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    if (Platform.isWindows)
      return DummyState();
    else
      return YuhanNuriState(cookie);
  }
}

class DummyState extends State<YuhanNuri> {
  @override
  Widget build(BuildContext context) {
    return null;
  }
}

class YuhanNuriState extends State<YuhanNuri> {
  static List<String> page = ["홈", "예약", "문의", "MY"];
  String selected = page[0];

  Map<String, String> header;

  int bodyIndex = 0;
  List<InAppWebViewController> _webView = [null, null, null, null];
  ScrollController _scroll = ScrollController();

  CurvedNavigationBarState nav;
  GlobalKey globalKey = new GlobalKey();
  bool isExit = false;

  StateSetter msgState;
  List<Widget> msgList = [];

  YuhanNuriState(String cookie) {
    header = {'Cookie': '$cookie'};
  }

  void initState() {
    super.initState();

    const initAndroidSetting =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initIosSetting = IOSInitializationSettings();
    const initSetting = InitializationSettings(
        android: initAndroidSetting, iOS: initIosSetting);
    FlutterLocalNotificationsPlugin().initialize(initSetting);

    const android = AndroidNotificationDetails(
        'channelId', 'channelName', 'channelDescription');
    const iOS = IOSNotificationDetails();
    const platform = NotificationDetails(android: android, iOS: iOS);

    var keyboardVisibilityController = KeyboardVisibilityController();

    fcm.configure(onMessage: (Map<String, dynamic> message) async {
      if (Platform.isIOS) {
        FlutterLocalNotificationsPlugin()
            .show(0, '유한누리', message['aps']['alert']['body'], platform);
      } else if (Platform.isAndroid) {
        FlutterLocalNotificationsPlugin()
            .show(0, '유한누리', message['notification']['body'], platform);
      }
    }, onResume: (Map<String, dynamic> message) async {
      if (Platform.isIOS) {
        pushClick(message['page']);
      } else if (Platform.isAndroid) {
        pushClick(message['data']['page']);
      }
    }, onLaunch: (Map<String, dynamic> message) async {
      Timer(Duration(milliseconds: 1500), () {
        if (Platform.isIOS) {
          pushClick(message['page']);
        } else if (Platform.isAndroid) {
          pushClick(message['data']['page']);
        }
      });
    });

    fcm.requestNotificationPermissions(const IosNotificationSettings(
        sound: true, badge: true, alert: true, provisional: true));

    keyboardVisibilityController.onChange.listen((bool visible) {
      if (visible && selected == "MY") {
        Timer(Duration(milliseconds: 500), () {
          _scroll.animateTo(_scroll.position.maxScrollExtent + 100,
              duration: Duration(milliseconds: 500), curve: Curves.ease);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    syncToken(context);
    return OKToast(
      position: ToastPosition.bottom,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: WillPopScope(
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Color.fromARGB(255, 0, 115, 215),
              toolbarHeight: 50,
              title: new Text(selected,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: () {
                    logoutDialog();
                  },
                )
              ],
            ),
            body: IndexedStack(
              index: bodyIndex,
              children: [
                buildWebView(0),
                buildWebView(1),
                buildQuestionPage(),
                buildWebView(3)
              ],
            ),
            bottomNavigationBar: CurvedNavigationBar(
              key: globalKey,
              index: 0,
              backgroundColor: Color.fromARGB(255, 0, 115, 215),
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
              animationDuration: const Duration(milliseconds: 300),
              onTap: (int index) {
                setState(() {
                  bodyIndex = index;
                  selected = page[index];
                  //if (index == 3) chattingDialog(); // temp code
                });
              },
              animationCurve: Curves.easeOut,
              height: 55.0,
            ),
          ),
          onWillPop: () {
            if (bodyIndex == 0) {
              if (!isExit) {
                isExit = true;
                Timer(Duration(milliseconds: 2000), () {
                  isExit = false;
                });
                showToast("뒤로 가기 버튼을 한 번 더\n누르면 앱을 종료합니다.",
                    textPadding: EdgeInsets.all(10));
                return Future.value(false);
              }
              return Future.value(true);
            }
            nav = globalKey.currentState;
            nav.setPage(0);
            return null;
          },
        ),
      ),
    );
  }

  Widget buildWebView(int index) {
    return Center(
        child: SafeArea(
            child: InAppWebView(
      initialOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
          debuggingEnabled: true,
          supportZoom: false,
          horizontalScrollBarEnabled: false,
          clearCache: true,
        ),
      ),
      initialUrl: urls[index],
      initialHeaders: header,
      onLoadStart: (controller, url) {
        _webView[index] = controller;

        if (!urls.contains(url)) {
          if (url.contains("browser_fallback_url")) {
            url = url
                .toString()
                .split("#Intent")[0]
                .replaceAll("intent://", "https://");
          }
          controller.stopLoading();
          launch(url, forceWebView: false);
          controller.evaluateJavascript(
              source: "window.location.reload(true);");
        }

        controller.addJavaScriptHandler(
          handlerName: 'mobileHandler',
          callback: (args) {
            String command = args[0].toString();
            workCallByWeb(command, args);
          },
        );
      },
    )));
  }

  Widget buildQuestionPage() {
    List<String> typeList = ["시스템 문의", "상담 문의"];
    String selectedType = typeList[0];

    TextEditingController _title = TextEditingController();
    TextEditingController _content = TextEditingController();

    return StatefulBuilder(builder: (context, StateSetter _setState) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  margin: const EdgeInsets.fromLTRB(40, 30, 40, 20),
                  child: Text(
                    "무엇이든 물어보세요!",
                    style: TextStyle(fontSize: 25),
                  )),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(15, 10, 15, 10),
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "문의 유형",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    child: DropdownButton(
                      isExpanded: true,
                      items: typeList.map((e) {
                        return DropdownMenuItem(value: e, child: Text(e));
                      }).toList(),
                      value: selectedType,
                      onChanged: (value) {
                        _setState(() {
                          selectedType = value;
                        });
                      },
                    ),
                  )
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(15, 10, 15, 10),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "제목",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextField(
                    controller: _title,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(), hintText: "제목을 입력하세요."),
                  )
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(15, 10, 15, 10),
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      "내용",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextField(
                    controller: _content,
                    maxLines: 10,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(), hintText: "내용을 입력하세요."),
                  )
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(right: 15),
              alignment: Alignment.centerRight,
              child: RaisedButton(
                child: Text(
                  "작성",
                  style: TextStyle(color: Colors.white),
                ),
                color: Color(0xFF0275D7),
                onPressed: () {
                  print(
                      'selected : $selectedType \ntitle : ${_title.value.text}\ncontent : ${_content.value.text}');
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  void pushClick(String msg) {
    if (msg == "mypage" || msg == "satisfaction") {
      nav = globalKey.currentState;
      nav.setPage(3);
    } else if (msg == "question") {
      nav = globalKey.currentState;
      nav.setPage(3);
      _webView[3].loadUrl(url: urls[4], headers: header);
    }
  }

  void removePreferences(SharedPreferences prefs) {
    prefs.remove('Token');
    prefs.remove('Cookie');
    prefs.remove('Expires');
  }

  void logoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("유한누리"),
          content: Text(
            "자동 로그인을 해제하고,\n로그아웃을 하시겠습니까?",
            style: TextStyle(height: 1.3),
          ),
          actions: [
            RaisedButton(
              child: Text("예"),
              color: Color(0xFF0275D7),
              elevation: 5,
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();

                http.Client().post(
                  Uri.parse(Domain + 'user/mobile'),
                  headers: {
                    'Content-Type':
                        'application/x-www-form-urlencoded; charset=UTF-8',
                    'Accept': 'application/json; charset=utf-8',
                  },
                  body: {
                    'command': 'logout',
                    'userToken': prefs.getString('Token')
                  },
                );

                removePreferences(prefs);

                if (Platform.isAndroid)
                  SystemNavigator.pop();
                else if (Platform.isIOS) exit(0);
              },
            ),
            RaisedButton(
              child: Text("아니오"),
              elevation: 5,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop('dialog');
              },
            )
          ],
        );
      },
    );
  }

  void autoLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () => Phoenix.rebirth(context),
          child: AlertDialog(
            title: Text("유한누리"),
            content: Text(
              "다른 기기에서 로그인하여\n자동으로 로그아웃 되었습니다.",
              style: TextStyle(height: 1.3),
            ),
            actions: [
              RaisedButton(
                child: Text("확인"),
                color: Color(0xFF0275D7),
                elevation: 5,
                onPressed: () {
                  Phoenix.rebirth(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void syncToken(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    http.Response res = await http.Client().post(
      Uri.parse(Domain + 'user/mobile'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'Accept': 'application/json; charset=utf-8',
      },
      body: {'command': 'login', 'userToken': prefs.getString('Token')},
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      if (res.body == "again") {
        removePreferences(prefs);
        autoLogoutDialog();
      }
    } else {
      removePreferences(prefs);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () => Phoenix.rebirth(context),
            child: AlertDialog(
              title: Text("유한누리"),
              content: Text(
                "서버 점검 중입니다.\n잠시 후 다시 시도해 주세요.",
                style: TextStyle(height: 1.3),
              ),
              actions: [
                RaisedButton(
                  child: Text("확인"),
                  color: Color(0xFF0275D7),
                  elevation: 5,
                  onPressed: () {
                    Phoenix.rebirth(context);
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }

  void webAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("유한누리"),
          content: Text(message),
          actions: [
            RaisedButton(
              child: Text("확인"),
              color: Color(0xFF0275D7),
              elevation: 5,
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop('dialog');
              },
            ),
          ],
        );
      },
    );
  }

  void openInputDialog(String strTextInfo) {
    Map<String, dynamic> objTextInfo = jsonDecode(strTextInfo);

    String txtTitle = objTextInfo['title'].toString();
    String txtHint = objTextInfo['value'].toString().isEmpty
        ? objTextInfo['hint'].toString()
        : objTextInfo['value'].toString();
    String txtElement = objTextInfo['element'].toString();

    String txtValue = "";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("유한누리"),
          content: new Row(
            children: [
              new Expanded(
                  child: new TextField(
                autofocus: true,
                decoration:
                    new InputDecoration(labelText: txtTitle, hintText: txtHint),
                onChanged: (value) {
                  txtValue = value;
                },
              ))
            ],
          ),
          actions: [
            RaisedButton(
              child: Text("완료"),
              color: Color(0xFF0275D7),
              elevation: 5,
              onPressed: () async {
                await _webView[bodyIndex].evaluateJavascript(
                    source: "\$('#$txtElement').val('$txtValue')");

                Navigator.of(context, rootNavigator: true).pop('dialog');
              },
            ),
            RaisedButton(
              child: Text("취소"),
              elevation: 5,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop('dialog');
              },
            )
          ],
        );
      },
    );
  }

  void chattingDialog() {
    bool isInput = false;
    TextEditingController _msg = TextEditingController();

    showGeneralDialog(
      transitionBuilder: (context, a1, a2, widget) {
        final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0.0, curvedValue * -200, 0.0),
          child: Opacity(
            opacity: a1.value,
            child: StatefulBuilder(builder: (context, StateSetter _setState) {
              msgState = _setState;
              return new WillPopScope(
                onWillPop: closeChatting,
                child: Scaffold(
                  appBar: AppBar(
                    backgroundColor: Color.fromARGB(255, 0, 115, 215),
                    toolbarHeight: 50,
                    title: new Text("채팅상담",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20)),
                  ),
                  body: Column(children: <Widget>[
                    Expanded(
                      child:
                          NotificationListener<OverscrollIndicatorNotification>(
                        onNotification:
                            (OverscrollIndicatorNotification overscroll) {
                          overscroll.disallowGlow();
                          return;
                        },
                        child: SingleChildScrollView(
                          controller: _scroll,
                          padding: EdgeInsets.only(bottom: 15),
                          child: Column(
                            children: msgList,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      color: Color(0xFFEAEAEA),
                      alignment: Alignment.bottomCenter,
                      child: Row(children: [
                        Flexible(
                            child: new TextField(
                          keyboardType: TextInputType.multiline,
                          maxLines: 4,
                          minLines: 1,
                          controller: _msg,
                          decoration: InputDecoration(
                            hintText: "메시지 전송...",
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            fillColor: Color(0xFFEAEAEA),
                            filled: true,
                          ),
                          onChanged: (value) {
                            _setState(() {
                              if (value.isEmpty)
                                isInput = false;
                              else
                                isInput = true;
                            });
                          },
                        )),
                        Container(
                          child: IconButton(
                              icon: Icon(Icons.send),
                              color: Color.fromARGB(255, 0, 115, 215),
                              onPressed: isInput
                                  ? () => _setState(() {
                                        String input = _msg.value.text;

                                        msgList.add(sendMessage(input));

                                        _scroll.animateTo(
                                            _scroll.position.maxScrollExtent +
                                                100,
                                            duration:
                                                Duration(milliseconds: 500),
                                            curve: Curves.ease);

                                        // await _webView.evaluateJavascript(
                                        //     source: "sendMessage('$input');");

                                        _msg.clear();
                                        isInput = false;
                                      })
                                  : null),
                        ),
                      ]),
                    ),
                  ]),
                ),
              );
            }),
          ),
        );
      },
      transitionDuration: Duration(milliseconds: 350),
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0),
      pageBuilder: (context, animation1, animation2) {
        return null;
      },
    );
  }

  Widget sendMessage(String msg) {
    DateTime now = DateTime.now();
    String nowHour = now.hour.toString();
    String nowMinute = now.minute.toString();
    if (nowHour.length == 1) nowHour = "0" + nowHour;
    if (nowMinute.length == 1) nowMinute = "0" + nowMinute;

    return new Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
            decoration: BoxDecoration(),
            margin: EdgeInsets.only(top: 15, right: 15),
            child: Text(
              "나",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            )),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: EdgeInsets.only(right: 5),
            child: Text(
              nowHour + ":" + nowMinute,
              style: TextStyle(color: Color.fromARGB(130, 0, 0, 0)),
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 3, right: 10),
            padding: EdgeInsets.only(top: 7, bottom: 10, right: 10, left: 10),
            constraints:
                BoxConstraints(minWidth: 0.0, maxWidth: 275.0, minHeight: 20.0),
            decoration: new BoxDecoration(
                color: Color.fromARGB(255, 0, 115, 215),
                borderRadius: BorderRadius.all(Radius.circular(10.0))),
            child: new Text(
              msg,
              style: TextStyle(color: Colors.white, fontSize: 15, height: 1.3),
            ),
          ),
        ])
      ])
    ]);
  }

  Widget recvMessage(String name, String msg) {
    DateTime now = DateTime.now();
    String nowHour = now.hour.toString();
    String nowMinute = now.minute.toString();
    if (nowHour.length == 1) nowHour = "0" + nowHour;
    if (nowMinute.length == 1) nowMinute = "0" + nowMinute;

    return new Row(mainAxisAlignment: MainAxisAlignment.start, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            decoration: BoxDecoration(),
            margin: EdgeInsets.only(top: 15, left: 15),
            child: Text(
              name + " 선생님",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            )),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
              margin: EdgeInsets.only(top: 3, left: 10),
              padding: EdgeInsets.only(top: 7, bottom: 10, right: 10, left: 10),
              constraints: BoxConstraints(
                  minWidth: 0.0, maxWidth: 275.0, minHeight: 20.0),
              decoration: new BoxDecoration(
                  color: Color(0xFFEAEAEA),
                  borderRadius: BorderRadius.all(Radius.circular(10.0))),
              child: new Text(msg,
                  style: TextStyle(
                      color: Color(0xFF656565), fontSize: 15, height: 1.3))),
          Container(
            padding: EdgeInsets.only(left: 5),
            child: Text(
              nowHour + ":" + nowMinute,
              style: TextStyle(color: Color.fromARGB(130, 0, 0, 0)),
            ),
          ),
        ]),
      ]),
    ]);
  }

  Future<bool> closeChatting() {
    Vibration.vibrate();
    return showDialog(
      context: context,
      builder: (context) {
        FocusScope.of(context).unfocus();
        return AlertDialog(
          title: Text("유한누리"),
          content: Text('채팅상담을 종료하시겠습니까?'),
          actions: <Widget>[
            RaisedButton(
              child: Text('예'),
              color: Color(0xFF0275D7),
              elevation: 5,
              onPressed: () async {
                Navigator.pop(context, true);
                await _webView[3]
                    .evaluateJavascript(source: "closeChatting();");
              },
            ),
            RaisedButton(
              child: Text('아니오'),
              elevation: 5,
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
          ],
        );
      },
    );
  }

  void workCallByWeb(String command, List<dynamic> args) async {
    switch (command) {
      case "alert":
        webAlertDialog(args[1].toString());
        break;
      case "replaceHome":
        Future.delayed(Duration(milliseconds: 300), () {
          nav = globalKey.currentState;
          nav.setPage(0);
        });
        break;
      case "replaceMypage":
        nav = globalKey.currentState;
        nav.setPage(3);
        break;
      case "openInput":
        openInputDialog(args[1].toString());
        break;
      case "openChatting":
        chattingDialog();
        break;
      case "recvChatting":
        msgState(() {
          msgList.add(recvMessage(args[1].toString(), args[2].toString()));
        });
        break;
      default:
        break;
    }
  }
}
