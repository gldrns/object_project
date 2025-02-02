
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:object_project/Camera/CameraWithBlackBoard.dart';
import 'package:object_project/Camera/DrawingProvider.dart';
import 'package:object_project/Camera/ImageDrawing.dart';
import 'package:object_project/FolderMake.dart';
import 'package:object_project/FolderSelect.dart';
import 'package:object_project/LodingPage.dart';
import 'package:object_project/Pictures/ImagePicker.dart';
import 'package:object_project/SnackbarPage.dart';
import 'package:object_project/ToastPage.dart';
import 'package:object_project/blackBoard/BlackBoardList.dart';
import 'package:http/http.dart' as http;

class PictureItemScreen extends StatefulWidget{
  final String folderPath;
  final String projectId;
  final Map<String, dynamic> pictureFolderData;
  final bool fromChecklist;
  late Function(bool) resetEditList;
  late Function(String,bool,int,int) editingFiles;
  late Function(bool, List<String>,String,List<String>,List<List>) onUploadToChecklist;
  late Function(bool) reload;
  final String fromNotification_folderId;
  final List<dynamic> fromNotification_itemId;

  PictureItemScreen({
    super.key,
    required this.folderPath,
    required this.projectId,
    required this.pictureFolderData,
    required this.fromChecklist,
    required this.resetEditList,
    required this.editingFiles,
    required this.onUploadToChecklist,
    required this.reload,
    required this.fromNotification_folderId,
    required this.fromNotification_itemId
  });

  @override
  PictureItemScreenState createState() => PictureItemScreenState();
}

class PictureItemScreenState extends State<PictureItemScreen>   {
  final RefreshController _refreshController =  RefreshController(initialRefresh: false);

  late String folderPath;
  late String folderId;
  String folderPathTitle = '写真';
  late List<String> folderNames = [];
  late String corporationId;

  List<String> folderPathList = [];

  late List<dynamic> pictureItems;
  late List<dynamic> pictureItems_whole;
  List<List<dynamic>> pictureItems_record = [];
  List<dynamic> pictureItems_last = [];

  late List<dynamic> pictureObjects;
  List<List<dynamic>> pictureObjects_record = [];
  List<dynamic> pictureObjects_last = [];

  late String projectId = widget.projectId;
  bool listSelected = false;
  int selectIndex = 0;
  String fileName = '';
  String folderName = '';
  String _userId = "";

  bool backAction = false;
  late String apiUrl;
  late TextEditingController textEditingController;

  late List<dynamic> overViewData;
  int selectedIndex_file = -1;
  int selectedIndex_folder = -1;
  List<String>selectedIndex_fileList = [];
  List<String>selectedFileIdList = [];
  List<Map<String,dynamic>>fileMapsList = [];
  bool selectedFiles = false;

  int folderIndex = 0;
  List<dynamic> folderObjects = [];
  bool isEditImage = false;
  String isEditImageText = "";
  late Function(bool,int) setIsEditImage;

  Color editColor = const Color(0xFF005F6B).withOpacity(0.5);
  List<String> editImagesList = [];

  bool editingFiles = false;
  String loadingText = "";
  int total = 0;
  int approved = 0;

  final ScrollController _scrollController = ScrollController();
  bool arrayFromNew = true;

  int insideCounter = 0;

  List<String> toChecklistId = [];
  List<String> toChecklistComment = [];
  List<List> toChecklistTags = [];
  List<String> selectedIndex_toChecklist = [];
  List<dynamic> notificationItemId = [];
  String notificationFolderId  = "";
  String newFolderName = "";
  List<String>_selectedUserIdList = [];

  @override
  void initState() {
    super.initState();
    setState(() {
      folderPath = widget.folderPath;
      pictureItems = widget.pictureFolderData['items'];
      pictureItems_whole = widget.pictureFolderData['items'];

      folderId = widget.pictureFolderData['id'];
      folderPathList.add(widget.pictureFolderData['folder_path']);

      pictureObjects = widget.pictureFolderData['objects'] ?? [];
      pictureItems_last = pictureItems;

      textEditingController = TextEditingController();
      notificationItemId = widget.fromNotification_itemId;
      notificationFolderId = widget.fromNotification_folderId;
    });

    getIdToken();

    pictureItems_record.add(pictureItems);
    folderNames.add('写真');
    pictureObjects_record.add(pictureObjects);

    if (notificationFolderId != '') {
      moveToFolder(notificationFolderId);
    }

    setIsEditImage = (bool value,int index) async {

      if (mounted) {
        setState(() {
          if (index != 9999) {
            pictureObjects_last.removeWhere((item) => item['id'] == selectedFileIdList[index]);
          }
          selectedIndex_fileList.clear();

          if (value) {
            if (index != 9999) {
              pictureObjects_last.removeWhere((item) => item['id'] == selectedFileIdList[index]);
            }
            selectedIndex_fileList.clear();
            isEditImage = false;
            selectedIndex_file = -1;
            selectedIndex_folder = -1;
            selectedFileIdList.clear();
            fileMapsList.clear();
          }
        });
      } else {
        if (index != 9999) {
          pictureObjects_last.removeWhere((item) => item['id'] == selectedFileIdList[index]);
        }
        selectedIndex_fileList.clear();

        if (value) {
          if (index != 9999) {
            pictureObjects_last.removeWhere((item) => item['id'] == selectedFileIdList[index]);
          }
          selectedIndex_fileList.clear();
          isEditImage = false;
          selectedIndex_file = -1;
          selectedIndex_folder = -1;
          selectedFileIdList.clear();
          fileMapsList.clear();
        }
      }
    };
  }

  Future<void> _refreshData() async {

    if (widget.fromChecklist) {
      bool versionCheck = await LoadingPage(loadingMessage: "").checkVersion();

      if (versionCheck) {
        // Map<String,dynamic>? responseData = await _httpService.returnMap_get(
        //     "$apiUrl/api/mobile/projects/$projectId/pictureFolder/pictures",0,{}
        // );
        //
        // if (responseData != null) {
        //   if (mounted) {
        //     setState(() {
        //       toChecklistId.clear();
        //       toChecklistComment.clear();
        //       toChecklistTags.clear();
        //       folderPathList.clear();
        //       pictureItems_record.clear();
        //       folderNames.clear();
        //       pictureObjects_record.clear();
        //       insideCounter = 0;
        //
        //       folderPathList.add(responseData['folder_path']);
        //       folderNames.add('写真');
        //
        //       pictureItems_whole = responseData['items'] ?? [];
        //       pictureItems = responseData['items'] ?? [] ;
        //       pictureItems_record.add(responseData['items'] ?? []);
        //       folderId = responseData['id'] ?? "";
        //       pictureObjects = responseData['objects'] ?? [];
        //       pictureObjects_record.add(responseData['objects'] ?? []);
        //     });
        //   }
        // }
      }
    }

    _refreshController.refreshCompleted();
  }

  void getIdToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiUrl = prefs.getString('apiUrl') ?? '';
      editImagesList = prefs.getStringList('editImages') ?? [];
      _userId = prefs.getString('id') ?? '';

