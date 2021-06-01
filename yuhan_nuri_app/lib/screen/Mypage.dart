import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:vibration/vibration.dart';
import 'package:custom_switch/custom_switch.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'Domain.dart';

class Mypage {
  Map<String, String> header;

  IO.Socket socket;

  StateSetter msgState;

  List<Widget> msgList = [];
  List<Widget> questionList = [];

  Map<String, dynamic> stuInfo;

  Map<String, dynamic> chatInfo;

  Widget widgetChatting;

  ScrollController scroll = ScrollController();

  KeyboardVisibilityController keyboardVisibilityController;

  bool isInit;

  bool isPush = false;

  var parentKey;

  var ctx;

  Future<bool> initData() async {
    isInit = false;

    msgList.clear();
    questionList.clear();

    http.Response mypage = await http.Client().post(
      Uri.parse(Domain.url + "user/get/mypage"),
      headers: header,
    );

    stuInfo = jsonDecode(mypage.body);

    if (stuInfo["push"].toString() == 'Y')
      isPush = true;
    else
      isPush = false;

    http.Response question = await http.Client().get(
      Uri.parse(Domain.url + "user/get/question"),
      headers: header,
    );

    var list = jsonDecode(question.body);

    list.forEach((data) {
      List<String> strDate = data["date"].toString().split('-');
      if (data["answer"].toString() == "null") {
        questionList.add(setQuestion(
            data["title"], "${strDate[1]}.${strDate[2]}", data["content"]));
      } else {
        questionList.add(setAnswer(data["title"], "${strDate[1]}.${strDate[2]}",
            data["content"], data["answer"]));
      }
    });

    http.Response chat = await http.Client().get(
      Uri.parse(Domain.url + "user/get/chat"),
      headers: header,
    );

    chatInfo = jsonDecode(chat.body);
    widgetChatting = getChatting(chatInfo);

    return true;
  }

