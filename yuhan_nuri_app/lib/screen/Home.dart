import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Domain.dart';

class Home {
  Map<String, String> header;
  int countRequest;
  List<Widget> noticeList;

  RefreshController _refreshController;

  TextEditingController _searchController;
  String keyword = "";
  bool isSearch = false;

  StateSetter _setState;

  BuildContext ctx;

  Future<bool> getDate() async {
    String page = countRequest.toString();
    http.Response res = await http.Client().get(
      Uri.parse(Domain.url + "user/get/home/" + page),
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

  Future<bool> getSearch() async {
    http.Response res = await http.Client().get(
      Uri.parse(Domain.url + "user/get/search/" + keyword),
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
    keyword = "";
    return true;
  }

  Future<Widget> getBuild(Map<String, String> _header) async {
    header = _header;
    countRequest = 1;
    noticeList = [];

    _refreshController = RefreshController();

    _searchController = TextEditingController();

    return StatefulBuilder(
      builder: (context, StateSetter setState) {
        ctx = context;
        return SmartRefresher(
          enablePullDown: false,
          enablePullUp: true,
          footer: ClassicFooter(
            loadStyle: LoadStyle.ShowWhenLoading,
          ),
          controller: _refreshController,
          onLoading: () async {
            ++countRequest;
            String page = countRequest.toString();

            http.Response res = await http.Client().get(
              Uri.parse(Domain.url + "user/get/home/" + page),
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
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "검색",
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                        ),
                        onChanged: (value) {
                          keyword = value;
                        },
                      )),
                      Container(
                        child: IconButton(
                          icon: Icon(Icons.search),
                          color: Color(0xFF0073D7),
                          onPressed: () {
                            if (keyword.trim().isEmpty) {
                              isSearch = false;
                              countRequest = 1;
                              _refreshController.loadComplete();
                            } else {
                              isSearch = true;
                              _searchController.clear();
                            }
                            setState(() {
                              noticeList.clear();
                            });
                          },
                        ),
                      )
                    ],
                  ),
                ),
                FutureBuilder(
                  future: isSearch ? getSearch() : getDate(),
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
  if (content.contains("img")) {
    String parseUrl = content.split("../../")[1].split('"')[0];
    content = "<p><img src=\"${Domain.url + parseUrl}\"/></p>";
  }

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
                      if (url.contains(
                          'action=com.google.firebase.dynamiclinks.VIEW_DYNAMIC_LINK;')) {
                        url = url
                                .toString()
                                .split(';')[4]
                                .toString()
                                .split('=')[1]
                                .split('viewform')[0] +
                            'viewform';
                      }
                      launch(url, forceWebView: false);
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