      loadingText = prefs.getString("loadingText") ?? "";
      total = prefs.getInt("total") ?? 0;
      approved = prefs.getInt("approved") ?? 0;
      editingFiles = prefs.getBool('editingFiles') ?? false;
    });
  }

  void moveToFolder(String notification_folderId) async{

    if (folderId != notification_folderId) {
      int index = pictureItems.indexWhere((element) => element['id'] == notification_folderId);
      int innerIndex = pictureItems.indexWhere((element) => element['items'].toString().contains(notification_folderId) );

      if (index != -1) {
        setState(() {
          pictureItems_last = pictureItems[index]['items'];
          folderPathTitle = pictureItems[index]['name'];
          backAction = false;
          selectIndex = index;
          folderId = pictureItems[index]['id'];
          pictureObjects_last = pictureItems[index]['objects'] ?? [];
          folderPathList.add(pictureItems[index]['folder_path']);
          insideCounter++;
        });

        goPicturesItem(
            pictureItems[index]['items'],
            pictureItems[index]['name'].toString(),
            pictureItems[index]['objects'] ?? []
        );

        updatePicturesItem(
            newPicturesItem: pictureItems[index]['items'],
            newFolderName: '$folderPath/${pictureItems[index]['name'].toString()}',
            newPicturesItemObjects: pictureItems[index]['objects'] ?? []
        );

    } else if (innerIndex != -1) {
        setState(() {
          pictureItems_last = pictureItems[innerIndex]['items'];
          folderPathTitle = pictureItems[innerIndex]['name'];
          backAction = false;
          selectIndex = innerIndex;
          folderId = pictureItems[innerIndex]['id'];
          pictureObjects_last = pictureItems[innerIndex]['objects'] ?? [];
          folderPathList.add(pictureItems[innerIndex]['folder_path']);
          insideCounter++;
        });

        goPicturesItem(
            pictureItems[innerIndex]['items'],
            pictureItems[innerIndex]['name'].toString(),
            pictureItems[innerIndex]['objects'] ?? []
        );

        updatePicturesItem(
            newPicturesItem: pictureItems[innerIndex]['items'],
            newFolderName: '$folderPath/${pictureItems[innerIndex]['name'].toString()}',
            newPicturesItemObjects: pictureItems[innerIndex]['objects'] ?? []
        );

        moveToFolder(notification_folderId);
      }
    } else {
      setState(() {
        notificationFolderId = "";
      });
    }
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  void updatePicturesItem({
    required List<dynamic> newPicturesItem,
    required String newFolderName,
    required List<dynamic> newPicturesItemObjects
  }) {
    setState(() {
      pictureItems = newPicturesItem;
      folderPath = newFolderName;
      pictureObjects = newPicturesItemObjects;
    });
  }

  void goPicturesItem(
      List<dynamic> selectItem ,
      String selectPath,
      List<dynamic> selectObjectItem) {
    if (!backAction) {
      pictureItems_record.add(selectItem);
      folderNames.add(selectPath);
      pictureObjects_record.add(selectObjectItem);
    }
  }

  void backPicturesItem(String lastTitle){

    if (lastTitle == '写真') {
      setState(() {
        folderPathTitle = '資料';
      });
    } else {
      pictureItems_record.removeLast();
      folderNames.removeLast();
      pictureObjects_record.removeLast();

      setState(() {
        pictureItems_last = pictureItems_record.last;
        folderPathTitle = folderNames.last;
        pictureObjects_last = pictureObjects_record.last;
      });

      updatePicturesItem(
          newPicturesItem: pictureItems_record.last,
          newFolderName: folderNames.last,
          newPicturesItemObjects: pictureObjects_record.last
      );
    }
  }

  void selectFolder(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
          FolderSelect(
            picturesItems: pictureItems_whole,
            onFolderSelected: (
                selectObjectsList,
                selectFolderTitle,
                selectFolderId,
                selectFolderPath) {
              setState(() {
                showDialog (
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      '${selectedFileIdList.length}枚の写真を'
                      '"$selectFolderTitle"フォルダへ移動します。\nよろしいですか',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF005F6B)
                      )
                    ),
                    content: selectedFileIdList.length > 5 ?
                    const Text(
                      '状況により時間がかかる場合があります\n移動中は撮影等の作業はできません',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF005F6B)
                      )
                    ) : null,
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('キャンセル',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF005F6B)
                            )),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          List<dynamic> items = widget.pictureFolderData["items"];
                          for (int inner = 0; inner < items.length; inner++) {
                            if (items[inner]["folder_path"] == selectFolderPath) {
                              setState(() {
                                folderIndex = inner;
                              });
                            }
                          }

                          folderObjects = items[folderIndex]["objects"];
                          isEditImage = true;
                          isEditImageText = "写真移動中...";

                          prefs.setStringList("editImages", selectedFileIdList);
                          editImagesList = selectedFileIdList;
                          //else
                          List<String> checkedPermissionList = [];
                          for (int i = 0; i < selectedFileIdList.length; i++) {
                            if  (_selectedUserIdList[i] == _userId) {
                              checkedPermissionList.add(selectedFileIdList[i]);
                            }
                          }
                          prefs.setStringList("editImages", checkedPermissionList);
                          editImagesList = checkedPermissionList;

                          prefs.setBool("editingFiles", true);
                          moveImages(
                            folderIndex,
                            selectFolderTitle,
                            selectFolderPath,
                            apiUrl,
                            projectId,
                            fileMapsList,
                            selectedFileIdList,
                            folderPathList,
                            setIsEditImage,
                            widget.resetEditList,
                            widget.editingFiles,
                            editFolder,
                          );
                        },
                        child: const Text('移動',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF005F6B)
                            )
                        ),
                      )
                    ],
                  ),
                );
              });
            },
            fromChecklist: false,
            fromEdit: true,
            folderId: folderId,
            projectId: projectId,
            apiUrl: apiUrl,
          )
      ),
    );
  }

  void editFolder(String id, Map<String, dynamic> updateData) {

    bool updateItem(List<dynamic> items) {
      for (var item in items) {
        if (item is Map<String, dynamic> && item['id'] == id) {
          item.addAll(updateData);
          return true;
        }

        if (item is Map<String, dynamic> && item.containsKey('items') && item['items'] is List) {
          if (updateItem(item['items'])) {
            return true;
          }
        }
      }
      return false;
    }

    updateItem(pictureItems_whole);
  }

  static Future<void>moveImages (
      int folderIndex,
      String newFolderName,
      String newFolderPath,
      String apiUrl,
      String projectId,
      List<Map<String,dynamic>> fileMapsList,
      List<String>selectedFileIdList,
      List<String> folderPathList,
      Function(bool,int) setIsEditImage,
      Function(bool) resetEditList,
      Function(String, bool, int, int) editingFiles,
      Function(String, Map<String,dynamic>) editFolder,
  ) async {
    final completer = Completer<void>();
    final receivePort = ReceivePort();

    final String folderPathList_last = folderPathList.last;

    final String imageUrl = '$apiUrl/api/mobile/projects/$projectId/pictureFolder/pictures';


    moveImagePoint ({
      'sendPort': receivePort.sendPort,
      'newFolderPath' : newFolderPath,
      'imageUrl': imageUrl,
      'selectedFileIdList' : selectedFileIdList,
      'folderPathList' : folderPathList_last,
      'editFolder' : editFolder,
    });

    final prefs = await SharedPreferences.getInstance();

    receivePort.listen((dynamic data) async {
      int? nullableIndex = int.tryParse(data.split(':')[2]);
      int? nullableIndex_total = int.tryParse(data.split(':')[1].toString());

      if (data.toString().startsWith('start')) {
        if (nullableIndex != null && nullableIndex_total != null) {
          int index = nullableIndex;
          int index_total = nullableIndex_total;

          prefs.setBool("editingFiles", true);
          editingFiles("写真移動中...",true,index_total,index);
        }
      }

      if (data.toString().startsWith('success')) {
        if (nullableIndex != null && nullableIndex_total != null) {
          int index = nullableIndex;
          int index_total = nullableIndex_total;

          if (index + 1 == index_total) {
            SnackBarPage.showSnackBar(true, '写真の移動', '$newFolderNameに$index_total枚の写真を移動しました');
            prefs.remove('editImages');

            resetEditList(true);
            setIsEditImage(true,index);
            editingFiles("写真移動中...",false,index_total,index);

            completer.complete();
            receivePort.close();
          } else {
            int index = nullableIndex;
            int index_total = nullableIndex_total;

            editingFiles("写真移動中...",false,index_total,index);
            setIsEditImage(false,index);
          }
        }
      }

      if (data.toString().startsWith('error')) {

        SnackBarPage.showSnackBar(false,
            '写真移動中エラー', '$newFolderNameに移動中にエラーが発生しました');
        prefs.remove('editImages');

        resetEditList(true);

        completer.complete();
        receivePort.close();
      }
    });

    return completer.future;
  }

  static Future<void> moveImagePoint(Map<String, dynamic> message) async {
    final SendPort sendPort = message['sendPort'];
    final String newFolderPath = message['newFolderPath'];
    final String imageUrl = message['imageUrl'];
    final List<String> selectedFileIdList = List<String>.from(message['selectedFileIdList']);
    final String folderPathList = message['folderPathList'];
    final List<String> selectedFileIdList_back = List<String>.from(selectedFileIdList);
    Function(String, Map<String,dynamic>) editFolder = message['editFolder'];

    int moveIndex = selectedFileIdList_back.length;
    sendPort.send('start:$moveIndex:0');

    for (int i = 0; i < moveIndex; i++) {

      // Map<String,dynamic>? responseData = await _httpService.returnMap_put(
      //     imageUrl,
      //     {
      //       'id' : selectedFileIdList_back[i],
      //       'current_folder' : folderPathList,
      //       'new_folder' : newFolderPath,
      //     }, false,false
      // );
      //
      // if (responseData != null) {
      //   sendPort.send('success:$moveIndex:$i');
      //   if (i+1 == moveIndex) {
      //     editFolder(responseData['folder']['id'],responseData['folder']);
      //   }
      // } else {
      //   sendPort.send('error:$moveIndex:$i');
      // }
    }
  }

  bool canImageEdit(Map<String,dynamic> fileMap) {
    if ((fileMap['use_report'] != null &&
        fileMap['use_report'] != 0) ||
        (fileMap['use_checklist'] != null &&
        fileMap['use_checklist'].isNotEmpty) ||
      (  fileMap['use_report_file'] != null &&
        fileMap['use_report_file'].isNotEmpty)
    ) {
      return false;
    } else {
      return true;
    }
  }

  static Future<void>deleteImages (
      String newFolderName,
      String apiUrl,
      String projectId,
      List<Map<String,dynamic>> fileMapsList,
      List<String>selectedFileIdList,
      Function(bool,int) setIsEditImage,
      Function(bool) resetEditList,
      Function(String, bool,int, int) editingFiles,
      ) async {
    final completer = Completer<void>();
    final receivePort = ReceivePort();

    final String imageUrl = '$apiUrl/api/mobile/projects/$projectId/pictureFolder/pictures';

    deleteImagesPoint ({
      'sendPort': receivePort.sendPort,
      'imageUrl': imageUrl,
      'selectedFileIdList' : selectedFileIdList,
    });

    final prefs = await SharedPreferences.getInstance();

    receivePort.listen((dynamic data) async {
      int? nullableIndex = int.tryParse(data.split(':')[2]);
      int? nullableIndex_total = int.tryParse(data.split(':')[1].toString());
      int? nullableIndex_report = int.tryParse(data.split(':')[3].toString()) ?? 0;
      bool? imageInReport = bool.tryParse(data.split(':')[4].toString()) ?? false;

      if (data.contains('start')) {
        if (nullableIndex != null && nullableIndex_total != null) {
          int index = nullableIndex;
          int index_total = nullableIndex_total;

          prefs.setBool("editingFiles", true);
          editingFiles("写真削除中...",true,index_total,index);
        }
      }

      if (data.contains('success')) {
        if (nullableIndex != null && nullableIndex_total != null) {
          int index = nullableIndex;
          int index_total = nullableIndex_total;
          int index_report = nullableIndex_report;
          bool index_bool = imageInReport;

          if (index + 1 == index_total) {
            if (index_total-index_report > 0) {
              String deleteMessage = '$newFolderNameの${index_total-index_report}枚写真を削除しました';

              if (nullableIndex_report > 0) {
                deleteMessage += "\n(報告,報告書,チェクリストで使用中写真：$index_report枚)";
              }

              SnackBarPage.showSnackBar(true, '写真削除結果', deleteMessage);
              prefs.remove("editImages");
              editingFiles("写真削除中...",false,index_total,index);

              resetEditList(true);
              if (!index_bool) {
                setIsEditImage(true,index);
              } else {
                setIsEditImage(true,9999);
              }
            } else {
              SnackBarPage.showSnackBar(true, '写真削除結果', '報告,報告書,チェクリストで使用中ため、削除できません');
              resetEditList(true);
              setIsEditImage(true,9999);
            }
            completer.complete();
            receivePort.close();
          } else {
            int index = nullableIndex;
            int index_total = nullableIndex_total;
            bool index_bool = imageInReport;

            editingFiles("写真削除中...",false,index_total,index);

            if (!index_bool) {
              setIsEditImage(false,index);
            }
          }
        }
      }

      if (data.contains('error')) {

        SnackBarPage.showSnackBar(false, '写真削除結果', '$newFolderNameの写真削除中にエラーが発生しました');
        prefs.remove("editImages");
        resetEditList(true);

        completer.complete();
        receivePort.close();
      }
    });

    return completer.future;
  }

  static Future<void> deleteImagesPoint(Map<String, dynamic> message
      ) async {
    final SendPort sendPort = message['sendPort'];
    final String imageUrl = message['imageUrl'];
    final List<String> selectedFileIdList = List<String>.from(message['selectedFileIdList']);

    int deleteIndex = selectedFileIdList.length;
    sendPort.send('start:$deleteIndex:0:0:false');
    int reportPictureIndex = 0;

    for (int i = 0; i < deleteIndex; i++) {

      // Map<String,dynamic>? responseData = await _httpService.returnMap_delete(
      //     "$imageUrl/${selectedFileIdList[i]}",
      //     {}
      // );
      // if (responseData != null) {
      //   if (responseData.toString().contains('写真が削除できません')) {
      //     reportPictureIndex++;
      //     sendPort.send('success:$deleteIndex:$i:$reportPictureIndex:true');
      //   } else {
      //     sendPort.send('success:$deleteIndex:$i:$reportPictureIndex:false');
      //   }
      // } else {
      //   sendPort.send('error:$deleteIndex:$i:$reportPictureIndex:false');
      // }
    }
  }

  Future<void> _startSelectPage(List<dynamic> objectList, bool checkUpload) async {
    final prefs = await SharedPreferences.getInstance();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) {
        return Theme(
          data: Theme.of(context).copyWith(
            iconTheme: IconThemeData(
              color: Theme.of(context).primaryColor,
            ),
            textTheme: Theme.of(context).textTheme.copyWith(
              labelLarge: TextStyle(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.opaque,
              child: GridView.count(
                crossAxisCount: 3,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            selectedIndex_file = -1;
                            selectedIndex_folder = -1;
                            selectedIndex_fileList.clear();
                            selectedFileIdList.clear();
                            fileMapsList.clear();
                            _selectedUserIdList.clear();
                          });
                          Navigator.pop(context);
                          // createFolder(context);
                        },
                        icon: Container(
                          color: Colors.transparent,
                          child: Icon(
                            Icons.create_new_folder_outlined,
                            color:const Color(0xFF005F6B),
                          ),
                        ),
                      ),
                       Text('フォルダ追加',
                          style: TextStyle(
                            color: const Color(0xFF005F6B),
                            fontWeight: FontWeight.bold,
                          )
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            selectedIndex_file = -1;
                            selectedIndex_folder = -1;
                            selectedIndex_fileList.clear();
                            selectedFileIdList.clear();
                            fileMapsList.clear();
                            _selectedUserIdList.clear();
                          });
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    ImagesPicker(
                                      folderPath: folderPath,
                                      items_whole: pictureItems_whole,
                                      projectId: projectId,
                                      folderPathTitle: folderPathTitle,
                                      folderId: folderId,
                                      objectsList : pictureObjects,
                                      fromPictureItems: true,
                                      fromReport: false,
                                      fromChecklist: false,
                                      reportImagesList : [],
                                      imagesByte: [],
                                      takePictureTime: [],
                                      onUploadComplete : (uploadFinish, uploadFolder, selectedFolder) async {
                                        if(mounted) {
                                          setState(() {
                                            selectedFolder = uploadFolder;
                                            if (uploadFinish) {
                                              widget.resetEditList(true);
                                            }
                                          });
                                        } else {
                                          selectedFolder = uploadFolder;
                                          if (uploadFinish) {
                                            widget.resetEditList(true);
                                          }
                                        }
                                      },
                                      onEditImagesByte: (onEditImagesByte,onEditImagesFile) {  },
                                      onUpdateReport: (List<File> updateFile,
                                          uploadFolderId, uploadFolderPath,uploadFolderName) {  },
                                      editingFiles: (String editText, bool add, int total, int approved) {
                                        if(mounted) {
                                          setState(() {
                                            widget.editingFiles(editText,add,total,approved);
                                          });
                                        } else {
                                          widget.editingFiles(editText,add,total,approved);
                                        }
                                      },
                                      // onUploadToChecklist: (fromAgentFolder, byteList, fileList,folderPath ,fileComment,tags) {  },
                                      settingFolderForChecklist: (newFolderPathTitle , newFolderId , newObjectList,newFolderPath) {  },
                                    )
                            ),
                          );
                        },
                        icon: Container(
                          color: Colors.transparent,
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            color: const Color(0xFF005F6B),
                          ),
                        ),
                      ),
                      Text('写真追加',
                        style: TextStyle(
                          color: const Color(0xFF005F6B),
                          fontWeight: FontWeight.bold,
                        )
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            selectedIndex_file = -1;
                            selectedIndex_folder = -1;
                            selectedIndex_fileList.clear();
                            selectedFileIdList.clear();
                            fileMapsList.clear();
                            _selectedUserIdList.clear();
                          });
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    BlackBoardList(
                                      folderPath: folderPath,
                                      fromChecklist: false,
                                      fromDrawing: false,
                                      items_whole: pictureItems_whole,
                                      projectId: projectId,
                                      folderPathTitle: folderPathTitle,
                                      folderId: folderId,
                                      objectsList: pictureObjects,
                                      overViewData : overViewData,
                                      addBlackboard: (svgString, comment, add) {},
                                      onUploadComplete : (uploadFinish, uploadFolder, selectedFolder) async {
                                        if(mounted) {
                                          setState(() {
                                            selectedFolder = uploadFolder;
                                            if (uploadFinish) {
                                              widget.resetEditList(true);
                                            }
                                          });
                                        } else {
                                          selectedFolder = uploadFolder;
                                          if (uploadFinish) {
                                            widget.resetEditList(true);
                                          }
                                        }
                                      },
                                      editingFiles: (String editText, bool add, int total, int approved) {
                                        if(mounted) {
                                          setState(() {
                                            widget.editingFiles(editText,add,total,approved);
                                          });
                                        } else {
                                          widget.editingFiles(editText,add,total,approved);
                                        }
                                      },
                                      // onUploadToChecklist:(fromAgentFolder, byteList, fileList,folderPath,fileComment,tags) {},
                                      settingFolderForChecklist: (newFolderPathTitle , newFolderId , newObjectList, newFolderPath) {  },
                                    )
                            ),
                          ).then((result) {
                            setState(() {
                              pictureObjects = pictureObjects;
                            });
                          });
                        },
                        icon:
                        Container(
                          color: Colors.transparent,
                            child: Icon(
                              Icons.add_box_outlined,
                              color: const Color(0xFF005F6B) ,
                            )
                          )
                      ),
                      Text(
                        '黒板あり\n写真撮影',
                        style: TextStyle(
                          color: const Color(0xFF005F6B),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            selectedIndex_file = -1;
                            selectedIndex_folder = -1;
                            selectedIndex_fileList.clear();
                            selectedFileIdList.clear();
                            fileMapsList.clear();
                            _selectedUserIdList.clear();
                          });
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CameraWithBlackBoard(
                                folderPath: folderPath,
                                commentFromBlackboard : "",
                                fromChecklist: false,
                                items_whole: pictureItems_whole,
                                projectId: projectId,
                                folderPathTitle: folderPathTitle,
                                folderId: folderId,
                                objectsList: pictureObjects,
                                imagesByte: [],
                                takePictureTime: [],
                                svgImageUrl: '',
                                imagesFile: [],
                                overViewData: overViewData,
                                onUploadComplete : (uploadFinish, uploadFolder, selectedFolder) async {
                                  if(mounted) {
                                    setState(() {
                                      selectedFolder = uploadFolder;
                                      if (uploadFinish) {
                                        widget.resetEditList(true);
                                      }
                                    });
                                  } else {
                                    selectedFolder = uploadFolder;
                                    if (uploadFinish) {
                                      widget.resetEditList(true);
                                    }
                                  }
                                },
                                editingFiles: (String editText, bool add,int total, int approved) {
                                  if(mounted) {
                                    setState(() {
                                      widget.editingFiles(editText,add,total,approved);
                                    });
                                  } else {
                                    widget.editingFiles(editText,add,total,approved);
                                  }
                                },
                                // onUploadToChecklist:(fromAgentFolder, byteList, fileList,folderPath ,fileComment,tags) {},
                                settingFolderForChecklist: (newFolderPathTitle , newFolderId , newObjectList,newFolderPath) {  },
                              ),
                            ),
                          );
                        },
                        icon: Container(
                          color: Colors.transparent,
                          child: Icon(
                            Icons.camera_alt_outlined,
                            color: const Color(0xFF005F6B),
                          )
                        )
                      ),
                      Text(
                        '黒板なし\n写真撮影',
                        style: TextStyle(
                          color: const Color(0xFF005F6B),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (checkUpload) {
                            ToastPage.showToast('写真アップロード中です');
                          } else {
                            if (objectList.isEmpty) {
                              ToastPage.showToast("選択できる写真がありません");
                            } else {
                              setState(() async{
                                editImagesList = prefs.getStringList("editImages") ?? [];
                                for (int i = 0; i < pictureObjects_last.length; i ++) {
                                  if (!selectedIndex_fileList.contains(i.toString()) &&
                                      canImageEdit(objectList[i]) &&
                                      (objectList[i]['created_by'][0] == _userId)) {
                                    selectedIndex_fileList.add(i.toString());
                                    selectedFileIdList.add(objectList[i]['id'].toString());
                                    fileMapsList.add(objectList[i]);
                                    _selectedUserIdList.add(objectList[i]['created_by'][0].toString());
                                  }

                                  if (i + 1 == pictureObjects_last.length &&
                                      selectedIndex_fileList.isEmpty) {
                                    ToastPage.showToast("選択できる写真がありません");
                                  }
                                }
                              });
                            }
                            Navigator.pop(context);
                          }
                        },
                        icon: Icon(
                          Icons.checklist_outlined,
                          color: const Color(0xFF005F6B),
                        ),
                      ),
                      const Text(
                       '選択可能なもの\nすべて選択',
                        style: TextStyle(
                          color: Color(0xFF005F6B),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            selectedIndex_fileList.clear();
                            selectedFileIdList.clear();
                            fileMapsList.clear();
                            _selectedUserIdList.clear();
                          });
                        },
                        icon: Icon(
                          Icons.cancel_outlined,
                          color: selectedIndex_fileList.isEmpty ?
                          Colors.grey : const Color(0xFF005F6B),
                        )
                      ),
                      Text('選択キャンセル',
                          style: TextStyle(
                            color: selectedIndex_fileList.isEmpty ?
                            Colors.grey : const Color(0xFF005F6B),
                            fontWeight: FontWeight.bold,
                          )
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {

                          if (selectedIndex_fileList.isEmpty) {
                            ToastPage.showToast('選択された写真がありません');
                          } else {
                            if (checkUpload) {
                              ToastPage.showToast('写真アップロード中です');
                            } else {
                              Navigator.pop(context);
                              selectFolder(context);
                            }
                          }
                        },
                        icon: Icon(
                          Icons.drive_file_move_outlined,
                          color: selectedIndex_fileList.isEmpty ?
                          Colors.grey : const Color(0xFF005F6B)
                        ),
                      ),
                      Text('写真移動',
                          style: TextStyle(
                            color: selectedIndex_fileList.isEmpty ?
                            Colors.grey : const Color(0xFF005F6B),
                            fontWeight: FontWeight.bold,
                          )
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (selectedIndex_fileList.isEmpty) {
                            ToastPage.showToast('選択された写真がありません');
                          } else {

                            Navigator.pop(context);
                            setState(() {
                              selectedIndex_file = -1;
                            });

                            if (checkUpload) {
                              ToastPage.showToast('写真アップロード中です');
                            } else {
                              showDialog (
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                      '${selectedFileIdList.length}枚の写真を削除します。\nよろしいですか',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF005F6B))
                                  ),
                                  content: selectedFileIdList.length > 5 ?
                                  const Text(
                                      '状況により時間がかかる場合があります\n削除中は撮影等の作業はできません',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF005F6B)
                                      )
                                  ) : null,
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text('キャンセル',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF005F6B)
                                          )),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);

                                        isEditImage = true;
                                        isEditImageText = "写真削除中...";

                                        prefs.setStringList("editImages", selectedFileIdList);
                                        editImagesList = selectedFileIdList;
                                        //else
                                        List<String> checkedPermissionList = [];
                                        for (int i = 0; i < selectedFileIdList.length; i++) {
                                          if  (_selectedUserIdList[i] == _userId) {
                                            checkedPermissionList.add(selectedFileIdList[i]);
                                          }
                                        }
                                        prefs.setStringList("editImages", checkedPermissionList);
                                        editImagesList = checkedPermissionList;

                                        prefs.setBool("editingFiles", true);

                                        deleteImages(
                                          folderPathTitle,
                                          apiUrl,
                                          projectId,
                                          fileMapsList,
                                          selectedFileIdList,
                                          setIsEditImage,
                                          widget.resetEditList,
                                          widget.editingFiles,

                                        );
                                      },
                                      child: const Text('削除',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red
                                          )
                                      ),
                                    )
                                  ],
                                ),
                              );
                            }
                          }
                        },
                        icon:
                        Icon(
                          Icons.delete_outline,
                          color: selectedIndex_fileList.isEmpty ?
                          Colors.grey : Colors.red,
                        )
                      ),
                      Text('写真削除',
                          style: TextStyle(
                            color: selectedIndex_fileList.isEmpty ?
                            Colors.grey : Colors.red,
                            fontWeight: FontWeight.bold,
                          )
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // void createFolder(BuildContext context) async {
  //
  //   await showDialog<String>(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         contentPadding: EdgeInsets.zero,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(8.0),
  //         ),
  //         content: SizedBox(
  //           height: MediaQuery.of(context).size.height * 0.3,
  //           width: MediaQuery.of(context).size.width,
  //           child: ClipRRect(
  //             borderRadius: BorderRadius.circular(8.0),
  //             child: FolderMake(
  //               // projectId: projectId,
  //               // parentFolderId: folderId,
  //               // folderPath: folderPathList.last,
  //               itemsList : pictureItems,
  //               onUploadComplete : (uploadFolder,makeFolder) {
  //                 setState(() {
  //                   uploadFolder.add(makeFolder);
  //                 });
  //               }
  //             ),
  //           ),
  //         )
  //       );
  //     },
  //   );
  // }

  Future<void> downloadImage(String signedUrl) async {
    final response = await http.get(Uri.parse(signedUrl));

    if (response.statusCode == 200) {
      await ImageGallerySaver.saveImage(Uint8List.fromList(response.bodyBytes));
      setState(() {
        selectedIndex_file = -1;
      });
      ToastPage.showToast('写真をダウンロードしました');
    } else {
      ToastPage.showToast('ダウンロードに失敗しました');
    }
  }

  void showFileOptionsBottomSheet(
      List<dynamic> itemList,
      List<dynamic> objectList,
      Map<String,dynamic> fileMap,
      ) {

    String thumbnailUrl = fileMap['full_path_thumbnail'] ?? "";
    String fileUrl = fileMap['full_path'] ?? "";

    String selectName = fileMap['display_name'].toString();
    String selectId = fileMap['id'].toString();
    String selectComment = fileMap['comment'].toString();
    List<dynamic> selectTags =
    fileMap['tags'] == null ||
    fileMap['tags'].toString() == "[[]]" ||
    fileMap['tags'].toString() == "[]" ? [] : fileMap['tags'];
    List createdBy = fileMap['created_by'];

    Map<String,dynamic> editMap = {
      "items_whole": pictureItems_whole,
      "pictureFolderData": widget.pictureFolderData,
      "projectId": projectId,
      "fileId": selectId,
      "fileName": selectName,
      "fileUrl": thumbnailUrl,
      "folderPathTitle": folderNames.last,
      "folderPath":folderPathList.last,
      "editImage": true,
      "fromItemScreen": true,
      "fileByte": Uint8List(0),
      "typeIsFile": false,
      "file": File(''),
      "fileMap": fileMap,
      "fileComment": selectComment,
      "tagsList": selectTags,
      "created_by": createdBy[0].toString(),
      "overViewData" : overViewData
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: "/Drawing"),
        builder: (context) => ChangeNotifierProvider(
          create: (context) => DrawingProvider(),
          child: ImageDrawing(
            imageName: selectName,
            imageThumbnail: thumbnailUrl,
            projectId: projectId,
            folderPathTitle: folderPathTitle,
            folderId: folderId,
            objectsList : pictureObjects,
            onUploadComplete : (uploadFolder,uploadImage) {
              setState(() {
                uploadFolder.add(uploadImage);
              });
            },
            typeIsFile: false,
            imageUrl: fileUrl,
            imageByte: Uint8List(0),
            imageFile: File(''),
            onEditImage: (File editImage, bool upload) {},
            onDelete: (bool onDelete) async {
              if (onDelete) {
                // bool deleteSuccess =
                // await _httpService.delete(
                //     '$apiUrl/api/mobile/projects/$projectId/pictureFolder/pictures/$selectId',
                //     {}
                // );
                //
                // if (deleteSuccess) {
                //   if (mounted) {
                //     setState(() {
                //       SnackBarPage.showSnackBar(true,'写真削除','$selectNameを削除しました');
                //       objectList.removeWhere((item) => item['id'] == selectId);
                //       selectedIndex_fileList.clear();
                //       selectedFileIdList.clear();
                //       fileMapsList.clear();
                //     });
                //   } else {
                //     SnackBarPage.showSnackBar(true,'写真削除','$selectNameを削除しました');
                //     objectList.removeWhere((item) => item['id'] == selectId);
                //     selectedIndex_fileList.clear();
                //     selectedFileIdList.clear();
                //     fileMapsList.clear();
                //   }
                // } else {
                //   ToastPage.showToast('写真削除に失敗しました');
                // }
              }
            },
            fromList: true,
            editMap: editMap,
            onEditComplete: (String editName,String editComment,
                List editTags, bool moveFile) {
              if(mounted) {
                int index = objectList.indexWhere((item) => item['id'] == selectId);
                if (index != -1) {
                  setState(() {
                    objectList[index]['display_name'] = editName;
                    objectList[index]['name'] = editName;
                    objectList[index]['comment'] = editComment;
                    if (editTags != []) {
                      objectList[index]['tags'] = editTags;
                    }
                  });
                }

                if (moveFile) {
                  setState(() {
                    pictureObjects_last.remove(fileMap);
                  });
                }
              } else {
                int index = objectList.indexWhere((item) => item['id'] == selectId);
                if (index != -1) {
                  objectList[index]['display_name'] = editName;
                  objectList[index]['name'] = editName;
                  objectList[index]['comment'] = editComment;
                  if (editTags != []) {
                    objectList[index]['tags'] = editTags;
                  }
                }

                if (moveFile) {
                  pictureObjects_last.remove(fileMap);
                }
              }
            },
          ),
        ),
      ),
    );
  }

  void showFolderOptionsBottomSheet(
      List<dynamic> itemList,
      int folderIndex,
      String selectName,
      String selectId,
      String folderPath
      ) {
    String newName = selectName;

    textEditingController.text = selectName;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.3,
          child: Theme(
            data: Theme.of(context).copyWith(
              iconTheme: IconThemeData(
                color: Theme.of(context).primaryColor,
              ),
              textTheme: Theme.of(context).textTheme.copyWith(
                labelLarge: TextStyle(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            child: GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.opaque,
              child: GridView.count(
                crossAxisCount: 2,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center ,
                    children: [
                      IconButton(
                          onPressed: () {
                            Navigator.pop(context);
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
                                              'フォルダ名変更',
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
                                            '新しいフォルダ名',
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
                                                fontWeight: FontWeight.bold
                                            ),
                                            maxLength: 30,
                                            controller: textEditingController,
                                            keyboardType: TextInputType.text,
                                            decoration: InputDecoration(
                                              focusedBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: newName.isEmpty ? Colors.grey : const Color(0xFF005F6B),
                                                ),
                                              ),
                                              enabledBorder: const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              counterStyle: TextStyle(
                                                color: newName.isEmpty ? Colors.grey : const Color(0xFF005F6B),
                                              ),
                                            ),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                RegExp(r'[a-zA-Z\dぁ-ゔァ-ヴー一-龥々〆〤ー_ -]'),
                                              ),
                                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                newName = value;
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
                                                  onPressed: () async {
                                                    if (newName != '') {
                                                      Navigator.pop(context);

                                                      // Map<String,dynamic>? responseData = await _httpService.returnMap_put(
                                                      //     '$apiUrl/api/mobile/projects/$projectId/folder/$selectId',
                                                      //     {
                                                      //       "folder_path" : folderPath,
                                                      //       "name" : newName
                                                      //     }, false,false
                                                      // );
                                                      //
                                                      // if (responseData != null) {
                                                      //   setState(() {
                                                      //     selectedIndex_folder = -1;
                                                      //     int index = itemList.indexWhere((item) => item['id'] == selectId);
                                                      //     if (index != -1) {
                                                      //       itemList[index]['name'] = newName;
                                                      //     }
                                                      //   });
                                                      //   ToastPage.showToast('フォルダ名を編集しました');
                                                      // } else {
                                                      //   ToastPage.showToast('フォルダ名を編集中エラー発生');
                                                      // }
                                                    } else {
                                                      ToastPage.showToast('フォルダ名を入力してください');
                                                    }
                                                  },
                                                  child: const Center(
                                                    child: Text(
                                                      '修正',
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
                          },
                        icon: Icon(
                          Icons.edit_outlined,
                          color: const Color(0xFF005F6B),
                        ),
                      ),
                      Text('フォルダ名修正',
                        style: TextStyle(
                          color: const Color(0xFF005F6B) ,
                          fontWeight: FontWeight.bold,
                        )
                      ),
                    ]
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (itemList[folderIndex].toString().contains("use_report") ||
                              itemList[folderIndex].toString().contains("use_report_file") ||
                              itemList[folderIndex].toString().contains("use_checklist")
                          ) {
                            ToastPage.showToast('報告,報告書,チェクリストで使用中ため、削除できません');
                          } else {
                            showDialog (
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                    '$selectNameを削除します。\nよろしいですか',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF005F6B))
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('キャンセル',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF005F6B)
                                        )),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      // bool deleteSuccess = await _httpService.delete(
                                      //     '$apiUrl/api/mobile/projects/$projectId/folder/$selectId',
                                      //     {"folder_path" : folderPath}
                                      // );
                                      //
                                      // if (deleteSuccess) {
                                      //   SnackBarPage.showSnackBar(true, 'フォルダ削除', '$selectNameを削除しました');
                                      //   widget.reload(true);
                                      // }
                                    },
                                    child: const Text('削除',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red
                                        )
                                    ),
                                  )
                                ],
                              ),
                            );
                          }
                        },
                        icon:
                        Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        )
                      ),
                      Text('フォルダ削除',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        )
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int getTotalObjectsCount(Map<String, dynamic> data) {
    int totalFileCount = 0;

    if (data.containsKey('objects') && data['objects'] is List) {
      List<dynamic> objectsList = data['objects'];
      totalFileCount += objectsList.length;
    }

    if (data.containsKey('items') && data['items'] is List) {
      List<dynamic> itemsList = data['items'];
      for (var item in itemsList) {
        totalFileCount += getTotalObjectsCount(item);
      }
    }

    return totalFileCount;
  }


  @override
  Widget build(BuildContext context) {
    List<Widget> projectFolderList =
        pictureItems.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> data = entry.value;

        fileName = data['name'].toString();

        int totalFileCount = getTotalObjectsCount(data);

        return GestureDetector(
          onLongPress: () {
            if (!widget.fromChecklist) {
              setState(() {
                selectedIndex_folder = index;
                selectedIndex_file = -1;
                selectedIndex_fileList.clear();
                selectedFileIdList.clear();
                fileMapsList.clear();
              });
              showFolderOptionsBottomSheet(
                  pictureItems_last,
                  index,
                  data['name'],
                  data['id'],
                  data['folder_path']
              );
            }
          },
          onTap: () {
            setState(() {
              if (widget.fromChecklist) {
                selectedIndex_toChecklist.clear();
                toChecklistId.clear();
                toChecklistComment.clear();
                toChecklistTags.clear();
              } else {
                selectedIndex_folder = -1;
                selectedIndex_file = -1;
                selectedIndex_fileList.clear();
                selectedFileIdList.clear();
                fileMapsList.clear();
              }
              pictureItems_last = data['items'] ?? [];
              folderPathTitle = data['name'] ?? [];
              backAction = false;
              folderId = data['id'] ?? '';
              pictureObjects_last = data['objects'] ?? [];

              folderPathList.add(data['folder_path']);
              insideCounter++;
            }
            );
            goPicturesItem(
                data['items'],
                data['name'].toString(),
                data['objects'] ?? []
            );
            updatePicturesItem(
              newPicturesItem: data['items'],
              newFolderName: '$folderPath/${data['name'].toString()}',
              newPicturesItemObjects: data['objects'] ?? [],
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Icon(
                      Icons.folder_open_outlined,
                      color: isEditImage ? editColor : const Color(0xFF005F6B),
                    ),
                    if (selectedIndex_folder == index)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    if (selectedIndex_folder == index)
                      const Positioned(
                        top: 10,
                        right: 0,
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF005F6B),
                          size: 20,
                        ),
                      ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(
                        color: Color(0xFF005F6B),
                      ),
                    ),
                    Text(
                      '$totalFileCount個',
                      style: const TextStyle(
                        color: Color(0xFF005F6B),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList();

    List<Widget> projectImageList =
    pictureObjects.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> data = entry.value ?? {};

      fileName = (data['display_name'] ?? data['name']).toString();

      if (notificationItemId.contains(data['id'])) {
        widget.reload(false);
      }

      return GestureDetector(
        onLongPress: () {
          if (!widget.fromChecklist) {
            if (editImagesList.contains(data['id'].toString())) {
              ToastPage.showToast('移動または削除中のファイルです');
            } else {
              setState(() {
                selectedIndex_file = -1;
                selectedIndex_folder = -1;
                if (selectedIndex_fileList.contains(index.toString())) {
                  selectedIndex_fileList.remove(index.toString());
                  selectedFileIdList.remove(data['id'].toString());
                  fileMapsList.remove(data);
                  _selectedUserIdList.remove(data['created_by'][0].toString());
                } else {
                  if (
                  canImageEdit(data) &&
                 ((data['created_by'] != null && data['created_by'][0] == _userId))) {
                    selectedFiles = true;
                    selectedIndex_fileList.add(index.toString());
                    selectedFileIdList.add(data['id'].toString());
                    fileMapsList.add(data);
                    _selectedUserIdList.add(data['created_by'][0].toString());
                  } else {
                    ToastPage.showToast('編集権限がない写真です');
                  }
                }
              });
            }
          }
        },
        onDoubleTap: () {
          showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Image.network(data['full_path'].toString(), fit: BoxFit.cover),
                    ),
                  ],
                ),
              );
            },
          );
        },
        onTap: () {
          if(widget.fromChecklist) {
            if (selectedIndex_toChecklist.contains(index.toString())) {
              setState(() {
                selectedIndex_toChecklist.remove(index.toString());
                toChecklistId.remove(data['id'].toString());
                toChecklistComment.remove(data['comment'].toString());
                toChecklistTags.remove(data['tags'] ?? []);
              });
            } else {
              setState(() {
                selectedIndex_toChecklist.add(index.toString());
                toChecklistId.add(data['id'].toString());
                toChecklistComment.add(data['comment'].toString());
                toChecklistTags.add(data['tags'] ?? []);
              });
            }
          } else {
            if (editImagesList.contains(data['id'].toString())) {
              ToastPage.showToast('移動または削除中のファイルです');
            } else {
              if (selectedIndex_fileList.isEmpty) {
                setState(() {
                  selectedIndex_folder = -1;
                });
                showFileOptionsBottomSheet(
                    pictureItems_last,
                    pictureObjects_last,
                    data,
                );
              } else {
                if (selectedIndex_fileList.contains(index.toString())) {
                  setState(() {
                    selectedIndex_fileList.remove(index.toString());
                    selectedFileIdList.remove(data['id'].toString());
                    fileMapsList.remove(data);
                    _selectedUserIdList.remove(data['created_by'][0].toString());
                  });
                } else {
                  if (
                  canImageEdit(data) &&
                  ((data['created_by'] != null &&
                    data['created_by'][0] == _userId))) {
                      setState(() {
                        selectedIndex_fileList.add(index.toString());
                        selectedFileIdList.add(data['id'].toString());
                        fileMapsList.add(data);
                        _selectedUserIdList.add(data['created_by'][0].toString());
                      });
                  } else {
                    ToastPage.showToast('編集権限がない写真です');
                  }
                }
              }
            }
          }
        },

        child: Container(
          margin: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Stack(
                children: [
                  Image.network(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: MediaQuery.of(context).size.height * 0.2,
                    data['full_path_thumbnail'].toString() == "" ||
                    data['full_path_thumbnail'].toString() == "null" ||
                    data['full_path_thumbnail'] == null ?
                    data['full_path'].toString() : data['full_path_thumbnail'].toString(),
                    errorBuilder: (context, error, stackTrace) {
                      return Image.network(
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: MediaQuery.of(context).size.height * 0.2,
                          data['full_path'].toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                           return Icon(
                             Icons.error_outline,
                           );
                        }
                      );
                    },
                    loadingBuilder: (
                        BuildContext context,
                        Widget child,
                        ImageChunkEvent? loadingProgress,
                        ) {
                      if (loadingProgress != null) {
                        return  const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005F6B))
                        );
                      }
                      return child;
                    },
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child:  Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if(data['use_report'] != null && data['use_report'] != 0)
                          Icon(
                            Icons.report_gmailerrorred
                          ),
                        if(data['use_report_file'] != null && data['use_report_file'].isNotEmpty)
                          Transform.translate(
                            offset: Offset(
                                data['use_report'] != null && data['use_report'] != 0 ?
                                -10 : 0, 0
                            ),
                            child: Icon(
                                Icons.file_open_outlined
                            ),
                          ),
                        if(data['use_checklist'] != null && data['use_checklist'].isNotEmpty)
                          Transform.translate(
                            offset: Offset(
                                data['use_report'] != null && data['use_report'] != 0 &&
                                data['use_report_file'] != null && data['use_report_file'].isNotEmpty ?
                                -20 :
                                data['use_report'] != null && data['use_report'] != 0 ?
                                -10 :
                                data['use_report_file'] != null && data['use_report_file'].isNotEmpty ?
                                -10 : 0, 0
                            ),
                            child:  Icon(
                                Icons.check_box_outlined
                            ),
                          ),
                        if(notificationItemId.contains(data['id']))
                          Transform.translate(
                            offset: Offset(
                                data['use_report'] != null && data['use_report'] != 0 &&
                                data['use_report_file'] != null && data['use_report_file'].isNotEmpty &&
                                data['use_checklist'] != null && data['use_checklist'].isNotEmpty ?
                                -30 :
                                data['use_report'] != null && data['use_report'] != 0 &&
                                data['use_report_file'] != null && data['use_report_file'].isNotEmpty ?
                                -20 :
                                data['use_report'] != null && data['use_report'] != 0 &&
                                data['use_checklist'] != null && data['use_checklist'].isNotEmpty ?
                                -20 :
                                data['use_report_file'] != null && data['use_report_file'].isNotEmpty &&
                                data['use_checklist'] != null && data['use_checklist'].isNotEmpty ?
                                -20 :
                                data['use_report'] != null && data['use_report'] != 0 ?
                                -10 :
                                data['use_report_file'] != null && data['use_report_file'].isNotEmpty ?
                                -10 :
                                data['use_checklist'] != null && data['use_checklist'].isNotEmpty ?
                                -10 : 0, 0
                            ),
                            child: Icon(
                                Icons.star_border
                            ),
                          ),
                      ],
                    )
                  ),
                  if (
                  selectedIndex_toChecklist.contains(index.toString()) ||
                  selectedIndex_file == index ||
                  selectedIndex_fileList.contains(index.toString()) ||
                  isEditImage
                  )
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  if (
                  selectedIndex_toChecklist.contains(index.toString()) ||
                  selectedIndex_file == index ||
                  selectedIndex_fileList.contains(index.toString()))
                    const Positioned(
                      top: 10,
                      right: 0,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF005F6B),
                        size: 20,
                      ),
                    ),
                ]
              ),
              Text(
                fileName,
                style: const TextStyle(
                  color: Color(0xFF005F6B),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    if(pictureObjects.isNotEmpty) {
      setState(() {
        projectImageList = projectImageList.reversed.toList();
      });
      projectFolderList.addAll(
          projectImageList,
        );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Transform.translate(
          offset: const Offset(-25, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                  child: Text(
                    folderNames.last,
                    style: const TextStyle(
                      color: Color(0xFF005F6B),
                      fontWeight: FontWeight.bold,
                    )
                  )
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        leading: (folderNames.last == "写真" && insideCounter == 0) || isEditImage ?
        widget.fromChecklist ?
        IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_outlined),
            onPressed: () {
              Navigator.pop(context);
            }
        ):
        const Text("")  :
        IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_outlined),
            onPressed: () {
              setState(() {
                if (widget.fromChecklist) {
                  selectedIndex_toChecklist.clear();
                  toChecklistId.clear();
                  toChecklistComment.clear();
                  toChecklistTags.clear();
                } else {
                  selectedIndex_folder = -1;
                  selectedIndex_file = -1;
                  selectedIndex_fileList.clear();
                  selectedFileIdList.clear();
                  fileMapsList.clear();
                }

                if (folderPathTitle != '写真' && insideCounter != 0) {
                  insideCounter--;
                  backAction = true;
                  folderPathList.removeLast();
                  backPicturesItem(folderNames.last);
                }

              });
            }
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (pictureObjects.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.05),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          pictureObjects = pictureObjects.reversed.toList();
                          arrayFromNew = !arrayFromNew;
                        });
                      },
                      child: Icon(
                        Icons.filter_list_outlined,
                          color: Color(0xFF005F6B)
                      )
                    ),
                  ),
                if (listSelected)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        listSelected = false;
                      });
                    },
                    child:
                    Icon(
                        Icons.account_tree_outlined,
                        color: Color(0xFF005F6B)
                    )
                  ),
                if (!listSelected)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        listSelected = true;
                      });
                    },
                    child: Icon(
                        Icons.list,
                        color: Color(0xFF005F6B)
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SmartRefresher(
          controller: _refreshController,
          onRefresh: _refreshData,
          header: CustomHeader(
            builder: (context, mode) {
              Widget body = widget.fromChecklist ?
              const Icon(
                Icons.refresh_outlined,
                color: Color(0xFF005F6B),
                size: 50,
              ) : const Text("");
              return SizedBox(
                height: 80.0,
                child: Center(child: body),
              );
            },
          ),
      child:listSelected
        ? SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.1),
          child: ListView.builder(
            reverse: true,
            controller: _scrollController,
            shrinkWrap: true,
            itemCount: pictureItems.length + pictureObjects.length,
            itemBuilder: (context, index) {

              if (index < pictureItems.length) {
                int totalFileCount = getTotalObjectsCount(pictureItems[index]);
                folderName = pictureItems[index]['name'].toString();
                return ListTile(
                  onLongPress: () {
                    if(!widget.fromChecklist) {
                      setState(() {
                        selectedIndex_folder = index;
                        selectedIndex_file = -1;
                        selectedIndex_fileList.clear();
                        selectedFileIdList.clear();
                        fileMapsList.clear();
                      });
                      showFolderOptionsBottomSheet(
                          pictureItems_last,
                          index,
                          pictureItems[index]['name'],
                          pictureItems[index]['id'],
                          pictureItems[index]['folder_path']
                      );
                    }
                  },
                  onTap: () {
                    setState(() {
                      if (widget.fromChecklist) {
                        selectedIndex_toChecklist.clear();
                        toChecklistId.clear();
                        toChecklistComment.clear();
                        toChecklistTags.clear();
                      } else {
                        selectedIndex_folder = -1;
                        selectedIndex_file = -1;
                        selectedIndex_fileList.clear();
                        selectedFileIdList.clear();
                        fileMapsList.clear();
                      }
                      pictureItems_last = pictureItems[index]['items'];
                      folderPathTitle = pictureItems[index]['name'];
                      backAction = false;
                      selectIndex = index;
                      folderId = pictureItems[index]['id'];
                      pictureObjects_last = pictureItems[index]['objects'] ?? [];
                      folderPathList.add(pictureItems[index]['folder_path']);
                      insideCounter++;
                    });
                    goPicturesItem(
                        pictureItems[index]['items'],
                        pictureItems[index]['name'].toString(),
                        pictureItems[index]['objects'] ?? []
                    );
                    updatePicturesItem(
                        newPicturesItem: pictureItems[index]['items'],
                        newFolderName: '$folderPath/${pictureItems[index]['name'].toString()}',
                        newPicturesItemObjects: pictureItems[index]['objects'] ?? []
                    );
                  },
                  leading: selectedIndex_folder == index ?
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF005F6B),
                  ): Icon(
                    Icons.folder_open_outlined,
                    color: isEditImage ?  editColor : const Color(0xFF005F6B),
                  ),
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            folderName,
                            style: const TextStyle(
                              color: Color(0xFF005F6B),
                            ),
                          ),
                          Text(
                            '$totalFileCount個',
                            style: const TextStyle(
                              color: Color(0xFF005F6B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              } else {
                int adjustedIndex = index - pictureItems.length;

                fileName =
                  ( pictureObjects[adjustedIndex]['display_name'] ??
                    pictureObjects[adjustedIndex]['name']).toString();
                return ListTile(
                  onLongPress: () {
                    if (!widget.fromChecklist) {
                      if (editImagesList.contains(pictureObjects[adjustedIndex]['id'].toString())) {
                        ToastPage.showToast('移動または削除中のファイルです');

                      } else {
                        setState(() {
                          selectedIndex_file = -1;
                          selectedIndex_folder = -1;

                          if (selectedIndex_fileList.contains(adjustedIndex.toString())) {
                            selectedIndex_fileList.remove(adjustedIndex.toString());
                            selectedFileIdList.remove(pictureObjects[adjustedIndex]['id'].toString());
                            fileMapsList.remove(pictureObjects[adjustedIndex]);
                            _selectedUserIdList.remove(pictureObjects[adjustedIndex]['created_by'][0].toString());
                          } else {
                            if (
                            canImageEdit(pictureObjects[adjustedIndex]) &&
                            ((pictureObjects[adjustedIndex]['created_by'] != null &&
                                pictureObjects[adjustedIndex]['created_by'][0] == _userId))) {
                              selectedIndex_fileList.add(adjustedIndex.toString());
                              selectedFileIdList.add(pictureObjects[adjustedIndex]['id'].toString());
                              fileMapsList.add(pictureObjects[adjustedIndex]);
                              _selectedUserIdList.add(pictureObjects[adjustedIndex]['created_by'][0].toString());
                            } else {
                              ToastPage.showToast('編集権限がない写真です');
                            }
                          }
                        });
                      }
                    }
                  },
                  onTap: () {
                    if(widget.fromChecklist) {
                      if (selectedIndex_toChecklist.contains(index.toString())) {
                        setState(() {
                          selectedIndex_toChecklist.remove(index.toString());
                          toChecklistId.remove(pictureObjects[adjustedIndex]['id'].toString());
                          toChecklistComment.remove(pictureObjects[adjustedIndex]['comment'].toString());
                          toChecklistTags.remove(pictureObjects[adjustedIndex]['tags'] ?? []);

                        });
                      } else {
                        setState(() {
                          selectedIndex_toChecklist.add(index.toString());
                          toChecklistId.add(pictureObjects[adjustedIndex]['id'].toString());
                          toChecklistComment.add(pictureObjects[adjustedIndex]['comment'].toString());
                          toChecklistTags.add(pictureObjects[adjustedIndex]['tags'] ?? []);
                        });
                      }
                    } else {
                      if (editImagesList.contains(pictureObjects[adjustedIndex]['id'].toString())) {
                        ToastPage.showToast('移動または削除中のファイルです');
                      } else {
                        if (selectedIndex_fileList.isEmpty) {
                          setState(() {
                            selectedIndex_folder = -1;
                          });
                          showFileOptionsBottomSheet(
                            pictureItems_last,
                            pictureObjects_last,
                            pictureObjects[adjustedIndex],
                          );
                        } else {
                          if (selectedIndex_fileList.contains(adjustedIndex.toString())) {
                            setState(() {
                              selectedIndex_fileList.remove(adjustedIndex.toString());
                              selectedFileIdList.remove(pictureObjects[adjustedIndex]['id'].toString());
                              fileMapsList.remove(pictureObjects[adjustedIndex]);
                              _selectedUserIdList.remove(pictureObjects[adjustedIndex]['created_by'][0].toString());
                            });
                          } else {
                            if (
                            canImageEdit(pictureObjects[adjustedIndex]) &&
                            ((pictureObjects[adjustedIndex]['created_by'] != null &&
                              pictureObjects[adjustedIndex]['created_by'][0] == _userId))) {
                              setState(() {
                                selectedIndex_fileList.add(adjustedIndex.toString());
                                selectedFileIdList.add(pictureObjects[adjustedIndex]['id'].toString());
                                fileMapsList.add(pictureObjects[adjustedIndex]);
                                _selectedUserIdList.add(pictureObjects[adjustedIndex]['created_by'][0].toString());
                              });
                            } else {
                              ToastPage.showToast('編集権限がない写真です');
                            }
                          }
                        }
                      }
                    }
                  },
                  leading:
                  selectedIndex_toChecklist.contains(adjustedIndex.toString()) ||
                  selectedIndex_file == adjustedIndex ||
                  selectedIndex_fileList.contains(adjustedIndex.toString()) ?
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF005F6B),
                  ): Icon(
                    Icons.image_outlined,
                    color: isEditImage ? editColor :
                    const Color(0xFF005F6B),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(
                            color: Color(0xFF005F6B),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              }
            },
          ),
        )
      )
       : GridView.count(
        physics: const BouncingScrollPhysics(),
        crossAxisCount: 2,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.12),
        crossAxisSpacing: MediaQuery.of(context).size.width * 0.05,
        mainAxisSpacing: MediaQuery.of(context).size.height * 0.05,
        children: projectFolderList,
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
            child:
            widget.fromChecklist ?
            FloatingActionButton.extended(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              backgroundColor: toChecklistId.isNotEmpty ?
              const Color(0xFF005F6B) : Colors.grey,
              onPressed: () async {
                if(toChecklistId.isNotEmpty) {
                  widget.onUploadToChecklist(true,toChecklistId,folderPathList.last,toChecklistComment,toChecklistTags);
                }
                Navigator.pop(context);
              },
              label:
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.image_outlined,color: Colors.white),
                  ),
                  const Text(
                      '決定',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                      )
                  ),
                  if(toChecklistId.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        width : MediaQuery.of(context).size.width * 0.08,
                        height :  MediaQuery.of(context).size.height * 0.07,
                        child: Center(
                            child : Text(
                              toChecklistId.length.toString(),
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.height * 0.02,
                                color: const Color(0xFF005F6B),
                              ),
                            )
                        ),
                      ),
                    ),
                ],
              ),
            ) :
            !isEditImage  ?
            FloatingActionButton.extended(
              backgroundColor: const Color(0xFF005F6B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                bool checkEditing = prefs.getBool('editingFiles') ?? false;
                bool checkUpload = prefs.getBool('uploadFiles') ?? false;
                  if (checkEditing) {
                    ToastPage.showToast('ファイルを削除、移動中です。おまちください');
                  } else {
                    _startSelectPage(pictureObjects_last,checkUpload);
                  }
                },
                label:
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.keyboard_option_key_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                        'ファイルオプション',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white
                        )
                    ),
                    if (selectedIndex_fileList.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            selectedIndex_fileList.length > 99 ?
                            '99+':
                            '${selectedIndex_fileList.length}',
                            style: TextStyle(
                                fontSize:
                                selectedIndex_fileList.length < 10 ?
                                MediaQuery.of(context).size.height * 0.02 :
                                selectedIndex_fileList.length < 100 ?
                                MediaQuery.of(context).size.height * 0.015 :
                                MediaQuery.of(context).size.height * 0.01,
                                color: const Color(0xFF005F6B),
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ) : null
          ),
        ],
      )
    );
  }
}