
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:object_project/ToastPage.dart';

class FolderMake extends StatefulWidget {
  final List<dynamic> itemsList;

  late Function(bool,String) onUploadComplete;


  FolderMake({
    required this.itemsList,
    required this.onUploadComplete,
  });

  @override
  _FolderMakeState createState() => _FolderMakeState();
}

class _FolderMakeState extends State<FolderMake> {
  String folderName = '';
  final TextEditingController _textEditingController = TextEditingController();
  late List<dynamic> itemsList;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    itemsList = widget.itemsList;
  }

  void createEmptyFolder(String newFolderName) async {

    widget.onUploadComplete(true,newFolderName);

    setState(() {
      isLoading = false;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFFe4f0f0),
          elevation: 0,
          title: const Text(
            '폴더추가',
            style: TextStyle(
                color: Color(0xFF005F6B),
                fontSize: 18,
                fontWeight: FontWeight.bold
            ),
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
                padding: const EdgeInsets.only(left: 10,right: 10),
                height: MediaQuery.of(context).size.height * 0.1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10,right: 10),
                      child: TextField(
                        style: const TextStyle(
                            color: Color(0xFF005F6B),
                            fontWeight: FontWeight.bold
                        ),
                        maxLength: 30,
                        controller: _textEditingController,
                        keyboardType: TextInputType.text,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z\dぁ-ゔァ-ヴー一-龥々〆〤ー_ -]'),
                          ),
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        ],
                        decoration: InputDecoration(
                          hintText: '폴더명',
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: folderName.isEmpty ? Colors.grey : const Color(0xFF005F6B),
                            ),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey,
                            ),
                          ),
                          counterStyle: TextStyle(
                            color: folderName.isEmpty ? Colors.grey : const Color(0xFF005F6B),
                          ),
                        ),
                        cursorColor: Colors.blueAccent,
                        onChanged: (value) {
                          setState(() {
                            folderName = value;
                          });
                        },
                      ),
                    )
                  ],
                )
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Center(
                          child: Text(
                            '취소',
                            style: TextStyle(
                                color: Color(0xFF005F6B),
                                fontSize: 18,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: folderName != '' ?
                      const Color(0xFF005F6B) : Colors.grey,
                      child: TextButton(
                        onPressed: () {
                          if (!isLoading && folderName != '') {
                            setState(() {
                              isLoading = true;
                              createEmptyFolder(folderName);
                            });
                          } else {
                            ToastPage.showToast('폴더명을 입력해주십시오');
                          }
                        },
                        child: const Center(
                          child: Text(
                            '추가',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }
}
