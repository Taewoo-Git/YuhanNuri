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

  //인트로 확인했을 때 실행
  void _onIntroEnd(context) {
    // Navigator.of(context).push(
    //   MaterialPageRoute(builder: (_) => LoginApp()),
    // );
    runApp(LoginApp());
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 19.0);
    const pageDecoration = const PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
      bodyTextStyle: bodyStyle,
      descriptionPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    //각각 페이지들을 배열처럼 저장
    return IntroductionScreen(
      key: introKey,
      pages: [
        PageViewModel(
          title: "안내,소개 페이지 1",
          //image: _buildImage('img name'),
          body: "body ",
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "안내,소개 페이지 2",
          body: "body ",
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "안내,소개 페이지 3",
          body: "body ",
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "안내,소개 페이지 4",
          body: "Body",
          footer: RaisedButton(
            onPressed: () {
              introKey.currentState?.animateScroll(0);
            },
            child: const Text(
              'Button',
              style: TextStyle(color: Colors.pink),
            ),
            color: Colors.lightBlue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
          ),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "안내,소개 페이지 Last",
          bodyWidget: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text("Click", style: bodyStyle),
            ],
          ),
          //image
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
