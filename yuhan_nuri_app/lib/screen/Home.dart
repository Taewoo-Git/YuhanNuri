import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import 'Domain.dart';

class Home {
  Map<String, String> header;
  int countRequest;
  List<Widget> noticeList;

  RefreshController _refreshController;

  StateSetter _setState;

  Future<bool> getDate() async {
    http.Response res = await http.Client().post(
      Uri.parse(Domain.url + "user/home/" + countRequest.toString()),
      headers: header,
    );
    String temp = res.body.substring(1, res.body.length - 1);
    if (temp.length != 0) {
      List<String> tempList = temp.split('},{');

      tempList.forEach((element) {
        element = element.replaceAll('{', '');
        element = element.replaceAll('}', '');

        Map<String, dynamic> noticeObject = jsonDecode('{' + element + '}');
        String tempDate = noticeObject["date"];
        List<String> noticeDate = tempDate.split('-');
        noticeList.add(setNotice(noticeObject["title"], noticeObject["content"],
            "${noticeDate[1]}.${noticeDate[2]}"));
      });
    }
    return true;
  }

  Widget getBuild(Map<String, String> _haeder) {
    header = _haeder;
    countRequest = 1;
    noticeList = [];

    _refreshController = RefreshController();

    return StatefulBuilder(
      builder: (context, StateSetter setState) {
        return SmartRefresher(
          enablePullDown: false,
          enablePullUp: true,
          footer: ClassicFooter(
            loadStyle: LoadStyle.ShowWhenLoading,
          ),
          controller: _refreshController,
          onLoading: () async {
            ++countRequest;

            http.Response res = await http.Client().post(
              Uri.parse(Domain.url + "user/home/" + countRequest.toString()),
              headers: header,
            );
            String temp = res.body.substring(1, res.body.length - 1);
            if (temp.length == 0) {
              --countRequest;
              _refreshController.loadNoData();
            } else {
              List<String> tempList = temp.split('},{');

              tempList.forEach((element) {
                element = element.replaceAll('{', '');
                element = element.replaceAll('}', '');

                Map<String, dynamic> noticeObject =
                    jsonDecode('{' + element + '}');
                String tempDate = noticeObject["date"];
                List<String> noticeDate = tempDate.split('-');
                noticeList.add(setNotice(
                    noticeObject["title"],
                    noticeObject["content"],
                    "${noticeDate[1]}.${noticeDate[2]}"));
              });

              _setState(() {});

              _refreshController.loadComplete();
            }
          },
          child: SingleChildScrollView(
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
                FutureBuilder(
                  future: getDate(),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.hasData == false) {
                      var verticalCenter =
                          MediaQuery.of(context).size.height / 3.5;
                      return Container(
                        margin: EdgeInsets.only(top: verticalCenter),
                        child: Center(
                          child: CircularProgressIndicator(
                            backgroundColor: Colors.white,
                          ),
                        ),
                      );
                    } else {
                      return StatefulBuilder(
                        builder: (context, StateSetter setState) {
                          _setState = setState;
                          return Column(
                            children: noticeList,
                          );
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget setNotice(String title, String content, String date) {
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
            title,
            style: TextStyle(fontSize: 20),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            date,
            style: TextStyle(color: Colors.black, height: 1.5),
          ),
          children: [
            Divider(height: 1, indent: 10, endIndent: 10, color: Colors.black),
            Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Html(
                    data: content,
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
