import 'dart:async';
import 'package:flutter/material.dart';

class Question {
  static List<String> typeList = ["시스템 문의", "상담 문의"];
  String selectedType = typeList[0];

  TextEditingController _title = TextEditingController();
  TextEditingController _content = TextEditingController();
  ScrollController _scroll = ScrollController();

  Widget getBuild() {
    return StatefulBuilder(builder: (context, StateSetter setState) {
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
                          border: OutlineInputBorder(), hintText: "제목을 입력하세요."),
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
                          border: OutlineInputBorder(), hintText: "내용을 입력하세요."),
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
                child: RaisedButton(
                  child: Text(
                    "등 록",
                    style: TextStyle(color: Colors.white, fontSize: 17),
                  ),
                  color: Color(0xFF0275D7),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  onPressed: () {
                    print(
                        'selected : $selectedType \ntitle : ${_title.value.text}\ncontent : ${_content.value.text}');
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
