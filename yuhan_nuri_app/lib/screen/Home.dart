import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class Home {
  List<Widget> noticeList = [
    setNotice(),
    setNotice(),
    setNotice(),
    setNotice()
  ];

  Widget getBuild() {
    return StatefulBuilder(
      builder: (context, StateSetter setState) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 50,
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.only(left: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Color(0xFFEAEAEA),
                ),
                child: Row(
                  children: [
                    Flexible(
                        child: new TextField(
                      decoration: InputDecoration(
                        hintText: "검색",
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    )),
                    Container(
                      child: IconButton(
                        icon: Icon(Icons.search),
                        color: Color(0xFF0073D7),
                        onPressed: () {},
                      ),
                    )
                  ],
                ),
              ),
              Column(
                children: noticeList,
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget setNotice() {
  return StatefulBuilder(builder: (context, StateSetter setState) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5),
        ),
        child: ExpansionTile(
          title: Text(
            "시스템 정기점검 알림",
            style: TextStyle(fontSize: 20),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            "03.06",
            style: TextStyle(color: Colors.black, height: 1.5),
          ),
          children: [
            Divider(height: 1, indent: 10, endIndent: 10, color: Colors.black),
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.all(10),
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Html(
                    data: """<p>Hello <b>Flutter</b></p>""",
                    onLinkTap: (url) {
                      print("Opening $url");
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  });
}
