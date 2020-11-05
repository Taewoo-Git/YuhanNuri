import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'Login.dart';

class IntroduceScreenApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: IntroduceScreen(),
    );
  }
}

class IntroduceScreen extends StatefulWidget {
  @override
  IntroduceScreenState createState() => IntroduceScreenState();
}

class IntroduceScreenState extends State<IntroduceScreen> {
  final introKey = GlobalKey<IntroductionScreenState>();

  // 인트로 확인했을 때 실행
  void _onIntroEnd(context) {
    runApp(LoginApp());
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 19.0);
    const pageDecoration = const PageDecoration(
      titleTextStyle: TextStyle(
          fontSize: 28.0,
          fontWeight: FontWeight.w700,
          height: 5,
          textBaseline: TextBaseline.alphabetic),
      bodyTextStyle: bodyStyle,
      descriptionPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    // 각각 페이지들을 배열처럼 저장
    return IntroductionScreen(
      key: introKey,
      pages: [
        PageViewModel(
          title: "안녕하세용",
          image: Image(image: AssetImage('assets/hi.png')),
          body: "유한 대학교 심리 상담 센터 예약 앱 유한누리입니다.",
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "하단 탭",
          body: "",
          // footer: RaisedButton(
          //   onPressed: () {
          //     introKey.currentState?.animateScroll(0);
          //   },
          //   child: const Text(
          //     'Button',
          //     style: TextStyle(color: Colors.black),
          //   ),
          //   color: Colors.amber,
          //   shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(8.0)),
          // ),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "마이 페이지",
          bodyWidget: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text("테스트1", style: bodyStyle),
              Text("테스트2", style: bodyStyle),
              Text("테스트3", style: bodyStyle),
            ],
          ),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      showSkipButton: true,
      skipFlex: 0,
      nextFlex: 0,
      skip: const Text('Skip'),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}