  Widget getChatting(dynamic info) {
    Widget ret;

    switch (int.parse(info["status"].toString())) {
      case 0:
        ret = Container(
          alignment: Alignment.topCenter,
          margin: EdgeInsets.only(top: 200),
          child: Text(
            "예약된 채팅상담이 없습니다.",
            style: TextStyle(fontSize: 18),
          ),
        );
        break;
      case 1:
        ret = SingleChildScrollView(
            child: Container(
          margin: EdgeInsets.only(top: 150),
          child: Column(
            children: [
              Center(
                heightFactor: 3,
                child: CircularProgressIndicator(
                  backgroundColor: Colors.white,
                  strokeWidth: 3.5,
                ),
              ),
              Text(
                "상담 대기 중입니다.\n잠시만 기다려 주세요.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ));
        socket = IO.io(Domain.url + "chat", <String, dynamic>{
          'transports': ['websocket'],
        });
        socket.emit(
          "waiting",
          {
            "name": chatInfo["stuname"].toString(),
            "code": chatInfo["stuno"].toString(),
            "empid": chatInfo["empid"].toString()
          },
        );
        break;
      case 2:
        ret = Container(
          alignment: Alignment.topCenter,
          margin: EdgeInsets.only(top: 200),
          child: Text(
            "예약 접수를 기다리고 있습니다.",
            style: TextStyle(fontSize: 18),
          ),
        );
        break;
      case 3:
        ret = Container(
          alignment: Alignment.topCenter,
          margin: EdgeInsets.only(top: 200),
          child: Text(
            "아직 채팅상담 시간이 아닙니다.",
            style: TextStyle(fontSize: 18),
          ),
        );
        break;
      default:
        break;
    }

    return ret;
  }

  String convertBirth(strBirth) {
    String nowYear = new DateTime.now().year.toString().substring(2, 4);

    String fullBirth = "";

    if (int.parse(nowYear) > int.parse(strBirth.substring(0, 2))) {
      fullBirth = "20" +
          strBirth.substring(0, 2) +
          "-" +
          strBirth.substring(2, 4) +
          "-" +
          strBirth.substring(4, 6);
    } else {
      fullBirth = "19" +
          strBirth.substring(0, 2) +
          "-" +
          strBirth.substring(2, 4) +
          "-" +
          strBirth.substring(4, 6);
    }

    return fullBirth;
  }

  Future<Widget> getBuild(Map<String, String> _header, var key) async {
    header = _header;
    parentKey = key;

    return FutureBuilder(
      future: initData(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          return StatefulBuilder(
            builder: (context, StateSetter setState) {
              if (socket != null) {
                socket.on("okay", (logs) {
                  if (isInit) {
                    socket.emit("join");
                  } else {
                    isInit = true;
                    if (logs != null) {
                      logs.toString().split('\n').forEach((log) {
                        if (log.trim().isNotEmpty) {
                          if (log.split('：')[0].contains("학생")) {
                            String hour = log
                                .split('（')[1]
                                .split('일')[1]
                                .split('시')[0]
                                .trim();
                            String minute = log
                                .split('（')[1]
                                .split('시')[1]
                                .split('분')[0]
                                .trim();
                            String msg = log.split('：')[1].split('（')[0];
                            msgList.add(sendMessage(msg, hour, minute));
                          } else {
                            String hour = log
                                .split('（')[1]
                                .split('일')[1]
                                .split('시')[0]
                                .trim();
                            String minute = log
                                .split('（')[1]
                                .split('시')[1]
                                .split('분')[0]
                                .trim();
                            String name =
                                log.split('：')[0].replaceAll("선생님", "").trim();
                            String msg = log.split('：')[1].split('（')[0];
                            msgList.add(recvMessage(name, msg, hour, minute));
                          }
                        }
                      });
                    }

                    chattingDialog(context);

                    Timer(Duration(milliseconds: 500), () {
                      scroll.animateTo(scroll.position.maxScrollExtent + 100,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.ease);
                    });

                    socket.emit("join");
                  }
                });

                socket.on("msg", (data) {
                  msgState(() {
                    msgList.add(recvMessage(data["name"].toString(),
                        data["msg"].toString(), null, null));

                    scroll.animateTo(scroll.position.maxScrollExtent + 100,
                        duration: Duration(milliseconds: 500),
                        curve: Curves.ease);
                  });
                });

                socket.on("finish", (_) {
                  socket.disconnect();
                  finishChatting(context);
                });

                socket.onDisconnect((_) {
                  if (ctx != null) Navigator.pop(ctx, true);
                  parentKey.currentState.setPage(0);
                });
              }

              return MaterialApp(
                debugShowCheckedModeBanner: false,
                home: DefaultTabController(
                  length: 3,
                  child: Scaffold(
                    appBar: TabBar(
                      indicatorColor: Color(0xFF0073D7),
                      labelColor: Color(0xFF0073D7),
                      labelStyle: TextStyle(fontSize: 18),
                      unselectedLabelColor: Colors.black,
                      tabs: [
                        Container(
                          padding: EdgeInsets.all(10),
                          child: Text("내 정보"),
                        ),
                        Container(
                          padding: EdgeInsets.all(10),
                          child: Text("문의내역"),
                        ),
                        Container(
                          padding: EdgeInsets.all(10),
                          child: Text("채팅"),
                        ),
                      ],
                    ),
                    body: TabBarView(
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.all(15),
                          color: Color(0xFFF0F0F0),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(15.0),
                                    ),
                                  ),
                                  child: Table(
                                    columnWidths: {0: FixedColumnWidth(100)},
                                    defaultVerticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    children: [
                                      TableRow(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.fromLTRB(
                                                20, 20, 0, 10),
                                            child: Text(
                                              "이름",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.fromLTRB(
                                                20, 20, 0, 10),
                                            child: Text(
                                              stuInfo["stuname"],
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      TableRow(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.fromLTRB(
                                                20, 10, 0, 10),
                                            child: Text(
                                              "학번",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.fromLTRB(
                                                20, 10, 0, 10),
                                            child: Text(
                                              stuInfo["stuno"],
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      TableRow(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.fromLTRB(
                                                20, 10, 0, 10),
                                            child: Text(
                                              "학과",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.fromLTRB(
                                                20, 10, 0, 10),
                                            child: Text(
                                              stuInfo["major"]
                                                  .replaceAll(" ", "\n"),
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      TableRow(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.fromLTRB(
                                                20, 10, 0, 10),
                                            child: Text(
                                              "생년월일",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.fromLTRB(
                                                20, 10, 0, 10),
                                            child: Text(
                                              convertBirth(stuInfo["birth"]),
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      TableRow(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.fromLTRB(
                                                20, 10, 0, 10),
                                            child: Text(
                                              "전화번호",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.fromLTRB(
                                                20, 10, 0, 10),
                                            child: Text(
                                              stuInfo["phonenum"],
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      TableRow(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.fromLTRB(
                                                20, 10, 0, 20),
                                            child: Text(
                                              "이메일",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.fromLTRB(
                                                20, 10, 0, 20),
                                            child: Text(
                                              stuInfo["email"],
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.fromLTRB(10, 35, 10, 0),
                                  child: Column(
                                    children: [
                                      Container(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "마지막 상담 일자",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Container(
                                              child: Text(
                                                stuInfo["last"].toString(),
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        margin: EdgeInsets.only(top: 30),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text("PUSH 알림 수신",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                )),
                                            Container(
                                              child: CustomSwitch(
                                                activeColor: Color(0xFF0073D7),
                                                value: isPush,
                                                onChanged: (value) async {
                                                  setState(() {
                                                    http.Client().post(
                                                      Uri.parse(Domain.url +
                                                          "user/set/push"),
                                                      headers: header,
                                                      body: {
                                                        'push':
                                                            value ? 'Y' : 'N',
                                                      },
                                                    );
                                                    isPush = value;
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        Container(
                          color: Color(0xFFF0F0F0),
                          child: StatefulBuilder(
                            builder: (context, StateSetter setState) {
                              if (questionList.length > 0) {
                                return SingleChildScrollView(
                                  padding: EdgeInsets.only(top: 10, bottom: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: questionList,
                                  ),
                                );
                              } else {
                                return Container(
                                  alignment: Alignment.topCenter,
                                  margin: EdgeInsets.only(top: 200),
                                  child: Text(
                                    "등록된 문의가 없습니다.",
                                    style: TextStyle(fontSize: 18),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        widgetChatting,
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        } else {
          return Container(
            child: Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.white,
              ),
            ),
          );
        }
      },
    );
  }

  void chattingDialog(BuildContext _context) {
    bool isInput = false;
    TextEditingController _msg = TextEditingController();

    keyboardVisibilityController = KeyboardVisibilityController();

    keyboardVisibilityController.onChange.listen((bool visible) {
      if (visible && socket != null && socket.connected) {
        Timer(Duration(milliseconds: 500), () {
          scroll.animateTo(scroll.position.maxScrollExtent + 100,
              duration: Duration(milliseconds: 500), curve: Curves.ease);
        });
      }
    });

    showGeneralDialog(
      transitionDuration: Duration(milliseconds: 350),
      context: _context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0),
      pageBuilder: (context, animation1, animation2) {
        return null;
      },
      transitionBuilder: (context, a1, a2, widget) {
        final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0.0, curvedValue * -200, 0.0),
          child: Opacity(
            opacity: a1.value,
            child: StatefulBuilder(builder: (context, StateSetter _setState) {
              ctx = context;
              msgState = _setState;
              return new WillPopScope(
                onWillPop: () => closeChatting(context),
                child: Scaffold(
                  appBar: AppBar(
                    backgroundColor: Color(0xFF0073D7),
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
                          controller: scroll,
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
                              color: Color(0xFF0073D7),
                              onPressed: isInput
                                  ? () => _setState(() {
                                        String input = _msg.value.text;

                                        socket.emit("msg", input);

                                        msgList.add(
                                            sendMessage(input, null, null));

                                        scroll.animateTo(
                                            scroll.position.maxScrollExtent +
                                                100,
                                            duration:
                                                Duration(milliseconds: 500),
                                            curve: Curves.ease);

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
    );
  }

  Widget sendMessage(String msg, String logHour, String logMinute) {
    DateTime now = DateTime.now();
    String nowHour = now.hour.toString();
    String nowMinute = now.minute.toString();
    if (nowHour.length == 1) nowHour = "0" + nowHour;
    if (nowMinute.length == 1) nowMinute = "0" + nowMinute;

    return new Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
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
              (logHour ?? nowHour) + ":" + (logMinute ?? nowMinute),
              style: TextStyle(color: Color.fromARGB(130, 0, 0, 0)),
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 3, right: 10),
            padding: EdgeInsets.only(top: 7, bottom: 10, right: 10, left: 10),
            constraints:
                BoxConstraints(minWidth: 0.0, maxWidth: 275.0, minHeight: 20.0),
            decoration: new BoxDecoration(
                color: Color(0xFF0073D7),
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

  Widget recvMessage(
      String name, String msg, String logHour, String logMinute) {
    DateTime now = DateTime.now();
    String nowHour = now.hour.toString();
    String nowMinute = now.minute.toString();
    if (nowHour.length == 1) nowHour = "0" + nowHour;
    if (nowMinute.length == 1) nowMinute = "0" + nowMinute;

    return new Row(mainAxisAlignment: MainAxisAlignment.start, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
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
              (logHour ?? nowHour) + ":" + (logMinute ?? nowMinute),
              style: TextStyle(color: Color.fromARGB(130, 0, 0, 0)),
            ),
          ),
        ]),
      ]),
    ]);
  }

  Future<bool> closeChatting(BuildContext _context) {
    Vibration.vibrate();
    return showDialog(
      context: _context,
      builder: (context) {
        FocusScope.of(context).unfocus();
        return AlertDialog(
          title: Text("유한누리"),
          content: Text('채팅상담을 종료하시겠습니까?'),
          actions: [
            ElevatedButton(
              onPressed: () {
                ctx = null;
                Navigator.pop(context, true);
                socket.disconnect();
              },
              child: Text('예'),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFF0275D7),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text('아니오'),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFFE6E6E6),
                onPrimary: Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }

  void finishChatting(BuildContext _context) {
    showDialog(
      context: _context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("유한누리"),
          content: Text(
            "상담사가 채팅을 종료했습니다.",
            style: TextStyle(
              height: 1.3,
            ),
          ),
          contentPadding: EdgeInsets.fromLTRB(24, 24, 24, 15),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text("확 인"),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFF0275D7),
              ),
            ),
          ],
        );
      },
    );
  }
}

Widget setQuestion(String t, String d, String q) {
  return StatefulBuilder(builder: (context, StateSetter setState) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: ExpansionTile(
          title: Text(
            t,
            style: TextStyle(fontSize: 20),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(
            children: [
              Text(
                d,
                style: TextStyle(color: Colors.black, height: 1.5),
              ),
              Container(
                margin: EdgeInsets.only(left: 10),
                child: Text(
                  "미완료",
                  style: TextStyle(color: Colors.red, height: 1.5),
                ),
              ),
            ],
          ),
          children: [
            Divider(height: 1, indent: 10, endIndent: 10, color: Colors.black),
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.all(10),
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "질문",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                  ),
                  Divider(
                    height: 10,
                    color: Colors.transparent,
                  ),
                  Text(q),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  });
}

Widget setAnswer(String t, String d, String q, String a) {
  return StatefulBuilder(builder: (context, StateSetter setState) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: ExpansionTile(
          title: Text(
            t,
            style: TextStyle(fontSize: 20),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(
            children: [
              Text(
                d,
                style: TextStyle(color: Colors.black, height: 1.5),
              ),
              Container(
                margin: EdgeInsets.only(left: 10),
                child: Text(
                  "완료",
                  style: TextStyle(color: Colors.blue, height: 1.5),
                ),
              ),
            ],
          ),
          children: [
            Divider(height: 1, indent: 10, endIndent: 10, color: Colors.black),
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.all(10),
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "질문",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                  ),
                  Divider(
                    height: 10,
                    color: Colors.transparent,
                  ),
                  Text(q),
                ],
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "답변",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                  ),
                  Divider(
                    height: 10,
                    color: Colors.transparent,
                  ),
                  Text(a),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  });
}
