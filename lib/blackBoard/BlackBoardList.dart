
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:object_project/LodingPage.dart';
import 'package:object_project/Pictures/ImagePicker.dart';
import 'package:object_project/Pictures/commentClass.dart';
import 'package:object_project/ToastPage.dart';
import 'package:object_project/blackBoard/BlackBoardSelect.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:object_project/blackBoard/BlackBoardTemplate.dart';
import 'package:xml/xml.dart';

class BlackBoardList  extends StatefulWidget {
  final List<dynamic> items_whole;
  final String projectId;
  final String folderPathTitle;
  final String folderPath;

  final String folderId;
  final List<dynamic> objectsList;
  final List<dynamic> overViewData;
  late Function(bool,List<dynamic>,List<dynamic>) onUploadComplete;
  late Function(String, bool,int, int) editingFiles;
  late Function(String, String, bool) addBlackboard;

  final bool fromChecklist;
  final bool fromDrawing;
  // late Function(bool, List<Uint8List>, List<File>,String,List<String>,List<List>) onUploadToChecklist;
  late Function(String, String, List<dynamic>, String) settingFolderForChecklist;

  BlackBoardList({
    super.key,
    required this.items_whole,
    required this.projectId,
    required this.folderPathTitle,
    required this.folderId,
    required this.objectsList,
    required this.overViewData,
    required this.onUploadComplete,
    required this.editingFiles,
    required this.fromChecklist,
    // required this.onUploadToChecklist,
    required this.settingFolderForChecklist,
    required this.folderPath,
    required this.fromDrawing,
    required this.addBlackboard
  });

  @override
  BlackBoardListState createState() => BlackBoardListState();
}

class BlackBoardListState  extends State<BlackBoardList> {
  var logger = Logger();

  List<dynamic> items_whole = [];
  String projectId = "";
  String folderPathTitle = "";
  String folderId = "";
  List<dynamic> objectsList = [];

  String presetSearchText = '';
  String templateSearchText = '';
  String userId = '';
  String userName = '';
  bool loadBlackboards = false;

  List blackboardList_user = [];
  List blackboardList_corporation = [];
  String corporationId = "";

  List<dynamic> overViewData = [];

  final TextEditingController textEditingController = TextEditingController();

  bool isLoading = true;
  String apiUrl = "";

  String cognitoUserName = "";
  List<Uint8List> imagesByte = [];
  List<File> imagesFile = [];

  String testUrl = "";
  bool userBlackboard = true;
  List<String> takePictureTime = [];

  List<dynamic> opportunityInformationList = [];
  List<dynamic> customerInformationList = [];
  List<dynamic> installationInformationList = [];

  Map<String,dynamic> opportunityInformation = {};
  Map<String,dynamic>  customerInformation = {};
  Map<String,dynamic>  installationInformation = {};

  String projectName = "";
  String corporationName = "";
  String agentCreator = "";

  List<String> templateList = [];

  @override
  void initState() {
    super.initState();

    // items_whole = widget.items_whole;
    // projectId = widget.projectId;
    //
    // folderId = widget.folderId;
    // objectsList = widget.objectsList;
    //
    // folderPathTitle = widget.folderPathTitle;
    // overViewData = widget.overViewData;
    //
    // commentClass().clearList();
    // getIdToken();
  }

