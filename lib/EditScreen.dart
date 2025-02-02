
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:object_project/FolderSelect.dart';
import 'package:object_project/ToastPage.dart';

class EditScreen extends StatefulWidget {

  final String projectId;
  final String fileId;

  final String fileName;
  final String fileUrl;
  final String folderPathTitle;
  final String folderPathList;
  final bool editImage;

  final bool fromItemScreen;
  final Uint8List fileByte;

  final bool typeIsFile;
  final File file;
  final String folderId;
  final bool canMove;

  late Function(String,String,List<String>,bool) onEditComplete;
  final List<dynamic> items_whole;
  final Map<String,dynamic> pictureFolderData;
  final Map<String,dynamic> fileMap;
  // final List<String> projectRole;

  final String fileComment;
  final List<String> tagsList;

  EditScreen({
    required this.projectId,
    required this.fileName,
    required this.fileUrl,
    required this.folderPathTitle,
    required this.editImage,
    required this.fileId,
    required this.onEditComplete,
    required this.fromItemScreen,
    required this.fileByte,
    required this.typeIsFile,
    required this.file,
    required this.items_whole,
    required this.folderPathList,
    required this.pictureFolderData,
    required this.fileMap,
    required this.fileComment,
    required this.tagsList,
    // required this.projectRole,
    required this.folderId,
    required this.canMove
  });

  @override
  EditScreenState createState() => EditScreenState();
}

class EditScreenState extends State<EditScreen> {

  late TextEditingController nameEditingController;
  late TextEditingController commentEditingController;
  late TextEditingController tagsEditingController;
  late String projectId;

  late String apiUrl;

  List<String> tagsList = [];

  late String folderPathTitle;

  late TextEditingController textEditingController;
  String newTagName = "";

  Map<String,dynamic> pictureFolderData = {}.cast<String, dynamic>();
  Map<String,dynamic> fileMap = {}.cast<String, dynamic>();

  String fileId = "";
  List<dynamic> created_by = [" "," "," "];
  String fileSize = "";
  String created_at = "";
  String shootingDate_at = "";
  String fileType = "";
  bool fileMove = false;
  bool editedFile = false;

  List<dynamic> items = [];
  String folderPath = "";

  @override
  void initState() {
    super.initState();
    nameEditingController = TextEditingController();
    commentEditingController = TextEditingController();
    tagsEditingController = TextEditingController();

    getIdToken();
    setState(() {
      nameEditingController.text = widget.fileName;
      if (widget.fileComment != "") {
        commentEditingController.text = widget.fileComment ?? '';
      }
      projectId = widget.projectId;
      folderPathTitle = widget.folderPathTitle;
      fileId = widget.fileId;
      if (widget.tagsList.isNotEmpty) {
        tagsList = widget.tagsList;
      }
      if ( widget.fileMap.isNotEmpty) {
        fileMap = widget.fileMap;

        if (widget.fileMap.toString().contains('shooting_date_display') &&
            widget.fileMap['shooting_date_display'].toString() != "" &&
            widget.fileMap['shooting_date_display'].toString() != "null" &&
            !widget.fileMap['shooting_date_display'].toString().contains("1970年")
        ) {
          shootingDate_at =  widget.fileMap['shooting_date_display'].toString();
        }

        if (widget.fileMap.toString().contains('created_at_display') &&
            widget.fileMap['created_at_display'].toString() != "" &&
            widget.fileMap['created_at_display'].toString() != "null" &&
            !widget.fileMap['created_at_display'].toString().contains("1970年")
        ) {
          created_at = widget.fileMap['created_at_display'].toString();
        } else {
          if (!widget.fileMap['created_at'].toString().contains("numberLong")) {
            DateTime dateTime = DateTime.parse(widget.fileMap['created_at'].toString());
            created_at =
                DateFormat('yyyy年MM月dd日(EEEE) HH:mm', 'ja_JP').format(dateTime.add(const Duration(hours: 9)));
          } else {
            created_at = DateFormat('yyyy年MM月dd日(EEEE) HH:mm', 'ja_JP').format(DateTime.now());
          }
        }

        if (widget.fileMap['mime_type'] != null ) {
          fileType = widget.fileMap['mime_type'].toString();
        }
        fileSize = formatFileSize(widget.fileMap['size']);
        created_by = widget.fileMap['created_by'];
      }

      if (widget.pictureFolderData.isNotEmpty) {
        pictureFolderData = widget.pictureFolderData;
        items = pictureFolderData["items"];
      }
    });
  }

