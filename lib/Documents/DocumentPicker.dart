import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:object_project/EditScreen.dart';
import 'package:object_project/FolderSelect.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart';
import 'package:object_project/SnackbarPage.dart';
import 'package:object_project/ToastPage.dart';
import '../LodingPage.dart';

class DocumentPicker extends StatefulWidget {

  final List<dynamic> documentItems_whole;
  final String projectId;

  final String folderId;

  final List<dynamic> documentObjects;
  final String folderPathTitle;
  late Function(String, bool,int, int) editingFiles;

  late Function(List<dynamic>,List<dynamic>) onUploadComplete;
  // final List<String> projectRole;

  DocumentPicker({
    required this.documentItems_whole,
    required this.projectId,
    required this.folderId,
    required this.documentObjects,
    required this.folderPathTitle,
    required this.onUploadComplete,
    required this.editingFiles,
    // required this.projectRole,
  });
  @override
  DocumentPickerState createState() => DocumentPickerState();
}

class DocumentPickerState extends State<DocumentPicker> {
  // final HTTPService _httpService = HTTPService();

  late List<dynamic> documentItems_whole;
  late List<dynamic> documentObjects;
  late File pickedFile;
  late String projectId;
  late String apiUrl;
  late String folderId;
  String folderPathTitle = "フォルダを選択";

  late bool? selectFile = false;
  String postFileExtension = '';
  String? fileName = 'null';

  late String userName;
  late String roleName;
  late String corporationId;

  List<String> documentTagsList = [];
  String newTagName = "";

  TextEditingController fileNameEditingController = TextEditingController();
  TextEditingController fileCommentEditingController = TextEditingController();
  TextEditingController tagsEditingController = TextEditingController();

  bool isLoading  = true;

  @override
  void initState() {
    super.initState();
    setState(() {
      folderId = widget.folderId;
      projectId = widget.projectId;
      documentItems_whole = widget.documentItems_whole;
      if (widget.folderPathTitle != "資料") {
        folderPathTitle = widget.folderPathTitle;
      }
      documentObjects = widget.documentObjects;

    });

    _pickDocument();
  }

