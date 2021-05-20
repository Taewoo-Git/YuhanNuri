import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:vibration/vibration.dart';
import 'package:grouped_buttons/grouped_buttons.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'Domain.dart';

class Reservation {
  Map<String, String> header;

  PageController pageController = PageController(
    initialPage: 0,
  );

  String btnPsycho = "assets/btnCheck-off.png";
  String btnConsult = "assets/btnCheck-off.png";

  Widget selectBuild;

  List<Widget> pageList = [];

  Map<int, String> tempSelectedAnswers = {};

  List<int> tempSelectedPsyTest = [];

  Map<String, dynamic> lastData = {};

  int initCheckNum;

  List<Widget> psychoTestList = [];

  List<Widget> psychoInquiries = [];

  List<Widget> consultInquiries = [];

  BuildContext ctx;

  var parentKey;

  Future<Widget> getBuild(Map<String, String> _header, var key) async {
    header = _header;
    parentKey = key;
    await getInit();
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
    lastData.clear();
    return StatefulBuilder(builder: (context, StateSetter setState) {
      ctx = context;
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
                        onPressed: () async {
                          tempSelectedAnswers.clear();
                          initCheckNum = psychoInquiries.length;
                          lastData["type"] = 2;
                          pageList.removeRange(1, pageList.length);
                          pageList.add(await privacyPage());
                          setState(() {
                            btnPsycho = "assets/btnCheck-on.png";
                            btnConsult = "assets/btnCheck-off.png";
                            selectBuild = psychoBuild();
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
                        onPressed: () async {
                          tempSelectedAnswers.clear();
                          initCheckNum = consultInquiries.length;
                          lastData["type"] = 1;
                          pageList.removeRange(1, pageList.length);
                          pageList.add(await schedulePage());
                          pageList.add(await selfCheckPage());
                          pageList.add(await privacyPage());
                          setState(() {
                            btnConsult = "assets/btnCheck-on.png";
                            btnPsycho = "assets/btnCheck-off.png";
                            selectBuild = consultBuild();
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

  Future<Widget> schedulePage() async {
    List<Map> typeList = [
      {"empid": "null", "empname": "선생님을 선택해 주세요."}
    ];

    http.Response res = await http.Client().get(
      Uri.parse(Domain.url + "user/get/counselor"),
      headers: header,
    );

    var recv = jsonDecode(res.body);

    recv.forEach((obj) {
      if (obj["empid"].toString() != "admin") {
        typeList
            .add({"empid": obj["empid"], "empname": "${obj["empname"]} 선생님"});
      }
    });

    String selectedType = typeList[0]["empid"];

    Color btnChatConsultBgColor = Colors.white;
    Color btnVideoConsultBgColor = Colors.white;
    Color btnVoiceConsultBgColor = Colors.white;
    Color btnMeetConsultBgColor = Colors.white;

    Color btnChatConsultFontColor = Colors.black;
    Color btnVideoConsultFontColor = Colors.black;
    Color btnVoiceConsultFontColor = Colors.black;
    Color btnMeetConsultFontColor = Colors.black;

    DateTime dt = new DateTime.now();

    List<DateTime> fullDateTime = [];

    List<String> btnConsultDate = List<String>.generate(10, (index) {
      String strDay;

      dt = dt.add(Duration(days: 1));

      if (dt.weekday == DateTime.saturday) {
        dt = dt.add(Duration(days: 2));
      } else if (dt.weekday == DateTime.sunday) {
        dt = dt.add(Duration(days: 1));
      }

      if (index != 0 &&
          (dt.day == 1 ||
              (dt.day == 2 && dt.weekday == DateTime.monday) ||
              dt.day == 3 && dt.weekday == DateTime.monday)) {
        strDay = dt.month.toString() + "." + dt.day.toString();
      } else {
        strDay = dt.day.toString();
      }

      fullDateTime.add(dt);

      return strDay;
    });

    List<Color> btnConsultDateBgColors = List<Color>.filled(10, Colors.white);

    List<Color> btnConsultDateFontColors = List<Color>.filled(10, Colors.black);

    List<Color> btnConsultTimeBgColors = List<Color>.filled(8, Colors.white);

    List<Color> btnConsultTimeFontColors = List<Color>.filled(8, Colors.black);

    // ignore: non_constant_identifier_names
    var possible_days;

    // ignore: non_constant_identifier_names
    var possible_times;

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
                    return DropdownMenuItem(
                        value: e["empid"], child: Text(e["empname"]));
                  }).toList(),
                  value: selectedType,
                  onChanged: (value) async {
                    lastData["empid"] = value.toString();
                    lastData["reservationCode"] = null;
                    lastData["date"] = null;
                    lastData["time"] = null;

                    btnChatConsultBgColor = Colors.white;
                    btnVideoConsultBgColor = Colors.white;
                    btnVoiceConsultBgColor = Colors.white;
                    btnMeetConsultBgColor = Colors.white;

                    btnChatConsultFontColor = Colors.black;
                    btnVideoConsultFontColor = Colors.black;
                    btnVoiceConsultFontColor = Colors.black;
                    btnMeetConsultFontColor = Colors.black;

                    btnConsultDateBgColors =
                        List<Color>.filled(10, Colors.white);
                    btnConsultDateFontColors =
                        List<Color>.filled(10, Colors.black);

                    btnConsultTimeBgColors =
                        List<Color>.filled(8, Colors.white);
                    btnConsultTimeFontColors =
                        List<Color>.filled(8, Colors.black);

                    http.Response res = await http.Client().post(
                      Uri.parse(Domain.url + "user/get/schedule"),
                      headers: header,
                      body: {
                        'empid': value.toString(),
                      },
                    );

                    possible_days = jsonDecode(res.body);

                    possible_days.forEach((obj) {
                      // ignore: non_constant_identifier_names
                      int possible_day =
                          int.parse(obj["possible"].toString().split('-')[2]);
                      btnConsultDate.asMap().forEach((index, value) {
                        // ignore: non_constant_identifier_names
                        int consult_day;
                        if (value.contains('.'))
                          consult_day = int.parse(value.split('.')[1]);
                        else
                          consult_day = int.parse(value);

                        if (consult_day == possible_day) {
                          btnConsultDateFontColors[index] = Color(0xFF0275D7);
                        }
                      });
                    });

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
                            lastData["reservationCode"] = "1";
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
                            lastData["reservationCode"] = "2";
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
                            lastData["reservationCode"] = "3";
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
                            lastData["reservationCode"] = "4";
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
                          onPressed: () async {
                            if (btnConsultDateFontColors[0] ==
                                Color(0xFF0275D7)) {
                              lastData["date"] =
                                  fullDateTime[0].toString().split(' ')[0];

                              http.Response res = await http.Client().post(
                                Uri.parse(Domain.url + "user/get/times"),
                                headers: header,
                                body: {
                                  'empid': selectedType,
                                  'consultDate':
                                      fullDateTime[0].toString().split(' ')[0]
                                },
                              );

                              // ignore: non_constant_identifier_names
                              possible_times = jsonDecode(res.body);

                              setState(() {
                                btnConsultDateBgColors =
                                    List<Color>.filled(10, Colors.white);
                                btnConsultDateBgColors[0] = Color(0xFF0275D7);

                                possible_days.forEach((obj) {
                                  // ignore: non_constant_identifier_names
                                  int possible_day = int.parse(
                                      obj["possible"].toString().split('-')[2]);
                                  btnConsultDate
                                      .asMap()
                                      .forEach((index, value) {
                                    // ignore: non_constant_identifier_names
                                    int consult_day;
                                    if (value.contains('.'))
                                      consult_day =
                                          int.parse(value.split('.')[1]);
                                    else
                                      consult_day = int.parse(value);

                                    if (consult_day == possible_day) {
                                      btnConsultDateFontColors[index] =
                                          Color(0xFF0275D7);
                                    }
                                  });
                                });

                                btnConsultTimeBgColors =
                                    List<Color>.filled(8, Colors.white);
                                btnConsultTimeFontColors =
                                    List<Color>.filled(8, Colors.black);

                                possible_times.forEach((obj) {
                                  int time = int.parse(obj.toString());

                                  switch (time) {
                                    case 9:
                                      btnConsultTimeFontColors[0] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 10:
                                      btnConsultTimeFontColors[1] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 11:
                                      btnConsultTimeFontColors[2] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 13:
                                      btnConsultTimeFontColors[3] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 14:
                                      btnConsultTimeFontColors[4] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 15:
                                      btnConsultTimeFontColors[5] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 16:
                                      btnConsultTimeFontColors[6] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 17:
                                      btnConsultTimeFontColors[7] =
                                          Color(0xFF0275D7);
                                      break;
                                    default:
                                      break;
                                  }
                                });

                                btnConsultDateFontColors[0] = Colors.white;
                              });
                            }
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
                          onPressed: () async {
                            if (btnConsultDateFontColors[1] ==
                                Color(0xFF0275D7)) {
                              lastData["date"] =
                                  fullDateTime[1].toString().split(' ')[0];

                              http.Response res = await http.Client().post(
                                Uri.parse(Domain.url + "user/get/times"),
                                headers: header,
                                body: {
                                  'empid': selectedType,
                                  'consultDate':
                                      fullDateTime[1].toString().split(' ')[0]
                                },
                              );

                              // ignore: non_constant_identifier_names
                              possible_times = jsonDecode(res.body);

                              setState(() {
                                btnConsultDateBgColors =
                                    List<Color>.filled(10, Colors.white);
                                btnConsultDateBgColors[1] = Color(0xFF0275D7);

                                possible_days.forEach((obj) {
                                  // ignore: non_constant_identifier_names
                                  int possible_day = int.parse(
                                      obj["possible"].toString().split('-')[2]);
                                  btnConsultDate
                                      .asMap()
                                      .forEach((index, value) {
                                    // ignore: non_constant_identifier_names
                                    int consult_day;
                                    if (value.contains('.'))
                                      consult_day =
                                          int.parse(value.split('.')[1]);
                                    else
                                      consult_day = int.parse(value);

                                    if (consult_day == possible_day) {
                                      btnConsultDateFontColors[index] =
                                          Color(0xFF0275D7);
                                    }
                                  });
                                });

                                btnConsultTimeBgColors =
                                    List<Color>.filled(8, Colors.white);
                                btnConsultTimeFontColors =
                                    List<Color>.filled(8, Colors.black);

                                possible_times.forEach((obj) {
                                  int time = int.parse(obj.toString());

                                  switch (time) {
                                    case 9:
                                      btnConsultTimeFontColors[0] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 10:
                                      btnConsultTimeFontColors[1] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 11:
                                      btnConsultTimeFontColors[2] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 13:
                                      btnConsultTimeFontColors[3] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 14:
                                      btnConsultTimeFontColors[4] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 15:
                                      btnConsultTimeFontColors[5] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 16:
                                      btnConsultTimeFontColors[6] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 17:
                                      btnConsultTimeFontColors[7] =
                                          Color(0xFF0275D7);
                                      break;
                                    default:
                                      break;
                                  }
                                });

                                btnConsultDateFontColors[1] = Colors.white;
                              });
                            }
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
                          onPressed: () async {
                            if (btnConsultDateFontColors[2] ==
                                Color(0xFF0275D7)) {
                              lastData["date"] =
                                  fullDateTime[2].toString().split(' ')[0];

                              http.Response res = await http.Client().post(
                                Uri.parse(Domain.url + "user/get/times"),
                                headers: header,
                                body: {
                                  'empid': selectedType,
                                  'consultDate':
                                      fullDateTime[2].toString().split(' ')[0]
                                },
                              );

                              // ignore: non_constant_identifier_names
                              possible_times = jsonDecode(res.body);

                              setState(() {
                                btnConsultDateBgColors =
                                    List<Color>.filled(10, Colors.white);
                                btnConsultDateBgColors[2] = Color(0xFF0275D7);

                                possible_days.forEach((obj) {
                                  // ignore: non_constant_identifier_names
                                  int possible_day = int.parse(
                                      obj["possible"].toString().split('-')[2]);
                                  btnConsultDate
                                      .asMap()
                                      .forEach((index, value) {
                                    // ignore: non_constant_identifier_names
                                    int consult_day;
                                    if (value.contains('.'))
                                      consult_day =
                                          int.parse(value.split('.')[1]);
                                    else
                                      consult_day = int.parse(value);

                                    if (consult_day == possible_day) {
                                      btnConsultDateFontColors[index] =
                                          Color(0xFF0275D7);
                                    }
                                  });
                                });

                                btnConsultTimeBgColors =
                                    List<Color>.filled(8, Colors.white);
                                btnConsultTimeFontColors =
                                    List<Color>.filled(8, Colors.black);

                                possible_times.forEach((obj) {
                                  int time = int.parse(obj.toString());

                                  switch (time) {
                                    case 9:
                                      btnConsultTimeFontColors[0] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 10:
                                      btnConsultTimeFontColors[1] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 11:
                                      btnConsultTimeFontColors[2] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 13:
                                      btnConsultTimeFontColors[3] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 14:
                                      btnConsultTimeFontColors[4] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 15:
                                      btnConsultTimeFontColors[5] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 16:
                                      btnConsultTimeFontColors[6] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 17:
                                      btnConsultTimeFontColors[7] =
                                          Color(0xFF0275D7);
                                      break;
                                    default:
                                      break;
                                  }
                                });

                                btnConsultDateFontColors[2] = Colors.white;
                              });
                            }
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
                          onPressed: () async {
                            if (btnConsultDateFontColors[3] ==
                                Color(0xFF0275D7)) {
                              lastData["date"] =
                                  fullDateTime[3].toString().split(' ')[0];

                              http.Response res = await http.Client().post(
                                Uri.parse(Domain.url + "user/get/times"),
                                headers: header,
                                body: {
                                  'empid': selectedType,
                                  'consultDate':
                                      fullDateTime[3].toString().split(' ')[0]
                                },
                              );

                              // ignore: non_constant_identifier_names
                              possible_times = jsonDecode(res.body);

                              setState(() {
                                btnConsultDateBgColors =
                                    List<Color>.filled(10, Colors.white);
                                btnConsultDateBgColors[3] = Color(0xFF0275D7);

                                possible_days.forEach((obj) {
                                  // ignore: non_constant_identifier_names
                                  int possible_day = int.parse(
                                      obj["possible"].toString().split('-')[2]);
                                  btnConsultDate
                                      .asMap()
                                      .forEach((index, value) {
                                    // ignore: non_constant_identifier_names
                                    int consult_day;
                                    if (value.contains('.'))
                                      consult_day =
                                          int.parse(value.split('.')[1]);
                                    else
                                      consult_day = int.parse(value);

                                    if (consult_day == possible_day) {
                                      btnConsultDateFontColors[index] =
                                          Color(0xFF0275D7);
                                    }
                                  });
                                });

                                btnConsultTimeBgColors =
                                    List<Color>.filled(8, Colors.white);
                                btnConsultTimeFontColors =
                                    List<Color>.filled(8, Colors.black);

                                possible_times.forEach((obj) {
                                  int time = int.parse(obj.toString());

                                  switch (time) {
                                    case 9:
                                      btnConsultTimeFontColors[0] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 10:
                                      btnConsultTimeFontColors[1] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 11:
                                      btnConsultTimeFontColors[2] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 13:
                                      btnConsultTimeFontColors[3] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 14:
                                      btnConsultTimeFontColors[4] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 15:
                                      btnConsultTimeFontColors[5] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 16:
                                      btnConsultTimeFontColors[6] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 17:
                                      btnConsultTimeFontColors[7] =
                                          Color(0xFF0275D7);
                                      break;
                                    default:
                                      break;
                                  }
                                });

                                btnConsultDateFontColors[3] = Colors.white;
                              });
                            }
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
                          onPressed: () async {
                            if (btnConsultDateFontColors[4] ==
                                Color(0xFF0275D7)) {
                              lastData["date"] =
                                  fullDateTime[4].toString().split(' ')[0];

                              http.Response res = await http.Client().post(
                                Uri.parse(Domain.url + "user/get/times"),
                                headers: header,
                                body: {
                                  'empid': selectedType,
                                  'consultDate':
                                      fullDateTime[4].toString().split(' ')[0]
                                },
                              );

                              // ignore: non_constant_identifier_names
                              possible_times = jsonDecode(res.body);

                              setState(() {
                                btnConsultDateBgColors =
                                    List<Color>.filled(10, Colors.white);
                                btnConsultDateBgColors[4] = Color(0xFF0275D7);

                                possible_days.forEach((obj) {
                                  // ignore: non_constant_identifier_names
                                  int possible_day = int.parse(
                                      obj["possible"].toString().split('-')[2]);
                                  btnConsultDate
                                      .asMap()
                                      .forEach((index, value) {
                                    // ignore: non_constant_identifier_names
                                    int consult_day;
                                    if (value.contains('.'))
                                      consult_day =
                                          int.parse(value.split('.')[1]);
                                    else
                                      consult_day = int.parse(value);

                                    if (consult_day == possible_day) {
                                      btnConsultDateFontColors[index] =
                                          Color(0xFF0275D7);
                                    }
                                  });
                                });

                                btnConsultTimeBgColors =
                                    List<Color>.filled(8, Colors.white);
                                btnConsultTimeFontColors =
                                    List<Color>.filled(8, Colors.black);

                                possible_times.forEach((obj) {
                                  int time = int.parse(obj.toString());

                                  switch (time) {
                                    case 9:
                                      btnConsultTimeFontColors[0] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 10:
                                      btnConsultTimeFontColors[1] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 11:
                                      btnConsultTimeFontColors[2] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 13:
                                      btnConsultTimeFontColors[3] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 14:
                                      btnConsultTimeFontColors[4] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 15:
                                      btnConsultTimeFontColors[5] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 16:
                                      btnConsultTimeFontColors[6] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 17:
                                      btnConsultTimeFontColors[7] =
                                          Color(0xFF0275D7);
                                      break;
                                    default:
                                      break;
                                  }
                                });

                                btnConsultDateFontColors[4] = Colors.white;
                              });
                            }
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
                          onPressed: () async {
                            if (btnConsultDateFontColors[5] ==
                                Color(0xFF0275D7)) {
                              lastData["date"] =
                                  fullDateTime[5].toString().split(' ')[0];

                              http.Response res = await http.Client().post(
                                Uri.parse(Domain.url + "user/get/times"),
                                headers: header,
                                body: {
                                  'empid': selectedType,
                                  'consultDate':
                                      fullDateTime[5].toString().split(' ')[0]
                                },
                              );

                              // ignore: non_constant_identifier_names
                              possible_times = jsonDecode(res.body);

                              setState(() {
                                btnConsultDateBgColors =
                                    List<Color>.filled(10, Colors.white);
                                btnConsultDateBgColors[5] = Color(0xFF0275D7);

                                possible_days.forEach((obj) {
                                  // ignore: non_constant_identifier_names
                                  int possible_day = int.parse(
                                      obj["possible"].toString().split('-')[2]);
                                  btnConsultDate
                                      .asMap()
                                      .forEach((index, value) {
                                    // ignore: non_constant_identifier_names
                                    int consult_day;
                                    if (value.contains('.'))
                                      consult_day =
                                          int.parse(value.split('.')[1]);
                                    else
                                      consult_day = int.parse(value);

                                    if (consult_day == possible_day) {
                                      btnConsultDateFontColors[index] =
                                          Color(0xFF0275D7);
                                    }
                                  });
                                });

                                btnConsultTimeBgColors =
                                    List<Color>.filled(8, Colors.white);
                                btnConsultTimeFontColors =
                                    List<Color>.filled(8, Colors.black);

                                possible_times.forEach((obj) {
                                  int time = int.parse(obj.toString());

                                  switch (time) {
                                    case 9:
                                      btnConsultTimeFontColors[0] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 10:
                                      btnConsultTimeFontColors[1] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 11:
                                      btnConsultTimeFontColors[2] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 13:
                                      btnConsultTimeFontColors[3] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 14:
                                      btnConsultTimeFontColors[4] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 15:
                                      btnConsultTimeFontColors[5] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 16:
                                      btnConsultTimeFontColors[6] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 17:
                                      btnConsultTimeFontColors[7] =
                                          Color(0xFF0275D7);
                                      break;
                                    default:
                                      break;
                                  }
                                });

                                btnConsultDateFontColors[5] = Colors.white;
                              });
                            }
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
                          onPressed: () async {
                            if (btnConsultDateFontColors[6] ==
                                Color(0xFF0275D7)) {
                              lastData["date"] =
                                  fullDateTime[6].toString().split(' ')[0];

                              http.Response res = await http.Client().post(
                                Uri.parse(Domain.url + "user/get/times"),
                                headers: header,
                                body: {
                                  'empid': selectedType,
                                  'consultDate':
                                      fullDateTime[6].toString().split(' ')[0]
                                },
                              );

                              // ignore: non_constant_identifier_names
                              possible_times = jsonDecode(res.body);

                              setState(() {
                                btnConsultDateBgColors =
                                    List<Color>.filled(10, Colors.white);
                                btnConsultDateBgColors[6] = Color(0xFF0275D7);

                                possible_days.forEach((obj) {
                                  // ignore: non_constant_identifier_names
                                  int possible_day = int.parse(
                                      obj["possible"].toString().split('-')[2]);
                                  btnConsultDate
                                      .asMap()
                                      .forEach((index, value) {
                                    // ignore: non_constant_identifier_names
                                    int consult_day;
                                    if (value.contains('.'))
                                      consult_day =
                                          int.parse(value.split('.')[1]);
                                    else
                                      consult_day = int.parse(value);

                                    if (consult_day == possible_day) {
                                      btnConsultDateFontColors[index] =
                                          Color(0xFF0275D7);
                                    }
                                  });
                                });

                                btnConsultTimeBgColors =
                                    List<Color>.filled(8, Colors.white);
                                btnConsultTimeFontColors =
                                    List<Color>.filled(8, Colors.black);

                                possible_times.forEach((obj) {
                                  int time = int.parse(obj.toString());

                                  switch (time) {
                                    case 9:
                                      btnConsultTimeFontColors[0] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 10:
                                      btnConsultTimeFontColors[1] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 11:
                                      btnConsultTimeFontColors[2] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 13:
                                      btnConsultTimeFontColors[3] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 14:
                                      btnConsultTimeFontColors[4] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 15:
                                      btnConsultTimeFontColors[5] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 16:
                                      btnConsultTimeFontColors[6] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 17:
                                      btnConsultTimeFontColors[7] =
                                          Color(0xFF0275D7);
                                      break;
                                    default:
                                      break;
                                  }
                                });

                                btnConsultDateFontColors[6] = Colors.white;
                              });
                            }
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
                          onPressed: () async {
                            if (btnConsultDateFontColors[7] ==
                                Color(0xFF0275D7)) {
                              lastData["date"] =
                                  fullDateTime[7].toString().split(' ')[0];

                              http.Response res = await http.Client().post(
                                Uri.parse(Domain.url + "user/get/times"),
                                headers: header,
                                body: {
                                  'empid': selectedType,
                                  'consultDate':
                                      fullDateTime[7].toString().split(' ')[0]
                                },
                              );

                              // ignore: non_constant_identifier_names
                              possible_times = jsonDecode(res.body);

                              setState(() {
                                btnConsultDateBgColors =
                                    List<Color>.filled(10, Colors.white);
                                btnConsultDateBgColors[7] = Color(0xFF0275D7);

                                possible_days.forEach((obj) {
                                  // ignore: non_constant_identifier_names
                                  int possible_day = int.parse(
                                      obj["possible"].toString().split('-')[2]);
                                  btnConsultDate
                                      .asMap()
                                      .forEach((index, value) {
                                    // ignore: non_constant_identifier_names
                                    int consult_day;
                                    if (value.contains('.'))
                                      consult_day =
                                          int.parse(value.split('.')[1]);
                                    else
                                      consult_day = int.parse(value);

                                    if (consult_day == possible_day) {
                                      btnConsultDateFontColors[index] =
                                          Color(0xFF0275D7);
                                    }
                                  });
                                });

                                btnConsultTimeBgColors =
                                    List<Color>.filled(8, Colors.white);
                                btnConsultTimeFontColors =
                                    List<Color>.filled(8, Colors.black);

                                possible_times.forEach((obj) {
                                  int time = int.parse(obj.toString());

                                  switch (time) {
                                    case 9:
                                      btnConsultTimeFontColors[0] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 10:
                                      btnConsultTimeFontColors[1] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 11:
                                      btnConsultTimeFontColors[2] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 13:
                                      btnConsultTimeFontColors[3] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 14:
                                      btnConsultTimeFontColors[4] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 15:
                                      btnConsultTimeFontColors[5] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 16:
                                      btnConsultTimeFontColors[6] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 17:
                                      btnConsultTimeFontColors[7] =
                                          Color(0xFF0275D7);
                                      break;
                                    default:
                                      break;
                                  }
                                });

                                btnConsultDateFontColors[7] = Colors.white;
                              });
                            }
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
                          onPressed: () async {
                            if (btnConsultDateFontColors[8] ==
                                Color(0xFF0275D7)) {
                              lastData["date"] =
                                  fullDateTime[8].toString().split(' ')[0];

                              http.Response res = await http.Client().post(
                                Uri.parse(Domain.url + "user/get/times"),
                                headers: header,
                                body: {
                                  'empid': selectedType,
                                  'consultDate':
                                      fullDateTime[8].toString().split(' ')[0]
                                },
                              );

                              // ignore: non_constant_identifier_names
                              possible_times = jsonDecode(res.body);

                              setState(() {
                                btnConsultDateBgColors =
                                    List<Color>.filled(10, Colors.white);
                                btnConsultDateBgColors[8] = Color(0xFF0275D7);

                                possible_days.forEach((obj) {
                                  // ignore: non_constant_identifier_names
                                  int possible_day = int.parse(
                                      obj["possible"].toString().split('-')[2]);
                                  btnConsultDate
                                      .asMap()
                                      .forEach((index, value) {
                                    // ignore: non_constant_identifier_names
                                    int consult_day;
                                    if (value.contains('.'))
                                      consult_day =
                                          int.parse(value.split('.')[1]);
                                    else
                                      consult_day = int.parse(value);

                                    if (consult_day == possible_day) {
                                      btnConsultDateFontColors[index] =
                                          Color(0xFF0275D7);
                                    }
                                  });
                                });

                                btnConsultTimeBgColors =
                                    List<Color>.filled(8, Colors.white);
                                btnConsultTimeFontColors =
                                    List<Color>.filled(8, Colors.black);

                                possible_times.forEach((obj) {
                                  int time = int.parse(obj.toString());

                                  switch (time) {
                                    case 9:
                                      btnConsultTimeFontColors[0] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 10:
                                      btnConsultTimeFontColors[1] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 11:
                                      btnConsultTimeFontColors[2] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 13:
                                      btnConsultTimeFontColors[3] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 14:
                                      btnConsultTimeFontColors[4] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 15:
                                      btnConsultTimeFontColors[5] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 16:
                                      btnConsultTimeFontColors[6] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 17:
                                      btnConsultTimeFontColors[7] =
                                          Color(0xFF0275D7);
                                      break;
                                    default:
                                      break;
                                  }
                                });

                                btnConsultDateFontColors[8] = Colors.white;
                              });
                            }
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
                          onPressed: () async {
                            if (btnConsultDateFontColors[9] ==
                                Color(0xFF0275D7)) {
                              lastData["date"] =
                                  fullDateTime[9].toString().split(' ')[0];

                              http.Response res = await http.Client().post(
                                Uri.parse(Domain.url + "user/get/times"),
                                headers: header,
                                body: {
                                  'empid': selectedType,
                                  'consultDate':
                                      fullDateTime[9].toString().split(' ')[0]
                                },
                              );

                              // ignore: non_constant_identifier_names
                              possible_times = jsonDecode(res.body);

                              setState(() {
                                btnConsultDateBgColors =
                                    List<Color>.filled(10, Colors.white);
                                btnConsultDateBgColors[9] = Color(0xFF0275D7);

                                possible_days.forEach((obj) {
                                  // ignore: non_constant_identifier_names
                                  int possible_day = int.parse(
                                      obj["possible"].toString().split('-')[2]);
                                  btnConsultDate
                                      .asMap()
                                      .forEach((index, value) {
                                    // ignore: non_constant_identifier_names
                                    int consult_day;
                                    if (value.contains('.'))
                                      consult_day =
                                          int.parse(value.split('.')[1]);
                                    else
                                      consult_day = int.parse(value);

                                    if (consult_day == possible_day) {
                                      btnConsultDateFontColors[index] =
                                          Color(0xFF0275D7);
                                    }
                                  });
                                });

                                btnConsultTimeBgColors =
                                    List<Color>.filled(8, Colors.white);
                                btnConsultTimeFontColors =
                                    List<Color>.filled(8, Colors.black);

                                possible_times.forEach((obj) {
                                  int time = int.parse(obj.toString());

                                  switch (time) {
                                    case 9:
                                      btnConsultTimeFontColors[0] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 10:
                                      btnConsultTimeFontColors[1] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 11:
                                      btnConsultTimeFontColors[2] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 13:
                                      btnConsultTimeFontColors[3] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 14:
                                      btnConsultTimeFontColors[4] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 15:
                                      btnConsultTimeFontColors[5] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 16:
                                      btnConsultTimeFontColors[6] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 17:
                                      btnConsultTimeFontColors[7] =
                                          Color(0xFF0275D7);
                                      break;
                                    default:
                                      break;
                                  }
                                });

                                btnConsultDateFontColors[9] = Colors.white;
                              });
                            }
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
                            if (btnConsultTimeFontColors[0] ==
                                Color(0xFF0275D7)) {
                              lastData["time"] = "9";

                              setState(() {
                                btnConsultTimeBgColors =
                                    List<Color>.filled(8, Colors.white);
                                btnConsultTimeBgColors[0] = Color(0xFF0275D7);

                                btnConsultTimeFontColors =
                                    List<Color>.filled(8, Colors.black);

                                possible_times.forEach((obj) {
                                  int time = int.parse(obj.toString());

                                  switch (time) {
                                    case 9:
                                      btnConsultTimeFontColors[0] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 10:
                                      btnConsultTimeFontColors[1] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 11:
                                      btnConsultTimeFontColors[2] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 13:
                                      btnConsultTimeFontColors[3] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 14:
                                      btnConsultTimeFontColors[4] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 15:
                                      btnConsultTimeFontColors[5] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 16:
                                      btnConsultTimeFontColors[6] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 17:
                                      btnConsultTimeFontColors[7] =
                                          Color(0xFF0275D7);
                                      break;
                                    default:
                                      break;
                                  }
                                });

                                btnConsultTimeFontColors[0] = Colors.white;
                              });
                            }
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
                            if (btnConsultTimeFontColors[1] ==
                                Color(0xFF0275D7)) {
                              lastData["time"] = "10";

                              setState(() {
                                btnConsultTimeBgColors =
                                    List<Color>.filled(8, Colors.white);
                                btnConsultTimeBgColors[1] = Color(0xFF0275D7);

                                btnConsultTimeFontColors =
                                    List<Color>.filled(8, Colors.black);

                                possible_times.forEach((obj) {
                                  int time = int.parse(obj.toString());

                                  switch (time) {
                                    case 9:
                                      btnConsultTimeFontColors[0] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 10:
                                      btnConsultTimeFontColors[1] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 11:
                                      btnConsultTimeFontColors[2] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 13:
                                      btnConsultTimeFontColors[3] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 14:
                                      btnConsultTimeFontColors[4] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 15:
                                      btnConsultTimeFontColors[5] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 16:
                                      btnConsultTimeFontColors[6] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 17:
                                      btnConsultTimeFontColors[7] =
                                          Color(0xFF0275D7);
                                      break;
                                    default:
                                      break;
                                  }
                                });

                                btnConsultTimeFontColors[1] = Colors.white;
                              });
                            }
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
                            if (btnConsultTimeFontColors[2] ==
                                Color(0xFF0275D7)) {
                              lastData["time"] = "11";

                              setState(() {
                                btnConsultTimeBgColors =
                                    List<Color>.filled(8, Colors.white);
                                btnConsultTimeBgColors[2] = Color(0xFF0275D7);

                                btnConsultTimeFontColors =
                                    List<Color>.filled(8, Colors.black);

                                possible_times.forEach((obj) {
                                  int time = int.parse(obj.toString());

                                  switch (time) {
                                    case 9:
                                      btnConsultTimeFontColors[0] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 10:
                                      btnConsultTimeFontColors[1] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 11:
                                      btnConsultTimeFontColors[2] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 13:
                                      btnConsultTimeFontColors[3] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 14:
                                      btnConsultTimeFontColors[4] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 15:
                                      btnConsultTimeFontColors[5] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 16:
                                      btnConsultTimeFontColors[6] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 17:
                                      btnConsultTimeFontColors[7] =
                                          Color(0xFF0275D7);
                                      break;
                                    default:
                                      break;
                                  }
                                });

                                btnConsultTimeFontColors[2] = Colors.white;
                              });
                            }
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
                            if (btnConsultTimeFontColors[3] ==
                                Color(0xFF0275D7)) {
                              lastData["time"] = "13";

                              setState(() {
                                btnConsultTimeBgColors =
                                    List<Color>.filled(8, Colors.white);
                                btnConsultTimeBgColors[3] = Color(0xFF0275D7);

                                btnConsultTimeFontColors =
                                    List<Color>.filled(8, Colors.black);

                                possible_times.forEach((obj) {
                                  int time = int.parse(obj.toString());

                                  switch (time) {
                                    case 9:
                                      btnConsultTimeFontColors[0] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 10:
                                      btnConsultTimeFontColors[1] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 11:
                                      btnConsultTimeFontColors[2] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 13:
                                      btnConsultTimeFontColors[3] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 14:
                                      btnConsultTimeFontColors[4] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 15:
                                      btnConsultTimeFontColors[5] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 16:
                                      btnConsultTimeFontColors[6] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 17:
                                      btnConsultTimeFontColors[7] =
                                          Color(0xFF0275D7);
                                      break;
                                    default:
                                      break;
                                  }
                                });

                                btnConsultTimeFontColors[3] = Colors.white;
                              });
                            }
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
                            if (btnConsultTimeFontColors[4] ==
                                Color(0xFF0275D7)) {
                              lastData["time"] = "14";

                              setState(() {
                                btnConsultTimeBgColors =
                                    List<Color>.filled(8, Colors.white);
                                btnConsultTimeBgColors[4] = Color(0xFF0275D7);

                                btnConsultTimeFontColors =
                                    List<Color>.filled(8, Colors.black);

                                possible_times.forEach((obj) {
                                  int time = int.parse(obj.toString());

                                  switch (time) {
                                    case 9:
                                      btnConsultTimeFontColors[0] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 10:
                                      btnConsultTimeFontColors[1] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 11:
                                      btnConsultTimeFontColors[2] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 13:
                                      btnConsultTimeFontColors[3] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 14:
                                      btnConsultTimeFontColors[4] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 15:
                                      btnConsultTimeFontColors[5] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 16:
                                      btnConsultTimeFontColors[6] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 17:
                                      btnConsultTimeFontColors[7] =
                                          Color(0xFF0275D7);
                                      break;
                                    default:
                                      break;
                                  }
                                });

                                btnConsultTimeFontColors[4] = Colors.white;
                              });
                            }
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
                            if (btnConsultTimeFontColors[5] ==
                                Color(0xFF0275D7)) {
                              lastData["time"] = "15";

                              setState(() {
                                btnConsultTimeBgColors =
                                    List<Color>.filled(8, Colors.white);
                                btnConsultTimeBgColors[5] = Color(0xFF0275D7);

                                btnConsultTimeFontColors =
                                    List<Color>.filled(8, Colors.black);

                                possible_times.forEach((obj) {
                                  int time = int.parse(obj.toString());

                                  switch (time) {
                                    case 9:
                                      btnConsultTimeFontColors[0] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 10:
                                      btnConsultTimeFontColors[1] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 11:
                                      btnConsultTimeFontColors[2] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 13:
                                      btnConsultTimeFontColors[3] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 14:
                                      btnConsultTimeFontColors[4] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 15:
                                      btnConsultTimeFontColors[5] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 16:
                                      btnConsultTimeFontColors[6] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 17:
                                      btnConsultTimeFontColors[7] =
                                          Color(0xFF0275D7);
                                      break;
                                    default:
                                      break;
                                  }
                                });

                                btnConsultTimeFontColors[5] = Colors.white;
                              });
                            }
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
                            if (btnConsultTimeFontColors[6] ==
                                Color(0xFF0275D7)) {
                              lastData["time"] = "16";

                              setState(() {
                                btnConsultTimeBgColors =
                                    List<Color>.filled(8, Colors.white);
                                btnConsultTimeBgColors[6] = Color(0xFF0275D7);

                                btnConsultTimeFontColors =
                                    List<Color>.filled(8, Colors.black);

                                possible_times.forEach((obj) {
                                  int time = int.parse(obj.toString());

                                  switch (time) {
                                    case 9:
                                      btnConsultTimeFontColors[0] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 10:
                                      btnConsultTimeFontColors[1] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 11:
                                      btnConsultTimeFontColors[2] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 13:
                                      btnConsultTimeFontColors[3] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 14:
                                      btnConsultTimeFontColors[4] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 15:
                                      btnConsultTimeFontColors[5] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 16:
                                      btnConsultTimeFontColors[6] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 17:
                                      btnConsultTimeFontColors[7] =
                                          Color(0xFF0275D7);
                                      break;
                                    default:
                                      break;
                                  }
                                });

                                btnConsultTimeFontColors[6] = Colors.white;
                              });
                            }
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
                            if (btnConsultTimeFontColors[7] ==
                                Color(0xFF0275D7)) {
                              lastData["time"] = "17";

                              setState(() {
                                btnConsultTimeBgColors =
                                    List<Color>.filled(8, Colors.white);
                                btnConsultTimeBgColors[7] = Color(0xFF0275D7);

                                btnConsultTimeFontColors =
                                    List<Color>.filled(8, Colors.black);

                                possible_times.forEach((obj) {
                                  int time = int.parse(obj.toString());

                                  switch (time) {
                                    case 9:
                                      btnConsultTimeFontColors[0] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 10:
                                      btnConsultTimeFontColors[1] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 11:
                                      btnConsultTimeFontColors[2] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 13:
                                      btnConsultTimeFontColors[3] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 14:
                                      btnConsultTimeFontColors[4] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 15:
                                      btnConsultTimeFontColors[5] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 16:
                                      btnConsultTimeFontColors[6] =
                                          Color(0xFF0275D7);
                                      break;
                                    case 17:
                                      btnConsultTimeFontColors[7] =
                                          Color(0xFF0275D7);
                                      break;
                                    default:
                                      break;
                                  }
                                });

                                btnConsultTimeFontColors[7] = Colors.white;
                              });
                            }
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
                    if (lastData["empid"] == null ||
                        lastData["empid"] == "null") {
                      openDescription(
                          context, "유한누리", "상담 선생님을 선택해 주세요.", false);
                    } else if (lastData["reservationCode"] == null) {
                      openDescription(
                          context, "유한누리", "상담 유형을 선택해 주세요.", false);
                    } else if (lastData["date"] == null) {
                      openDescription(
                          context, "유한누리", "상담 날짜를 선택해 주세요.", false);
                    } else if (lastData["time"] == null) {
                      openDescription(
                          context, "유한누리", "상담 시간을 선택해 주세요.", false);
                    } else {
                      setState(() {
                        pageController.nextPage(
                            duration: Duration(milliseconds: 1000),
                            curve: Curves.fastLinearToSlowEaseIn);
                      });
                    }
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

  Future<Widget> selfCheckPage() async {
    http.Response res = await http.Client().get(
      Uri.parse(Domain.url + "user/get/selfcheck"),
      headers: header,
    );

    Map selfcheckAnswers = {};

    List<Widget> selfcheckList = [];

    lastData["selfcheckCode"] = [];
    lastData["selfcheckNum"] = [];

    jsonDecode(res.body).forEach((obj) {
      lastData["selfcheckCode"].add(obj["checkno"].toString());
      lastData["selfcheckNum"].add(0);

      selfcheckList.add(
          selfcheck(obj["checkno"].toString(), obj["checkname"].toString()));

      selfcheckAnswers[obj["checkno"].toString()] = "";
    });

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
                      if (lastData["selfcheckNum"].indexOf(0) == -1) {
                        setState(() {
                          pageController.nextPage(
                            duration: Duration(milliseconds: 1000),
                            curve: Curves.fastLinearToSlowEaseIn,
                          );
                        });
                      } else {
                        openDescription(
                            context, "유한누리", "답변하지 않은 질문이 있습니다.", false);
                      }
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

  Future<Widget> privacyPage() async {
    String agree1 = "assets/btnCheck-off.png";
    String agree2 = "assets/btnCheck-off.png";
    String agree3 = "assets/btnCheck-off.png";
    String agree4 = "assets/btnCheck-off.png";
    String agree5 = "assets/btnCheck-off.png";

    List<int> privacySum = [0, 0, 0, 0];

    return StatefulBuilder(builder: (context, StateSetter setState) {
      return SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.fromLTRB(10, 15, 10, 13),
          child: Column(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    if (privacySum[0] == 0) {
                      agree1 = "assets/btnCheck-on.png";
                      privacySum[0] = 1;
                    } else {
                      agree1 = "assets/btnCheck-off.png";
                      privacySum[0] = 0;
                    }

                    if (privacySum.reduce((a, b) => a + b) == 4)
                      agree5 = "assets/btnCheck-on.png";
                    else
                      agree5 = "assets/btnCheck-off.png";
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
                    if (privacySum[1] == 0) {
                      agree2 = "assets/btnCheck-on.png";
                      privacySum[1] = 1;
                    } else {
                      agree2 = "assets/btnCheck-off.png";
                      privacySum[1] = 0;
                    }

                    if (privacySum.reduce((a, b) => a + b) == 4)
                      agree5 = "assets/btnCheck-on.png";
                    else
                      agree5 = "assets/btnCheck-off.png";
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
                    if (privacySum[2] == 0) {
                      agree3 = "assets/btnCheck-on.png";
                      privacySum[2] = 1;
                    } else {
                      agree3 = "assets/btnCheck-off.png";
                      privacySum[2] = 0;
                    }

                    if (privacySum.reduce((a, b) => a + b) == 4)
                      agree5 = "assets/btnCheck-on.png";
                    else
                      agree5 = "assets/btnCheck-off.png";
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
                    if (privacySum[3] == 0) {
                      agree4 = "assets/btnCheck-on.png";
                      privacySum[3] = 1;
                    } else {
                      agree4 = "assets/btnCheck-off.png";
                      privacySum[3] = 0;
                    }

                    if (privacySum.reduce((a, b) => a + b) == 4)
                      agree5 = "assets/btnCheck-on.png";
                    else
                      agree5 = "assets/btnCheck-off.png";
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
                    if (privacySum.reduce((a, b) => a + b) != 4) {
                      agree1 = "assets/btnCheck-on.png";
                      agree2 = "assets/btnCheck-on.png";
                      agree3 = "assets/btnCheck-on.png";
                      agree4 = "assets/btnCheck-on.png";
                      agree5 = "assets/btnCheck-on.png";

                      for (var i = 0; i < privacySum.length; i++) {
                        privacySum[i] = 1;
                      }
                    } else {
                      agree1 = "assets/btnCheck-off.png";
                      agree2 = "assets/btnCheck-off.png";
                      agree3 = "assets/btnCheck-off.png";
                      agree4 = "assets/btnCheck-off.png";
                      agree5 = "assets/btnCheck-off.png";

                      for (var i = 0; i < privacySum.length; i++) {
                        privacySum[i] = 0;
                      }
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
                      "상위 유한누리 이용 약관에 모두 동의합니다.",
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
                  onPressed: () async {
                    if (privacySum.reduce((a, b) => a + b) == 4) {
                      header["Content-Type"] = "application/json";
                      await http.Client().post(
                        Uri.parse(Domain.url + "user/set/reservation"),
                        headers: header,
                        body: json.encode(lastData),
                      );
                      header["Content-Type"] =
                          "application/x-www-form-urlencoded; charset=UTF-8";

                      openDescription(
                          context, "유한누리", "예약이 완료되었습니다, 감사합니다.", true);
                    } else {
                      openDescription(context, "유한누리",
                          "이용 약관에 모두 동의해야 예약을\n완료할 수 있습니다.", false);
                    }
                  },
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

  Widget unreservation(var data) {
    return StatefulBuilder(builder: (context, StateSetter setState) {
      if (data[0]["typeno"] == null) {
        List<String> testList = [];
        for (int i = 0; i < data.length; i++) {
          testList.add(data[i]["testname"].toString());
        }
        Widget status;
        Widget btnUnreserv;
        if (int.parse(data[0]["status"].toString()) == 0 &&
            int.parse(data[0]["finished"].toString()) == 0 &&
            int.parse(data[0]["research"].toString()) == 0) {
          status = Row(
            children: [
              Text(
                "접수 중",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: Colors.red,
                ),
              ),
              Text(
                " (확정 시 '완료'로 변경)",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey,
                ),
              )
            ],
          );
          btnUnreserv = Container(
            margin: EdgeInsets.only(top: 10, right: 10),
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () async {
                http.Response res = await http.Client().post(
                  Uri.parse(Domain.url + "user/set/cancel"),
                  headers: header,
                  body: {
                    "serialno": data[0]["serialno"].toString(),
                  },
                );
                var recv = jsonDecode(res.body);
                if (recv["isComplete"]) {
                  IO.Socket socket =
                      IO.io(Domain.url + "reaction", <String, dynamic>{
                    'transports': ['websocket'],
                  });
                  socket.onConnect((_) {
                    socket.emit('cancel', data[0]["serialno"].toString());
                  });
                  socket.onDisconnect((_) => {});
                  openDescription(context, "유한누리", "취소가 완료되었습니다.", true);
                } else
                  openDescription(context, "유한누리", "이미 완료되었거나 취소되었습니다.", true);
              },
              child: Text(
                "취 소",
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.red[700],
              ),
            ),
          );
        } else if (int.parse(data[0]["status"].toString()) == 1 &&
            int.parse(data[0]["finished"].toString()) == 0 &&
            int.parse(data[0]["research"].toString()) == 0) {
          status = Text(
            "접수 완료",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.normal,
              color: Colors.green,
            ),
          );
        } else if (int.parse(data[0]["status"].toString()) == 1 &&
            int.parse(data[0]["finished"].toString()) == 1 &&
            int.parse(data[0]["research"].toString()) == 0) {
          status = Text(
            "검사 완료",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.normal,
              color: Color(0xFF0275D7),
            ),
          );

          btnUnreserv = Container(
            margin: EdgeInsets.only(top: 10, right: 10),
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => satisfactionDialog(context),
              child: Text(
                "만족도조사",
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFF0275D7),
              ),
            ),
          );
        }
        return Container(
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
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      children: [
                        Container(
                          padding: EdgeInsets.fromLTRB(20, 20, 0, 10),
                          child: Text(
                            "상담유형",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.fromLTRB(20, 20, 0, 10),
                          child: Text(
                            "심리검사",
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
                            "검사목록",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.fromLTRB(20, 10, 0, 10),
                          child: Text(
                            testList.join(", "),
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
                            "접수현황",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.fromLTRB(20, 10, 0, 20),
                          child: status,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (btnUnreserv != null) btnUnreserv,
            ],
          ),
        );
      } else {
        List<String> strDate = data[0]["date"].toString().split('-');
        String strTime;
        if (int.parse(data[0]["starttime"].toString()) < 12) {
          strTime = "오전 ${data[0]["starttime"].toString()}시";
        } else {
          strTime = "오후 ${int.parse(data[0]["starttime"].toString()) - 12}시";
        }
        Widget status;
        Widget btnUnreserv;
        if (int.parse(data[0]["status"].toString()) == 0 &&
            int.parse(data[0]["finished"].toString()) == 0 &&
            int.parse(data[0]["research"].toString()) == 0) {
          status = Row(
            children: [
              Text(
                "접수 중",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: Colors.red,
                ),
              ),
              Text(
                " (확정 시 '완료'로 변경)",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey,
                ),
              )
            ],
          );

          btnUnreserv = Container(
            margin: EdgeInsets.only(top: 10, right: 10),
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () async {
                http.Response res = await http.Client().post(
                  Uri.parse(Domain.url + "user/set/cancel"),
                  headers: header,
                  body: {
                    "serialno": data[0]["serialno"].toString(),
                  },
                );
                var recv = jsonDecode(res.body);
                if (recv["isComplete"]) {
                  IO.Socket socket =
                      IO.io(Domain.url + "reaction", <String, dynamic>{
                    'transports': ['websocket'],
                  });
                  socket.onConnect((_) {
                    socket.emit('cancel', data[0]["serialno"].toString());
                  });
                  socket.onDisconnect((_) => {});
                  openDescription(context, "유한누리", "취소가 완료되었습니다.", true);
                } else
                  openDescription(context, "유한누리", "이미 완료되었거나 취소되었습니다.", true);
              },
              child: Text(
                "취 소",
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.red[700],
              ),
            ),
          );
        } else if (int.parse(data[0]["status"].toString()) == 1 &&
            int.parse(data[0]["finished"].toString()) == 0 &&
            int.parse(data[0]["research"].toString()) == 0) {
          status = Text(
            "접수 완료",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.normal,
              color: Colors.green,
            ),
          );
        } else if (int.parse(data[0]["status"].toString()) == 1 &&
            int.parse(data[0]["finished"].toString()) == 1 &&
            int.parse(data[0]["research"].toString()) == 0) {
          status = Text(
            "상담 완료",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.normal,
              color: Color(0xFF0275D7),
            ),
          );

          btnUnreserv = Container(
            margin: EdgeInsets.only(top: 10, right: 10),
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => satisfactionDialog(context),
              child: Text(
                "만족도조사",
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFF0275D7),
              ),
            ),
          );
        }

        return Container(
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
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      children: [
                        Container(
                          padding: EdgeInsets.fromLTRB(20, 20, 0, 10),
                          child: Text(
                            "상담유형",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.fromLTRB(20, 20, 0, 10),
                          child: Text(
                            data[0]["typename"],
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
                            "상담사명",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.fromLTRB(20, 10, 0, 10),
                          child: Text(
                            data[0]["empname"],
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
                            "예약날짜",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.fromLTRB(20, 10, 0, 10),
                          child: Text(
                            "${strDate[0]}년 ${strDate[1]}월 ${strDate[2]}일",
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
                            "시작시간",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.fromLTRB(20, 10, 0, 10),
                          child: Text(
                            strTime,
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
                            "접수현황",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.fromLTRB(20, 10, 0, 20),
                          child: status,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (btnUnreserv != null) btnUnreserv,
            ],
          ),
        );
      }
    });
  }

  Future<void> getInit() async {
    consultInquiries.clear();
    psychoInquiries.clear();
    psychoTestList.clear();

    http.Response res = await http.Client().get(
      Uri.parse(Domain.url + "user/get/reservation"),
      headers: header,
    );

    var recv = jsonDecode(res.body);

    if (recv["isPossible"]) {
      recv["consultAsk"].forEach((obj) {
        if (obj["choices"].toString() == "null") {
          consultInquiries.add(inquiry(int.parse(obj["askno"].toString()),
              obj["choicetypename"].toString(), obj["ask"].toString(), null));
        } else {
          consultInquiries.add(inquiry(
              int.parse(obj["askno"].toString()),
              obj["choicetypename"].toString(),
              obj["ask"].toString(),
              obj["choices"].toString().split('|')));
        }
      });

      recv["testAsk"].forEach((obj) {
        if (obj["choices"].toString() == "null") {
          psychoInquiries.add(inquiry(int.parse(obj["askno"].toString()),
              obj["choicetypename"].toString(), obj["ask"].toString(), null));
        } else {
          psychoInquiries.add(inquiry(
              int.parse(obj["askno"].toString()),
              obj["choicetypename"].toString(),
              obj["ask"].toString(),
              obj["choices"].toString().split('|')));
        }
      });

      recv["psyTestList"].forEach((obj) {
        psychoTestList.add(psychoTest(int.parse(obj["testno"].toString()),
            obj["testname"].toString(), obj["description"].toString()));
      });

      pageList.add(inquiryPage());
    } else {
      pageList.add(unreservation(recv["data"]));
    }
  }

  Widget psychoBuild() {
    return StatefulBuilder(builder: (context, StateSetter setState) {
      return Column(
        children: [
          Column(
            children: psychoInquiries,
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
              onPressed: () async {
                if (tempSelectedAnswers.length != initCheckNum) {
                  openDescription(context, "유한누리", "답변하지 않은 질문이 있습니다.", false);
                } else {
                  if (tempSelectedPsyTest.length == 0) {
                    openDescription(
                        context, "유한누리", "심리검사를 하나 이상 선택하세요.", false);
                  } else {
                    lastData["stuAnswer"] = [];
                    tempSelectedAnswers.forEach((key, value) {
                      lastData["stuAnswer"]
                          .add({"question": key, "answer": value});
                    });
                    lastData["psyTestList"] = tempSelectedPsyTest;
                    setState(() {
                      pageController.nextPage(
                          duration: Duration(milliseconds: 1000),
                          curve: Curves.fastLinearToSlowEaseIn);
                    });
                  }
                }
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
    return StatefulBuilder(builder: (context, StateSetter setState) {
      return Column(
        children: [
          Column(
            children: consultInquiries,
          ),
          Container(
            margin: EdgeInsets.only(right: 15),
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () async {
                if (tempSelectedAnswers.length != initCheckNum) {
                  openDescription(context, "유한누리", "답변하지 않은 질문이 있습니다.", false);
                } else {
                  lastData["stuAnswer"] = [];
                  tempSelectedAnswers.forEach((key, value) {
                    lastData["stuAnswer"]
                        .add({"question": key, "answer": value});
                  });
                  pageController.nextPage(
                      duration: Duration(milliseconds: 1000),
                      curve: Curves.fastLinearToSlowEaseIn);
                }
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

  Widget psychoTest(int no, String title, String description) {
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
                  if (value)
                    tempSelectedPsyTest.add(no);
                  else
                    tempSelectedPsyTest.remove(no);

                  setState(() {
                    _value = value;
                  });
                },
              ),
              Text(title),
            ],
          ),
          TextButton(
            onPressed: () {
              setState(() {
                openDescription(context, title, description, false);
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

  Widget inquiry(int no, String type, String title, List<String> options) {
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
                    title,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                RadioButtonGroup(
                  labels: options,
                  picked: _radio,
                  onSelected: (String selected) => setState(() {
                    tempSelectedAnswers[no] = selected;
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
                    title,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                CheckboxGroup(
                  labels: options,
                  checked: _check,
                  onSelected: (List selected) => setState(() {
                    var str = selected.toString().replaceAll(', ', ',');
                    var bracket = str.substring(1, str.length - 1);
                    tempSelectedAnswers[no] = bracket;
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
        TextEditingController textEditingController = TextEditingController();
        String txt = "";
        temp = StatefulBuilder(builder: (context, StateSetter setState) {
          textEditingController.text = txt.trim().isEmpty ? "" : txt.trim();
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
                    title,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(left: 15, right: 15),
                  child: TextField(
                    controller: textEditingController,
                    decoration: InputDecoration(
                      hintText: "자유롭게 작성해 주세요.",
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                    onChanged: (value) {
                      txt = value;
                      tempSelectedAnswers[no] = value;
                    },
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

  Widget selfcheck(String checkno, String checkname) {
    String _radio;
    List<String> options = ["매우 나쁨", "나쁨", "보통", "좋음", "매우 좋음"];
    return StatefulBuilder(builder: (context, StateSetter setState) {
      return Center(
        child: Container(
          margin: EdgeInsets.only(top: 25),
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              Text(
                checkname,
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
                  labels: options,
                  picked: _radio,
                  onSelected: (String selected) => setState(() {
                    var idx = lastData["selfcheckCode"].indexOf(checkno);
                    var score = options.indexOf(selected);
                    lastData["selfcheckNum"][idx] = score + 1;
                    _radio = selected;
                  }),
                  itemBuilder: (radioButton, label, index) {
                    return Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(left: 10, right: 10),
                          child:
                              Transform.scale(scale: 2.0, child: radioButton),
                        ),
                        label,
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void openDescription(
      BuildContext context, String title, String msg, bool isRebuild) {
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
                if (isRebuild) parentKey.currentState.setPage(1);
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

  void satisfactionDialog(BuildContext _context) async {
    tempSelectedAnswers.clear();

    List<Widget> surveyList = [];

    Map<String, dynamic> surveyData = {"serialno": null, "dataList": []};

    http.Response res = await http.Client().get(
      Uri.parse(Domain.url + "user/get/satisfaction"),
      headers: header,
    );

    var recv = jsonDecode(res.body);

    surveyData["serialno"] = recv["serial"][0]["serialno"];

    recv["testAsk"].forEach((obj) {
      if (obj["choices"].toString() == "null") {
        surveyList.add(inquiry(int.parse(obj["askno"].toString()),
            obj["choicetypename"].toString(), obj["ask"].toString(), null));
      } else {
        surveyList.add(inquiry(
          int.parse(obj["askno"].toString()),
          obj["choicetypename"].toString(),
          obj["ask"].toString(),
          obj["choices"].toString().split('|'),
        ));
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
        ctx = context;
        final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0.0, curvedValue * -200, 0.0),
          child: Opacity(
            opacity: a1.value,
            child: StatefulBuilder(builder: (context, StateSetter _setState) {
              return new WillPopScope(
                onWillPop: () => closeSatisfaction(context),
                child: Scaffold(
                  appBar: AppBar(
                    backgroundColor: Color(0xFF0073D7),
                    toolbarHeight: 50,
                    title: new Text("만족도조사",
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
                          padding: EdgeInsets.only(bottom: 15),
                          child: Column(
                            children: [
                              Container(
                                child: Column(
                                  children: surveyList,
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(right: 15),
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (surveyList.length ==
                                        tempSelectedAnswers.length) {
                                      tempSelectedAnswers.forEach((key, value) {
                                        surveyData["dataList"].add(
                                            {"question": key, "answer": value});
                                      });

                                      header["Content-Type"] =
                                          "application/json";
                                      await http.Client().post(
                                        Uri.parse(Domain.url +
                                            "user/set/satisfaction"),
                                        headers: header,
                                        body: json.encode(surveyData),
                                      );
                                      header["Content-Type"] =
                                          "application/x-www-form-urlencoded; charset=UTF-8";

                                      FocusScope.of(context).unfocus();

                                      Navigator.pop(context, true);

                                      openDescription(context, "유한누리",
                                          "조사에 참여해 주셔서 감사합니다.", true);
                                    } else {
                                      openDescription(_context, "유한누리",
                                          "답변하지 않은 질문이 있습니다.", false);
                                    }
                                  },
                                  child: Text(
                                    "완 료",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 17),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    primary: Color(0xFF0275D7),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
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

  Future<bool> closeSatisfaction(BuildContext _context) {
    Vibration.vibrate();
    return showDialog(
      context: _context,
      builder: (context) {
        FocusScope.of(context).unfocus();
        return AlertDialog(
          title: Text("유한누리"),
          content: Text('만족도조사를 종료하시겠습니까?'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
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
}