  String formatFileSize(int fileSizeInBytes) {
    const int kbInBytes = 1024;
    const int mbInBytes = 1024 * 1024;

    if (fileSizeInBytes >= mbInBytes) {
      final double fileSizeInMB = fileSizeInBytes / mbInBytes;
      return '${fileSizeInMB.toStringAsFixed(2)} MB';
    } else {
      final double fileSizeInKB = fileSizeInBytes / kbInBytes;
      return '${fileSizeInKB.toStringAsFixed(2)} KB';
    }
  }

  Future<void> getIdToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiUrl = prefs.getString('apiUrl') ?? '';
    });
  }

  void moveFile(String newFolderName, String newFolderPath) async {
    if (widget.folderPathList != newFolderPath) {

      // for (int i = 0; i < items.length; i++) {
      //   if (items[i]["folder_path"] == newFolderPath) {
      //
      //     Map<String,dynamic>? responseData = await _httpService.returnMap_put(
      //         widget.editImage ?
      //         '$apiUrl/api/mobile/projects/$projectId/pictureFolder/pictures' :
      //         '$apiUrl/api/mobile/projects/$projectId/documentFolder/documents',
      //         {
      //           'id' : fileId,
      //           'current_folder' : widget.folderPathList,
      //           'new_folder' : newFolderPath,
      //         }, false,false
      //     );
      //
      //     if (responseData != null) {
      //       if (mounted) {
      //         setState(() {
      //           items[i]["objects"].add(fileMap);
      //           folderPathTitle = newFolderName;
      //         });
      //       }
      //
      //       Navigator.pop(context);
      //
      //       ToastPage.showToast('$newFolderNameに移動しました');
      //     } else {
      //       ToastPage.showToast('移動に失敗しました');
      //
      //     }
      //   }
      // }
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
                picturesItems: widget.items_whole,
                onFolderSelected: (
                    selectObjectsList,
                    selectFolderTitle,
                    selectFolderId,
                    selectFolderPath) {
                  setState(() {
                    folderPathTitle = selectFolderTitle;
                    if (widget.folderPathList != selectFolderPath) {
                      folderPath = selectFolderPath;
                      fileMove = true;
                    } else {
                      fileMove = false;
                    }
                  });
                },
                fromChecklist: false,
                fromEdit: true,
                // projectRole: widget.projectRole,
                folderId: widget.folderId,
              )
      ),
    );
  }

  void addTag() {

    List<String> tagsList_string = [];

    for (var tag in tagsList) {
      tagsList_string.add(tag.toString());
    }

    showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: const BoxDecoration(
                    color: Color(0xFFe4f0f0),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(8.0),
                    ),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: const Center(
                    child: Text(
                      'タグを追加',
                      style: TextStyle(
                        color: Color(0xFF005F6B),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    '新しいタグ名',
                    style: TextStyle(
                      color: Color(0xFF005F6B),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    style: const TextStyle(
                      color: Color(0xFF005F6B),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLength: 30,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    controller: tagsEditingController,
                    keyboardType: TextInputType.text,
                    cursorColor: const Color(0xFF005F6B),
                    decoration: InputDecoration(
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: newTagName.isEmpty ? Colors.grey : const Color(0xFF005F6B),
                        ),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey,
                        ),
                      ),
                      counterStyle: TextStyle(
                        color: newTagName.isEmpty ? Colors.grey : const Color(0xFF005F6B),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        newTagName = value;
                      });
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        height : MediaQuery.of(context).size.height * 0.08,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8.0),
                          ),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              tagsEditingController.text = "";
                            });
                          },
                          child: const Center(
                            child: Text(
                              'キャンセル',
                              style: TextStyle(
                                color: Color(0xFF005F6B),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height : MediaQuery.of(context).size.height * 0.08,
                        decoration: const BoxDecoration(
                          color: Color(0xFF005F6B),
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(8.0),
                          ),
                        ),
                        child: TextButton(
                          onPressed: () {
                            if (tagsEditingController.text != "") {
                              if (
                              tagsList_string.contains(
                                  tagsEditingController.text)
                              ) {
                                ToastPage.showToast("すでにリストにあるタグ名です");
                              } else  {
                                setState(() {
                                  tagsList.add(newTagName);
                                  tagsEditingController.text = "";
                                  editedFile = true;
                                });
                                Navigator.pop(context);
                              }
                            } else {
                              ToastPage.showToast("タグ名を入力してください");
                            }
                          },
                          child: const Center(
                            child: Text(
                              '追加',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> editImage() async {
    // if (widget.fromItemScreen) {
    //   Map<String,dynamic>? responseData = await _httpService.returnMap_put(
    //       widget.editImage ?
    //       '$apiUrl/api/mobile/projects/$projectId/pictureFolder/pictures/$fileId' :
    //       '$apiUrl/api/mobile/projects/$projectId/documentFolder/documents/$fileId',
    //       {
    //         'display_name' : nameEditingController.text,
    //         'comment' : commentEditingController.text,
    //         'tags' : jsonEncode(tagsList)
    //       }, false,false
    //   );
    //
    //   if (responseData != null) {
    //     setState(() {
    //       widget.onEditComplete(nameEditingController.text,
    //           commentEditingController.text,tagsList, fileMove);
    //     });
    //
    //     if (nameEditingController.text != widget.fileName) {
    //       FirebaseAnalyticsHelper.logEvent(
    //         eventName: 'm_写真名変更',
    //       );
    //     }
    //
    //     if (tagsList != widget.tagsList ||
    //         widget.fileComment != commentEditingController.text
    //     ) {
    //       FirebaseAnalyticsHelper.logEvent(
    //         eventName: 'm_写真の編集',
    //       );
    //     }
    //
    //     ToastPage.showToast("情報を変更しました");
    //
    //     if (fileMove) {
    //       moveFile(folderPathTitle,folderPath);
    //     } else {
    //       Navigator.pop(context);
    //     }
    //   } else {
    //     ToastPage.showToast("情報変更中エラー発生");
    //   }
    // } else {
    //   widget.onEditComplete(nameEditingController.text,
    //       commentEditingController.text, tagsList, fileMove);
    //   Navigator.pop(context);
    // }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
            elevation: 0,
            title: Text(widget.fileName,
                style: const TextStyle(
                    color: Color(0xFF005F6B),
                    fontWeight: FontWeight.bold)
            ),
            backgroundColor: Colors.white,
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                  Icons.arrow_back_ios_new_outlined,
                  color: Color(0xFF005F6B)
              ),
            )
        ),
        body: GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child:
          Container(
            color:  Colors.white,
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: widget.editImage ? MediaQuery.of(context).size.height * 0.22 : MediaQuery.of(context).size.height * 0.1,
                      child:
                      widget.editImage && widget.fromItemScreen? Image.network(widget.fileUrl) :
                      widget.editImage && widget.typeIsFile ? Image.file(widget.file) :
                      widget.editImage ? Image.memory(widget.fileByte) :
                      Icon(
                        Icons.insert_drive_file_outlined,color: const Color(0xFF005F6B),
                        size: MediaQuery.of(context).size.height * 0.1,
                      )
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width,
                            padding: const EdgeInsets.all(8.0),
                            child: Wrap(
                              alignment: WrapAlignment.start,
                              children: [
                                SizedBox(
                                  width:MediaQuery.of(context).size.width * 0.35,
                                  child: const Text(
                                    "保存フォルダ : ",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFF005F6B),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Padding(
                                    padding: const EdgeInsets.only(right: 16),
                                    child: Column(
                                        children: [
                                          SizedBox(
                                            width: MediaQuery.of(context).size.width * 0.35,
                                            child: Text(
                                                folderPathTitle,
                                                style: TextStyle(
                                                  fontSize: folderPathTitle.length > 20 ? 15 : 18,
                                                  color: const Color(0xFF005F6B),
                                                  fontWeight: FontWeight.bold,
                                                )
                                            ),
                                          ),
                                          if(widget.folderPathTitle != folderPathTitle && fileMove)
                                            const Text(
                                                "＊移動先フォルダを選択中",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                )
                                            )
                                        ]
                                    )
                                ),
                                if(widget.folderPathList != "" && widget.canMove)
                                  IconButton(
                                    onPressed: () async {
                                      final prefs = await SharedPreferences.getInstance();
                                      bool checkEditing = prefs.getBool('editingFiles') ?? false;
                                      if (checkEditing) {
                                        ToastPage.showToast('ファイルを削除、移動中です。おまちください');
                                      } else {
                                        selectFolder(context);
                                      }
                                    },
                                    icon: Image.asset(
                                      'assets/images/fileMoveIcon.png',
                                      height: MediaQuery.of(context).size.height * 0.05,
                                    ),
                                  )
                              ],
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width,
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width:MediaQuery.of(context).size.width * 0.35,
                                  child: const Text(
                                    "ファイル名 : ",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFF005F6B),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                    child:
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        color: Colors.white,
                                        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                                        border: Border.all(
                                          color: Colors.grey.withOpacity(0.4),
                                          width: 2.0,
                                        ),
                                      ),
                                      child:  TextFormField(
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Color(0xFF005F6B),
                                          fontWeight: FontWeight.bold,
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.only(left: 10),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Color(0xFF005F6B)),
                                          ),
                                          counterText: '',
                                          counterStyle: TextStyle(
                                            fontSize: 12.0,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        maxLines: null,
                                        maxLength: 100,
                                        controller: nameEditingController,
                                        keyboardType: TextInputType.text,
                                        cursorColor: const Color(0xFF005F6B),
                                        onChanged: (value) {
                                          setState(() {
                                            editedFile = true;
                                          });
                                        },
                                      ),
                                    )
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width,
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width : MediaQuery.of(context).size.width * 0.35,
                                  child: const Text(
                                    "コメント : ",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFF005F6B),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.rectangle,
                                      color: Colors.white,
                                      borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.4),
                                        width: 2.0,
                                      ),
                                    ),
                                    child: TextFormField(
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Color(0xFF005F6B),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      cursorColor : const Color(0xFF005F6B),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.only(left: 10),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Color(0xFF005F6B)),
                                        ),
                                        counterText: '',
                                        counterStyle: TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      maxLines: null,
                                      maxLength: 100,
                                      controller: commentEditingController,
                                      keyboardType: TextInputType.multiline,
                                      onChanged: (value) {
                                        setState(() {
                                          editedFile = true;
                                        });
                                      },
                                      onTapOutside : (value) {
                                        FocusManager.instance.primaryFocus?.unfocus();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                              width: MediaQuery.of(context).size.width,
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width:MediaQuery.of(context).size.width * 0.35,
                                        child: const Text(
                                          "タグ : ",
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Color(0xFF005F6B),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width:MediaQuery.of(context).size.width * 0.4,
                                        child: Text(
                                            tagsList.toString()
                                                .replaceAll('[', '')
                                                .replaceAll(']', '')
                                                .replaceAll('"', '')
                                                .replaceAll('\\', '')
                                                .replaceAll('/', '')
                                                .replaceAll('null', ''),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Color(0xFF005F6B),
                                              fontWeight: FontWeight.bold,
                                            )
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          IconButton (
                                            onPressed: () {
                                              if (tagsList.isEmpty) {
                                                setState(() {
                                                  newTagName = "";
                                                  addTag();
                                                });
                                              } else {
                                                showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return Dialog(
                                                      backgroundColor: Colors.transparent,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8.0),
                                                      ),
                                                      child: Container(
                                                        width: MediaQuery.of(context).size.width,
                                                        height: MediaQuery.of(context).size.height * 0.5,
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(8.0),
                                                          color: Colors.white,
                                                        ),
                                                        child: Column(
                                                          children: [
                                                            Container(
                                                              padding: const EdgeInsets.all(8.0),
                                                              decoration: const BoxDecoration(
                                                                color: Color(0xFFe4f0f0),
                                                                borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
                                                              ),
                                                              child: Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  IconButton(
                                                                    onPressed: () {
                                                                      setState(() {
                                                                        newTagName = "";
                                                                      });
                                                                      addTag();
                                                                    },
                                                                    icon: Image.asset(
                                                                      'assets/images/tagIcon.png',
                                                                      height: MediaQuery.of(context).size.height * 0.04,
                                                                    ),

                                                                  )
                                                                  ,
                                                                  const Text(
                                                                    'タグリスト',
                                                                    style: TextStyle(
                                                                      color: Color(0xFF005F6B),
                                                                      fontSize: 16,
                                                                      fontWeight: FontWeight.bold,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(width: 24)
                                                                ],
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: ListView.builder(
                                                                itemCount: tagsList.length,
                                                                itemBuilder: (context, index) {
                                                                  return Padding(
                                                                    padding : EdgeInsets.only(
                                                                        top: 12,
                                                                        right: 16,
                                                                        left: 16,
                                                                        bottom : index + 1 == tagsList.length ? 12 : 0
                                                                    ),
                                                                    child: Container(
                                                                      height:  tagsList[index]
                                                                          .replaceAll('[', '')
                                                                          .replaceAll(']', '')
                                                                          .replaceAll('"', '')
                                                                          .replaceAll('\\', '')
                                                                          .replaceAll('/', '').toString().length > 10 ?
                                                                      MediaQuery.of(context).size.height * 0.1 :
                                                                      MediaQuery.of(context).size.height * 0.07,
                                                                      width: MediaQuery.of(context).size.width * 0.3,
                                                                      alignment: Alignment.center,
                                                                      decoration: BoxDecoration(
                                                                        color: const Color(0xFFe4f0f0),
                                                                        borderRadius: BorderRadius.circular(8.0),
                                                                      ),
                                                                      child: ListTile(
                                                                        trailing: IconButton(
                                                                          onPressed: () {
                                                                            setState(() {
                                                                              tagsList.removeAt(index);
                                                                              editedFile = true;
                                                                              Navigator.pop(context);
                                                                            });
                                                                          },
                                                                          icon: Image.asset(
                                                                            'assets/images/agentDeleteIcon.png',
                                                                            height: MediaQuery.of(context).size.height * 0.04,
                                                                          ),
                                                                        ),
                                                                        title: Text(
                                                                          tagsList[index]
                                                                              .replaceAll('[', '')
                                                                              .replaceAll(']', '')
                                                                              .replaceAll('"', '')
                                                                              .replaceAll('\\', '')
                                                                              .replaceAll('/', ''),
                                                                          style: const TextStyle(
                                                                            fontSize: 15,
                                                                            color: Color(0xFF005F6B),
                                                                            fontWeight: FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                            ),

                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              }
                                            },
                                            icon:  Image.asset(
                                              'assets/images/agentEditIcon.png',
                                              height: MediaQuery.of(context).size.height * 0.05,
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ],
                              )
                          ),
                          if(widget.fromItemScreen && widget.fromItemScreen)
                            Column(
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width:MediaQuery.of(context).size.width * 0.35,
                                        child: const Text(
                                          "サイズ : ",
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Color(0xFF005F6B),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Text(
                                          fileSize.toString(),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Color(0xFF005F6B),
                                            fontWeight: FontWeight.bold,
                                          )
                                      ),
                                    ],
                                  ),
                                ),
                                if(widget.typeIsFile)
                                  Container(
                                    width: MediaQuery.of(context).size.width,
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width:MediaQuery.of(context).size.width * 0.35,
                                          child: const Text(
                                            "撮影日時 : ",
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Color(0xFF005F6B),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                            child: Text(
                                                shootingDate_at,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  color: Color(0xFF005F6B),
                                                  fontWeight: FontWeight.bold,
                                                )
                                            )
                                        ),
                                      ],
                                    ),
                                  ),
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width:MediaQuery.of(context).size.width * 0.35,
                                        child: Text(
                                          !widget.typeIsFile ?
                                          "追加日時 : " :
                                          "登録日時 : ",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Color(0xFF005F6B),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                          child: Text(
                                              created_at,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                color: Color(0xFF005F6B),
                                                fontWeight: FontWeight.bold,
                                              )
                                          )
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width : MediaQuery.of(context).size.width * 0.35,
                                        child: const Text(
                                          "登録者 : ",
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Color(0xFF005F6B),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          created_by[1].toString() == "" ||
                                              created_by[2].toString() == "" ?
                                          "社外" : "${created_by[2]}\n${created_by[1]}",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Color(0xFF005F6B),
                                            fontWeight: FontWeight.bold,
                                          )
                                          ,
                                        ) ,
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          if(!widget.editImage && widget.fromItemScreen)
                            Container(
                              width: MediaQuery.of(context).size.width,
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width:MediaQuery.of(context).size.width * 0.35,
                                    child: const Text(
                                      "タイプ : ",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Color(0xFF005F6B),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                        fileType,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Color(0xFF005F6B),
                                          fontWeight: FontWeight.bold,
                                        )
                                    ),
                                  )
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                ],
              ),
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
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  backgroundColor: (editedFile || fileMove)

                      && nameEditingController.text.replaceAll(' ','').isNotEmpty ?
                  const Color(0xFF005F6B) : Colors.grey,
                  onPressed: (editedFile || fileMove)  ?
                  nameEditingController.text.replaceAll(' ','').replaceAll('　','').isNotEmpty ?
                  editImage : () {
                    ToastPage.showToast('ファイル名を入力してください');
                  } :
                      () {
                    ToastPage.showToast('編集内容がありません');
                  },
                  label:
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                            'assets/images/cloudUpload.png',
                            color: Colors.white,
                            height: MediaQuery.of(context).size.height * 0.05
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
                )
            ),
          ],
        )
    );
  }
}
