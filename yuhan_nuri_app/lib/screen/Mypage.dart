import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

class Mypage {
  StateSetter msgState;
  List<Widget> msgList = [];
  ScrollController scroll = ScrollController();

  bool isChatting = false;

  Widget getBuild() {
    return StatefulBuilder(
      builder: (context, StateSetter setState) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: TabBar(
                indicatorColor: Color.fromARGB(255, 0, 115, 215),
                labelColor: Color.fromARGB(255, 0, 115, 215),
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
                  Tab(icon: Icon(Icons.directions_car)),
                  Tab(icon: Icon(Icons.directions_transit)),
                  Container(
                    child: RaisedButton(
                      child: Text("Test"),
                      onPressed: () {
                        chattingDialog(context);
                        isChatting = true;
                      },
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
                              color: Color.fromARGB(255, 0, 115, 215),
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
