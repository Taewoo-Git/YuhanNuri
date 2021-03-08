import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:custom_switch/custom_switch.dart';

class Mypage {
  StateSetter msgState;
  List<Widget> msgList = [];
  ScrollController scroll = ScrollController();

  bool isChatting = false;

  Widget getBuild() {
    bool isPush = true;

    List<Widget> myList = [
      setQuestion(),
      setAnswer(),
    ];

    return StatefulBuilder(
      builder: (context, StateSetter setState) {
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
                                    padding: EdgeInsets.fromLTRB(20, 20, 0, 10),
                                    child: Text(
                                      "이름",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.fromLTRB(20, 20, 0, 10),
                                    child: Text(
                                      "김태우",
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
                                    padding: EdgeInsets.fromLTRB(20, 10, 0, 10),
                                    child: Text(
                                      "학번",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.fromLTRB(20, 10, 0, 10),
                                    child: Text(
                                      "201507067",
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
                                    padding: EdgeInsets.fromLTRB(20, 10, 0, 10),
                                    child: Text(
                                      "학과",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.fromLTRB(20, 10, 0, 10),
                                    child: Text(
                                      "컴퓨터소프트웨어공학과".replaceAll(" ", "\n"),
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
                                    padding: EdgeInsets.fromLTRB(20, 10, 0, 10),
                                    child: Text(
                                      "생년월일",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.fromLTRB(20, 10, 0, 10),
                                    child: Text(
                                      "1995-07-27",
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
                                    padding: EdgeInsets.fromLTRB(20, 10, 0, 10),
                                    child: Text(
                                      "전화번호",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.fromLTRB(20, 10, 0, 10),
                                    child: Text(
                                      "010-2969-2563",
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
                                    padding: EdgeInsets.fromLTRB(20, 10, 0, 20),
                                    child: Text(
                                      "이메일",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.fromLTRB(20, 10, 0, 20),
                                    child: Text(
                                      "tass95@naver.com",
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
                                        "2021-03-09",
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
                                        onChanged: (value) {
                                          setState(() {
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
                  Container(
                    color: Color(0xFFF0F0F0),
                    child: StatefulBuilder(
                      builder: (context, StateSetter setState) {
                        return SingleChildScrollView(
                          padding: EdgeInsets.only(top: 10, bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: myList,
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    color: Color(0xFFF0F0F0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          heightFactor: 3,
                          child: CircularProgressIndicator(
                            backgroundColor: Colors.white,
                            strokeWidth: 3.5,
                          ),
                        ),
                        RaisedButton(
                          child: Text("Test"),
                          onPressed: () {
                            chattingDialog(context);
                            isChatting = true;
                          },
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void chattingDialog(BuildContext _context) {
    bool isInput = false;
    TextEditingController _msg = TextEditingController();

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

                                        msgList.add(sendMessage(input));

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

  Widget sendMessage(String msg) {
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

  Widget recvMessage(String name, String msg) {
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
              nowHour + ":" + nowMinute,
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
          actions: <Widget>[
            RaisedButton(
              child: Text('예'),
              color: Color(0xFF0275D7),
              elevation: 5,
              onPressed: () async {
                isChatting = false;
                Navigator.pop(context, true);
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
}

Widget setQuestion() {
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
            "3일 후 채팅상담을 대면상담으로 바꾸고 싶어요.",
            style: TextStyle(fontSize: 20),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(
            children: [
              Text(
                "03.07",
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
                  Text("가능할까요? 아니면 시간이라도 변경하고 싶어요.."),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  });
}

Widget setAnswer() {
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
            "대면으로 상담할 수 있나요?",
            style: TextStyle(fontSize: 20),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(
            children: [
              Text(
                "03.07",
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
                  Text("시국이 시국인지라 조심스럽긴 하지만 꼭 대면으로 상담하고 싶습니다.."),
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
                  Text("물론입니다, 대면상담 예약을 통해 언제든지 방문해 주세요! :)"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  });
}