  Future<void> getIdToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      cognitoUserName = prefs.getString('userName') ?? '';
      userId = prefs.getString('id') ?? '';
      userName = prefs.getString('name') ?? '';
      apiUrl = prefs.getString('apiUrl') ?? '';
      corporationId = prefs.getString('corporation_id') ?? '';
      corporationName = prefs.getString('corporation_name') ?? '';
      agentCreator = prefs.getString('agentCreator') ?? '';
    });

    fetchData_corporationBlackboard(true);
  }

  void checkInformationList(List overViewData) {

    for(int i = 0; overViewData[0]['items'].length > i; i++) {
      opportunityInformation[overViewData[0]['items'][i]['name'].toString()] =
          overViewData[0]['items'][i]['value'].toString();
    }

    for(int i = 0; overViewData[1]['items'].length > i; i++) {
      customerInformation[overViewData[1]['items'][i]['name'].toString()] =
          overViewData[1]['items'][i]['value'].toString();
    }

    for(int i = 0; overViewData[2]['items'].length > i; i++) {
      installationInformation[overViewData[2]['items'][i]['name'].toString()] =
          overViewData[2]['items'][i]['value'].toString();
    }

    opportunityInformationList.add(opportunityInformation);
    customerInformationList.add(customerInformation);
    installationInformationList.add(installationInformation);
  }

  Future<String> downloadSvg(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final response = await http.get(Uri.parse(url));

      List<int> fontSizeList = [];
      List<String> autofillList = [];
      List<bool> multiLineList = [];
      List<int> dataMaxLengthList = [];
      List<String> labelAttributeList = [];
      List<String> textValues = [];
      BlackboardTemplate template;
      String _rawSvgTemplate;

      if (response.statusCode == 200) {

        _rawSvgTemplate = utf8.decode(response.bodyBytes).toString();
        template = BlackboardTemplate.fromSvgString(updateLineStrokeWidth(_rawSvgTemplate,4.0));
        projectName = prefs.getString('projectName') ?? '';

        final textElements = XmlDocument.parse(_rawSvgTemplate).findAllElements('text');

        for (var text in textElements) {
          final fontSize = text.getAttribute('font-size');
          fontSizeList.add(int.parse(fontSize.toString()));
        }

        // RegExp regExp = RegExp(r'font-size="(\d+)"');
        //
        // fontSizeList = regExp.allMatches(_rawSvgTemplate)
        //     .map((match) => int.parse(match.group(1) ?? '0'))
        //     .toList();

        fontSizeList.insert(0, 40);

        Map<int, BlackboardField> textFields = template.findTextFields();


        textFields.forEach((index, field) async {

          autofillList.add(field.autofill.toString());
          multiLineList.add(field.multiline);
          dataMaxLengthList.add(field.maxLength);

          final currentTime = DateTime.now();
          final formattedDate = formatDate(currentTime);

          labelAttributeList.add(field.label);

          for (opportunityInformation in opportunityInformationList) {
            if (opportunityInformation.containsKey(
                field.autofill.toString()
                    .replaceAll('[', '')
                    .replaceAll(']','')
            ))
            {
              dynamic value = opportunityInformation[
              field.autofill.toString()
                  .replaceAll('[', '')
                  .replaceAll(']','')
              ];
              textValues.add(value.toString());
            } else {
              for (customerInformation in customerInformationList) {
                if (customerInformation.containsKey(
                    field.autofill.toString()
                        .replaceAll('[', '')
                        .replaceAll(']','')
                        .replaceAll('（設置先）', '')
                        .replaceAll('（フリガナ）', '<br>(フリガナ)')
                ))
                {
                  dynamic value = customerInformation[
                  field.autofill.toString()
                      .replaceAll('[', '')
                      .replaceAll(']','')
                      .replaceAll('（設置先）', '')
                      .replaceAll('（フリガナ）', '<br>(フリガナ)')
                  ];
                  textValues.add(value.toString());
                } else {
                  for (installationInformation in installationInformationList) {
                    if (installationInformation.containsKey(
                        field.autofill.toString()
                            .replaceAll('[', '')
                            .replaceAll(']','')
                            .replaceAll('（取引先）', '')
                            .replaceAll('（フリガナ）', '<br>(フリガナ)')
                    ))
                    {
                      dynamic value = installationInformation[
                      field.autofill.toString()
                          .replaceAll('[', '')
                          .replaceAll(']','')
                          .replaceAll('（取引先）', '')
                          .replaceAll('（フリガナ）', '<br>(フリガナ)')
                      ];
                      textValues.add(value.toString());
                    } else {
                      switch (field.autofill.toString()) {
                        case "[撮影日]":
                          textValues.add(formattedDate);
                          break;
                        case "[会社名]":
                          textValues.add(corporationName);
                          break;
                        case "[案件作成者]" :
                          textValues.add(agentCreator);
                          break;
                        default :
                          textValues.add(field.defaultValue);
                          break;
                      }
                    }
                  }
                }
              }
            }
          }
        });

        for (int multiLineIndex = 0; multiLineIndex < multiLineList.length; multiLineIndex++) {
          if (multiLineList[multiLineIndex]) {
            fontSizeList.add(60);
          } else {
            fontSizeList.add(45);
          }
        }

        return template
            .fillTextFields(
            {
              for (int i = 0; i < textValues.length; i++)
                i + 1 : textValues[i],
            },
            fontSize: fontSizeList,
        );

      } else {
        throw Exception('Failed to load SVG');
      }

    }  catch (e) {
      logger.e('Error downloading SVG: $e');
      return '';
    }

  }

  String updateLineStrokeWidth(String rawSvg, double newStrokeWidth) {
    final RegExp lineRegExp = RegExp(r'<line\s+[^>]*stroke-width="(\d+\.?\d*)"\s*[^>]*>', multiLine: true);

    String updatedSvg = rawSvg.replaceAllMapped(lineRegExp, (match) {
      String originalTag = match.group(0) ?? "";
      double currentStrokeWidth = double.parse(match.group(1) ?? "0");

      if (currentStrokeWidth < newStrokeWidth) {
        String updatedTag = originalTag.replaceAll(RegExp(r'stroke-width="(\d+\.?\d*)"'), 'stroke-width="$newStrokeWidth"');
        return updatedTag;
      } else {
        return originalTag;
      }
    });

    return updatedSvg;
  }

  Future<void> fetchData_corporationBlackboard(bool fromUser) async {

    if (fromUser) {
      // List? responseData = await _httpService.returnList_get(
      //     "$apiUrl/api/mobile/$userId/blackboardPresets?corporation_id=$corporationId");
      //
      // if (responseData != null) {
      //
      //   setState(() {
      //     blackboardList_user = responseData.reversed.toList();
      //     checkInformationList(widget.overViewData);
      //     isLoading = false;
      //   });
      // } else {
      //   setState(() {
      //     isLoading = false;
      //   });
      // }

    } else {
      // List? responseData = await _httpService.returnList_get(
      //     "$apiUrl/api/mobile/$corporationId/blackboardTemplates"
      // );
      //
      // if (responseData != null) {
      //   setState(() {
      //     blackboardList_corporation = responseData;
      //     isLoading = false;
      //   });
      //
      // } else {
      //   setState(() {
      //     isLoading = false;
      //   });
      // }
    }
  }

  String formatDate(DateTime dateTime) {
    final formatter = DateFormat('yyyy/MM/dd', 'ja_JP');
    return formatter.format(dateTime);
  }

  void selectBlackboardBottomOptions(
      String blackBoardName,
      String blackboardId,
      int selectBlackboard
      ) {

    textEditingController.text = blackBoardName;

    showModalBottomSheet(
      isScrollControlled: true,
      elevation: 2.0,
      context: context,
      backgroundColor: Colors.white,
      builder: (_) {
        return
          SizedBox(
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
                child: GridView.count(
                  crossAxisCount: 2,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                                              '黒板名の変更',
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
                                            '新しい黒板名',
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
                                            inputFormatters: [
                                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                                            ],
                                            keyboardType: TextInputType.text,
                                            decoration: InputDecoration(
                                              focusedBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: blackBoardName.isEmpty ? Colors.grey : const Color(0xFF005F6B),
                                                ),
                                              ),
                                              enabledBorder: const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              counterStyle: TextStyle(
                                                color: blackBoardName.isEmpty ? Colors.grey : const Color(0xFF005F6B),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                blackBoardName = value;
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
                                                    if(blackBoardName != '') {
                                                      // final responsePut = await _httpService.returnMap_put(
                                                      //     '$apiUrl/api/mobile/$userId/blackboardPresets/$blackboardId',
                                                      //     {
                                                      //       'name': blackBoardName.toString()
                                                      //     },false,false
                                                      // );
                                                      // if (responsePut != null) {
                                                      //   ToastPage.showToast("黒板名を編集しました");
                                                      //   setState(() {
                                                      //     blackboardList_user[selectBlackboard]['name'] = blackBoardName.toString();
                                                      //   });
                                                      //   Navigator.pop(context);
                                                      // }
                                                    } else {
                                                      ToastPage.showToast("黒板名を入力してください");
                                                    }
                                                  },
                                                  child: const Center(
                                                    child: Text(
                                                      '保存',
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
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          icon: Image.asset(
                            'assets/images/editPencilIcon.png',
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                        ),
                        const Text('黒板名変更',
                            style: TextStyle(
                              color: Color(0xFF005F6B),
                              fontWeight: FontWeight.bold,
                            )
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () async {
                            Navigator.pop(context);

                            showDialog (
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                    '$blackBoardNameを削除します。\nよろしいですか',
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

                                      // Map<String,dynamic> ? deleteResponse =
                                      //   await _httpService.returnMap_delete(
                                      //     '$apiUrl/api/mobile/$userId/blackboardPresets/$blackboardId',{}
                                      //   );
                                      // if (deleteResponse != null) {
                                      //   setState(() {
                                      //     blackboardList_user.removeAt(selectBlackboard);
                                      //   });
                                      //   FirebaseAnalyticsHelper.logEvent(
                                      //     eventName: 'm_黒板プリセット削除',
                                      //   );
                                      //   ToastPage.showToast("黒板を削除しました");
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
                          },
                          icon:  Image.asset(
                            'assets/images/deleteImageIcon.png',
                            color: Colors.red,
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                        ),
                        const Text('黒板削除',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            )
                        ),
                      ],
                    ),
                  ],
                ),

              )
          );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return isLoading ? LoadingPage(loadingMessage: "黒板読み込み中...") :
    PopScope(
      canPop: false,
        child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          elevation: 0,
          title: Text(
            userBlackboard ? '黒板プリセット' : '黒板テンプレート',
            style: const TextStyle(color: Color(0xFF005F6B),
                fontWeight: FontWeight.bold
            ),
          ),
          leading:
          IconButton(
            onPressed: () {
              if (userBlackboard) {
                if (imagesByte.isNotEmpty) {
                  showDialog (
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text(
                          'クラウドに保存されていない写真があります。戻りますか？',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF005F6B)
                          )
                      ),
                      content: const Text(
                        '撮影した写真はデバイスに保存されています',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('いいえ',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF005F6B)
                              )),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text('はい',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:  Color(0xFF005F6B)
                            )
                          ),
                        )
                      ],
                    ),
                  );
                } else {
                  Navigator.pop(context) ;
                }
              } else {
                setState(() {
                  userBlackboard = true;
                });
              }
            },
            icon: const Icon(
                Icons.arrow_back_ios_new_outlined,
                color: Color(0xFF005F6B)
            ),
          ),
          actions: [
            imagesByte.toString() != "[]" ?
            GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                        ImagesPicker(
                          items_whole: items_whole,
                          projectId: projectId,
                          folderPathTitle: folderPathTitle,
                          folderPath: widget.folderPath,
                          folderId: folderId,
                          objectsList : objectsList,
                          fromPictureItems: true,
                          fromReport: false,
                          fromChecklist: false,
                          reportImagesList : imagesFile,
                          takePictureTime: takePictureTime,
                          onUploadComplete : (uploadFinish,uploadFolder,selectedFolder) {
                            widget.onUploadComplete(uploadFinish,uploadFolder,selectedFolder);
                          },
                          onEditImagesByte : (editImagesByte, editImagesFile) {
                            setState(() {
                              imagesByte = editImagesByte;
                              imagesFile = editImagesFile;
                            });
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.portraitUp,
                              DeviceOrientation.portraitDown,
                              DeviceOrientation.landscapeLeft,
                              DeviceOrientation.landscapeRight,
                            ]);
                          },
                          onUpdateReport: (List<File> updateFile,
                              uploadFolderId, uploadFolderPath,uploadFolderName) {  },
                          imagesByte: imagesByte,
                          editingFiles: (String editText, bool add,int total, int approved) {
                            widget.editingFiles(editText,add,total,approved);
                          },
                          // onUploadToChecklist: (fromAgentFolder, byteList, fileList,folderPath,fileComment,tags) {  },
                          settingFolderForChecklist: (newFolderPathTitle , newFolderId , newObjectList, newFolderPath) {
                            widget.settingFolderForChecklist(newFolderPathTitle , newFolderId , newObjectList, newFolderPath);
                          },
                        )
                    ),
                  );
                },
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.2,
                  child: Stack(
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/images/pictureAddIcon.png',
                          height: MediaQuery.of(context).size.height * 0.04,
                        ),
                      ),
                      Positioned(
                        right: MediaQuery.of(context).size.width * 0.05,
                        top: MediaQuery.of(context).size.height * 0.002,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: const BoxDecoration(
                            color: Color(0xFF005F6B),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${imagesByte.length + imagesFile.length}',
                            style: TextStyle(
                                fontSize:
                                imagesByte.length + imagesFile.length < 10 ?
                                MediaQuery.of(context).size.height * 0.02 :
                                MediaQuery.of(context).size.height * 0.015 ,
                                color: Colors.white,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
            ) : const Text(""),
          ],
          backgroundColor: Colors.white,
        ),
        body:
        userBlackboard ?
        blackboardList_user.isEmpty ?
        const Center(
          child: Text(
            '黒板プリセットがありません',
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFF005F6B),
              fontWeight: FontWeight.bold,
            ),
          ),
        ):
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Text(
                      "黒板検索：",
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF005F6B),
                        fontWeight: FontWeight.bold,
                      )
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      color: Colors.white,
                      borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                      border: Border.all(
                        color: Colors.grey,
                        width: 2.0,
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 10),
                    child: TextField(
                      style: const TextStyle(
                          color: Color(0xFF005F6B),
                          fontWeight: FontWeight.bold
                      ),
                      maxLines: 1,
                      decoration:
                      const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'プリセット名'
                      ),
                      onChanged: (value) {
                        setState(() {
                          presetSearchText = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: 14,
                itemBuilder: (context, index) {

                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: index + 1 == 14 ? MediaQuery.of(context).size.height * 0.1 : 0
                    ),
                    child: GestureDetector(
                      onTap: () {},
                      onLongPress: () {
                        selectBlackboardBottomOptions(
                            "blackboardName",
                            "blackboardList_user[index]['_id'].toString()",
                            index
                        );
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.25,
                                child:
                                AspectRatio(
                                  aspectRatio: 4/3,
                                  child:
                                  SvgPicture.asset(
                                      'assets/blackboard/blackboard${index+1}.svg'
                                  ),
                                )),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'null$index',
                                style: const TextStyle(
                                    color: Color(0xFF005F6B),
                                    fontSize: 12
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  // var blackboardName = blackboardList_user[index]['name'] ?? 'null$index';
                  // if (blackboardName != null && (
                  //     presetSearchText.isEmpty || blackboardName.contains(presetSearchText))){
                  //   return Padding(
                  //     padding: EdgeInsets.only(
                  //       bottom: index + 1 == blackboardList_user.length ? MediaQuery.of(context).size.height * 0.1 : 0
                  //     ),
                  //     child: GestureDetector(
                  //       onTap: () {
                  //         Navigator.push(
                  //           context,
                  //           MaterialPageRoute(
                  //             builder: (context) =>
                  //               BlackBoardSelect(
                  //                 folderPath: widget.folderPath,
                  //                 svgImageUrl: blackboardList_user[index]['origin_url'].toString(),
                  //                 projectId: projectId,
                  //                 imagesByte : imagesByte,
                  //                 imagesFile : imagesFile,
                  //                 themeId : blackboardList_user[index]['theme_id'] ?? 0,
                  //                 templateId: blackboardList_user[index]['_id'] ?? "",
                  //                 blackboardName : blackboardName,
                  //                 overViewData: overViewData,
                  //                 items_whole: items_whole,
                  //                 folderPathTitle: folderPathTitle,
                  //                 folderId: folderId,
                  //                 objectsList: objectsList,
                  //                 fromChecklist: widget.fromChecklist,
                  //                 fromDrawing: widget.fromDrawing,
                  //                 hiddenCells: blackboardList_user[index]['hidden_cells'] ?? [],
                  //                 fromUserBlackBoard: userBlackboard,
                  //                 takePictureTime: takePictureTime,
                  //                 addBlackboard: (String svgString, String comment, bool add) {
                  //                   widget.addBlackboard(svgString,comment, add);
                  //                 },
                  //                 onUploadComplete: (uploadFinish,uploadFolder,selectedFolder) {
                  //                   widget.onUploadComplete(uploadFinish,uploadFolder,selectedFolder);
                  //                 },
                  //                 editingFiles: (String editText, bool add, int total, int approved) {
                  //                   widget.editingFiles(editText,add,total,approved);
                  //                 },
                  //                 // onUploadToChecklist:(fromAgentFolder, byteList, fileList,folderPath,fileComment,tags) {
                  //                 //   widget.onUploadToChecklist(fromAgentFolder, byteList, fileList,folderPath,fileComment,tags);
                  //                 // },
                  //                 settingFolderForChecklist: (newFolderPathTitle , newFolderId , newObjectList, newFolderPath) {
                  //                   widget.settingFolderForChecklist(newFolderPathTitle , newFolderId , newObjectList, newFolderPath);
                  //                 },
                  //               )
                  //           ),
                  //         ).then((value) => setState(() {
                  //           if (value != null) {
                  //             setState(() {
                  //               imagesFile = value['imagesFile'];
                  //               imagesByte = value['imagesByte'];
                  //               takePictureTime = value['takePictureTime'];
                  //
                  //               if (value['fromUser'] != null) {
                  //                 Navigator.of(context).pushReplacement(
                  //                     MaterialPageRoute(
                  //                       builder: (context) => BlackBoardList(
                  //                         folderPath: widget.folderPath,
                  //                         items_whole: items_whole,
                  //                         projectId: projectId,
                  //                         folderPathTitle: folderPathTitle,
                  //                         folderId: folderId,
                  //                         objectsList: objectsList,
                  //                         overViewData: overViewData,
                  //                         fromChecklist: widget.fromChecklist,
                  //                         fromDrawing: widget.fromDrawing,
                  //                         addBlackboard: (String svgString, String comment, bool add) {
                  //                           widget.addBlackboard(svgString,comment, add);
                  //                         },
                  //                         onUploadComplete: (uploadFinish, uploadFolder, selectedFolder) async {
                  //                           widget.onUploadComplete(uploadFinish,uploadFolder,selectedFolder);
                  //                         },
                  //                         editingFiles: (String editText, bool add,int total, int approved) {
                  //                           widget.editingFiles(editText,add,total,approved);
                  //                         },
                  //
                  //                         // onUploadToChecklist: (fromAgentFolder, byteList, fileList,folderPath,fileComment,tags) {
                  //                         //   widget.onUploadToChecklist(fromAgentFolder, byteList, fileList,folderPath,fileComment,tags);
                  //                         // },
                  //                         settingFolderForChecklist: (newFolderPathTitle , newFolderId , newObjectList, newFolderPath) {
                  //                           widget.settingFolderForChecklist(newFolderPathTitle , newFolderId , newObjectList, newFolderPath);
                  //                         },
                  //                       ),
                  //                     )
                  //                 );
                  //               }
                  //             });
                  //           }
                  //         }));
                  //       },
                  //       onLongPress: () {
                  //         selectBlackboardBottomOptions(
                  //             blackboardName,
                  //             blackboardList_user[index]['_id'].toString(),
                  //             index
                  //         );
                  //       },
                  //       child: Container(
                  //         width: MediaQuery.of(context).size.width,
                  //         decoration: const BoxDecoration(
                  //           border: Border(
                  //             top: BorderSide(color: Colors.grey),
                  //           ),
                  //         ),
                  //         child: Row(
                  //           children: [
                  //
                  //             SizedBox(
                  //                 height: MediaQuery.of(context).size.height * 0.25,
                  //                 child:
                  //                 AspectRatio(
                  //                   aspectRatio: 4/3,
                  //                   child:
                  //                   FutureBuilder<String>(
                  //                     future: downloadSvg(blackboardList_user[index]['origin_url']),
                  //                     builder: (context, snapshot) {
                  //                       if (snapshot.connectionState == ConnectionState.waiting) {
                  //                         return
                  //                           SizedBox(
                  //                               height: MediaQuery.of(context).size.height * 0.1,
                  //                               width: MediaQuery.of(context).size.width * 0.1,
                  //                               child: const Center(
                  //                                   child: CircularProgressIndicator(
                  //                                     valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005F6B)),
                  //                                   )
                  //                               )
                  //                           );
                  //                       } else if (snapshot.hasError || snapshot.data == '') {
                  //                         return const Center(
                  //                           child: Text(
                  //                             '黒板の読み込みに失敗しました',
                  //                             style: TextStyle(
                  //                                 color: Colors.red,
                  //                                 fontSize: 15
                  //                             ),
                  //                           ),
                  //                         );
                  //                       } else {
                  //                         return SvgPicture.string(
                  //                           snapshot.data!,
                  //                         );
                  //                       }
                  //                     },
                  //                   ),
                  //                 )),
                  //             const SizedBox(width: 10),
                  //             Expanded(
                  //               child: Text(
                  //                 blackboardList_user[index]['name'] ?? 'null$index',
                  //                 style: const TextStyle(
                  //                     color: Color(0xFF005F6B),
                  //                     fontSize: 12
                  //                 ),
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     ),
                  //   );
                  // } else {
                  //   return const SizedBox.shrink();
                  // }
                },
              ),
            ),
          ],
        ) :
        blackboardList_corporation.isEmpty ?
        const Center(
          child: Text(
            '黒板テンプレートがありません',
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFF005F6B),
              fontWeight: FontWeight.bold,
            ),
          ),
        ):
        SizedBox(
          height: MediaQuery.of(context).size.height,
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: blackboardList_corporation.length,
            itemBuilder: (context, index) {
              var blackboardName = blackboardList_corporation[index]['name'] ?? 'null$index';
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                          BlackBoardSelect(
                            folderPath: widget.folderPath,
                            svgImageUrl: blackboardList_corporation[index]['origin_url'].toString(),
                            projectId: projectId,
                            imagesByte : imagesByte,
                            imagesFile : imagesFile,
                            themeId : blackboardList_corporation[index]['theme_id'],
                            templateId: blackboardList_corporation[index]['_id'] ?? "",
                            blackboardName : blackboardName,
                            overViewData: overViewData,
                            items_whole: items_whole,
                            folderPathTitle: folderPathTitle,
                            folderId: folderId,
                            objectsList: objectsList,
                            fromChecklist: widget.fromChecklist,
                            fromDrawing: widget.fromDrawing,
                            hiddenCells: blackboardList_corporation[index]['hidden_cells'] ?? [""],
                            fromUserBlackBoard: userBlackboard,
                            takePictureTime: takePictureTime,
                            addBlackboard: (String svgString, String comment, bool add) {
                              widget.addBlackboard(svgString,comment, add);
                            },
                            // onUploadToChecklist:(fromAgentFolder, byteList, fileList,folderPath,fileComment,tags) {
                            //   widget.onUploadToChecklist(fromAgentFolder, byteList, fileList,folderPath,fileComment,tags);
                            // },
                            onUploadComplete: (uploadFinish,uploadFolder,selectedFolder) {
                              widget.onUploadComplete(uploadFinish,uploadFolder,selectedFolder);
                            },
                            editingFiles: (String editText, bool add, int total, int approved) {
                              widget.editingFiles(editText, add, total,approved);
                            },
                            settingFolderForChecklist: (newFolderPathTitle , newFolderId , newObjectList, newFolderPath) {
                              widget.settingFolderForChecklist(newFolderPathTitle , newFolderId , newObjectList, newFolderPath);
                            },
                          )
                    ),
                  ).then((value) => setState(() {
                    if (value != null) {
                      setState(() {
                        imagesFile = value['imagesFile'];
                        imagesByte = value['imagesByte'];
                        takePictureTime = value['takePictureTime'];

                        if (value['fromUser'] != null) {
                          userBlackboard = true;
                          isLoading = true;

                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => BlackBoardList(
                                items_whole: items_whole,
                                projectId: projectId,
                                folderPathTitle: folderPathTitle,
                                folderPath: widget.folderPath,
                                folderId: folderId,
                                objectsList: objectsList,
                                overViewData: overViewData,
                                fromChecklist: widget.fromChecklist,
                                fromDrawing: widget.fromDrawing,
                                addBlackboard: (String svgString, String comment, bool add) {
                                  widget.addBlackboard(svgString,comment, add);
                                },
                                onUploadComplete: (uploadFinish, uploadFolder, selectedFolder) async {
                                  widget.onUploadComplete(uploadFinish, uploadFolder, selectedFolder);
                                },
                                editingFiles: (String editText, bool add, int total, int approved) {
                                  widget.editingFiles(editText,add, total,approved);
                                },
                                // onUploadToChecklist: (fromAgentFolder, byteList, fileList,folderPath,fileComment,tags) {
                                //   widget.onUploadToChecklist(fromAgentFolder, byteList, fileList,folderPath,fileComment,tags);
                                // },
                                settingFolderForChecklist: (newFolderPathTitle , newFolderId , newObjectList, newFolderPath) {
                                  widget.settingFolderForChecklist(newFolderPathTitle , newFolderId , newObjectList, newFolderPath);
                                },
                              ),
                            ),
                          );
                        }
                      });
                    }
                  }));
                },
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.25,
                        child: AspectRatio(
                          aspectRatio: 4/3,
                          child: SvgPicture.network(
                            blackboardList_corporation[index]['origin_url'],
                            placeholderBuilder: (BuildContext context) =>
                            const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005F6B)),
                                )
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          blackboardList_corporation[index]['name'] ?? 'null$index',
                          style: const TextStyle(
                              color: Color(0xFF005F6B),
                              fontSize: 12
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            floatingActionButton: userBlackboard ? Row(
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
                    backgroundColor: const Color(0xFF005F6B) ,
                    onPressed:() {
                      setState(() {
                        userBlackboard = false;
                        isLoading = true;
                        fetchData_corporationBlackboard(false);
                      });
                    } ,
                    label: const Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.add_circle_outline,color: Colors.white),
                        ),
                        Text(
                            'プリセットを追加',
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
            ) : Container()
      )
    );
  }
}