  Future<void> _pickDocument() async {
    FilePickerResult? pickedFiles = await FilePicker.platform.pickFiles();
    final prefs = await SharedPreferences.getInstance();
    List<String> ALLOW_DOCUMENT_FILE_EXTENSIONS = prefs.getStringList('ALLOW_DOCUMENT_FILE_EXTENSIONS') ?? [];

    if (pickedFiles != null) {
      String? extension = pickedFiles.files.first.extension?.toLowerCase();
      final isValid = ALLOW_DOCUMENT_FILE_EXTENSIONS.contains(extension);

      if (isValid){
        setState(() {
          pickedFile = File(pickedFiles.files.single.path!);
          fileName = pickedFiles.names.toString();
          fileName = fileName!.replaceAll('[', '').replaceAll(']', '');
          selectFile = true;
          fileNameEditingController.text = fileName.toString();
          userName = prefs.getString('name') ?? '';
          roleName = prefs.getString('role_name') ?? '';
          corporationId = prefs.getString('corporation_id') ?? '';
          apiUrl = prefs.getString('apiUrl') ?? '';
        });
      } else {
        ToastPage.showToast("$extensionは対応できないタイプです");
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }

    List<String> parts = fileName!.split('.');
    if (parts.length > 1) {
      String fileExtension = parts.last;
      setState(() {
        postFileExtension = fileExtension;
        isLoading = false;
      });
    } else {
      postFileExtension = 'pdf';
    }
  }

  void selectFolder(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
          FolderSelect(
            projectId: projectId,
            apiUrl: apiUrl,
            picturesItems: documentItems_whole,
            onFolderSelected: (
                selectObjectsList,
                selectFolderTitle,
                selectFolderId,
                selectFolderPath) {
              setState(() {
                documentObjects = selectObjectsList;
                folderPathTitle = selectFolderTitle;
                folderId = selectFolderId;
              });
            },
            fromChecklist: false,
            fromEdit: false,
            // projectRole: widget.projectRole,
            folderId: '',
          )
      ),
    );
  }

  static Future<void> uploadDocument(
      String fileName,
      String folderName,
      File pickedFile,
      String apiUrl,
      String folderId,
      String fileComment,
      List<dynamic> tagsList_fromFile,
      List<dynamic> uploadObjectsList,
      List<dynamic> selectedObjectsList,
      String postFileExtension,
      Function(List<dynamic>,List<dynamic>) onUploadComplete,
      Function(String, bool, int, int)editingFiles,
      // HTTPService httpService
      ) async {
    final completer = Completer<void>();
    final receivePort = ReceivePort();

    List<int> fileBytes = await pickedFile.readAsBytes();
    String base64Data = base64Encode(fileBytes);

    _isolateEntryPoint({
      'fileName' : fileName,
      'sendPort': receivePort.sendPort,
      'pickedFile': base64Data,
      'apiUrl': apiUrl,
      'folderId': folderId,
      'fileComment': fileComment,
      'tagsList_fromFile': tagsList_fromFile,
      'uploadObjectsList' : uploadObjectsList,
      'selectedObjectsList' : selectedObjectsList,
      'postFileExtension': postFileExtension,
      // 'httpService': httpService
    });

    final prefs = await SharedPreferences.getInstance();


    receivePort.listen((dynamic data) async {
      if (data == 'complete') {
        SnackBarPage.showSnackBar(true, '資料の送信', '$folderNameに$fileNameを格納しました');

        editingFiles("資料送信中...",false,1,1);
        onUploadComplete(uploadObjectsList,selectedObjectsList);

        completer.complete();
        receivePort.close();
      }

      if (data.startsWith('start')) {
        int? nullableIndex = int.tryParse(data.split(':')[2].toString());
        int? nullableIndex_total = int.tryParse(data.split(':')[1].toString());
        if (nullableIndex != null && nullableIndex_total != null) {
          int index = nullableIndex;
          int index_total = nullableIndex_total;

          prefs.setBool("uploadFiles", true);
          editingFiles("資料送信中...",true,index_total,index);
        }
      }

      if (data == 'error') {
        SnackBarPage.showSnackBar(false, '資料送信中エラー', '$folderNameに送信中にエラーが発生しました');
        onUploadComplete(uploadObjectsList,selectedObjectsList);
        completer.complete();
        receivePort.close();
      }
    });

    return completer.future;
  }

  static void _isolateEntryPoint(Map<String, dynamic> message) async {
    final String fileName = message['fileName'];
    final SendPort sendPort = message['sendPort'];
    final String pickedFile = message['pickedFile'];
    final String apiUrl = message['apiUrl'];
    final String folderId = message['folderId'];
    String fileComment = message['fileComment'];
    List<dynamic> tagsList_fromFile = message['tagsList_fromFile'];
    List<dynamic> uploadObjectsList = message['uploadObjectsList'];
    // final HTTPService _httpService = message['httpService'];

    sendPort.send('start:1:0');

    String getMimeType(String fileName) {
      if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
        return 'image/jpeg';
      } else if (fileName.endsWith('.png')) {
        return 'image/png';
      } else if (fileName.endsWith('.pdf')) {
        return 'application/pdf';
      } else if (fileName.endsWith('.pages')) {
        return 'application/vnd.apple.pages';
      } else if (fileName.endsWith('.numbers')) {
        return 'application/vnd.apple.numbers';
      } else if (fileName.endsWith('.doc')) {
        return 'application/msword';
      } else if (fileName.endsWith('.docx')) {
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      } else if (fileName.endsWith('.xls')) {
        return 'application/vnd.ms-excel';
      } else if (fileName.endsWith('.xlsx')) {
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      } else if (fileName.endsWith('.ppt')) {
        return 'application/vnd.ms-powerpoint';
      } else if (fileName.endsWith('.pptx')) {
        return 'text/html';
      } else if (fileName.endsWith('.txt')) {
        return 'text/plain';
      }else if (fileName.endsWith('.html')) {
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      }
      else {
        String fileType = lookupMimeType(fileName).toString();
        if (fileType == "null") {
          return 'application/octet-stream';
        } else {
          return fileType;
        }
      }
    }

    final Map<String, dynamic> requestBody = {
      'folder_id': folderId.toString(),
      'name': fileName,
      'display_name': fileName,
      'file_data':'data:${getMimeType(fileName)};base64, $pickedFile',
    };

    if (fileComment.isNotEmpty &&
        fileComment.toString() != "null" &&
        fileComment.toString() != ""
    ) {
      requestBody['comment'] = fileComment;
    }

    if (tagsList_fromFile.isNotEmpty &&
        tagsList_fromFile.toString() != "[[...]]" &&
        tagsList_fromFile.toString() != "[]"
    ) {
      requestBody['tags'] = tagsList_fromFile.toString().replaceAll('[...]', '');
    }

    // // Map<String,dynamic>? responseData = await _httpService.returnMap_post(
    // //     apiUrl,requestBody,false,false
    // // );
    //
    // if (responseData != null) {
    //   final responseObject = responseData['data'];
    //   uploadObjectsList.add(responseObject);
    //   sendPort.send('complete');
    // } else {
    //   sendPort.send('error');
    // }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading ?
      LoadingPage(loadingMessage: "資料データ処理中...") :
    Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        elevation: 0,
        title: const Text('資料を追加',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF005F6B)
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
              Icons.arrow_back_ios_new_outlined,
              color: Color(0xFF005F6B)
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Container(
          color: Colors.white,
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height:  MediaQuery.of(context).size.height * 0.06,
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      selectFolder(context);
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.transparent),
                      side: MaterialStateProperty.all(
                          const BorderSide(color: Color(0xff8d8d8d))),
                      padding: MaterialStateProperty.all(
                          const EdgeInsets.all(12.0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.7,
                            child: Text(
                              folderPathTitle,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF005F6B)
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_outlined,
                          size: 24,
                          color: Color(0xff8d8d8d),
                        ),
                      ],
                    ),
                  )
                )
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          '追加する資料',
                          style: TextStyle(
                              color: Color(0xFF005F6B),
                              fontSize: 12,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(6),
                           child: Text(
                             '必須',
                             style: TextStyle(
                                 color: Colors.red,
                                 fontSize: 10,
                                 fontWeight: FontWeight.bold
                             ),
                           ),
                        )
                      ],
                    ),
                  ),
                  selectFile == true
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                          height: MediaQuery.of(context).size.height * 0.15,
                          width: MediaQuery.of(context).size.width * 0.9,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.insert_drive_file,
                                    size: MediaQuery.of(context).size.height * 0.05,
                                    color: const Color(0xFF005F6B),
                                  )
                              ),
                              Flexible(
                                child: Text(
                                  fileName ?? '',
                                  style: const TextStyle(
                                      color: Color(0xFF005F6B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15
                                  ),
                                  overflow: TextOverflow.clip,
                                ),
                              ),
                            ],
                          )
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.07,
                        child: FloatingActionButton.extended(
                          backgroundColor: const Color(0xFF005F6B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                    EditScreen(
                                      items_whole : documentItems_whole,
                                      projectId: projectId,
                                      fileId: "",
                                      fileName: fileName.toString(),
                                      fileUrl: "",
                                      folderPathTitle: folderPathTitle,
                                      folderPathList: "",
                                      editImage: false,
                                      onEditComplete: (String editName,String editComment,
                                          List<String> editTags, bool moveFile) {
                                        // setState(() {
                                        //   fileName = editName;
                                        //   if (editComment.toString() != "") {
                                        //     fileCommentEditingController.text = editComment;
                                        //   }
                                        //   if (editTags.isNotEmpty) {
                                        //     documentTagsList = editTags;
                                        //   }
                                        // });
                                      },
                                      fromItemScreen: false,
                                      fileByte: Uint8List(0),
                                      typeIsFile: false,
                                      file: File(''),
                                      pictureFolderData: {},
                                      fileMap: {},
                                      fileComment: fileCommentEditingController.text,
                                      tagsList: documentTagsList,
                                      // projectRole: widget.projectRole,
                                      folderId: folderId,
                                      canMove: true,
                                    )
                              ),
                            );
                          },
                          label: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit, color: Colors.white),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  '詳細と編集',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    ],
                  ) : Container(
                      height: MediaQuery.of(context).size.height * 0.15,
                      width: MediaQuery.of(context).size.width * 0.9,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            size: MediaQuery.of(context).size.height * 0.05,
                            color: const Color(0xFF005F6B),
                          ),
                          const SizedBox(width: 4.0),
                          TextButton(
                            onPressed: _pickDocument,
                            child:  const Text('ファイル選択',
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Color(0xFF005F6B),
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          )
                        ],
                      )
                  ),
                ],
              )
            ],
          ),
        ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.07,
              child: FloatingActionButton.extended(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                backgroundColor: const Color(0xFF005F6B),
                onPressed: () async {
                  if (selectFile == false ||
                      folderPathTitle =='フォルダを選択')
                  {
                    ToastPage.showToast('選択フォルダまたは資料を確認してください');
                  } else {
                    uploadDocument(
                        fileNameEditingController.text,
                        folderPathTitle,
                        pickedFile,
                        '$apiUrl/api/mobile/projects/$projectId/documentFolder/documents',
                        folderId.toString(),
                        fileCommentEditingController.text,
                        documentTagsList,
                        documentObjects,
                        documentObjects,
                        postFileExtension,
                        widget.onUploadComplete,
                        widget.editingFiles,
                        // _httpService
                    );
                    ToastPage.showToast('送信を開始します');
                    Navigator.of(context).popUntil(ModalRoute.withName('/AgendaMain'));
                  }
                },
                label: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.height * 0.03
                      ),
                    ),
                    const Text(
                        '保存',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white
                        )
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
    );
  }
}