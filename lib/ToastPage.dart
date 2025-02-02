import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastPage {
  static void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
      fontSize: 16.0,
      gravity: ToastGravity.CENTER,
      // timeInSecForIosWeb: 100,
    );
  }
}
