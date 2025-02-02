import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:object_project/Camera/DrawingProvider.dart';
import 'package:object_project/Camera/ImageDrawing.dart';
import 'package:object_project/FolderSelect.dart';
import 'package:object_project/Pictures/commentClass.dart';
import 'package:object_project/SnackbarPage.dart';
import 'package:object_project/ToastPage.dart';
import '../LodingPage.dart';
import 'package:image/image.dart' as img;

class ImagesPicker extends StatefulWidget {

  final List<dynamic> items_whole;
  final String projectId;
  final String folderPathTitle;
  final String folderPath;

  final String folderId;
  final List<dynamic> objectsList;

  late Function(bool,List<dynamic>, List<dynamic>) onUploadComplete;
  late Function(List<Uint8List>, List<File>) onEditImagesByte;
  late Function(List<File>,String,String,String) onUpdateReport;
  late Function(String, bool,int, int) editingFiles;
  // late Function(bool, List<Uint8List>, List<File>,String,List<String>,List<List>) onUploadToChecklist;
  late Function(String, String, List<dynamic>, String) settingFolderForChecklist;

  final bool fromPictureItems;
  final bool fromReport;
  final bool fromChecklist;

  final List<Uint8List> imagesByte;
  final List<File> reportImagesList;
  final List<String> takePictureTime;

  ImagesPicker({
    required this.items_whole,
    required this.projectId,
    required this.folderPathTitle,
    required this.folderPath,
    required this.folderId,
    required this.objectsList,
    required this.onUploadComplete,
    required this.fromPictureItems,
    required this.imagesByte,
    required this.onEditImagesByte,
    required this.fromReport,
    required this.onUpdateReport,
    required this.reportImagesList,
    required this.editingFiles,
    required this.fromChecklist,
    // required this.onUploadToChecklist,
    required this.takePictureTime,
    required this.settingFolderForChecklist,
  });
  @override
  ImagesPickerState createState() => ImagesPickerState();

}

class ImagesPickerState extends State<ImagesPicker> {

  List<File> imageFiles = [];
  List<Uint8List> imagesByte = [];

  List<String> pictureNames_fromCamera = [];
  List<String> pictureNames_fromPicker = [];
  List<String> commentList_fromCamera = [];
  List<String> commentList_fromPicker = [];

  late List<dynamic> items_whole;
  late List<dynamic> objectsList;
  late String projectId;
  late String apiUrl;
  late String folderId;
  late String parameterUrl;
  late String postBody;
  late bool fromPicturesItem;

  String folderPath = "";
  String folderPathTitle = "フォルダを選択";

  int currentProgress = 0;
  int plusImage = 1;

  late String userName;
  late String roleName;
  late String corporationId;

  List<List> tagsList_fromPicker = [];
  List<List> tagsList_fromCamera = [];
  List<String> takePictureTime = [];

  int selectedIndex = -1;
  bool isLoading  = true;

