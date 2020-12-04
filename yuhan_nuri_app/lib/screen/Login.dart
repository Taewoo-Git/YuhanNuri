import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:yuhan_nuri_app/screen/YuhanNuri.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:oktoast/oktoast.dart';

final FirebaseMessaging fcm = FirebaseMessaging();

String userID = "";
String userPassword = "";
bool isAutoLogin = true;
String myCookie = "";
TextEditingController idTextBoxController;
TextEditingController pwTextBoxController;

class LoginApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OKToast(
        position: ToastPosition.bottom,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'YuhanNuri',
          home: Login(title: 'YuhanNuri Login'),
        ));
  }
}

class Login extends StatefulWidget {
  Login({this.title});
  final String title;
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  ProgressDialog progressDialog;

  @override
  void initState() {
    super.initState();
    idTextBoxController = TextEditingController();
    pwTextBoxController = TextEditingController();
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
              color: Colors.blueGrey[300],
              fontSize: 13,
              fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
              ]),
          height: 60,
          child: TextField(
            controller: idTextBoxController,
            onChanged: (value) => userID = value,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14),
              prefixIcon: Icon(
                Icons.account_circle,
                color: Color(0xFF81C0D5),
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
              color: Colors.blueGrey[300],
              fontSize: 13,
              fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
              ]),
          height: 60,
          child: TextField(
            controller: pwTextBoxController,
            onChanged: (value) => userPassword = value,
            obscureText: true,
            style: TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14),
              prefixIcon: Icon(
                Icons.lock,
                color: Color(0xFF81C0D5),
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
      padding: EdgeInsets.symmetric(vertical: 25),
      width: double.infinity,
      child: RaisedButton(
        elevation: 5,
        onPressed: () => {portalLogin(userID, userPassword, isAutoLogin)},
        padding: EdgeInsets.all(15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        color: Color(0xFF0275D8),
        child: Text('로그인',
            style: TextStyle(
                color: Color(0xFFAFD9FE),
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget buildCheckAutoLogin(BuildContext context) {
    return CheckboxListTile(
      controlAffinity: ListTileControlAffinity.leading,
      autofocus: true,
      checkColor: Colors.lightBlue,
      activeColor: Colors.white,
      title: Text(
        'Remember',
        style:
            TextStyle(color: Colors.blueGrey[300], fontWeight: FontWeight.bold),
      ),
      value: isAutoLogin,
      onChanged: (bool newValue) {
        setState(() {
          isAutoLogin = newValue;
        });
      },
      contentPadding: const EdgeInsets.only(left: 0.00),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: GestureDetector(
          child: Stack(children: <Widget>[
        Container(
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color(0xFFF0F0F0),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 120),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '유한누리',
                  style: TextStyle(
                      fontFamily: 'jua',
                      color: Color(0xFF3C3C3C),
                      fontSize: 40,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 30),
                buildId(context),
                SizedBox(height: 30),
                buildPassword(context),
                SizedBox(height: 7),
                buildCheckAutoLogin(context),
                SizedBox(height: 63),
                buildLoginBtn(),
              ],
            ),
          ),
        )
      ])),
    ));
  }

  portalLogin(String userID, String userPassword, bool isAutoLogin) async {
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
        'myToken': await fcm.getToken()
      },
    );
    if (res.body == "null") {
      FocusManager.instance.primaryFocus.unfocus();
      progressDialog.hide();
      showToast("아이디와 패스워드를 확인하세요.");
      idTextBoxController.clear();
      pwTextBoxController.clear();
      return;
    }
    if (res.statusCode == 200) {
      Cookie cookie = Cookie.fromSetCookieValue(res.headers['set-cookie']);
      if (isAutoLogin) {
        DateTime dateTime = cookie.expires.add(new Duration(days: 30));
        prefs.setString('cookie', cookie.toString());
        prefs.setString('expires', dateTime.toString());
      }
      progressDialog.hide();
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (BuildContext context) => YuhanNuri(
                cookie: cookie.toString(),
              )));
    } else {
      throw Exception();
    }
  }
}
