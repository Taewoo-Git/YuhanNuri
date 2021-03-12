import 'package:flutter/material.dart';
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FlatButton(
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
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      FlatButton(
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
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
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
    return StatefulBuilder(builder: (context, StateSetter setState) {
      return SizedBox.expand(
        child: Container(
          color: Colors.yellow,
          child: Center(
            child: RaisedButton(
              child: Text("스케줄 확인"),
              onPressed: () {
                setState(() {
                  pageController.nextPage(
                      duration: Duration(milliseconds: 1000),
                      curve: Curves.fastLinearToSlowEaseIn);
                });
              },
            ),
          ),
        ),
      );
    });
  }

  Widget selfCheckPage() {
    return StatefulBuilder(builder: (context, StateSetter setState) {
      return SizedBox.expand(
        child: Container(
          color: Colors.green,
          child: Center(
            child: RaisedButton(
              child: Text("자가 진단"),
              onPressed: () {
                setState(() {
                  pageController.nextPage(
                      duration: Duration(milliseconds: 1000),
                      curve: Curves.fastLinearToSlowEaseIn);
                });
              },
            ),
          ),
        ),
      );
    });
  }

  Widget privacyPage() {
    return StatefulBuilder(builder: (context, StateSetter setState) {
      return SizedBox.expand(
        child: Container(
          color: Colors.blue,
          child: Center(
            child: RaisedButton(
              child: Text("개인정보 제공 동의"),
              onPressed: () {
                setState(() {
                  pageController.animateToPage(0,
                      duration: Duration(milliseconds: 1000),
                      curve: Curves.fastLinearToSlowEaseIn);
                });
              },
            ),
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
            child: RaisedButton(
              child: Text(
                "다 음",
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
              color: Color(0xFF0275D7),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              onPressed: () {
                setState(() {
                  pageController.nextPage(
                      duration: Duration(milliseconds: 1000),
                      curve: Curves.fastLinearToSlowEaseIn);
                });
              },
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
            child: RaisedButton(
              child: Text(
                "다 음",
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
              color: Color(0xFF0275D7),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              onPressed: () {
                setState(() {
                  pageController.nextPage(
                      duration: Duration(milliseconds: 1000),
                      curve: Curves.fastLinearToSlowEaseIn);
                });
              },
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
          FlatButton(
            minWidth: 10,
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
          actions: [
            RaisedButton(
              child: Text("확인"),
              color: Color(0xFF0275D7),
              elevation: 5,
              onPressed: () async {
                Navigator.pop(context, true);
              },
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