  void checkComment (bool clear) async  {
    final prefs = await SharedPreferences.getInstance();
    List<String> commentList = prefs.getStringList("commentList") ?? [];
    if (clear) {
      commentClass().clearList();
    } else {
      if (commentList.isEmpty) {
        for (int i = 0; widget.imagesByte.length > i; i ++) {
          commentList_fromCamera.add("null");
        }
      } else {
        if (mounted) {
          setState(() {
            commentList_fromCamera = commentList;
          });
        } else {
          commentList_fromCamera = commentList;
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    setState(() {
      projectId = widget.projectId;
      items_whole = widget.items_whole;
      objectsList = widget.objectsList;
      folderId = widget.folderId;
      if (widget.folderPath != "") {
        folderPath = widget.folderPath;
      }
      if (widget.folderPathTitle != "写真" &&
          widget.folderPathTitle != "写真を添付" &&
          widget.folderPathTitle != "資料"
      ) {
        folderPathTitle = widget.folderPathTitle;
      } else {
        if (widget.fromChecklist) {
          folderPathTitle = "保存先フォルダを選択";
        } else {
          folderPathTitle = "フォルダを選択";
        }
      }
      fromPicturesItem = widget.fromPictureItems;

      if (widget.reportImagesList != []) {
        imageFiles = widget.reportImagesList;
        for (int i = 0; i < imageFiles.length; i ++) {
          pictureNames_fromPicker.add(
              'pickedImage_${DateTime.now().millisecondsSinceEpoch}-${(i+1).toString().padLeft(2, '0')}.jpeg'
          );
          commentList_fromPicker.add("null");
          tagsList_fromPicker.add(["null"]);
        }
      }
    });

    getIdToken();

    if(widget.imagesByte.isEmpty && imagesByte.isEmpty) {
      _pickImages();
    } else if (imagesByte.length < widget.imagesByte.length) {
      for (int i = 0; imagesByte.length < widget.imagesByte.length; i ++) {
        imagesByte.add(widget.imagesByte[i]);
        takePictureTime.add(widget.takePictureTime[i]);
        pictureNames_fromCamera.add(
            'camera_${DateTime.now().millisecondsSinceEpoch}-${(i+1).toString().padLeft(2, '0')}.jpeg'
        );
        tagsList_fromCamera.add(["null"]);
      }

      if (imagesByte.length == pictureNames_fromCamera.length &&
      imageFiles.length == pictureNames_fromPicker.length
      ) {
        setState(() {
          isLoading = false;
        });
      }
    };

    checkComment(false);
  }

  void getIdToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiUrl = prefs.getString('apiUrl') ?? '';
      userName = prefs.getString('name') ?? '';
      roleName = prefs.getString('role_name') ?? '';
      corporationId = prefs.getString('corporation_id') ?? '';
    });
  }

  Future<void> _pickImages() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> ALLOW_IMAGE_FILE_TYPES = prefs.getStringList('ALLOW_IMAGE_FILE_TYPES') ?? [];

