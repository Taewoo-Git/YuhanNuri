import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:yuhan_nuri_app/screen/YuhanNuri.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:oktoast/oktoast.dart';

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
            controller: idTextBoxController,
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
            controller: pwTextBoxController,
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
      child: RaisedButton(
        onPressed: () => {portalLogin(userID, userPassword, isAutoLogin)},
        padding: EdgeInsets.all(15),
        color: Color(0xFF0275D8),
        child: Text('로그인',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget buildCheckAutoLogin(BuildContext context) {
    return new Row(
      children: <Widget>[
        GestureDetector(
            onTap: () {
              setState(() {
                isAutoLogin = !isAutoLogin;
              });
            },
            child: isAutoLogin
                ? Image.asset("assets/btnAuto-on.png", width: 20, height: 20)
                : Image.asset("assets/btnAuto-off.png", width: 20, height: 20)),
        new FlatButton(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onPressed: () {
              setState(() {
                isAutoLogin = !isAutoLogin;
              });
            },
            child: Text(
              "자동 로그인",
              style: new TextStyle(color: Color(0xFF9e9e9e), fontSize: 16),
            ))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 0, 115, 215),
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
                        image: AssetImage("assets/nuri_blue.png"),
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

  portalLogin(String userID, String userPassword, bool isAutoLogin) async {
    progressDialog.show();

    SharedPreferences prefs = await SharedPreferences.getInstance();

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
