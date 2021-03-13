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
    return StatefulBuilder(builder: (context, StateSetter setState) {
      return SizedBox.expand(
        child: Container(
          color: Colors.yellow,
          child: Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  pageController.nextPage(
                      duration: Duration(milliseconds: 1000),
                      curve: Curves.fastLinearToSlowEaseIn);
                });
              },
              child: Text("스케줄 확인"),
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
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  pageController.nextPage(
                      duration: Duration(milliseconds: 1000),
                      curve: Curves.fastLinearToSlowEaseIn);
                });
              },
              child: Text("자가 진단"),
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
<p>
비대면으로 이뤄지는 상담내용을 상담자의 동의 없이 참여자가 임의로 녹음, 녹화, 저장하여 공개 또는 유포하여서는 안 되며, 이러한 경우에는 그에 따른 민·형사상의 책임을 지게 될 수 있음을 알려드립니다.<br/>
</p>
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
<p>
비대면으로 이뤄지는 상담내용을 상담자의 동의 없이 참여자가 임의로 녹음, 녹화, 저장하여 공개 또는 유포하여서는 안 되며, 이러한 경우에는 그에 따른 민·형사상의 책임을 지게 될 수 있음을 알려드립니다.<br/>
</p>
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
<p>
비대면으로 이뤄지는 상담내용을 상담자의 동의 없이 참여자가 임의로 녹음, 녹화, 저장하여 공개 또는 유포하여서는 안 되며, 이러한 경우에는 그에 따른 민·형사상의 책임을 지게 될 수 있음을 알려드립니다.<br/>
</p>
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
<p>
비대면으로 이뤄지는 상담내용을 상담자의 동의 없이 참여자가 임의로 녹음, 녹화, 저장하여 공개 또는 유포하여서는 안 되며, 이러한 경우에는 그에 따른 민·형사상의 책임을 지게 될 수 있음을 알려드립니다.<br/>
</p>
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