    final picker = ImagePicker();
    try {
      final pickedImages = await picker.pickMultiImage();

      if (pickedImages.isNotEmpty) {
        setState(() {
          if (imageFiles.length + imagesByte.length + pickedImages.length > 20) {
            isLoading = false;
            showDialog (
              context: context,
              builder: (context) => AlertDialog(
                title: const Text(
                    '送信可能な写真20枚を超えました',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF005F6B)
                    )
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        isLoading = true;
                      });
                      _pickImages();
                    },
                    child: const Text('確認',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF005F6B)
                        )),
                  ),
                ],
              ),
            );
          } else {
            for (int i = 0; i < pickedImages.length; i++) {

              setState(() {
                imageFiles.add(File(pickedImages[i].path));
                pictureNames_fromPicker.add(
                    'pickedImage_${DateTime.now().millisecondsSinceEpoch}-${(i+1).toString().padLeft(2, '0')}.jpeg'
                );
                commentList_fromPicker.add("null");
                tagsList_fromPicker.add(["null"]);
              });
              // final extension = pickedImages[i].name.split('.').last.toLowerCase();
              // final isValid = ALLOW_IMAGE_FILE_TYPES.contains(extension);
              //
              // if (isValid) {
              //
              // } else {
              //   ToastPage.showToast("$extensionは対応できないタイプです");
              // }
            }

            if (pictureNames_fromPicker.length == imageFiles.length
                && imagesByte.length == pictureNames_fromCamera.length) {
              isLoading = false;
            }
          }
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    }
    catch (e) {
      ToastPage.showToast("写真のアクセス権限を確認してください");
      setState(() {
        isLoading = false;
      });
      if (imagesByte.isEmpty) {
        Navigator.pop(context);
      }
    }
  }

  void selectFolder(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              FolderSelect(
                picturesItems: items_whole,
                onFolderSelected: (
                    selectObjectsList,
                    selectFolderTitle,
                    selectFolderId,
                    selectFolderPath) {
                  setState(() {
                    objectsList = selectObjectsList;
                    folderPathTitle = selectFolderTitle;
                    folderId = selectFolderId;
                    folderPath = selectFolderPath;
                  });
                },
                fromChecklist: widget.fromChecklist,
                fromEdit: false,
                folderId: '',
                projectId: projectId,
                apiUrl: apiUrl,
              )
      ),
    );
  }

  void _deleteImage(bool selectFromPicker, int index) {

    setState(() {
      if (selectFromPicker && imageFiles.isNotEmpty) {
        imageFiles.removeAt(index);
        pictureNames_fromPicker.removeAt(index);
        commentList_fromPicker.removeAt(index);
        tagsList_fromPicker.removeAt(index);
      }

      if (!selectFromPicker && imagesByte.isNotEmpty) {
        imagesByte.removeAt(index);
        pictureNames_fromCamera.removeAt(index);
        commentList_fromCamera.removeAt(index);
        tagsList_fromCamera.removeAt(index);
        commentClass().deleteComment(index);
      }
    });
  }

  static Future<void> uploadImages(
      String folderName,
      String postBody,
      List<String> pictureNames_fromPicker,
      List<String> pictureNames_fromCamera,
      List<File> imageFiles,
      List<Uint8List> imageBytes,
      String apiUrl,
      String parameterUrl,
      String folderId,
      List<String> commentList_fromPicker,
      List<List> tagsList_fromPicker,
      List<String> commentList_fromCamera,
      List<List> tagsList_fromCamera,
      List<dynamic> uploadObjectsList,
      List<dynamic> selectedObjectsList,
      List<String> takePictureTime,
      Function(bool,List<dynamic>,List<dynamic>) onUploadComplete,
      Function(String, bool,int, int) editingFiles,
      ) async {
    final completer = Completer<void>();
    final receivePort = ReceivePort();
    List<Uint8List> imageFileByteList = [];

    for(int i = 0; i < imageFiles.length; i++) {
      Uint8List imageFileBytes = imageFiles[i].readAsBytesSync();
      imageFileByteList.add(imageFileBytes);
    }

    _isolateEntryPoint({
      'postBody' : postBody,
      'sendPort': receivePort.sendPort,
      'pictureNames_fromPicker': pictureNames_fromPicker,
      'pictureNames_fromCamera': pictureNames_fromCamera,
      'imageFiles': imageFileByteList,
      'imageBytes': imageBytes,
      'apiUrl': apiUrl,
      'parameterUrl': parameterUrl,
      'folderId': folderId,
      'commentList_fromPicker': commentList_fromPicker,
      'tagsList_fromPicker': tagsList_fromPicker,
      'commentList_fromCamera': commentList_fromCamera,
      'tagsList_fromCamera': tagsList_fromCamera,
      'uploadObjectsList' : uploadObjectsList,
      'selectedObjectsList' : selectedObjectsList,
      'takePictureTime' : takePictureTime
    });

    final prefs = await SharedPreferences.getInstance();

    receivePort.listen((dynamic data) async {
      int? nullableIndex = int.tryParse(data.split(':')[2].toString());
      int? nullableIndex_total = int.tryParse(data.split(':')[1].toString());

      if (data.startsWith('complete')) {
        SnackBarPage.showSnackBar(true, '写真の送信',
            '$folderNameに${imageFiles.length + imageBytes.length}枚の写真を格納しました');
        onUploadComplete(true,uploadObjectsList, selectedObjectsList);
        completer.complete();
        receivePort.close();
      }

      if (data.startsWith('start')) {
        if (nullableIndex != null && nullableIndex_total != null) {
          int index = nullableIndex;
          int index_total = nullableIndex_total;

          prefs.setBool("uploadFiles", true);
          editingFiles("写真送信中...",true,index_total,index);
        }
      }

      if (data.startsWith('success')) {
        if (nullableIndex != null && nullableIndex_total != null) {
          int index = nullableIndex + 1;
          int index_total = nullableIndex_total;

          onUploadComplete(false,uploadObjectsList, selectedObjectsList);
          editingFiles("写真送信中...",false,index_total,index);
        }
      }

      if (data.startsWith('error')) {
        SnackBarPage.showSnackBar(false, '写真伝送中エラー',
          '$folderNameに送信中にエラーが発生しました');

        onUploadComplete(true,uploadObjectsList, selectedObjectsList);
        completer.complete();
        receivePort.close();
      }
    });
    return completer.future;
  }

  static void _isolateEntryPoint(Map<String, dynamic> message) async {
    final String postBody = message['postBody'];
    final SendPort sendPort = message['sendPort'];
    final List<String> pictureNames_fromPicker = message['pictureNames_fromPicker'];
    final List<String> pictureNames_fromCamera = message['pictureNames_fromCamera'];
    final List<Uint8List> imageFiles = message['imageFiles'];
    final List<Uint8List> imageBytes = message['imageBytes'];
    final String apiUrl = message['apiUrl'];
    final String parameterUrl = message['parameterUrl'];
    final String folderId = message['folderId'];
    final List<String> commentList_fromPicker = message['commentList_fromPicker'];
    final List<List> tagsList_fromPicker = message['tagsList_fromPicker'];
    final List<String> commentList_fromCamera = message['commentList_fromCamera'];
    final List<List> tagsList_fromCamera = message['tagsList_fromCamera'];
    List<dynamic> uploadObjectsList = message['uploadObjectsList'];
    final List<String> takePictureTime = message['takePictureTime'];

    final prefs = await SharedPreferences.getInstance();
    final String messageId = "${prefs.getString('id')}_${prefs.getString('email')}_${DateTime.now()}";

    int currentProgress = 0;
    sendPort.send('start:${pictureNames_fromCamera.length + pictureNames_fromPicker.length}:0');

    bool isJpeg(Uint8List bytes) {
      return bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;
    }

    if ( pictureNames_fromPicker.isNotEmpty) {
      for (int i = 0; i < pictureNames_fromPicker.length; i++) {
        Uint8List imageFileBytes = imageFiles[i];
        img.Image? pngImage = img.decodeImage(imageFileBytes);
        String base64Image_picker = "";

        if (isJpeg(imageFileBytes)) {
          base64Image_picker = base64Encode(imageFileBytes);
        } else {
          var jpegBytes = img.encodeJpg(pngImage!, quality: 100);
          base64Image_picker = base64Encode(jpegBytes);
        }

        final Map<String, dynamic> requestBody = {
          "folder_id": folderId.toString(),
          'name': pictureNames_fromPicker[i],
          postBody: 'data:image/jpeg;base64, $base64Image_picker',
        };

        if (commentList_fromPicker[i].toString() != "null" &&
            commentList_fromPicker[i].toString() != ""
        ) {
          requestBody['comment'] = commentList_fromPicker[i];
        }

        if (tagsList_fromPicker[i].toString() != "[null]" &&
            tagsList_fromPicker[i].toString() != "[]"
        ) {
          requestBody['tags'] = jsonEncode(tagsList_fromPicker[i]);
        }

        // Map<String,dynamic>? responseData = await _httpService.returnMap_post(
        //     apiUrl + parameterUrl,requestBody,false,false
        // );

        // if (responseData != null) {
        //
        //   final responseObject = responseData['data'];
        //
        //   sendPort.send('success:${pictureNames_fromCamera.length + pictureNames_fromPicker.length}:$i');
        //
        //   uploadObjectsList.add(responseObject);
        //   currentProgress++;
        //
        //   if (currentProgress ==
        //       pictureNames_fromCamera.length + pictureNames_fromPicker.length) {
        //     sendPort.send('complete:0:0');
        //   }
        // } else {
        //   sendPort.send('error:0:0');
        // }
      }
    }

    if (pictureNames_fromCamera.isNotEmpty) {
      for (int i = 0; i < pictureNames_fromCamera.length; i++) {

        img.Image? pngImage = img.decodeImage(imageBytes[i]);
        var jpegBytes = img.encodeJpg(pngImage!, quality: 100);
        String base64Image = base64Encode(jpegBytes);

        final Map<String, dynamic> requestBody = {
          "folder_id": folderId.toString(),
          'name': pictureNames_fromCamera[i],
          'shooting_date' : takePictureTime[i],
          postBody: 'data:image/jpeg;base64, $base64Image',
        };

        if (commentList_fromCamera[i].toString() != "null") {
          requestBody['comment'] = commentList_fromCamera[i];
        }

        if (tagsList_fromCamera[i].toString() != "[null]" &&
            tagsList_fromPicker[i].toString() != "[]"
        ) {
          requestBody['tags'] = jsonEncode(tagsList_fromCamera[i]);
        }

        // Map<String,dynamic>? responseData = await _httpService.returnMap_post(
        //     apiUrl + parameterUrl,requestBody,false,false
        // );
        //
        // if (responseData != null) {
        //   final responseObject = responseData['data'];
        //
        //   sendPort.send('success:${pictureNames_fromCamera.length + pictureNames_fromPicker.length}:$i');
        //
        //   uploadObjectsList.add(responseObject);
        //   currentProgress++;
        //
        //   if (currentProgress ==
        //       pictureNames_fromCamera.length + pictureNames_fromPicker.length) {
        //     sendPort.send('complete:0:0');
        //   }
        // } else {
        //   sendPort.send('error:0:0');
        // }
      }
    }
  }

  void showFileOptionsBottomSheet(
      Uint8List fileByte,
      File file,
      String selectName,
      String fileComment,
      List fileTags,
      int fileIndex,
      bool selectFromPicker,
      ) {

      Navigator.push(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: "/Drawing"),
          builder: (context) => ChangeNotifierProvider(
            create: (context) => DrawingProvider(),
            child: ImageDrawing(
              editMap : {
                "items_whole" : items_whole,
                "projectId": projectId,
                "fileId": "",
                "fileName": selectName,
                "fileUrl": "",
                "folderPathTitle": folderPathTitle,
                "folderPath": "",
                "editImage": true,
                "fromItemScreen": false,
                "fileByte": fileByte,
                "typeIsFile": selectFromPicker,
                "file": file,
                "pictureFolderData": {}.cast<String, dynamic>(),
                "fileMap": {}.cast<String, dynamic>(),
                "fileComment": fileComment,
                "tagsList": fileTags,
                "created_by": DateTime.now().toString(),
              },
              imageUrl: '',
              imageThumbnail: '',
              imageByte: fileByte,
              imageFile: file,
              imageName: selectName,
              projectId: projectId,
              folderPathTitle: folderPathTitle,
              folderId: folderId,
              objectsList : [],
              onUploadComplete : (uploadFolder,uploadedFile) {},
              typeIsFile: selectFromPicker,
              fromList: false,
              onEditImage: (File editImage, bool upload) {
                if (upload) {
                  setState(() {
                    imageFiles.add(editImage);
                    pictureNames_fromPicker.add("edit_$selectName");
                    tagsList_fromPicker.add(["null"]);
                  });
                }
              },
              onDelete: (bool onDelete) {
                if (onDelete) {
                  _deleteImage(selectFromPicker,fileIndex);
                }
              },
              onEditComplete: (String editName,String editComment,
                  List editTags, bool moveFile) {
                setState(() {
                  if(selectFromPicker) {
                    pictureNames_fromPicker[fileIndex] = editName;
                    if (editComment.toString() != "") {
                      commentList_fromPicker[fileIndex] = editComment;
                    }
                    if (editTags.toString() != "[]") {
                      tagsList_fromPicker[fileIndex] = editTags;
                    }
                  } else {
                    pictureNames_fromCamera[fileIndex] = editName;
                    if (editComment.toString() != "") {
                      commentList_fromCamera[fileIndex] = editComment;
                    }
                    if (editTags.toString() != "[]") {
                      tagsList_fromCamera[fileIndex] = editTags;
                    }
                  }
                });
              },

            ),
          ),
        ),
      ).then((fileComment) {
        if (fileComment != null && fileComment is String) {
          commentList_fromPicker.add(fileComment.toString());
        } else {
          commentList_fromPicker.add("null");
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    if (fromPicturesItem == true) {
      setState(() {
        parameterUrl = '/api/mobile/projects/$projectId/pictureFolder/pictures';
        postBody = 'image';
      });
    } else {
      setState(() {
        parameterUrl = '/api/mobile/projects/$projectId/documentFolder/documents';
        postBody = 'file_data';
      });
    }

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return isLoading ?
    LoadingPage(loadingMessage: "写真データ処理中...") :
    Scaffold(
        appBar: AppBar(
          elevation: 0,
        title: const Text('デバイスから写真を追加',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF005F6B)
          ),
        ),
        backgroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child:
          GestureDetector(
            onTap: () {
              widget.onEditImagesByte(imagesByte,imageFiles);
              Navigator.pop(context);
            },
            child: const Icon(
                Icons.arrow_back_ios_new_outlined,
                color: Color(0xFF005F6B)
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            selectedIndex = -1;
          });
        },
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
                        side: MaterialStateProperty.all(const BorderSide(color: Color(0xff8d8d8d))),
                        padding: MaterialStateProperty.all(const EdgeInsets.all(12.0)),
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
            Container(
              padding: const EdgeInsets.all(8.0),
              width: MediaQuery.of(context).size.width * 0.9,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                      '一度に選択可能な写真： 20枚',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF005F6B)
                      )
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFe4f0f0),
                      borderRadius: BorderRadius.all(Radius.circular(16.0)),
                    ),
                    child:
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                          'あと ${20 - (imageFiles.length + imagesByte.length)}枚 選択可能 ',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF005F6B))
                      ),
                    )

                  )
                ],
              )
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 8,right: 8,bottom: MediaQuery.of(context).size.height * 0.08),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 2.0,
                    mainAxisSpacing: 2.0,
                  ),
                  itemCount: imageFiles.length + imagesByte.length,
                  itemBuilder: (context, index) {
                    if (index < imageFiles.length) {
                      var image = imageFiles[index];
                      int imageSize = image.lengthSync();
                      return GestureDetector(
                        onTap: () {
                          showFileOptionsBottomSheet(
                            Uint8List(0),
                            imageFiles[index],
                            pictureNames_fromPicker[index].toString(),
                            commentList_fromPicker[index].toString(),
                            tagsList_fromPicker[index],
                            index,
                            true,
                          );
                        },
                        child: Container(
                          alignment: Alignment.center,
                          height: MediaQuery.of(context).size.height * 0.2,
                          width: MediaQuery.of(context).size.width * 0.4,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xff8d8d8d)),
                          ),
                          child: Stack(
                            children: [
                              AspectRatio(
                                aspectRatio: 1,
                                child: Image.file(image),
                              ),
                              if (selectedIndex == index)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              if (selectedIndex == index)
                                const Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: Colors.blueAccent,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      var byteData = imagesByte[index - imageFiles.length];
                      return GestureDetector(
                        onTap: () {
                          showFileOptionsBottomSheet(
                            byteData,
                            File(''),
                            pictureNames_fromCamera[index - imageFiles.length].toString(),
                            commentList_fromCamera[index - imageFiles.length].toString(),
                            tagsList_fromCamera[index - imageFiles.length],
                            index - imageFiles.length,
                            false
                          );
                        },
                        child: Container(
                          alignment: Alignment.center,
                          height: MediaQuery.of(context).size.height * 0.2,
                          width: MediaQuery.of(context).size.width * 0.4,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF005F6B)),
                          ),
                          child: Stack(
                            children: [
                              AspectRatio(
                                aspectRatio: 1,
                                child: Image.memory(byteData),
                              ),
                              if (selectedIndex == index)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              if (selectedIndex == index)
                                const Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: Colors.blueAccent,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton:
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.84,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: MediaQuery.of(context).size.height * 0.07,
                    child: FloatingActionButton.extended(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      backgroundColor: Colors.white,
                      onPressed: () {
                        setState(() {
                          isLoading = true;
                        });
                        checkComment(true);
                        _pickImages();
                      },
                      label: Column(
                        children: [
                          Image.asset(
                              'assets/images/pictureAddIcon.png',
                              color: const Color(0xFF005F6B),
                              height: MediaQuery.of(context).size.height * 0.03
                          ),
                          const Text(
                              '写真を選択',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF005F6B)
                              )
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: MediaQuery.of(context).size.height * 0.07,
                    child: widget.fromReport ?
                    FloatingActionButton.extended(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      backgroundColor: const Color(0xFF005F6B),
                      onPressed: () {
                        if (folderPathTitle =="保存先フォルダを選択" ||
                            folderPathTitle =="フォルダを選択"
                        ) {
                          ToastPage.showToast('選択フォルダまたは写真を確認してください');
                        } else {
                          widget.onUpdateReport(
                              imageFiles,
                              folderId,
                              folderPath,
                              folderPathTitle
                          );
                          checkComment(true);
                          Navigator.pop(context);
                        }
                      },
                      label: Column(
                        children: [
                          Image.asset(
                              'assets/images/cloudUpload.png',
                              color: Colors.white,
                              height: MediaQuery.of(context).size.height * 0.03
                          ),
                          const Text(
                              '報告に追加',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white
                              )
                          ),
                        ],
                      ),
                    )
                    : FloatingActionButton.extended(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      backgroundColor: const Color(0xFF005F6B),
                      onPressed: () async {

                        if (folderPathTitle =="保存先フォルダを選択" ||
                            folderPathTitle =="フォルダを選択"
                        )
                        {
                          ToastPage.showToast('選択フォルダまたは写真を確認してください');
                        } else {
                          if (widget.fromChecklist) {
                            widget.settingFolderForChecklist(
                                folderPathTitle,folderId,objectsList,folderPath
                            );

                            // widget.onUploadToChecklist(
                            //     false,imagesByte,imageFiles,folderPath,
                            //   commentList_fromPicker + commentList_fromCamera,
                            //     tagsList_fromCamera + tagsList_fromPicker
                            // );
                            checkComment(true);
                            Navigator.of(context).popUntil(ModalRoute.withName('/AgendaMain'));
                          } else {
                            uploadImages(
                              folderPathTitle,
                              postBody,
                              pictureNames_fromPicker,
                              pictureNames_fromCamera,
                              imageFiles,
                              imagesByte,
                              apiUrl,
                              parameterUrl,
                              folderId,
                              commentList_fromPicker,
                              tagsList_fromPicker,
                              commentList_fromCamera,
                              tagsList_fromCamera,
                              objectsList,
                              objectsList,
                              takePictureTime,
                              widget.onUploadComplete,
                              widget.editingFiles,
                            );
                            checkComment(true);
                            Navigator.of(context).popUntil(ModalRoute.withName('/AgendaMain'));
                          }
                        }
                      },
                      label: Column(
                        children: [
                          Image.asset(
                            'assets/images/cloudUpload.png',
                            color: Colors.white,
                            height: MediaQuery.of(context).size.height * 0.03
                          ),
                          Text(
                          widget.fromChecklist ?
                              '保存して追加' : '保存',
                              style: const TextStyle(
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
            ),
          ],
        )
    );
  }
}
