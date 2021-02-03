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

  void _onIntroEnd(context) {
    runApp(LoginApp());
  }

  @override
  Widget build(BuildContext context) {
    PageDecoration pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(
          fontSize: 35.0,
          fontWeight: FontWeight.w700,
          fontFamily: 'jua',
          color: Color(0xFF303030)),
      bodyTextStyle: TextStyle(
          fontSize: 19.0, color: Color(0xFFC7C7C7), fontFamily: 'jua'),
      descriptionPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      imagePadding: EdgeInsets.all(20),
      boxDecoration: BoxDecoration(
        color: Colors.white,
      ),
    );
    return IntroductionScreen(
      key: introKey,
      pages: [
        PageViewModel(
          title: "환영합니다",
          image: Image(
            image: AssetImage("assets/team_success.png"),
          ),
          body: "안녕하세요! \n 유한대학교 학생상담센터 앱 \n 유한누리입니다. \n 유한누리 방문이 처음이신가요? ",
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "무엇이 고민인가요?",
          image: Image(
            image: AssetImage("assets/sad_face.png"),
          ),
          body: "유한누리로 간편하게 \n 심리검사와 상담예약을 해보세요. \n 비밀을 지켜드립니다!",
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "유한누리",
          image: Image(
            image: AssetImage("assets/social_media.png"),
          ),
          body:
              "유한누리를 이용할 준비가 되었나요? \n 지금 바로 시작해보세요! \n 학생상담센터는  \n언제나 여러분을 환영합니다!",
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      showSkipButton: true,
      skipFlex: 0,
      nextFlex: 0,
      skip: Text(
        'Skip',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      next: const Icon(Icons.arrow_forward),
      done: Text(
        '시작하기',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
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
