import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:dynamic_height_grid_view/dynamic_height_grid_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:object_project/FolderMake.dart';
import 'package:object_project/FolderSelect.dart';
import 'package:http/http.dart' as http;
import 'package:object_project/SnackbarPage.dart';
import 'package:object_project/ToastPage.dart';
import 'package:open_file/open_file.dart';

class DocumentItemScreen extends StatefulWidget {
  final Map<String, dynamic> documentFolderData;
  final String folderPath;

  DocumentItemScreen({
    super.key,
    required this.documentFolderData,
    required this.folderPath,
  });

  @override
  DocumentItemScreenState createState() => DocumentItemScreenState();
}

class DocumentItemScreenState extends State<DocumentItemScreen> {

  late String folderPath;
  late String folderId;
  String folderPathTitle = '자료';
  late List<String> folderNames = [];

  List<String> folderPathList = [];

  late List<dynamic> documentItems;
  late List<dynamic> documentItems_whole;
  List<dynamic> documentItems_last = [];
  List<List<dynamic>> documentItems_record = [];

  late List<dynamic> documentObjects;
  List<List<dynamic>> documentObjects_record = [];
  List<dynamic>documentObjects_last = [];

  late String projectId;
  bool listSelected = false;
  int selectIndex = 0;
  String fileName = '';
  String folderName = '';
  bool backAction = false;
  late String apiUrl;
  late TextEditingController textEditingController;
  int selectedIndex_file = -1;
  int selectedIndex_folder = -1;
  List<String>selectedIndex_fileList = [];
  List<String>selectedFileIdList = [];
  List<Map<String,dynamic>>fileMapsList = [];

  int folderIndex = 0;
  List<dynamic> folderObjects = [];
  bool isEditFile = false;
  String isEditFileText = "";
  late Function(bool,int) setIsEditFile;

  Color editColor = Colors.blueGrey.withOpacity(0.5);
  List<String> editDocumentsList = [];
  bool editingFiles = false;

  final ScrollController _scrollController = ScrollController();
  bool arrayFromNew = true;
  int insideCounter = 0;

  List<dynamic> notificationItemId = [];
  String notificationFolderId  = "";
  String _userId = "";
  List<String>_selectedUserIdList = [];

  List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    setState(() {
      folderPath = widget.folderPath;
      documentItems = widget.documentFolderData['items'];
      documentItems_whole = widget.documentFolderData['items'];

      folderId = widget.documentFolderData['id'];
      folderPathList.add(widget.documentFolderData['folder_path']);

      documentObjects = widget.documentFolderData['objects'] ?? [];
      documentItems_last = documentItems;

      textEditingController = TextEditingController();
    });

    // getIdToken();

    documentItems_record.add(documentItems);
    folderNames.add('자료');
    documentObjects_record.add(documentObjects);

    if (notificationFolderId != '') {
      moveToFolder(notificationFolderId);
    }

