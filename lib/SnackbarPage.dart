import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackBarPage {
  static void showSnackBar(bool success, String title, String message) {
    Get.snackbar(
      title,
      message,
      colorText: success ? const Color(0xFF005F6B) : Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 30),
      backgroundColor: success ? const Color(0xFFe4f0f0) : Colors.redAccent,
      borderRadius: 10,
      mainButton: TextButton(
        onPressed: Get.back,
        child: Icon(
          Icons.cancel_outlined,
          color: success ? const Color(0xFF005F6B) : Colors.white,
        )
      ));
  }


  static OverlayEntry? _overlayEntry;
  static OverlayEntry? _overlayEntry_edit;

  static var title = ''.obs;
  static var message = ''.obs;
  static var totalCount = 0.obs;
  static var approvedCount = 0.obs;

  static var title_edit = ''.obs;
  static var message_edit = ''.obs;
  static var totalCount_edit = 0.obs;
  static var approvedCount_edit = 0.obs;

  static void showCustomSnackBar(
      BuildContext context,
      String messageTitle,
      String messageValue,
      bool start,
      int approved,
      int total,
      ) {

    if (_overlayEntry != null) {
      if (totalCount.value <= approvedCount.value + 1) {
        _removeCurrentSnackBar();
        return;
      } else  {
        message.value = messageValue;
        title.value = messageTitle;
        if (start) {
          totalCount.value += total;
        } else {
          approvedCount.value += 1;
        }
        return;
      }
    } else {
      if (approvedCount.value > 1 || start) {
        message.value = messageValue;
        title.value = messageTitle;
        totalCount.value = total;

        _overlayEntry = OverlayEntry(
          builder: (context) => Obx(() => Positioned(
            top: MediaQuery.of(context).size.height * 0.06,
            left: MediaQuery.of(context).size.width * 0.03,
            right: MediaQuery.of(context).size.width * 0.03,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFe4f0f0),
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.07,
                ),
                width: MediaQuery.of(context).size.width * 0.9,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.value,
                            style: const TextStyle(
                              color: Color(0xFF005F6B),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                          Text(
                            "${message.value}(${approvedCount.value}/${totalCount.value})",
                            style: const TextStyle(
                              color: Color(0xFF005F6B),
                              fontSize: 14,
                            ),
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const IconButton(
                      icon: Icon(Icons.cancel_outlined, color: Color(0xFF005F6B)),
                      onPressed: _removeCurrentSnackBar,
                      alignment: Alignment.centerRight,
                    ),
                  ],
                ),
              ),
            ),
          )),
        );

        Overlay.of(context)?.insert(_overlayEntry!);
      }
    }
  }

  static void _removeCurrentSnackBar() {
    totalCount.value = 0;
    approvedCount.value = 0;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  static void showCustomSnackBar_edit(
      BuildContext context,
      String messageTitle,
      String messageValue,
      bool start,
      int approved,
      int total,
      ) {

    if (_overlayEntry_edit != null) {
      if (totalCount_edit.value <= approvedCount_edit.value + 1) {
        _removeCurrentSnackBar_edit();
      } else  {
        message_edit.value = messageValue;
        title_edit.value = messageTitle;
        if (start) {
          totalCount_edit.value += total;
        } else {
          approvedCount_edit.value += 1;
        }
        return;
      }
    } else {
      if (approvedCount_edit.value > 1 || start) {
        message_edit.value = messageValue;
        title_edit.value = messageTitle;
        totalCount_edit.value = total;

        _overlayEntry_edit = OverlayEntry(
          builder: (context) => Obx(() => Positioned(
            top: MediaQuery.of(context).size.height * 0.06,
            left: MediaQuery.of(context).size.width * 0.03,
            right: MediaQuery.of(context).size.width * 0.03,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFe4f0f0),
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.07,
                ),
                width: MediaQuery.of(context).size.width * 0.9,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title_edit.value,
                            style: const TextStyle(
                              color: Color(0xFF005F6B),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                          Text(
                            "${message_edit.value}(${approvedCount_edit.value}/${totalCount_edit.value})",
                            style: const TextStyle(
                              color: Color(0xFF005F6B),
                              fontSize: 14,
                            ),
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const IconButton(
                      icon: Icon(Icons.cancel_outlined, color: Color(0xFF005F6B)),
                      onPressed: _removeCurrentSnackBar_edit,
                      alignment: Alignment.centerRight,
                    ),
                  ],
                ),
              ),
            ),
          )),
        );

        Overlay.of(context)?.insert(_overlayEntry_edit!);
      }
    }
  }

  static void _removeCurrentSnackBar_edit() {
    totalCount_edit.value = 0;
    approvedCount_edit.value = 0;
    _overlayEntry_edit?.remove();
    _overlayEntry_edit = null;
  }

}
