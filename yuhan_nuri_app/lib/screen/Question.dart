import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import 'Domain.dart';

class Question {
  Map<String, String> header;

  static List<String> typeList = ["시스템 문의", "상담 문의"];
  String selectedType = typeList[0];

  TextEditingController _title = TextEditingController();
  TextEditingController _content = TextEditingController();
  ScrollController _scroll = ScrollController();

  BuildContext ctx;

  Future<Widget> getBuild(Map<String, String> _header) async {
    header = _header;

    return StatefulBuilder(builder: (context, StateSetter setState) {
      ctx = context;

      void alertDialog(String message) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("유한누리"),
              content: Text(message),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                    FocusScope.of(context).unfocus();
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

      return NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (OverscrollIndicatorNotification overscroll) {
          overscroll.disallowGlow();
          return;
        },
        child: SingleChildScrollView(
          controller: _scroll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(40, 30, 40, 20),
                  child: Text(
                    "무엇이든 물어보세요!",
                    style: TextStyle(
                      fontSize: 25,
                      fontFamily: 'jua',
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "문의 유형",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
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
                        onTap: () => FocusScope.of(context)
                            .requestFocus(new FocusNode()),
                        onChanged: (value) {
                          setState(() {
                            selectedType = value;
                          });
                        },
                      ),
                    ),
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
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextField(
                      controller: _title,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "제목을 입력해 주세요."),
                      onTap: () {
                        _scroll.jumpTo(0);
                      },
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
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextField(
                      controller: _content,
                      maxLines: 11,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "내용을 입력해 주세요."),
                      onTap: () {
                        Timer(Duration(milliseconds: 300), () {
                          _scroll.animateTo(_scroll.offset + 500,
                              duration: Duration(milliseconds: 3000),
                              curve: Curves.fastLinearToSlowEaseIn);
                        });
                      },
                    )
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: 15, bottom: 10),
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    if (_title.value.text.trim().isEmpty) {
                      Vibration.vibrate();
                      alertDialog("반드시 제목을 입력해야 합니다.");
                      return;
                    } else if (_content.value.text.trim().isEmpty) {
                      Vibration.vibrate();
                      alertDialog("반드시 내용을 입력해야 합니다.");
                      return;
                    } else {
                      http.Client().post(
                        Uri.parse(Domain.url + "user/set/question"),
                        headers: header,
                        body: {
                          'type': selectedType.replaceAll(" 문의", ""),
                          'title': _title.value.text.trim(),
                          'content': _content.value.text.trim(),
                        },
                      );

                      alertDialog("문의가 정상적으로 등록되었습니다.");

                      setState(() {
                        selectedType = typeList[0];
                        _title.clear();
                        _content.clear();
                      });
                    }
                  },
                  child: Text(
                    "등 록",
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
}
