import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class commentClass extends StatelessWidget {

  void addComment(String comment) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> commentList = prefs.getStringList("commentList") ?? [];
    if (comment == "") {
      commentList.add("null");
    } else {
      commentList.add(comment);
    }
    prefs.setStringList("commentList", commentList);
  }

  void editComment(String comment) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> commentList = prefs.getStringList("commentList") ?? [];

    if (commentList.isNotEmpty) {
      commentList[commentList.length - 1] = comment;
    } else {
      commentList.add(comment);
    }

    prefs.setStringList("commentList", commentList);
  }

  void deleteComment(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> commentList = prefs.getStringList("commentList") ?? [];
    commentList.removeAt(index);
    prefs.setStringList("commentList", commentList);
  }

  void clearList() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("commentList");
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }


}