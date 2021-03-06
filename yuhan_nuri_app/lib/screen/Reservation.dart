import 'package:flutter/material.dart';

class Reservation {
  PageController pageController = PageController(
    initialPage: 0,
  );

  Widget getBuild() {
    return StatefulBuilder(
      builder: (context, StateSetter setState) {
        return PageView(
          controller: pageController,
          physics: NeverScrollableScrollPhysics(),
          children: [
            SizedBox.expand(
              child: Container(
                color: Colors.red,
                child: Center(
                  child: RaisedButton(
                    child: Text("간단 신청서"),
                    onPressed: () {
                      setState(() {
                        pageController.animateToPage(1,
                            duration: Duration(milliseconds: 1000),
                            curve: Curves.fastLinearToSlowEaseIn);
                      });
                    },
                  ),
                ),
              ),
            ),
            SizedBox.expand(
              child: Container(
                color: Colors.yellow,
                child: Center(
                  child: RaisedButton(
                    child: Text("예약 선택"),
                    onPressed: () {
                      setState(() {
                        pageController.animateToPage(2,
                            duration: Duration(milliseconds: 1000),
                            curve: Curves.fastLinearToSlowEaseIn);
                      });
                    },
                  ),
                ),
              ),
            ),
            SizedBox.expand(
              child: Container(
                color: Colors.green,
                child: Center(
                  child: RaisedButton(
                    child: Text("자가 진단"),
                    onPressed: () {
                      setState(() {
                        pageController.animateToPage(3,
                            duration: Duration(milliseconds: 1000),
                            curve: Curves.fastLinearToSlowEaseIn);
                      });
                    },
                  ),
                ),
              ),
            ),
            SizedBox.expand(
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
            )
          ],
        );
      },
    );
  }
}
