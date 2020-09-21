
import 'dart:async';
import 'dart:convert';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:toast/toast.dart';
import 'package:yuhan_nuri_app/screen/YuhanNuri.dart';
import 'package:shared_preferences/shared_preferences.dart';



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

class _LoginState extends State<Login>{

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
      padding: EdgeInsets.only(top: 150, left: 20, right: 20), //상, 좌, 우 여백
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
      obscureText: true, //Text 암호화 표시
      decoration: InputDecoration(
        labelText: 'Enter Password',
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _autoLoginCheckBox(BuildContext context){
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
          //로그인 버튼 눌렀을 때 실행 될 내용
          portalLogin(userID, userPassword, isAutoLogin);
        },
      ),
    );
  }

  Future<bool> checkHavingCookie() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String cookieParam = (prefs.getString('cookie') ?? "has not cookie" );
    String str = (prefs.getString('expires') ?? DateTime.now().toString());
    DateTime resetDay = DateTime.parse(str);

    //prefs.remove('expires');
    print("resetDay : " + resetDay.toString() + "################################");
    print("now : " + DateTime.now().toString() + "################################");

    //만료날짜가 지금보다 이후이면
    if(resetDay.isAfter(DateTime.now())){
      print("초기화 날짜가 안됐음@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
    }
    else{ 
      //지금이 초기화 지정 날짜이후이면 쿠키 만료일자와 쿠키 값 지움
      prefs.remove('expires');
      prefs.remove('cookie');
      cookieParam = "has not cookie";
      
    }

    //만료일자가 지나지 않았음, cookie string 확인
    if(cookieParam != "has not cookie"){
      //cookie에 정상적인 값이 있으면 바로 webView가있는 페이지로 이동, YuhanNuri.dart
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => YuhanNuri(cookie: cookieParam,)));
    }else{
      print("HAVE NOT COOKIE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    }

    return true;
  }

  portalLogin(String userID, String userPassword, bool isAutoLogin) async {
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
      },
    );

    if (res.statusCode == 200) {
      //응답의 헤더에서 cookie값 가져와서 저장
      Cookie cookie = Cookie.fromSetCookieValue(res.headers['set-cookie']);
      if(isAutoLogin){
        //만료일자(30일 후)세팅, 쿠키값 저장, 만료일자 저장
        DateTime dateTime = cookie.expires.add(new Duration(days: 30));
        prefs.setString('cookie', cookie.toString());
        prefs.setString('expires', dateTime.toString());
      }
      
      Map<String, dynamic> stuInfo = jsonDecode(res.body);
      if (stuInfo == null) {
        Toast.show('아이디와 패스워드를 확인하세요.', context,
            duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => YuhanNuri(cookie: cookie.toString(),))); 
      }
    } else {
      throw Exception();
    }
  }


 

}