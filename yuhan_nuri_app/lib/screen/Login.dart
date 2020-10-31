import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:toast/toast.dart';
import 'package:yuhan_nuri_app/screen/YuhanNuri.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final FirebaseMessaging fcm = FirebaseMessaging();

String userID = "";
String userPassword = "";
bool isAutoLogin = false;
String myCookie = "";

class LoginApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YuhanNuri',
      home: Login(title: 'YuhanNuri Login'),
    );
  }
}

class Login extends StatefulWidget {
  Login({this.title});
  final String title;
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // 로그인시 응답 수신동안 보여줄 ProgressDialog
  ProgressDialog progressDialog;

  @override
  // ignore: must_call_super
  void initState() {
    // ignore: todo
    // TODO: implement initState
    setProgressDialog();
    fcm.configure(onMessage: (Map<String, dynamic> message) async {
      print("onMessage: $message");
      print(message['data']['fileno']);
    }, onResume: (Map<String, dynamic> message) async {
      print("onResume: $message");
      print(message['data']['fileno']);
    }, onLaunch: (Map<String, dynamic> message) async {
      print("onLaunch: $message"); //
      print(message['data']['fileno']);
    });
  }

  //progressDialog 초기화
  setProgressDialog() async {
    progressDialog =
        new ProgressDialog(context, type: ProgressDialogType.Normal);
    progressDialog.style(message: '잠시만 기다려주세요...');
    //progressDialog 커스텀하는 방법
    // progressDialog.style(
    //       message: 'Please wait...',
    //       borderRadius: 10.0,
    //       backgroundColor: Colors.white,
    //       progressWidget: CircularProgressIndicator(),
    //       elevation: 10.0,
    //       insetAnimCurve: Curves.easeInOut,
    //       progressTextStyle: TextStyle(
    //           color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
    //       messageTextStyle: TextStyle(
    //           color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600),
    //     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildLayoutContainer(context),
    );
  }

  Widget _buildLayoutContainer(BuildContext context) {
    return SingleChildScrollView(
      child: _buildFormWrapper(context),
    );
  }

  Widget _buildFormWrapper(BuildContext context) {
    return Form(
      child: _buildLoginLayout(context),
    );
  }

  Widget _buildLoginLayout(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 150, left: 20, right: 20), // 상, 좌, 우 여백
      child: Column(
        children: <Widget>[
          _userIDTextField(context),
          SizedBox(
            height: 20,
          ), // 위젯들 사이의 여백
          _userPasswordTextField(context),
          SizedBox(
            height: 20,
          ),
          _buildSubmitButton(context),
          SizedBox(
            height: 10,
          ),
          _autoLoginCheckBox(context),
        ],
      ),
    );
  }

  Widget _userIDTextField(BuildContext context) {
    return TextFormField(
        onChanged: (value) => userID = value,
        decoration: InputDecoration(
          labelText: 'Enter ID',
          filled: true,
          fillColor: Colors.white,
        ));
  }

  Widget _userPasswordTextField(BuildContext context) {
    return TextFormField(
      onChanged: (value) => userPassword = value,
      obscureText: true, // Text 암호화 표시
      decoration: InputDecoration(
        labelText: 'Enter Password',
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _autoLoginCheckBox(BuildContext context) {
    return CheckboxListTile(
      controlAffinity: ListTileControlAffinity.leading,
      title: Text('자동 로그인'),
      value: isAutoLogin,
      onChanged: (bool newValue) {
        setState(() {
          isAutoLogin = newValue;
        });
      },
      contentPadding: const EdgeInsets.only(left: 0.00),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return ButtonTheme(
      minWidth: double.infinity,
      child: RaisedButton(
        child: Text(
          "Login",
        ),
        onPressed: () {
          // 로그인 버튼 눌렀을 때 실행 될 내용
          portalLogin(userID, userPassword, isAutoLogin);
        },
      ),
    );
  }

  portalLogin(String userID, String userPassword, bool isAutoLogin) async {
    // 로그인 루틴 시작하면서 dialog 띄움
    progressDialog.show();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    print(
        'userID: $userID, userPassword: $userPassword, autoLogin: $isAutoLogin');

    http.Response res = await http.Client().post(
      Uri.parse('https://yuhannuri.run.goorm.io/user/mobile'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'Accept': 'application/json; charset=utf-8',
      },
      body: {
        'userId': userID.trim(),
        'password': userPassword.trim(),
        'isAutoLogin': isAutoLogin.toString(),
        'myToken' : await fcm.getToken()
      },
    );

    if (res.statusCode == 200) {
      // 응답의 헤더에서 cookie값 가져와서 저장
      Cookie cookie = Cookie.fromSetCookieValue(res.headers['set-cookie']);
      if (isAutoLogin) {
        // 만료일자(30일 후)세팅, 쿠키값 저장, 만료일자 저장
        DateTime dateTime = cookie.expires.add(new Duration(days: 30));
        prefs.setString('cookie', cookie.toString());
        prefs.setString('expires', dateTime.toString());
      }

      Map<String, dynamic> stuInfo = jsonDecode(res.body);
      if (stuInfo == null) {
        // 스크린 이동전 dialog hide
        progressDialog.hide();
        Toast.show('아이디와 패스워드를 확인하세요.', context,
            duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
      } else {
        // id, pwd 재입력을 위해
        progressDialog.hide();
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (BuildContext context) => YuhanNuri(
                  cookie: cookie.toString(),
                )));
      }
    } else {
      throw Exception();
    }
  }
}
