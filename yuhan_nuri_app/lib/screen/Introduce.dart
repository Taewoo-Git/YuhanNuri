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
    PageDecoration pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(
          fontSize: 35.0,
          fontWeight: FontWeight.w700,
          fontFamily: 'jua',
          color: Color(0xFF303030)), //tile font size, weight and color
      bodyTextStyle: TextStyle(
          fontSize: 19.0, color: Color(0xFFC7C7C7), fontFamily: 'jua'),
      //body text size and color
      descriptionPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      //decription padding
      imagePadding: EdgeInsets.all(20), //image padding
      boxDecoration: BoxDecoration(
        color: Colors.white,
        // gradient: LinearGradient(
        //   begin: Alignment.topRight,
        //   end: Alignment.bottomLeft,
        //   stops: [0.1, 0.5, 0.7, 0.9],
        //   colors: [
        //     Color(0xFF71A7D0),
        //     Color(0xFF8CC3D9),
        //     Color(0xFF81C0D5),
        //     Color(0xFF85D1D6),
        //   ],
        // ),
      ), //show linear gradient background of page
    );
    // 각각 페이지들을 배열처럼 저장
    return IntroductionScreen(
      key: introKey,
      pages: [
        PageViewModel(
          title: "환영합니다",
          image: Image(
            image: AssetImage("assets/team_success.png"),
          ),
          body: "안녕하세요! \n 유한대학교 학생상담센터 예약어플 \n 유한누리입니다. \n 유한누리 방문이 처음이신가요? ",
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "무엇이 고민인가요?",
          image: Image(
            image: AssetImage("assets/sad_face.png"),
          ),
          body: "유한누리로 간편하게 \n 심리검사와 상담예약을 해보세요. \n 비밀을 지켜드려요!",
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "유한누리",
          image: Image(
            image: AssetImage("assets/social_media.png"),
          ),
          body:
              "유한누리를 이용할 준비가 되셨나요? \n 그럼 지금 바로 시작해보세요! \n 학생상담센터는  \n언제나 여러분을 환영합니다!",
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      showSkipButton: true,
      skipFlex: 0,
      nextFlex: 0,
      // skip: const Text('Skip'),
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