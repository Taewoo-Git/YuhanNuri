import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:grouped_buttons/grouped_buttons.dart';

class Reservation {
  PageController pageController = PageController(
    initialPage: 0,
  );

  String btnPsycho = "assets/btnCheck-off.png";
  String btnConsult = "assets/btnCheck-off.png";

  Widget selectBuild;

  List<Widget> pageList = [];

  Widget getBuild() {
    pageList = [inquiryPage()];
    return StatefulBuilder(
      builder: (context, StateSetter setState) {
        return PageView(
          controller: pageController,
          physics: NeverScrollableScrollPhysics(),
          children: pageList,
        );
      },
    );
  }

  Widget inquiryPage() {
    return StatefulBuilder(builder: (context, StateSetter setState) {
      return SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.fromLTRB(0, 30, 0, 13),
          child: Center(
            child: Column(
              children: [
                Text(
                  "무엇을 도와드릴까요?",
                  style: TextStyle(
                    fontSize: 25,
                    fontFamily: 'jua',
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            btnPsycho = "assets/btnCheck-on.png";
                            btnConsult = "assets/btnCheck-off.png";
                            selectBuild = psychoBuild();

                            if (pageList.length == 1) {
                              pageList.add(privacyPage());
                            } else if (pageList.length == 4) {
                              pageList.removeRange(1, 4);
                              pageList.add(privacyPage());
                            }
                          });
                        },
                        child: Row(
                          children: [
                            Container(
                              margin: EdgeInsets.only(right: 5),
                              child: Image(
                                image: AssetImage(btnPsycho),
                                width: 18,
                              ),
                            ),
                            Text(
                              "심리검사",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15.5,
                              ),
                            ),
                          ],
                        ),
                        style: ButtonStyle(
                          overlayColor: MaterialStateColor.resolveWith(
                              (states) => Colors.transparent),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            btnConsult = "assets/btnCheck-on.png";
                            btnPsycho = "assets/btnCheck-off.png";
                            selectBuild = consultBuild();

                            if (pageList.length == 1) {
                              pageList.add(schedulePage());
                              pageList.add(selfCheckPage());
                              pageList.add(privacyPage());
                            } else if (pageList.length == 2) {
                              pageList.removeLast();

                              pageList.add(schedulePage());
                              pageList.add(selfCheckPage());
                              pageList.add(privacyPage());
                            }
                          });
                        },
                        child: Row(
                          children: [
                            Container(
                              margin: EdgeInsets.only(right: 5),
                              child: Image(
                                image: AssetImage(btnConsult),
                                width: 18,
                              ),
                            ),
                            Text(
                              "상담예약",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15.5,
                              ),
                            ),
                          ],
                        ),
                        style: ButtonStyle(
                          overlayColor: MaterialStateColor.resolveWith(
                              (states) => Colors.transparent),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  child: selectBuild,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget schedulePage() {
    List<String> typeList = ["홍길동 선생님", "이몽룡 선생님"];
    String selectedType = typeList[0];

    Color btnChatConsultBgColor = Colors.white;
    Color btnVideoConsultBgColor = Colors.white;
    Color btnVoiceConsultBgColor = Colors.white;
    Color btnMeetConsultBgColor = Colors.white;

    Color btnChatConsultFontColor = Colors.black;
    Color btnVideoConsultFontColor = Colors.black;
    Color btnVoiceConsultFontColor = Colors.black;
    Color btnMeetConsultFontColor = Colors.black;

    DateTime dt = new DateTime.now();

    List<String> btnConsultDate = List<String>.generate(10, (index) {
      String strDay;

      dt = dt.add(Duration(days: 1));

      if (dt.weekday == DateTime.saturday) {
        dt = dt.add(Duration(days: 2));
      } else if (dt.weekday == DateTime.sunday) {
        dt = dt.add(Duration(days: 1));
      }

      if (index != 0 && dt.day == 1) {
        strDay = dt.month.toString() + "." + dt.day.toString();
      } else {
        strDay = dt.day.toString();
      }

      return strDay;
    });

    List<Color> btnConsultDateBgColors = List<Color>.filled(10, Colors.white);

    List<Color> btnConsultDateFontColors = List<Color>.filled(10, Colors.black);

    List<Color> btnConsultTimeBgColors = List<Color>.filled(8, Colors.white);

    List<Color> btnConsultTimeFontColors = List<Color>.filled(8, Colors.black);

    return StatefulBuilder(builder: (context, StateSetter setState) {
      return SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.fromLTRB(15, 30, 15, 10),
          child: Column(
            children: [
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  "상담 선생님 선택",
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                child: DropdownButton(
                  elevation: 8,
                  underline: Container(
                    height: 1,
                    color: Colors.grey,
                  ),
                  isExpanded: true,
                  items: typeList.map((e) {
                    return DropdownMenuItem(value: e, child: Text(e));
                  }).toList(),
                  value: selectedType,
                  onTap: () =>
                      FocusScope.of(context).requestFocus(new FocusNode()),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value;
                    });
                  },
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 30),
                alignment: Alignment.centerLeft,
                child: Text(
                  "상담 유형 선택",
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 15),
                child: Table(
                  border: TableBorder(
                    top: BorderSide(
                      color: Colors.black,
                    ),
                    bottom: BorderSide(
                      color: Colors.black,
                    ),
                  ),
                  children: [
                    TableRow(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnChatConsultBgColor = Color(0xFF0275D7);
                              btnVideoConsultBgColor = Colors.white;
                              btnVoiceConsultBgColor = Colors.white;
                              btnMeetConsultBgColor = Colors.white;

                              btnChatConsultFontColor = Colors.white;
                              btnVideoConsultFontColor = Colors.black;
                              btnVoiceConsultFontColor = Colors.black;
                              btnMeetConsultFontColor = Colors.black;
                            });
                          },
                          child: Text(
                            "채팅\n상담",
                            style: TextStyle(fontSize: 17, height: 1.3),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnChatConsultBgColor,
                            onPrimary: btnChatConsultFontColor,
                            padding: EdgeInsets.fromLTRB(0, 5, 0, 7),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnChatConsultBgColor = Colors.white;
                              btnVideoConsultBgColor = Color(0xFF0275D7);
                              btnVoiceConsultBgColor = Colors.white;
                              btnMeetConsultBgColor = Colors.white;

                              btnChatConsultFontColor = Colors.black;
                              btnVideoConsultFontColor = Colors.white;
                              btnVoiceConsultFontColor = Colors.black;
                              btnMeetConsultFontColor = Colors.black;
                            });
                          },
                          child: Text(
                            "화상\n상담",
                            style: TextStyle(fontSize: 17, height: 1.3),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnVideoConsultBgColor,
                            onPrimary: btnVideoConsultFontColor,
                            padding: EdgeInsets.fromLTRB(0, 5, 0, 7),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnChatConsultBgColor = Colors.white;
                              btnVideoConsultBgColor = Colors.white;
                              btnVoiceConsultBgColor = Color(0xFF0275D7);
                              btnMeetConsultBgColor = Colors.white;

                              btnChatConsultFontColor = Colors.black;
                              btnVideoConsultFontColor = Colors.black;
                              btnVoiceConsultFontColor = Colors.white;
                              btnMeetConsultFontColor = Colors.black;
                            });
                          },
                          child: Text(
                            "전화\n상담",
                            style: TextStyle(fontSize: 17, height: 1.3),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnVoiceConsultBgColor,
                            onPrimary: btnVoiceConsultFontColor,
                            padding: EdgeInsets.fromLTRB(0, 5, 0, 7),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnChatConsultBgColor = Colors.white;
                              btnVideoConsultBgColor = Colors.white;
                              btnVoiceConsultBgColor = Colors.white;
                              btnMeetConsultBgColor = Color(0xFF0275D7);

                              btnChatConsultFontColor = Colors.black;
                              btnVideoConsultFontColor = Colors.black;
                              btnVoiceConsultFontColor = Colors.black;
                              btnMeetConsultFontColor = Colors.white;
                            });
                          },
                          child: Text(
                            "대면\n상담",
                            style: TextStyle(fontSize: 17, height: 1.3),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnMeetConsultBgColor,
                            onPrimary: btnMeetConsultFontColor,
                            padding: EdgeInsets.fromLTRB(0, 5, 0, 7),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 35),
                alignment: Alignment.centerLeft,
                child: Text(
                  "상담 날짜 선택",
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 10),
                alignment: Alignment.centerLeft,
                child: Text(
                  new DateTime.now().month.toString() + "월",
                  style: TextStyle(fontSize: 12),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 5),
                child: Table(
                  border: TableBorder(
                    top: BorderSide(
                      color: Colors.black,
                    ),
                    bottom: BorderSide(
                      color: Colors.black,
                    ),
                  ),
                  children: [
                    TableRow(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnConsultDateBgColors =
                                  List<Color>.filled(10, Colors.white);
                              btnConsultDateBgColors[0] = Color(0xFF0275D7);

                              btnConsultDateFontColors =
                                  List<Color>.filled(10, Colors.black);
                              btnConsultDateFontColors[0] = Colors.white;
                            });
                          },
                          child: Text(
                            btnConsultDate[0].toString(),
                            style: TextStyle(fontSize: 17),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnConsultDateBgColors[0],
                            onPrimary: btnConsultDateFontColors[0],
                            padding: EdgeInsets.fromLTRB(0, 15, 0, 15),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnConsultDateBgColors =
                                  List<Color>.filled(10, Colors.white);
                              btnConsultDateBgColors[1] = Color(0xFF0275D7);

                              btnConsultDateFontColors =
                                  List<Color>.filled(10, Colors.black);
                              btnConsultDateFontColors[1] = Colors.white;
                            });
                          },
                          child: Text(
                            btnConsultDate[1].toString(),
                            style: TextStyle(fontSize: 17),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnConsultDateBgColors[1],
                            onPrimary: btnConsultDateFontColors[1],
                            padding: EdgeInsets.fromLTRB(0, 15, 0, 15),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnConsultDateBgColors =
                                  List<Color>.filled(10, Colors.white);
                              btnConsultDateBgColors[2] = Color(0xFF0275D7);

                              btnConsultDateFontColors =
                                  List<Color>.filled(10, Colors.black);
                              btnConsultDateFontColors[2] = Colors.white;
                            });
                          },
                          child: Text(
                            btnConsultDate[2].toString(),
                            style: TextStyle(fontSize: 17),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnConsultDateBgColors[2],
                            onPrimary: btnConsultDateFontColors[2],
                            padding: EdgeInsets.fromLTRB(0, 15, 0, 15),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnConsultDateBgColors =
                                  List<Color>.filled(10, Colors.white);
                              btnConsultDateBgColors[3] = Color(0xFF0275D7);

                              btnConsultDateFontColors =
                                  List<Color>.filled(10, Colors.black);
                              btnConsultDateFontColors[3] = Colors.white;
                            });
                          },
                          child: Text(
                            btnConsultDate[3].toString(),
                            style: TextStyle(fontSize: 17),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnConsultDateBgColors[3],
                            onPrimary: btnConsultDateFontColors[3],
                            padding: EdgeInsets.fromLTRB(0, 15, 0, 15),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnConsultDateBgColors =
                                  List<Color>.filled(10, Colors.white);
                              btnConsultDateBgColors[4] = Color(0xFF0275D7);

                              btnConsultDateFontColors =
                                  List<Color>.filled(10, Colors.black);
                              btnConsultDateFontColors[4] = Colors.white;
                            });
                          },
                          child: Text(
                            btnConsultDate[4].toString(),
                            style: TextStyle(fontSize: 17),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnConsultDateBgColors[4],
                            onPrimary: btnConsultDateFontColors[4],
                            padding: EdgeInsets.fromLTRB(0, 15, 0, 15),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnConsultDateBgColors =
                                  List<Color>.filled(10, Colors.white);
                              btnConsultDateBgColors[5] = Color(0xFF0275D7);

                              btnConsultDateFontColors =
                                  List<Color>.filled(10, Colors.black);
                              btnConsultDateFontColors[5] = Colors.white;
                            });
                          },
                          child: Text(
                            btnConsultDate[5].toString(),
                            style: TextStyle(fontSize: 17),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnConsultDateBgColors[5],
                            onPrimary: btnConsultDateFontColors[5],
                            padding: EdgeInsets.fromLTRB(0, 15, 0, 15),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnConsultDateBgColors =
                                  List<Color>.filled(10, Colors.white);
                              btnConsultDateBgColors[6] = Color(0xFF0275D7);

                              btnConsultDateFontColors =
                                  List<Color>.filled(10, Colors.black);
                              btnConsultDateFontColors[6] = Colors.white;
                            });
                          },
                          child: Text(
                            btnConsultDate[6].toString(),
                            style: TextStyle(fontSize: 17),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnConsultDateBgColors[6],
                            onPrimary: btnConsultDateFontColors[6],
                            padding: EdgeInsets.fromLTRB(0, 15, 0, 15),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnConsultDateBgColors =
                                  List<Color>.filled(10, Colors.white);
                              btnConsultDateBgColors[7] = Color(0xFF0275D7);

                              btnConsultDateFontColors =
                                  List<Color>.filled(10, Colors.black);
                              btnConsultDateFontColors[7] = Colors.white;
                            });
                          },
                          child: Text(
                            btnConsultDate[7].toString(),
                            style: TextStyle(fontSize: 17),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnConsultDateBgColors[7],
                            onPrimary: btnConsultDateFontColors[7],
                            padding: EdgeInsets.fromLTRB(0, 15, 0, 15),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnConsultDateBgColors =
                                  List<Color>.filled(10, Colors.white);
                              btnConsultDateBgColors[8] = Color(0xFF0275D7);

                              btnConsultDateFontColors =
                                  List<Color>.filled(10, Colors.black);
                              btnConsultDateFontColors[8] = Colors.white;
                            });
                          },
                          child: Text(
                            btnConsultDate[8].toString(),
                            style: TextStyle(fontSize: 17),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnConsultDateBgColors[8],
                            onPrimary: btnConsultDateFontColors[8],
                            padding: EdgeInsets.fromLTRB(0, 15, 0, 15),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnConsultDateBgColors =
                                  List<Color>.filled(10, Colors.white);
                              btnConsultDateBgColors[9] = Color(0xFF0275D7);

                              btnConsultDateFontColors =
                                  List<Color>.filled(10, Colors.black);
                              btnConsultDateFontColors[9] = Colors.white;
                            });
                          },
                          child: Text(
                            btnConsultDate[9].toString(),
                            style: TextStyle(fontSize: 17),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnConsultDateBgColors[9],
                            onPrimary: btnConsultDateFontColors[9],
                            padding: EdgeInsets.fromLTRB(0, 15, 0, 15),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 30),
                alignment: Alignment.centerLeft,
                child: Text(
                  "상담 시간 선택",
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 15),
                child: Table(
                  border: TableBorder(
                    top: BorderSide(
                      color: Colors.black,
                    ),
                    bottom: BorderSide(
                      color: Colors.black,
                    ),
                  ),
                  children: [
                    TableRow(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnConsultTimeBgColors =
                                  List<Color>.filled(8, Colors.white);
                              btnConsultTimeBgColors[0] = Color(0xFF0275D7);

                              btnConsultTimeFontColors =
                                  List<Color>.filled(8, Colors.black);
                              btnConsultTimeFontColors[0] = Colors.white;
                            });
                          },
                          child: Text(
                            "9",
                            style: TextStyle(fontSize: 17),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnConsultTimeBgColors[0],
                            onPrimary: btnConsultTimeFontColors[0],
                            padding: EdgeInsets.fromLTRB(0, 14, 0, 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnConsultTimeBgColors =
                                  List<Color>.filled(8, Colors.white);
                              btnConsultTimeBgColors[1] = Color(0xFF0275D7);

                              btnConsultTimeFontColors =
                                  List<Color>.filled(8, Colors.black);
                              btnConsultTimeFontColors[1] = Colors.white;
                            });
                          },
                          child: Text(
                            "10",
                            style: TextStyle(fontSize: 17),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnConsultTimeBgColors[1],
                            onPrimary: btnConsultTimeFontColors[1],
                            padding: EdgeInsets.fromLTRB(0, 14, 0, 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnConsultTimeBgColors =
                                  List<Color>.filled(8, Colors.white);
                              btnConsultTimeBgColors[2] = Color(0xFF0275D7);

                              btnConsultTimeFontColors =
                                  List<Color>.filled(8, Colors.black);
                              btnConsultTimeFontColors[2] = Colors.white;
                            });
                          },
                          child: Text(
                            "11",
                            style: TextStyle(fontSize: 17),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnConsultTimeBgColors[2],
                            onPrimary: btnConsultTimeFontColors[2],
                            padding: EdgeInsets.fromLTRB(0, 14, 0, 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnConsultTimeBgColors =
                                  List<Color>.filled(8, Colors.white);
                              btnConsultTimeBgColors[3] = Color(0xFF0275D7);

                              btnConsultTimeFontColors =
                                  List<Color>.filled(8, Colors.black);
                              btnConsultTimeFontColors[3] = Colors.white;
                            });
                          },
                          child: Text(
                            "13",
                            style: TextStyle(fontSize: 17),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnConsultTimeBgColors[3],
                            onPrimary: btnConsultTimeFontColors[3],
                            padding: EdgeInsets.fromLTRB(0, 14, 0, 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnConsultTimeBgColors =
                                  List<Color>.filled(8, Colors.white);
                              btnConsultTimeBgColors[4] = Color(0xFF0275D7);

                              btnConsultTimeFontColors =
                                  List<Color>.filled(8, Colors.black);
                              btnConsultTimeFontColors[4] = Colors.white;
                            });
                          },
                          child: Text(
                            "14",
                            style: TextStyle(fontSize: 17),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnConsultTimeBgColors[4],
                            onPrimary: btnConsultTimeFontColors[4],
                            padding: EdgeInsets.fromLTRB(0, 14, 0, 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnConsultTimeBgColors =
                                  List<Color>.filled(8, Colors.white);
                              btnConsultTimeBgColors[5] = Color(0xFF0275D7);

                              btnConsultTimeFontColors =
                                  List<Color>.filled(8, Colors.black);
                              btnConsultTimeFontColors[5] = Colors.white;
                            });
                          },
                          child: Text(
                            "15",
                            style: TextStyle(fontSize: 17),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnConsultTimeBgColors[5],
                            onPrimary: btnConsultTimeFontColors[5],
                            padding: EdgeInsets.fromLTRB(0, 14, 0, 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnConsultTimeBgColors =
                                  List<Color>.filled(8, Colors.white);
                              btnConsultTimeBgColors[6] = Color(0xFF0275D7);

                              btnConsultTimeFontColors =
                                  List<Color>.filled(8, Colors.black);
                              btnConsultTimeFontColors[6] = Colors.white;
                            });
                          },
                          child: Text(
                            "16",
                            style: TextStyle(fontSize: 17),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnConsultTimeBgColors[6],
                            onPrimary: btnConsultTimeFontColors[6],
                            padding: EdgeInsets.fromLTRB(0, 14, 0, 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              btnConsultTimeBgColors =
                                  List<Color>.filled(8, Colors.white);
                              btnConsultTimeBgColors[7] = Color(0xFF0275D7);

                              btnConsultTimeFontColors =
                                  List<Color>.filled(8, Colors.black);
                              btnConsultTimeFontColors[7] = Colors.white;
                            });
                          },
                          child: Text(
                            "17",
                            style: TextStyle(fontSize: 17),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: btnConsultTimeBgColors[7],
                            onPrimary: btnConsultTimeFontColors[7],
                            padding: EdgeInsets.fromLTRB(0, 14, 0, 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 12),
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      pageController.nextPage(
                          duration: Duration(milliseconds: 1000),
                          curve: Curves.fastLinearToSlowEaseIn);
                    });
                  },
                  child: Text(
                    "다 음",
                    style: TextStyle(color: Colors.white, fontSize: 17),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Color(0xFF0275D7),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget selfCheckPage() {
    List<Widget> selfcheckList = [
      selfcheck("자가진단 질문 예시1"),
      selfcheck("자가진단 질문 예시2"),
      selfcheck("자가진단 질문 예시3"),
      selfcheck("자가진단 질문 예시4"),
      selfcheck("자가진단 질문 예시5"),
    ];

    return StatefulBuilder(builder: (context, StateSetter setState) {
      return SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(top: 30, bottom: 13),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 5),
                  child: Text(
                    "간단 자가진단",
                    style: TextStyle(
                      fontSize: 25,
                      fontFamily: 'jua',
                    ),
                  ),
                ),
                Column(
                  children: selfcheckList,
                ),
                Container(
                  margin: EdgeInsets.only(top: 5, right: 15),
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        pageController.nextPage(
                          duration: Duration(milliseconds: 1000),
                          curve: Curves.fastLinearToSlowEaseIn,
                        );
                      });
                    },
                    child: Text(
                      "다 음",
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xFF0275D7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget privacyPage() {
    String agree1 = "assets/btnCheck-off.png";
    String agree2 = "assets/btnCheck-off.png";
    String agree3 = "assets/btnCheck-off.png";
    String agree4 = "assets/btnCheck-off.png";
    String agree5 = "assets/btnCheck-off.png";

    return StatefulBuilder(builder: (context, StateSetter setState) {
      return SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.fromLTRB(10, 15, 10, 13),
          child: Column(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    if (agree1 == "assets/btnCheck-off.png")
                      agree1 = "assets/btnCheck-on.png";
                    else
                      agree1 = "assets/btnCheck-off.png";
                  });
                },
                child: Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 15),
                      child: Image(
                        image: AssetImage(agree1),
                        width: 18,
                      ),
                    ),
                    Text(
                      "(필수)  ",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0275D7),
                      ),
                    ),
                    Text(
                      "상담 프로그램 이용 관련 동의",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                style: ButtonStyle(
                  overlayColor: MaterialStateColor.resolveWith(
                      (states) => Colors.transparent),
                ),
              ),
              Container(
                height: 200,
                margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                padding: EdgeInsets.only(top: 5, bottom: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.all(
                    Radius.circular(15.0),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: NotificationListener<OverscrollIndicatorNotification>(
                  onNotification: (OverscrollIndicatorNotification overscroll) {
                    overscroll.disallowGlow();
                    return;
                  },
                  child: SingleChildScrollView(
                    child: Html(
                      data: """
<div>
<b style="color:#d9534f;">1. 비밀보장에 관한 약속</b>
<p>
본 센터에서 이루어지는 모든 상담활동은 상담자 윤리강령에 근거하여 비밀 보장을 약속하며, 당사자 동의 없이 타인이나 센터 외부로 기록들이 공개되지 않습니다. 그러나 아래의 경우에는, 관련 의무 규정상 가족이나 제3자에게 공개될 수 있습니다.</br></br>
1) 최근 당신이 아동학대 혹은 성인학대의 피해자나 가해자로 여겨질 만한 근거가 있는 경우</br></br>
2) 당신이 자살하려고 하는 경우</br></br>
3) 당신의 행동이 타인에게 위해를 가할 가능성이 있는 경우</br></br>
4) 법정에서 증언을 위해 당신의 기록을 공개해 줄 것을 상담자에게 요청하는 경우</br></br>
5) 상담 내용이 자문과 교육의 목적으로 상담 수퍼바이저에게 공개하는 경우</br></br>
6) 당신이 감염성이 있는 치명적 질병이 있고, 당신과의 관계로 인해 위험한 수준으로 그 질병에 노출된 제3자가 있는 경우</br>
</p>
<b style="color:#d9534f;">2. 상담내용 기록 및 녹음</b>
<p>
상담사의 자문과 교육을 목적으로 상담내용을 기록, 녹음할 수 있습니다. 기록, 녹음은 철저히 비밀유지로 관리되며 이 외의 목적으로 절대 활용되지 않습니다(녹음을 원치 않을 경우 상담사에게 요구할 수 있습니다). 상담센터 내부에 관리되는 개인정보 및 기록물은 5년간 보관 후 폐기됩니다.<br/>
</p>
<b style="color:#d9534f;">3. 비대면 상담 관련 동의</b>
비대면으로 이뤄지는 상담내용을 상담자의 동의 없이 참여자가 임의로 녹음, 녹화, 저장하여 공개 또는 유포하여서는 안 되며, 이러한 경우에는 그에 따른 민·형사상의 책임을 지게 될 수 있음을 알려드립니다.<br/><br/>
<p style="color:#d9534f;">
※ 상위 제공된 상담 프로그램 이용 관련 동의를 거부할 권리가 있습니다. 그러나, 동의를 거부할 경우 관련 상담 프로그램 이용이 불가합니다.
</p>
</div>
                    """,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (agree2 == "assets/btnCheck-off.png")
                      agree2 = "assets/btnCheck-on.png";
                    else
                      agree2 = "assets/btnCheck-off.png";
                  });
                },
                child: Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 15),
                      child: Image(
                        image: AssetImage(agree2),
                        width: 18,
                      ),
                    ),
                    Text(
                      "(필수)  ",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0275D7),
                      ),
                    ),
                    Text(
                      "개인정보 수집·이용 동의",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                style: ButtonStyle(
                  overlayColor: MaterialStateColor.resolveWith(
                      (states) => Colors.transparent),
                ),
              ),
              Container(
                height: 200,
                margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                padding: EdgeInsets.only(top: 5, bottom: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.all(
                    Radius.circular(15.0),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: NotificationListener<OverscrollIndicatorNotification>(
                  onNotification: (OverscrollIndicatorNotification overscroll) {
                    overscroll.disallowGlow();
                    return;
                  },
                  child: SingleChildScrollView(
                    child: Html(
                      data: """
<div>
<u>수집항목</u>: 성명, 생년월일, 성별, 학과, 학년, 학번, 이메일, 연락처<br/>
<u>수집목적</u>: 상담 프로그램 제공에 필요한 내담자 이해, 본인 확인 및 연락 등의 절차에 이용, 행사 또는 프로그램 등의 안내, 센터 이용 현황 파악을 위한 통계 분석<br/> 
<u>보유기간</u>: <b style="font-size:105%;">최종 상담 프로그램 제공 종료일로부터 5년 보관 후 폐기</b><br/><br/>
<p style="color:#d9534f;">
※ 개인정보 수집·이용에 대한 동의를 거부할 권리가 있습니다. 그러나 동의를 거부할 경우 관련 상담 프로그램 이용이 불가합니다.
</p>
</div>
                    """,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (agree3 == "assets/btnCheck-off.png")
                      agree3 = "assets/btnCheck-on.png";
                    else
                      agree3 = "assets/btnCheck-off.png";
                  });
                },
                child: Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 15),
                      child: Image(
                        image: AssetImage(agree3),
                        width: 18,
                      ),
                    ),
                    Text(
                      "(필수)  ",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0275D7),
                      ),
                    ),
                    Text(
                      "민감정보 수집·이용 동의",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                style: ButtonStyle(
                  overlayColor: MaterialStateColor.resolveWith(
                      (states) => Colors.transparent),
                ),
              ),
              Container(
                height: 200,
                margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                padding: EdgeInsets.only(top: 5, bottom: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.all(
                    Radius.circular(15.0),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: NotificationListener<OverscrollIndicatorNotification>(
                  onNotification: (OverscrollIndicatorNotification overscroll) {
                    overscroll.disallowGlow();
                    return;
                  },
                  child: SingleChildScrollView(
                    child: Html(
                      data: """
<div>
<u>수집항목</u>: <b style="font-size:105%;">방문 경위 및 프로그램 신청 계기, 이전 상담경험, 휴학유무, 군대경험 유무, 종교, 주거지, 가족관계, 건강상태, 상담기록, 심리검사 결과</b><br/>
<u>수집목적</u>: 상담 프로그램 제공에 필요한 내담자 이해, 효과적인 상담 프로그램 제공에 이용<br/> 
<u>보유기간</u>: <b style="font-size:105%;">최종 상담 프로그램 제공 종료일로부터 5년 보관 후 폐기</b><br/><br/>
<p style="color:#d9534f;">
※ 민감정보 수집·이용에 대한 동의를 거부할 권리가 있습니다. 그러나 동의를 거부할 경우 관련 상담 프로그램 이용이 불가합니다.
</p>
</div>
                    """,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (agree4 == "assets/btnCheck-off.png")
                      agree4 = "assets/btnCheck-on.png";
                    else
                      agree4 = "assets/btnCheck-off.png";
                  });
                },
                child: Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 15),
                      child: Image(
                        image: AssetImage(agree4),
                        width: 18,
                      ),
                    ),
                    Text(
                      "(필수)  ",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0275D7),
                      ),
                    ),
                    Text(
                      "개인정보 제3자 제공 동의",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                style: ButtonStyle(
                  overlayColor: MaterialStateColor.resolveWith(
                      (states) => Colors.transparent),
                ),
              ),
              Container(
                height: 200,
                margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                padding: EdgeInsets.only(top: 5, bottom: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.all(
                    Radius.circular(15.0),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: NotificationListener<OverscrollIndicatorNotification>(
                  onNotification: (OverscrollIndicatorNotification overscroll) {
                    overscroll.disallowGlow();
                    return;
                  },
                  child: SingleChildScrollView(
                    child: Html(
                      data: """
<div>
<u>제공받는기관</u>: <b style="font-size:105%;">한국가이던스, 마음사랑, 인싸이트, 어세스타, 연우심리개발원, 게슈탈트포럼, 한국이고그램연구소, 한국심리연구소, 한국심리주식회사, 한국심리적성검사연구소(심리검사업체)</b><br/>
<u>제공목적</u>: <b style="font-size:105%;">온라인 심리검사 제공 및 심리검사 결과 처리</b><br/>
<u>제공하는항목</u>: 성명, 생년월일, 성별, 이메일, 연락처, 심리검사 결과<br/>
<u>보유기간</u>: <b style="font-size:105%;">최종 상담 프로그램 제공 종료일로부터 5년 보관 후 폐기</b><br/><br/>
<p style="color:#d9534f;">
※ 개인정보 제3자 제공에 대한 동의를 거부할 권리가 있습니다. 그러나 동의를 거부할 경우 관련 상담 프로그램 이용이 불가합니다.
</p>
</div>
                    """,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (agree5 == "assets/btnCheck-off.png") {
                      agree1 = "assets/btnCheck-on.png";
                      agree2 = "assets/btnCheck-on.png";
                      agree3 = "assets/btnCheck-on.png";
                      agree4 = "assets/btnCheck-on.png";
                      agree5 = "assets/btnCheck-on.png";
                    } else {
                      agree1 = "assets/btnCheck-off.png";
                      agree2 = "assets/btnCheck-off.png";
                      agree3 = "assets/btnCheck-off.png";
                      agree4 = "assets/btnCheck-off.png";
                      agree5 = "assets/btnCheck-off.png";
                    }
                  });
                },
                child: Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 15),
                      child: Image(
                        image: AssetImage(agree5),
                        width: 18,
                      ),
                    ),
                    Text(
                      "상위 유한누리 이용약간에 모두 동의합니다.",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                style: ButtonStyle(
                  overlayColor: MaterialStateColor.resolveWith(
                      (states) => Colors.transparent),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 40, right: 35),
                child: Text(
                  "※ 만 14세 미만 학생의 경우 보호자(법정대리인)의 동의가 필요하나 본 상담 프로그램은 유한대학교 재학생만 이용 가능하므로 해당사항이 없습니다.",
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF768192),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(0, 15, 5, 0),
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text(
                    "확 인",
                    style: TextStyle(color: Colors.white, fontSize: 17),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Color(0xFF0275D7),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  List<Widget> psychoTestList = [];

  List<Widget> inquiryList = [];

  Widget psychoBuild() {
    psychoTestList = [
      psychoTest(),
      psychoTest(),
      psychoTest(),
    ];
    inquiryList = [inquiey("Radio"), inquiey("Check"), inquiey("Normal")];
    return StatefulBuilder(builder: (context, StateSetter setState) {
      return Column(
        children: [
          Column(
            children: inquiryList,
          ),
          Container(
            padding: EdgeInsets.fromLTRB(25, 15, 25, 10),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(
                  "원하는 심리검사를 선택해주세요.",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  "  (중복선택 가능)",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.only(left: 10, right: 10),
            child: Column(
              children: psychoTestList,
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 15, right: 15),
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  pageController.nextPage(
                      duration: Duration(milliseconds: 1000),
                      curve: Curves.fastLinearToSlowEaseIn);
                });
              },
              child: Text(
                "다 음",
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFF0275D7),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget consultBuild() {
    psychoTestList = [
      psychoTest(),
      psychoTest(),
      psychoTest(),
    ];
    inquiryList = [inquiey("Radio"), inquiey("Check"), inquiey("Normal")];
    return StatefulBuilder(builder: (context, StateSetter setState) {
      return Column(
        children: [
          Column(
            children: inquiryList,
          ),
          Container(
            margin: EdgeInsets.only(right: 15),
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  pageController.nextPage(
                      duration: Duration(milliseconds: 1000),
                      curve: Curves.fastLinearToSlowEaseIn);
                });
              },
              child: Text(
                "다 음",
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFF0275D7),
              ),
            ),
          ),
        ],
      );
    });
  }

  void setPsychoTestList() {
    psychoTestList.add(psychoTest());
  }

  Widget psychoTest() {
    var _value = false;
    return StatefulBuilder(builder: (context, StateSetter setState) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Checkbox(
                value: _value,
                onChanged: (bool value) {
                  setState(() {
                    _value = value;
                  });
                },
              ),
              Text("MBTI"),
            ],
          ),
          TextButton(
            onPressed: () {
              setState(() {
                openDescription(
                    context, "MBTI", "16가지 성격유형 중 자신의 성격유형에 대한 장단점 탐색");
              });
            },
            child: Image(
              image: AssetImage("assets/btnDescription-on.png"),
              width: 18,
            ),
            style: ButtonStyle(
              overlayColor: MaterialStateColor.resolveWith(
                  (states) => Colors.transparent),
            ),
          ),
        ],
      );
    });
  }

  void setInquiryList() {
    inquiryList.add(psychoTest());
  }

  Widget inquiey(String type) {
    Widget temp;
    switch (type) {
      case "Radio":
        String _radio;
        temp = StatefulBuilder(builder: (context, StateSetter setState) {
          return Container(
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.only(top: 5, bottom: 5),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.all(
                Radius.circular(15.0),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(15),
                  child: Text(
                    "라디오 질문1",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                RadioButtonGroup(
                  labels: ["라디오 답변1", "라디오 답변2", "라디오 답변3"],
                  picked: _radio,
                  onSelected: (String selected) => setState(() {
                    _radio = selected;
                  }),
                  itemBuilder: (radioButton, label, index) {
                    return Container(
                      padding: EdgeInsets.all(0),
                      child: Row(
                        children: [radioButton, label],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        });
        break;
      case "Check":
        List<String> _check;
        temp = StatefulBuilder(builder: (context, StateSetter setState) {
          return Container(
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.only(top: 5, bottom: 5),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.all(
                Radius.circular(15.0),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(15),
                  child: Text(
                    "체크박스 질문1",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                CheckboxGroup(
                  labels: ["체크박스 답변1", "체크박스 답변2", "체크박스 답변3"],
                  checked: _check,
                  onSelected: (List selected) => setState(() {
                    _check = selected;
                  }),
                  itemBuilder: (checkBox, label, index) {
                    return Container(
                      padding: EdgeInsets.all(0),
                      child: Row(
                        children: [checkBox, label],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        });
        break;
      case "Normal":
        temp = StatefulBuilder(builder: (context, StateSetter setState) {
          return Container(
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.only(top: 5, bottom: 5),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.all(
                Radius.circular(15.0),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      EdgeInsets.only(left: 15, top: 15, right: 15, bottom: 10),
                  child: Text(
                    "서술형 질문1",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(left: 15, right: 15),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "자유롭게 작성해 주세요.",
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                  ),
                )
              ],
            ),
          );
        });
        break;
      default:
        break;
    }
    return temp;
  }

  Widget selfcheck(String title) {
    String _radio;
    return StatefulBuilder(builder: (context, StateSetter setState) {
      return Container(
        margin: EdgeInsets.only(top: 25),
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 20),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Container(
              padding: EdgeInsets.only(top: 10),
              child: RadioButtonGroup(
                activeColor: Color(0xFF0275D7),
                labelStyle: TextStyle(color: Colors.black54),
                orientation: GroupedButtonsOrientation.HORIZONTAL,
                labels: ["매우 나쁨", "나쁨", "보통", "좋음", "매우 좋음"],
                picked: _radio,
                onSelected: (String selected) => setState(() {
                  _radio = selected;
                }),
                itemBuilder: (radioButton, label, index) {
                  return Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(left: 10, right: 10),
                        child: Transform.scale(scale: 2.0, child: radioButton),
                      ),
                      label,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  void openDescription(BuildContext context, String title, String msg) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(
            msg,
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
              child: Text("확인"),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFF0275D7),
              ),
            ),
          ],
        );
      },
    );
  }

  /*Widget userInfo(String name, String number, String major, String gender,
      String birth, String phone, String email) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(left: 15, top: 35, right: 15),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.black),
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "이름",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: EdgeInsets.only(top: 15, bottom: 10),
                child: Text(name),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(left: 15, top: 35, right: 15),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.black),
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "학번",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: EdgeInsets.only(top: 15, bottom: 10),
                child: Text(number),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(left: 15, top: 35, right: 15),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.black),
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "학과",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: EdgeInsets.only(top: 15, bottom: 10),
                child: Text(major),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(left: 15, top: 35, right: 15),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.black),
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "성별",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: EdgeInsets.only(top: 15, bottom: 10),
                child: Text(gender),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(left: 15, top: 35, right: 15),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.black),
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "생년월일",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: EdgeInsets.only(top: 15, bottom: 10),
                child: Text(birth),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(left: 15, top: 35, right: 15),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.black),
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "전화번호",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: EdgeInsets.only(top: 15, bottom: 10),
                child: Text(phone),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(left: 15, top: 35, right: 15),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.black),
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "이메일",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: EdgeInsets.only(top: 15, bottom: 10),
                child: Text(email),
              ),
            ],
          ),
        ),
      ],
    );
  }*/
}
