import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'YuhanNuri.dart';
import 'Domain.dart';

class LoginApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OKToast(
      position: ToastPosition.bottom,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'YuhanNuri',
        home: Login(),
      ),
    );
  }
}

class Login extends StatefulWidget {
  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  String userID = "";
  String userPassword = "";
  bool isAutoLogin = true;

  TextEditingController _iD = TextEditingController();
  TextEditingController _pw = TextEditingController();

  ProgressDialog progressDialog;

  @override
  void initState() {
    super.initState();
    setProgressDialog();
  }

  setProgressDialog() async {
    progressDialog =
        new ProgressDialog(context, type: ProgressDialogType.Normal);
    progressDialog.style(message: '잠시만 기다려주세요...');
  }

  Widget buildId(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '아이디',
          style: TextStyle(
              color: Color(0xFF9e9e9e),
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFFd4d4d4), width: 1.5),
          ),
          height: 60,
          child: TextField(
            controller: _iD,
            onChanged: (value) => userID = value,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14),
              prefixIcon: Icon(
                Icons.account_circle,
                color: Color(0xFF7ac4ff),
              ),
              hintText: 'ID',
              hintStyle: TextStyle(color: Colors.black38),
            ),
          ),
        )
      ],
    );
  }

  Widget buildPassword(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '비밀번호',
          style: TextStyle(
              color: Color(0xFF9e9e9e),
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFFd4d4d4), width: 1.5),
          ),
          height: 60,
          child: TextField(
            controller: _pw,
            onChanged: (value) => userPassword = value,
            obscureText: true,
            style: TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14),
              prefixIcon: Icon(
                Icons.lock,
                color: Color(0xFF7ac4ff),
              ),
              hintText: 'Password',
              hintStyle: TextStyle(color: Colors.black38),
            ),
          ),
        )
      ],
    );
  }

  Widget buildLoginBtn() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 0),
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () => {portalLogin(userID, userPassword, isAutoLogin)},
        style: ElevatedButton.styleFrom(
          primary: Color(0xFF0275D7),
          padding: EdgeInsets.all(15),
        ),
        child: Text(
          '로그인',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget buildCheckAutoLogin(BuildContext context) {
    return Row(
      children: <Widget>[
        GestureDetector(
          onTap: () {
            setState(() {
              isAutoLogin = !isAutoLogin;
            });
          },
          child: isAutoLogin
              ? Image.asset("assets/btnAuto-on.png", width: 20, height: 20)
              : Image.asset("assets/btnAuto-off.png", width: 20, height: 20),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              isAutoLogin = !isAutoLogin;
            });
          },
          child: Text(
            "자동 로그인",
            style: TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 16,
            ),
          ),
          style: ButtonStyle(
            overlayColor:
                MaterialStateColor.resolveWith((states) => Colors.transparent),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF0073D7),
          toolbarHeight: 50,
          title: new Text('로그인',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
        ),
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: GestureDetector(
              child: Stack(children: <Widget>[
            Container(
              height: double.infinity,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFFfafbfc),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 50),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      child: new Image(
                        image: AssetImage("assets/nuriBlue.png"),
                      ),
                      padding: EdgeInsets.only(
                          bottom: 30.0, left: 60.0, right: 60.0),
                    ),
                    SizedBox(height: 30),
                    buildId(context),
                    SizedBox(height: 30),
                    buildPassword(context),
                    SizedBox(height: 5),
                    buildCheckAutoLogin(context),
                    SizedBox(height: 40),
                    buildLoginBtn(),
                  ],
                ),
              ),
            )
          ])),
        ));
  }

  void portalLogin(String userID, String userPassword, bool isAutoLogin) async {
    progressDialog.show();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String strToken = await fcm.getToken();

    http.Response res = await http.Client().post(
      Uri.parse(Domain.url + "user"),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'Accept': 'application/json; charset=utf-8',
      },
      body: {
        'userToken': strToken,
        'userId': userID.trim(),
        'password': userPassword.trim(),
        'isAutoLogin': isAutoLogin.toString()
      },
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      if (res.body == "success") {
        Cookie cookie = Cookie.fromSetCookieValue(res.headers['set-cookie']);

        if (isAutoLogin) {
          DateTime expires = cookie.expires.add(new Duration(days: 30));
          prefs.setString('Token', strToken);
          prefs.setString('Cookie', cookie.toString());
          prefs.setString('Expires', expires.toString());
        }
        progressDialog.hide();

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (BuildContext context) => YuhanNuri(
              cookie: cookie.toString(),
            ),
          ),
        );
      } else if (res.body == "fail") {
        FocusManager.instance.primaryFocus.unfocus();
        progressDialog.hide();
        showToast("아이디와 패스워드를 확인하세요.", textPadding: EdgeInsets.all(10));
        _iD.clear();
        _pw.clear();
      }
    } else {
      FocusManager.instance.primaryFocus.unfocus();
      progressDialog.hide();
      showToast("서버 점검 중입니다.\n잠시 후 다시 시도해 주세요.",
          textPadding: EdgeInsets.all(10));
    }
  }
}