    setIsEditFile = (bool value,int index) {

      if (mounted) {
        setState(() {
          documentObjects_last.removeWhere((item) => item['id'] == selectedFileIdList[index]);
          selectedIndex_fileList.clear();

          if (value) {
            selectedFileIdList.clear();
            fileMapsList.clear();
            isEditFile = false;
            selectedIndex_file = -1;
            selectedIndex_folder = -1;
          }
        });
      } else {
        documentObjects_last.removeWhere((item) => item['id'] == selectedFileIdList[index]);
        selectedIndex_fileList.clear();

        if (value) {
          selectedFileIdList.clear();
          fileMapsList.clear();
          isEditFile = false;
          selectedIndex_file = -1;
          selectedIndex_folder = -1;
        }
      }
    };
  }

  String transformDateString(String input) {

    final RegExp regex = RegExp(r'(\d{4})年(\d{2})月(\d{2})日.*?(\d{2}):(\d{2})');
    final match = regex.firstMatch(input);

    if (match != null) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      final hour = int.parse(match.group(4)!);
      final minute = int.parse(match.group(5)!);

      final dateTime = DateTime(year, month, day, hour, minute);

      return '${dateTime.year.toString().padLeft(4, '0')}/'
          '${dateTime.month.toString().padLeft(2, '0')}/'
          '${dateTime.day.toString().padLeft(2, '0')} '
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return "";
    }
  }

  void updateDocumentItem({
    required List<dynamic> newDocumentItem,
    required String newFolderName,
    required List<dynamic> newDocumentItemObjects
  }) {
    setState(() {
      documentItems = newDocumentItem;
      folderPath = newFolderName;
      documentObjects = newDocumentItemObjects;
    });
  }

  goDocumentItem(
      List<dynamic> selectItem ,
      String selectPath,
      List<dynamic> selectObjectItem) {
    if (!backAction) {
      documentItems_record.add(selectItem);
      folderNames.add(selectPath);
      documentObjects_record.add(selectObjectItem);
    }
  }

  // void getIdToken() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     apiUrl = prefs.getString('apiUrl') ?? '';
  //     editDocumentsList = prefs.getStringList('editDocuments') ?? [];
  //     editingFiles = prefs.getBool('editingFiles') ?? false;
  //     _userId = prefs.getString('id') ?? '';
  //   });
  // }

  void moveToFolder(String notification_folderId) async{

    if (folderId != notification_folderId) {
      int index = documentItems.indexWhere((element) => element['id'] == notification_folderId);
      int innerIndex = documentItems.indexWhere((element) => element['items'].toString().contains(notification_folderId) );

      if (index != -1) {
        setState(() {
          documentItems_last = documentItems[index]['items'];
          folderPathTitle = documentItems[index]['name'];
          backAction = false;
          selectIndex = index;
          folderId = documentItems[index]['id'];
          documentObjects_last = documentItems[index]['objects'] ?? [];
          folderPathList.add(documentItems[index]['folder_path']);
          insideCounter++;
        });

        goDocumentItem(
            documentItems[index]['items'],
            documentItems[index]['name'].toString(),
            documentItems[index]['objects'] ?? []
        );

        updateDocumentItem(
            newDocumentItem: documentItems[index]['items'],
            newFolderName: '$folderPath/${documentItems[index]['name'].toString()}',
            newDocumentItemObjects: documentItems[index]['objects'] ?? []
        );

      } else if (innerIndex != -1) {
        setState(() {
          documentItems_last = documentItems[innerIndex]['items'];
          folderPathTitle = documentItems[innerIndex]['name'];
          backAction = false;
          selectIndex = innerIndex;
          folderId = documentItems[innerIndex]['id'];
          documentObjects_last = documentItems[innerIndex]['objects'] ?? [];
          folderPathList.add(documentItems[innerIndex]['folder_path']);
          insideCounter++;
        });

        goDocumentItem(
            documentItems[innerIndex]['items'],
            documentItems[innerIndex]['name'].toString(),
            documentItems[innerIndex]['objects'] ?? []
        );

        updateDocumentItem(
            newDocumentItem: documentItems[innerIndex]['items'],
            newFolderName: '$folderPath/${documentItems[innerIndex]['name'].toString()}',
            newDocumentItemObjects: documentItems[innerIndex]['objects'] ?? []
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

  void backDocumentItem(String lastTitle){

    if (lastTitle == '자료') {
      setState(() {
        folderPathTitle = '자료';
      });
    } else {
      documentItems_record.removeLast();
      folderNames.removeLast();
      documentObjects_record.removeLast();

      setState(() {
        documentItems_last = documentItems_record.last;
        folderPathTitle = folderNames.last;
        documentObjects_last = documentObjects_record.last;
      });

      updateDocumentItem(
          newDocumentItem: documentItems_record.last,
          newFolderName: folderNames.last,
          newDocumentItemObjects: documentObjects_record.last
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
          projectId: projectId,
          apiUrl: apiUrl,
          picturesItems: documentItems_whole,
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
                      '${selectedFileIdList.length}장의 파일을'
                          '"$selectFolderTitle"폴더로 이동합니다。\n괜찮으시겠습니까',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey)
                  ),
                  content: selectedFileIdList.length > 5 ?
                  const Text(
                      '상황에 따라 시간이 걸릴 수 있습니다\n이동 중에는 촬영 등의 작업은 할 수 없습니다',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey
                      )
                  ) : null,
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('취소',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey
                          )),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        List<dynamic> items = widget.documentFolderData["items"];
                        for (int inner = 0; inner < items.length; inner++) {
                          if (items[inner]["folder_path"] == selectFolderPath) {
                            setState(() {
                              folderIndex = inner;
                            });
                          }
                        }

                        folderObjects = items[folderIndex]["objects"];
                        isEditFile = true;
                        isEditFileText = "파일 이동중...";


                        prefs.setStringList("editDocuments", selectedFileIdList);
                        editDocumentsList = selectedFileIdList;


                        prefs.setBool("editingFiles", true);
                      },
                      child: const Text('이동',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey
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
        )
      ),
    );
  }

  Future<void> showFileOptionsBottomSheet(
      int index,
      List<dynamic> itemList,
      List<dynamic> objectList,
      bool typeIsImage,
      Map<String,dynamic> fileMap
      ) async {
    String fileUrl = fileMap['full_path'] ?? "";
    String selectName = fileMap['name'].toString();

    final prefs = await SharedPreferences.getInstance();
    bool checkEditing = prefs.getBool('editingFiles') ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) {
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                          onPressed: () {
                            if (typeIsImage) {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return Dialog(
                                    child: Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        SizedBox(
                                          width: MediaQuery.of(context).size.width,
                                          child: Image.file(File(fileUrl), fit: BoxFit.cover),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            } else {
                              OpenFile.open(fileUrl);
                            }
                          },
                          icon:Icon(
                            Icons.open_in_new,
                            size: MediaQuery.of(context).size.height * 0.04,
                            color : Colors.blueGrey,
                          )
                      ),
                      const Text('파일 열기',
                          style: TextStyle(
                            color: Colors.blueGrey,
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
                            Navigator.pop(context);
                            showDialog (
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                    '$selectName을 삭제합니다\n괜찮으시겠습니까?',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey)
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('취소',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueGrey
                                        )),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);

                                      setState(() {
                                        documentObjects.removeAt(index);
                                      });

                                      if (checkEditing) {
                                        ToastPage.showToast('파일을 삭제, 이동 중입니다. 기다려 주십시오');
                                      } else {
                                      }
                                    },
                                    child: const Text('삭제',
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
                          },
                          icon:
                          Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: MediaQuery.of(context).size.height * 0.04,
                          )
                      ),
                      const Text(
                          '삭제',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          )
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ;
      },
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

    updateItem(documentItems_whole);
  }

  static Future<void>moveFiles (
      int folderIndex,
      String newFolderName,
      String newFolderPath,
      String apiUrl,
      String projectId,
      List<String>selectedFileIdList,
      List<String> folderPathList,
      Function(bool,int) setIsEditFile,
      Function(bool) resetEditList,
      Function(String,bool,int,int) editingFiles,
      Function(String, Map<String,dynamic>) editFolder,
      ) async {
    final completer = Completer<void>();
    final receivePort = ReceivePort();

    final String folderPathListLast = folderPathList.last;

    final String imageUrl =
        '$apiUrl/api/mobile/projects/$projectId/documentFolder/documents';

    moveFilesPoint ({
      'sendPort': receivePort.sendPort,
      'newFolderPath' : newFolderPath,
      'imageUrl': imageUrl,
      'selectedFileIdList' : selectedFileIdList,
      'folderPathList' : folderPathListLast,
      'editFolder' : editFolder,
    });

    final prefs = await SharedPreferences.getInstance();

    receivePort.listen((dynamic data) async {
      int? nullableIndex_total = int.tryParse(data.split(':')[1].toString());
      int? nullableIndex = int.tryParse(data.split(':')[2]);

      if (data.startsWith('start')) {
        if (nullableIndex != null && nullableIndex_total != null) {
          int index = nullableIndex;
          int index_total = nullableIndex_total;

          prefs.setBool("editingFiles", true);
          editingFiles("ファイル移動中...",true,index_total,index);
        }
      }

      if (data.startsWith('success')) {
        if (nullableIndex != null && nullableIndex_total != null) {
          int index = nullableIndex;
          int index_total = nullableIndex_total;

          if (index + 1 == index_total) {
            SnackBarPage.showSnackBar(true, 'ファイル移動', '$newFolderNameに$index_total数のファイルを移動しました');
            resetEditList(false);
            setIsEditFile(true,index);

            prefs.remove("editDocuments");
            editingFiles("ファイル移動中...",false,index_total,index);

            completer.complete();
            receivePort.close();
          } else {
            int index = nullableIndex;
            int index_total = nullableIndex_total;

            editingFiles("ファイル移動中...",false,index_total,index);
            setIsEditFile(false,index);
          }
        }
      }

      if (data.startsWith('error')) {
        if (nullableIndex != null && nullableIndex_total != null) {
          int index = nullableIndex;
          int index_total = nullableIndex_total;

          if (index + 1 == index_total) {
            SnackBarPage.showSnackBar(false, 'ファイル移動中エラー', '$newFolderNameに移動中にエラーが発生しました');

            resetEditList(false);
            setIsEditFile(true,index);

            editingFiles("ファイル移動中...",false,index_total,index);
            prefs.remove("editDocuments");

            completer.complete();
            receivePort.close();
          } else {
            int index = nullableIndex;
            int index_total = nullableIndex_total;

            editingFiles("ファイル移動中...",false,index_total,index);
            setIsEditFile(false,index);
          }
        }
      }
    });

    return completer.future;
  }

  static Future<void> moveFilesPoint(Map<String, dynamic> message) async {
    final SendPort sendPort = message['sendPort'];
    final String newFolderPath = message['newFolderPath'];
    final String imageUrl = message['imageUrl'];
    final List<String> selectedFileIdList = List<String>.from(message['selectedFileIdList']);
    final String folderPathList = message['folderPathList'];
    final List<String> selectedFileIdList_back = List<String>.from(selectedFileIdList);
    Function(String, Map<String,dynamic>) editFolder = message['editFolder'];
  }

  static Future<void>deleteFiles (
      String newFolderName,
      String apiUrl,
      String projectId,
      List<Map<String,dynamic>> fileMapsList,
      List<String>selectedFileIdList,
      Function(bool,int) setIsEditFile,
      ) async {
    final completer = Completer<void>();
    final receivePort = ReceivePort();

    final String imageUrl = '$apiUrl/api/mobile/projects/$projectId/documentFolder/documents';

    deleteFilesPoint ({
      'sendPort': receivePort.sendPort,
      'imageUrl': imageUrl,
      'selectedFileIdList' : selectedFileIdList,
    });

    final prefs = await SharedPreferences.getInstance();

    return completer.future;
  }

  static Future<void> deleteFilesPoint(Map<String, dynamic> message
      ) async {
    final SendPort sendPort = message['sendPort'];
    final String imageUrl = message['imageUrl'];
    final List<String> selectedFileIdList = List<String>.from(message['selectedFileIdList']);

    int deleteIndex = selectedFileIdList.length;
    sendPort.send('start:$deleteIndex:0');

  }

  Future<void> _pickImages() async {
    final prefs = await SharedPreferences.getInstance();

    final picker = ImagePicker();
    try {
      final pickedImages = await picker.pickMultiImage();

      if (pickedImages.isNotEmpty) {
        setState(() {
          for (int i = 0; i < pickedImages.length; i++) {
            documentObjects.add(
                {
                  "id" : "",
                  "name" : pickedImages[i].name.toString(),
                  "full_path" : pickedImages[i].path.toString(),
                }
            );

            _selectedImages.add(pickedImages[i]);
          }
        });
      }
    }
    catch (e) {
      ToastPage.showToast("사진의 접근 권한을 확인해 주세요");
    }
  }

  Future<void> _pickDocument() async {
    FilePickerResult? pickedFiles = await FilePicker.platform.pickFiles();

    if (pickedFiles != null) {
      setState(() {
        documentObjects.add(
            {
              "id" : "",
              "name" : pickedFiles.names.toString(),
              "full_path" : pickedFiles.paths.toString(),
            }
        );
      });
    } else {
      Navigator.pop(context);
    }

  }

  Future<void> _startSelectPage(BuildContext ctx,  List<dynamic> objectList) async {

    final prefs = await SharedPreferences.getInstance();
    bool checkUpload = prefs.getBool('uploadFiles') ?? false;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.white,
      builder: (_) {
        return
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
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
                            createFolder(context);
                          },
                          icon: Container(
                            color: Colors.transparent,
                            child: Icon(
                              Icons.folder_open_outlined,
                              color: Colors.blueGrey,
                              size: MediaQuery.of(context).size.height * 0.04,
                            )
                          ),
                        ),
                        const Text('폴더 추가',
                          style: TextStyle(
                            color: Colors.blueGrey ,
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
                            _pickImages();
                          },
                          icon: Container(
                            color: Colors.transparent,
                            child: const Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ),
                        const Text('사진 추가',
                            style: TextStyle(
                              color: Colors.blueGrey,
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
                            _pickDocument();
                          },
                          icon: Container(
                            color: Colors.transparent,
                            child:
                            Icon(
                              Icons.file_present_outlined,
                              color: Colors.blueGrey,
                              size: MediaQuery.of(context).size.height * 0.04,
                            )
                          ),
                        ),
                        const Text('파일 추가',
                          style: TextStyle(
                            color: Colors.blueGrey,
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
                            if(checkUpload) {
                              ToastPage.showToast("파일 업로드 중입니다");
                            } else {
                              if (objectList.isEmpty) {
                                ToastPage.showToast("선택할 수 있는 파일이 없습니다");
                              } else {
                                setState(() {
                                  for (int i = 0; i < documentObjects_last.length; i ++) {
                                    if (!selectedIndex_fileList.contains(i.toString())) {
                                      selectedIndex_fileList.add(i.toString());
                                      selectedFileIdList.add(objectList[i]['id'].toString());
                                      fileMapsList.add(objectList[i]);
                                    }

                                    if (i + 1 == documentObjects_last.length &&
                                        selectedIndex_fileList.isEmpty) {
                                      ToastPage.showToast("선택할 수 있는 파일이 없습니다");
                                    }
                                  }
                                });
                              }
                              Navigator.pop(context);
                            }
                          },
                          icon: Icon(
                            Icons.checklist_outlined,
                            color: Colors.blueGrey,
                            size: MediaQuery.of(context).size.height * 0.04,
                          )
                        ),
                        const Text(
                           '파일 전체 선택',
                          style: TextStyle(
                            color: Colors.blueGrey,
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
                          icon:
                          Icon(
                            Icons.cancel_outlined,
                            color: selectedIndex_fileList.isEmpty ?
                            Colors.grey : Colors.blueGrey,
                            size: MediaQuery.of(context).size.height * 0.04,
                          ),
                        ),
                        Text('선택 취소',
                            style: TextStyle(
                              color: selectedIndex_fileList.isEmpty ?
                              Colors.grey : Colors.blueGrey,
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
                            if(checkUpload) {
                              ToastPage.showToast("파일 업로드 중입니다");
                            } else {
                              if (selectedIndex_fileList.isEmpty) {
                                ToastPage.showToast('선택된 파일이 없습니다');
                              } else {
                                Navigator.pop(context);
                                selectFolder(context);
                              }
                            }
                          },
                          icon: Icon(
                            Icons.drive_file_move_outlined,
                            color: selectedIndex_fileList.isEmpty ?
                            Colors.grey : Colors.blueGrey,
                            size: MediaQuery.of(context).size.height * 0.04,
                          ),
                        ),
                        Text('파일 이동',
                            style: TextStyle(
                              color: selectedIndex_fileList.isEmpty ?
                              Colors.grey : Colors.blueGrey,
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
                            if(checkUpload) {
                              ToastPage.showToast("파일 업로드 중입니다");
                            } else {
                              if (selectedIndex_fileList.isEmpty) {
                                ToastPage.showToast('선택된 파일이 없습니다');
                              } else {
                                Navigator.pop(context);
                                setState(() {
                                  selectedIndex_file = -1;
                                });
                                showDialog (
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                        '${selectedFileIdList.length}장의 파일을 삭제합니다。\n괜찮으시겠습니까',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueGrey)
                                    ),
                                    content: selectedFileIdList.length > 5 ?
                                    const Text(
                                        '상황에 따라 시간이 걸릴 수 있습니다\n삭제중에는 촬영등의 작업은 할 수 없습니다',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueGrey
                                        )
                                    ) : null,
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('취소',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blueGrey
                                            )),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          final prefs = await SharedPreferences.getInstance();

                                          isEditFile = true;
                                          isEditFileText = "사진 삭제 중...";

                                          prefs.setStringList("editDocuments", selectedFileIdList);
                                          editDocumentsList = selectedFileIdList;


                                          prefs.setBool("editingFiles", true);
                                          deleteFiles(
                                            folderPathTitle,
                                            apiUrl,
                                            projectId,
                                            fileMapsList,
                                            selectedFileIdList,
                                            setIsEditFile,

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
                          icon: Icon(
                            Icons.delete_outline,
                            color: selectedIndex_fileList.isEmpty ?
                            Colors.grey : Colors.red,
                            size: MediaQuery.of(context).size.height * 0.04,
                          ),
                        ),
                        Text('파일 삭제',
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
            )
          );
      },
    );
  }

  void createFolder(BuildContext context) async {

    await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          content: SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.width,
            child:  ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: FolderMake(
                itemsList : documentItems,
                onUploadComplete : (create,folderName) {
                  if (create) {
                    setState(() {
                      documentItems.add(
                        {"id": "",
                          "name":folderName,
                          "folder_path": "",
                          "items": [], "objects": [],
                          "created_id": "",
                          "created_at": DateTime.now().toString()
                        }
                      );
                    });

                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> downloadImage(String signedUrl) async {
    final response = await http.get(Uri.parse(signedUrl));
    if (response.statusCode == 200) {
      await ImageGallerySaver.saveImage(Uint8List.fromList(response.bodyBytes));
      setState(() {
        selectedIndex_file = -1;
      });
      Navigator.pop(context);
    } else {
      ToastPage.showToast('다운로드에 실패했습니다');
    }
  }

  void showFolderOptionsBottomSheet(
      List<dynamic> itemList,
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
                                              '폴더명 변경',
                                              style: TextStyle(
                                                color: Colors.blueGrey,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            '새 폴더 이름',
                                            style: TextStyle(
                                              color: Colors.blueGrey,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child:  TextField(
                                            style: const TextStyle(
                                                color: Colors.blueGrey,
                                                fontWeight: FontWeight.bold
                                            ),
                                            maxLength: 30,
                                            controller: textEditingController,
                                            keyboardType: TextInputType.text,
                                            cursorColor: Colors.blueGrey,
                                            decoration: InputDecoration(
                                              focusedBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: newName.isEmpty ? Colors.grey : Colors.blueGrey,
                                                ),
                                              ),
                                              enabledBorder: const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              counterStyle: TextStyle(
                                                color: newName.isEmpty ? Colors.grey : Colors.blueGrey,
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
                                                      '취소',
                                                      style: TextStyle(
                                                        color: Colors.blueGrey,
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
                                                  color: Colors.blueGrey,
                                                  borderRadius: BorderRadius.only(
                                                    bottomRight: Radius.circular(8.0),
                                                  ),
                                                ),
                                                child: TextButton(
                                                  onPressed: () async {
                                                    if (newName != '') {
                                                      Navigator.pop(context);
                                                    } else {
                                                      ToastPage.showToast('폴더명을 입력하세요');
                                                    }
                                                  },
                                                  child: const Center(
                                                    child: Text(
                                                      '수정',
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
                            color: Colors.blueGrey ,
                            size: MediaQuery.of(context).size.height * 0.04,
                          )

                          ),
                        const Text('폴더명 변경',
                          style: TextStyle(
                            color: Colors.blueGrey,
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
                          showDialog (
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                  '$selectName을 삭제합니다。\n괜찮으십니까',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey)
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('취소',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey
                                      )),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    final prefs = await SharedPreferences.getInstance();
                                    bool checkEditing = prefs.getBool('editingFiles') ?? false;
                                    if (checkEditing) {
                                      ToastPage.showToast('파일을 삭제, 이동 중입니다. 기다려 주십시오');
                                    } else {
                                    }
                                  },
                                  child: const Text('삭제',
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
                        },
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: MediaQuery.of(context).size.height * 0.04,
                        ),
                      ),
                      const Text('폴더 삭제',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent ,
                        )
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
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
    documentItems.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> data = entry.value;

      fileName = data['name'].toString();

      int totalFileCount = getTotalObjectsCount(data);

      return GestureDetector(
        onLongPress: () {
          setState(() {
            selectedIndex_folder = index;
            selectedIndex_file = -1;
            selectedIndex_fileList.clear();
            selectedFileIdList.clear();
            fileMapsList.clear();
          });
          showFolderOptionsBottomSheet(
              documentItems_last,
              data['name'],
              data['id'],
              data['folder_path']
          );
        },
        onTap: () {
          setState(() {
            selectedIndex_folder = -1;
            selectedIndex_file = -1;
            selectedIndex_fileList.clear();
            selectedFileIdList.clear();
            fileMapsList.clear();
            documentItems_last = data['items'] ?? [];
            folderPathTitle = data['name'] ?? [];
            backAction = false;
            folderId = data['id'] ?? '';
            documentObjects_last = data['objects'] ?? [];
            folderPathList.add(data['folder_path']);
            insideCounter++;
          }
          );
          goDocumentItem(
              data['items'],
              data['name'].toString(),
              data['objects'] ?? []
          );
          updateDocumentItem(
            newDocumentItem: data['items'],
            newFolderName: '$folderPath/${data['name'].toString()}',
            newDocumentItemObjects: data['objects'] ?? [],
          );
        },
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Icon(
                    Icons.folder_outlined,
                    color: isEditFile ? editColor : Colors.blueGrey,
                    size: MediaQuery.of(context).size.height * 0.1,
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
                        color: Colors.blueGrey,
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
                      color: Colors.blueGrey,
                    ),
                  ),
                  Text(
                    '$totalFileCount개',
                    style: const TextStyle(
                      color: Colors.blueGrey,
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      );
    }).toList();

    List<Widget> projectFileList =
    documentObjects.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> data = entry.value;

      fileName = (data['display_name'] ?? data['name']).toString();
      String type = data['mime_type'].toString();

      return GestureDetector(
        onLongPress: () {
          if (editDocumentsList.contains(data['id'].toString())) {
            ToastPage.showToast('이동 또는 삭제 중인 파일입니다');
          } else {
            setState(() {
              selectedIndex_file = -1;
              selectedIndex_folder = -1;
              if (selectedIndex_fileList.contains(index.toString())) {
                selectedIndex_fileList.remove(index.toString());
                selectedFileIdList.remove(data['id'].toString());
                fileMapsList.remove(data);
              } else {
                selectedIndex_fileList.add(index.toString());
                selectedFileIdList.add(data['id'].toString());
                fileMapsList.add(data);
              }
            });
          }
        },
        onTap: () {
          if (editDocumentsList.contains(data['id'].toString())) {
            ToastPage.showToast('이동 또는 삭제 중인 파일입니다');
          } else {
            if (selectedIndex_fileList.isEmpty) {
              setState(() {
                selectedIndex_folder = -1;
              });
              if (fileName.contains('.jpg') ||
                  fileName.contains('.png') ||
                  fileName.contains('.jpeg') ||
                  fileName.contains('.svg')
              ) {
                showFileOptionsBottomSheet(
                  index,
                  documentItems_last,
                  documentObjects_last,
                  true,
                  data
                );
              } else {
                showFileOptionsBottomSheet(
                  index,
                  documentItems_last,
                  documentObjects_last,
                  false,
                  data
                );
              }
            } else {
              if (selectedIndex_fileList.contains(index.toString())) {
                setState(() {
                  selectedIndex_fileList.remove(index.toString());
                  selectedFileIdList.remove(data['id'].toString());
                  fileMapsList.remove(data);
                });
              } else {
                setState(() {
                  selectedIndex_fileList.add(index.toString());
                  selectedFileIdList.add(data['id'].toString());
                  fileMapsList.add(data);
                });
              }
            }
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selectedIndex_file == index ||
            selectedIndex_fileList.contains(index.toString()) ?
            const Color(0xFFDCDFE6) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFBEBEBE),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Stack(
                children: [
                  if (!data['full_path'].toString().contains('.jpg') &&
                      !data['full_path'].toString().contains('.png') &&
                      !data['full_path'].toString().contains('.jpeg') &&
                      !data['full_path'].toString().contains('.pdf')
                  )
                    Center(
                      child: Icon(
                        Icons.insert_drive_file_outlined,
                        size: MediaQuery.of(context).size.height * 0.1,
                        color: Colors.blueGrey,
                      ),
                    ),
                  if (data['name'].toString().contains('.jpg') ||
                      data['name'].toString().contains('.png') ||
                      data['name'].toString().contains('.jpeg')||
                      data['name'].toString().contains('.pdf')
                  )
                    Image.file(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: MediaQuery.of(context).size.height * 0.15,
                      File(data['full_path'].toString()),
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: MediaQuery.of(context).size.height * 0.15,
                        );
                      },
                    ),
                  if (selectedIndex_file == index ||
                      selectedIndex_fileList.contains(index.toString()) ||
                      isEditFile
                  )
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  if (selectedIndex_file == index ||
                      selectedIndex_fileList.contains(index.toString()))
                    const Positioned(
                      top: 10,
                      right: 0,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.blueGrey,
                        size: 20,
                      ),
                    ),
                ],
              ),
              Text(
                fileName,
                style: const TextStyle(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    if(documentObjects.isNotEmpty) {
      setState(() {
        projectFileList = projectFileList.reversed.toList();
      });
      projectFolderList.addAll(
          projectFileList
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
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                    )
                )
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        leading: (folderNames.last == "자료" && insideCounter == 0) || isEditFile ?
        const Text("") :
        IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_outlined,
              color: Colors.blueGrey,
            ),
            onPressed: () {
              setState(() {
                selectedIndex_folder = -1;
                selectedIndex_file = -1;
                selectedIndex_fileList.clear();
                selectedFileIdList.clear();
                fileMapsList.clear();

                if (folderPathTitle != '자료' && insideCounter != 0) {
                  insideCounter--;
                  backAction = true;
                  backDocumentItem(folderNames.last);
                  folderPathList.removeLast();
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
                if (documentObjects.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.05),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          documentObjects = documentObjects.reversed.toList();
                          documentItems = documentItems.reversed.toList();
                          arrayFromNew = !arrayFromNew;
                        });
                      },
                      child:
                      Icon(
                        arrayFromNew ?
                        Icons.sort_outlined:
                        Icons.sort_sharp,
                        color : Colors.blueGrey,
                        size: MediaQuery.of(context).size.height * 0.05,
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
                    child: Icon(
                      Icons.folder_copy_outlined,
                      color : Colors.blueGrey,
                      size : MediaQuery.of(context).size.height * 0.05,
                     ),
                  ),
                if (!listSelected)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        listSelected = true;
                      });
                    },
                    child: Icon(
                      Icons.list_outlined,
                      size : MediaQuery.of(context).size.height * 0.05,
                      color : Colors.blueGrey
                   )
                  ),
              ],
            ),
          ),
        ],
      ),
      body: listSelected
          ? SingleChildScrollView(
            child:  Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.1),
              child: ListView.builder(
                reverse: true,
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: documentItems.length + documentObjects.length,
                itemBuilder: (context, index) {
                  if (index < documentItems.length) {
                    fileName = documentItems[index]['name'].toString();
                    int totalFileCount = getTotalObjectsCount(documentItems[index]);
                    return GestureDetector(
                      onLongPress: () {
                        setState(() {
                          selectedIndex_folder = index;
                          selectedIndex_file = -1;
                          selectedIndex_fileList.clear();
                          selectedFileIdList.clear();
                          fileMapsList.clear();
                        });
                        showFolderOptionsBottomSheet(
                            documentItems_last,
                            documentItems[index]['name'],
                            documentItems[index]['id'],
                            documentItems[index]['folder_path']
                        );
                      },
                      onTap: () {
                        setState(() {
                          selectedIndex_folder = -1;
                          selectedIndex_file = -1;
                          selectedIndex_fileList.clear();
                          selectedFileIdList.clear();
                          fileMapsList.clear();
                          documentItems_last = documentItems[index]['items'];
                          folderPathTitle = documentItems[index]['name'];
                          backAction = false;
                          selectIndex = index;
                          folderId = documentItems[index]['id'];
                          documentObjects_last = documentItems[index]['objects'] ?? [];
                          folderPathList.add(documentItems[index]['folder_path']);
                          insideCounter++;
                        });
                        goDocumentItem(
                            documentItems[index]['items'],
                            documentItems[index]['name'].toString(),
                            documentItems[index]['objects'] ?? []
                        );
                        updateDocumentItem(
                            newDocumentItem: documentItems[index]['items'],
                            newFolderName: '$folderPath/${documentItems[index]['name'].toString()}',
                            newDocumentItemObjects: documentItems[index]['objects'] ?? []
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4,horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 2,horizontal: 10),
                        constraints: BoxConstraints(
                          minHeight : MediaQuery.of(context).size.height * 0.08,
                        ),
                        decoration: BoxDecoration(
                          color:
                          selectedIndex_folder == index ?
                          const Color(0xFFDCDFE6) : Colors.white,
                          border: Border.all(
                            color: const Color(0xFFBEBEBE),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            if (selectedIndex_folder == index)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.blueGrey,
                              ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.folder_outlined,
                                color: isEditFile ?  editColor : Colors.blueGrey,
                                size: MediaQuery.of(context).size.height * 0.05,
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    fileName,
                                    style: const TextStyle(
                                        color: Colors.blueGrey,
                                    ),
                                  ),
                                ),
                                Text(
                                  '파일 수：$totalFileCount개',
                                  style: const TextStyle(
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    );
                  } else {
                    int adjustedIndex = index - documentItems.length;
                    fileName =
                        (documentObjects[adjustedIndex]['display_name'] ??
                         documentObjects[adjustedIndex]['name']).toString();
                    IconData iconData;

                    if (fileName.contains('.jpg') || fileName.contains('.jpeg') || fileName.contains('.png')) {
                      iconData = Icons.image_outlined;
                    } else {
                      iconData = Icons.insert_drive_file_outlined;
                    }

                    return GestureDetector(
                      onLongPress: () {
                        if (editDocumentsList.contains(documentObjects[adjustedIndex]['id'].toString())) {
                          ToastPage.showToast('이동 또는 삭제 중인 파일입니다');
                        } else {
                          setState(() {
                            selectedIndex_file = -1;
                            selectedIndex_folder = -1;

                            if (selectedIndex_fileList.contains(adjustedIndex.toString())) {
                              selectedIndex_fileList.remove(adjustedIndex.toString());
                              selectedFileIdList.remove(documentObjects[adjustedIndex]['id'].toString());
                              fileMapsList.remove(documentObjects[adjustedIndex]);
                            } else {
                              selectedIndex_fileList.add(adjustedIndex.toString());
                              selectedFileIdList.add(documentObjects[adjustedIndex]['id'].toString());
                              fileMapsList.add(documentObjects[adjustedIndex]);
                            }
                          });
                        }
                      },
                      onTap: () {
                        if (editDocumentsList.contains(documentObjects[adjustedIndex]['id'].toString())) {
                          ToastPage.showToast('이동 또는 삭제 중인 파일입니다');
                        } else {
                          if (selectedIndex_fileList.isEmpty) {
                            setState(() {
                              selectedIndex_folder = -1;
                            });
                            if (iconData == Icons.image_outlined) {
                              showFileOptionsBottomSheet(
                                index,
                                documentItems_last,
                                documentObjects_last,
                                true,
                                documentObjects[adjustedIndex]
                              );
                            } else {
                              showFileOptionsBottomSheet(
                                index,
                                documentItems_last,
                                documentObjects_last,
                                false,
                                documentObjects[adjustedIndex]
                              );
                            }
                          } else {
                            if (selectedIndex_fileList.contains(adjustedIndex.toString())) {
                              setState(() {
                                selectedIndex_fileList.remove(adjustedIndex.toString());
                                selectedFileIdList.remove(documentObjects[adjustedIndex]['id'].toString());
                                fileMapsList.remove(documentObjects[adjustedIndex]);
                              });
                            } else {
                              setState(() {
                                selectedIndex_fileList.add(adjustedIndex.toString());
                                selectedFileIdList.add(documentObjects[adjustedIndex]['id'].toString());
                                fileMapsList.add(documentObjects[adjustedIndex]);
                              });
                            }
                          }
                        }
                      },

                      child : Container(
                          margin: EdgeInsets.symmetric(vertical: 4,horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 2,horizontal: 2),
                          decoration: BoxDecoration(
                            color: selectedIndex_file == adjustedIndex ||
                                selectedIndex_fileList.contains(adjustedIndex.toString()) ?
                            const Color(0xFFDCDFE6) : Colors.white,
                            border: Border.all(
                              color: const Color(0xFFBEBEBE),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              if (!documentObjects[adjustedIndex]['name'].contains(".jpg") &&
                                  !documentObjects[adjustedIndex]['name'].contains(".jpeg") &&
                                  !documentObjects[adjustedIndex]['name'].contains(".png") &&
                                  !documentObjects[adjustedIndex]['name'].contains(".svg")
                              )
                                SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.08,
                                  width : MediaQuery.of(context).size.width * 0.25,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                      children :
                                        [
                                          if ( selectedIndex_file == adjustedIndex ||
                                            selectedIndex_fileList.contains(adjustedIndex.toString()))
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              color: Colors.blueGrey,
                                            ),
                                          Icon(
                                            Icons.insert_drive_file_outlined,
                                            size: MediaQuery.of(context).size.height * 0.05,
                                            color: Colors.blueGrey,
                                          )
                                        ]
                                  ),
                                ),
                              if (documentObjects[adjustedIndex]['full_path'] != null &&
                               (  documentObjects[adjustedIndex]['name'].contains(".jpg") ||
                                  documentObjects[adjustedIndex]['name'].contains(".jpeg") ||
                                  documentObjects[adjustedIndex]['name'].contains(".png") ||
                                  documentObjects[adjustedIndex]['name'].contains(".svg"))
                              )
                                Stack(
                                  children: [
                                    Image.file(
                                      width : MediaQuery.of(context).size.width * 0.25,
                                      height: MediaQuery.of(context).size.height * 0.08,
                                      File(documentObjects[adjustedIndex]['full_path'].toString()),
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                          size: MediaQuery.of(context).size.height * 0.15,
                                        );
                                      },
                                    ),
                                    if(selectedIndex_file == adjustedIndex ||
                                        selectedIndex_fileList.contains(adjustedIndex.toString()))
                                      Positioned(
                                        top: MediaQuery.of(context).size.height * 0.025,
                                        left: MediaQuery.of(context).size.width * 0.1,
                                        child: const Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.blueGrey,
                                          size: 25,
                                        ),
                                      ),
                                  ],
                                ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.7,
                                child: Text(
                                  fileName,
                                  style: const TextStyle(
                                      color: Colors.blueGrey,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                              )
                            ],
                          )
                      ),
                    );
                  }
                },
              ),
            ),
      ) : Container(
        color: Colors.white,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.065,
        ),
        child: DynamicHeightGridView(
            itemCount:
            _selectedImages.isNotEmpty ? projectFolderList.length :
            projectFolderList.length + _selectedImages.length,
            crossAxisCount: 2,
            crossAxisSpacing: MediaQuery.of(context).size.width * 0.01,
            mainAxisSpacing:  MediaQuery.of(context).size.height * 0.02,
            builder: (ctx, index) {
              return projectFolderList[index];
            }
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
            FloatingActionButton.extended(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              backgroundColor: Colors.blueGrey,
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                bool checkEditing = prefs.getBool('editingFiles') ?? false;
                if (checkEditing) {
                  ToastPage.showToast('파일을 삭제, 이동 중입니다. 기다려 주십시오');
                } else {
                  setState(() {
                    selectedIndex_file = -1;
                    selectedIndex_folder = -1;
                  });
                  _startSelectPage(context, documentObjects_last);
                }
              },
              label: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.settings_outlined,
                      size: MediaQuery.of(context).size.height * 0.03,
                      color: Colors.white,
                    )
                  ),
                  const Text('파일 옵션',
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
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          )
        ],
      )
    );
  }
}