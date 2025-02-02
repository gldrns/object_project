
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:object_project/Camera/CameraWithBlackBoard.dart';
import 'package:object_project/ToastPage.dart';
import 'package:object_project/blackBoard/BlackBoardTemplate.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:xml/xml.dart';
import '../LodingPage.dart';

class BlackBoardSelect extends StatefulWidget {

  final String svgImageUrl;
  final int themeId;
  final String projectId;
  final String blackboardName;
  final List<dynamic> overViewData;
  final String templateId;
  final List<dynamic> items_whole;
  final String folderPathTitle;
  final String folderPath;
  final String folderId;
  final List<dynamic> objectsList;
  final List<Uint8List> imagesByte;
  final List<File> imagesFile;
  final List<dynamic> hiddenCells;
  final List<String> takePictureTime;
  final bool fromUserBlackBoard;
  final bool fromChecklist;
  final bool fromDrawing;
  late Function(bool,List<dynamic>,List<dynamic>) onUploadComplete;
  late Function(String, bool, int, int) editingFiles;
  // late Function(bool, List<Uint8List>, List<File>,String,List<String>,List<List>) onUploadToChecklist;
  late Function(String, String, List<dynamic>, String) settingFolderForChecklist;
  late Function(String, String, bool) addBlackboard;

  BlackBoardSelect({
    required this.svgImageUrl,
    required this.themeId,
    required this.projectId,
    required this.blackboardName,
    required this.overViewData,
    required this.items_whole,
    required this.folderPathTitle,
    required this.folderId,
    required this.onUploadComplete,
    required this.editingFiles,
    required this.objectsList,
    required this.imagesByte,
    required this.imagesFile,
    required this.fromChecklist,
    // required this.onUploadToChecklist,
    required this.settingFolderForChecklist,
    required this.hiddenCells,
    required this.fromUserBlackBoard,
    required this.takePictureTime,
    required this.templateId,
    required this.folderPath,
    required this.fromDrawing,
    required this.addBlackboard
  });

  @override
  BlackBoardSelectState createState() => BlackBoardSelectState();
}

class BlackBoardSelectState extends State<BlackBoardSelect> {

  late String _rawSvgTemplate;
  late File boardImage;
  late String corporationId;
  late String corporationName;
  late String projectId = widget.projectId;

  late String labelText;
  late String apiUrl;
  late String projectName;

  late List<String> labelAttributeList = [];
  late List<String> textValues = [];
  late List<String> fieldValues = [];
  late List<dynamic> overViewData;

  List<dynamic> opportunityInformationList = [];
  List<dynamic> customerInformationList = [];
  List<dynamic> installationInformationList = [];

  Map<String,dynamic> opportunityInformation = {};
  Map<String,dynamic>  customerInformation = {};
  Map<String,dynamic>  installationInformation = {};
  List<Uint8List> imagesByte = [];
  List<File> imagesFile = [];
  List<bool> hiddenCells = [];

  late List<TextEditingController> controllers = List.generate(
    textValues.length,
    (index) => TextEditingController(
        text: textValues[index] ?? '',
    ),
    growable: true,
  );

  late int themeId;
  late BlackboardTemplate template;

  bool isLoading = true;
  String userId = '';
  int lineCount = 1;
  int multiLineNumber = 0;
  bool singleLine = true;

  List<String> autofillList = [];
  List<bool> multiLineList = [];
  List<int> dataMaxLengthList = [];
  late String blackboardName;
  late String agentCreator;

  List<int> fontSizeList = [];
  final AutoScrollController blackboardEditListController = AutoScrollController();
  final scrollDirection = Axis.vertical;
  List<String> takePictureTime = [];
  String commentFromBlackboard = "";
  int closestIndex = 0;
  List<Rect> textPositions = [];
  Color selectBackgroundColor = Color(0xFF006837);
  Color selectTextColor = Color(0xFFFFFFFF);
  String selectBackgroundColor_background = "#006837";
  String selectBackgroundColor_text = "#FFFFFF";
  final FocusNode _focusNode = FocusNode();

  List<double> _widthList = [];
  List<double> _heightList = [];

  bool haveDataIndex = false;
  String _horizontal = 'start';
  String _vertical = 'top';

  final List<Color> colors = [
    const Color(0xFF006837),
    const Color(0xFFFFFFFF),
    const Color(0xFF000000),
    const Color(0xFFF6CD56),
  ];

  @override
  void initState() {
    super.initState();
    setState(() {
      themeId = widget.themeId;
      blackboardName = widget.blackboardName;
      overViewData = widget.overViewData;

      if (widget.imagesByte != []) {
        imagesByte = widget.imagesByte;
      }
      if (widget.imagesFile != []) {
        imagesFile = widget.imagesFile;
      }
      if (widget.takePictureTime != []) {
        takePictureTime = widget.takePictureTime;
      }
    });

    getIdToken();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void getIdToken() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userId = prefs.getString('id') ?? '';
      apiUrl = prefs.getString('apiUrl') ?? '';
      corporationId = prefs.getString('corporation_id') ?? '';
      corporationName = prefs.getString('corporation_name') ?? '';
      agentCreator = prefs.getString('agentCreator') ?? '';
    });

    downloadSvg(widget.svgImageUrl);
    checkInformationList(overViewData);
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

  void downloadSvg(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {

    final containerHeight = MediaQuery.of(context).size.height * 0.35;
    final containerWidth = MediaQuery.of(context).size.width;

    setState(() {
      _rawSvgTemplate = utf8.decode(response.bodyBytes).toString();

      textPositions = parseSvgToRectsFromString(
          utf8.decode(response.bodyBytes).toString(),
          containerWidth,
          containerHeight
      );

      template = BlackboardTemplate.fromSvgString(updateLineStrokeWidth(_rawSvgTemplate,4.0));
      projectName = prefs.getString('projectName') ?? '';
    });

    // print("_rawSvgTemplate : $_rawSvgTemplate");

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

      setState(() {
        labelText = field.label;
      });

      autofillList.add(field.autofill.toString());
      multiLineList.add(field.multiline);
      dataMaxLengthList.add(field.maxLength);

      if (widget.hiddenCells.contains(field.autofill.toString())) {
        hiddenCells.add(true);
      } else {
        hiddenCells.add(false);
      }

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
          fieldValues.add(field.autofill.toString());
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
              fieldValues.add(field.autofill.toString());
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
                  fieldValues.add(field.autofill.toString());
                } else {
                  switch (field.autofill.toString()) {
                    case "[撮影日]":
                      textValues.add(formattedDate);
                      fieldValues.add(field.autofill.toString());
                      break;
                    case "[会社名]":
                      textValues.add(corporationName);
                      fieldValues.add(field.autofill.toString());
                      break;
                    case "[案件作成者]" :
                      textValues.add(agentCreator);
                      fieldValues.add(field.autofill.toString());
                      break;
                    default :
                      textValues.add(field.defaultValue);
                      fieldValues.add(field.defaultValue);
                      break;
                  }
                }
              }
            }
          }
        }
      }
    });
      isLoading = false;
    } else {
      Navigator.pop(context, {
        'imagesFile': imagesFile,
        'imagesByte': imagesByte,
        'takePictureTime' : takePictureTime,
      });
      throw Exception('Failed to download SVG file');
    }

    for (int multiLineIndex = 0; multiLineIndex < multiLineList.length; multiLineIndex++) {
      if (multiLineList[multiLineIndex]) {
        fontSizeList.add(60);
        commentFromBlackboard = textValues[multiLineIndex];
      } else {
        fontSizeList.add(30);
      }
    }

    if (!haveDataIndex) {
      for (int i = 0; _widthList.length > i; i++) {
        if (i < hiddenCells.length && i+1 <= _widthList.length) {
          if (hiddenCells[i]) {
            _widthList[i+1] = _widthList[i+1] + 140;
          }
        }
      }
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

  String formatDate(DateTime dateTime) {
    final formatter = DateFormat('yyyy/MM/dd', 'ja_JP');
    return formatter.format(dateTime);
  }

  List<Rect> parseSvgToRectsFromString(String svgData, double containerWidth, double containerHeight) {
    final List<Rect> textRects = [];

    final document = XmlDocument.parse(svgData);

    final viewBox = document.rootElement.getAttribute('viewBox')?.split(' ').map(double.parse).toList();
    if (viewBox == null || viewBox.length != 4) {
      throw Exception('Invalid viewBox format');
    }
    final svgWidth = viewBox[2];
    final svgHeight = viewBox[3];

    final rectElements = document.findAllElements('rect');

    for (var rect in rectElements) {
      final dataIndex = rect.getAttribute('data-index');
      if (dataIndex != null) {
        setState(() {
          haveDataIndex = true;
        });
        final width = rect.getAttribute('width');
        final height = rect.getAttribute('height');

        if (width != null) {
          _widthList.add(double.parse(width));
        }
        if (height != null) {
          _heightList.add(double.parse(height));
        }
      }
    }

    final textElements = document.findAllElements('text');

    for (var index = 0; index < textElements.length; index++) {
      // final display = textElement.getAttribute('display');
      // if (display == 'none') continue;

      final textElement = textElements.elementAt(index);

      if (textElement.getAttribute('display') == 'none' && index == 0) {
        closestIndex = 1;
      }

      final parentGroup = textElement.parent;
      if (parentGroup == null || parentGroup.getAttribute('transform') == null) continue;

      final transform = parentGroup.getAttribute('transform')!;
      final translateMatch = RegExp(r'translate\(([\d.]+)[,\s]+([\d.]+)\)').firstMatch(transform);
      if (translateMatch == null) continue;

      final translateX = double.parse(translateMatch.group(1)!);
      final translateY = double.parse(translateMatch.group(2)!);
      final isMultiline = textElement.getAttribute('data-multiline') == 'true';

      if (!haveDataIndex) {

        var dataMax = textElement.getAttribute('data-max-length') ?? '10';

        switch (dataMax) {
          case '10':
            _widthList.add(130); //136
            _heightList.add(65); //72
          case '16' :
            _widthList.add(220); //228
            _heightList.add(65); //72
          case '50' :
            _widthList.add(600); //608
            _heightList.add(65); //72
          case '75' :
            _widthList.add(745); //752
            _heightList.add(145); //145
          case '100' :
            _widthList.add(745); //752
            _heightList.add(312); //312
        }
      }

      final rect = Rect.fromLTWH(
        translateX / svgWidth * containerWidth,
        translateY / svgHeight * containerHeight,
        _widthList[index] / svgWidth * containerWidth,
        isMultiline ?
        _heightList[index]*0.8/ svgHeight * containerHeight :
        _heightList[index] / svgHeight * containerHeight,
      );

      textRects.add(rect);
    }
    return textRects;
  }

  void _handleTap(Offset tapPosition) {
    int closestIndexTap = -1;
    double minDistance = double.infinity;

    for (int i = 0; i < textPositions.length; i++) {
      final Rect rect = textPositions[i];

      // タップ位置がRect内部にあるか確認
      if (rect.contains(tapPosition)) {
        closestIndexTap = i;
        break; // Rect内部にある場合は、すぐに選択
      }

      // Rect中心とタップ位置間の距離計算
      final Offset rectCenter = rect.center;
      final double distance = (tapPosition - rectCenter).distance;

      // 最寄りのRectをアップデート
      if (distance < minDistance) {
        minDistance = distance;
        closestIndexTap = i;
      }
    }

    if (closestIndexTap != -1) {
      setState(() {
        //hiddenCells確認及びclosestIndexアップデート
        closestIndex = hiddenCells[closestIndexTap] ? closestIndexTap + 1 : closestIndexTap;
      });
    }
  }

  String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  bool isLightColor(Color color) {
    final brightness = (color.red * 0.299 + color.green * 0.587 + color.blue * 0.114);
    return brightness > 186;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            elevation: 0,
            title: Text(blackboardName,
                style: const TextStyle(
                    color: Color(0xFF005F6B),
                    fontWeight: FontWeight.bold)
            ),
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context, {
                  'imagesFile': imagesFile,
                  'imagesByte': imagesByte,
                  'takePictureTime' : takePictureTime
                });
              },
              icon: const Icon(
                  Icons.arrow_back_ios_new_outlined,
                  color: Color(0xFF005F6B)
              ),
            ),
          ),
          body: isLoading
              ? LoadingPage(loadingMessage: "黒板読み込み中...") :
              SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      alignment: Alignment.topCenter,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.35,
                      ),
                      width: MediaQuery.of(context).size.width,
                      decoration: const BoxDecoration(
                        border: Border (
                          top: BorderSide(color: Colors.grey),
                          bottom: BorderSide(color: Colors.grey),
                        ),
                      ),
                      child: GestureDetector(
                        onTapDown: (details) {
                          _handleTap(details.localPosition);
                          controllers[closestIndex].selection = TextSelection.collapsed(
                            offset: controllers[closestIndex].text.length,
                          );
                          // _focusNode.requestFocus();
                        },
                        child: SvgPicture.string(
                          template.fillTextFields(
                            {
                              for (int i = 0; i < textValues.length; i++)
                                i + 1: controllers[i].text.replaceAll('\n', '').isEmpty &&
                                    closestIndex == i ? " | ":controllers[i].text,
                            },
                            svgContent : _rawSvgTemplate,
                            fontSize: fontSizeList.isEmpty ? [30] : fontSizeList,
                            keepPlaceholders: true,
                            ignoreRequirements: true,
                            highlightedIndex: closestIndex,
                            strokeColor: selectBackgroundColor_text,
                            backgroundColor : selectBackgroundColor_background,
                            haveDataIndex: haveDataIndex,
                            widthList: _widthList,
                            heightList: _heightList,
                            horizontal: _horizontal,
                            vertical: _vertical
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: MediaQuery.of(context).size.height * 0.12,
                            width: MediaQuery.of(context).size.width * 0.9,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color:
                              controllers[closestIndex].text.isNotEmpty ?
                              const Color(0xFF005F6B) : Colors.grey),
                            ),
                            child: IntrinsicHeight(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: TextFormField(
                                  focusNode: _focusNode,
                                  style: const TextStyle(
                                    color: Color(0xFF005F6B),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.all(10),
                                    border: InputBorder.none,
                                    hintText: labelAttributeList[closestIndex].toString(),
                                    suffixIcon: controllers[closestIndex].text.isEmpty
                                        ? const SizedBox.shrink()
                                        : IconButton(
                                      onPressed: () {
                                        setState(() {
                                          controllers[closestIndex].text = "";
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.cancel_outlined,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  maxLines: null,
                                  // maxLength: dataMaxLengthList[closestIndex],
                                  controller: controllers[closestIndex],
                                  keyboardType: TextInputType.multiline,
                                  onTapOutside: (value) {
                                    FocusManager.instance.primaryFocus?.unfocus();
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      textValues[closestIndex] = value;
                                      fieldValues[closestIndex] = value;

                                      if (multiLineList[closestIndex]) {
                                        commentFromBlackboard = value;
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 5, bottom: 5
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: const Color(0xFF005F6B)),
                              ),
                              width: MediaQuery.of(context).size.width * 0.9,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: MediaQuery.of(context).size.height * 0.005,
                                      bottom: MediaQuery.of(context).size.height * 0.01
                                    ),
                                    child:  Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  if (fontSizeList[closestIndex + 1] > 5) {
                                                    fontSizeList[closestIndex + 1] -= 5;
                                                  }
                                                });
                                              },
                                              icon: Image.asset(
                                                'assets/images/textSmallerIcon.png',
                                                height: MediaQuery.of(context).size.height * 0.03,
                                              ),
                                            ),
                                            const Text('縮小',
                                              style:  TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF005F6B),
                                                  fontSize: 11
                                              ) ,
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  if (fontSizeList[closestIndex + 1] < 100) {
                                                    fontSizeList[closestIndex + 1] += 5;
                                                  }
                                                });
                                              },
                                              icon:  Image.asset(
                                                'assets/images/textBiggerIcon.png',
                                                color: const Color(0xFF005F6B),
                                                height: MediaQuery.of(context).size.height * 0.04,
                                                width: MediaQuery.of(context).size.width * 0.08,
                                              ),
                                            ),
                                            const Text('拡大',
                                              style:  TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF005F6B),
                                                  fontSize: 12
                                              ),
                                            ),
                                          ],
                                        ),
                                        if(widget.fromUserBlackBoard)
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                onPressed: () {
                                                  if (multiLineList[closestIndex]) {
                                                    setState(() {
                                                      switch (_horizontal) {
                                                        case "start":
                                                          _horizontal = "center";
                                                        case "center":
                                                          _horizontal = "end";
                                                        case "end":
                                                          _horizontal = "start";
                                                      }
                                                    });
                                                  }
                                                },
                                                icon:
                                                Image.asset(
                                                  _horizontal == "center" ?
                                                  'assets/images/arrayCenter.png' :
                                                  _horizontal == "end" ?
                                                  'assets/images/arrayEnd.png':
                                                  'assets/images/arrayStart.png',
                                                  height: MediaQuery.of(context).size.height * 0.03,
                                                  color: multiLineList[closestIndex] ?
                                                  const Color(0xFF005F6B) : Colors.grey,
                                                ),
                                              ),
                                              Text( _horizontal == "center" ?
                                              '中央' :
                                              _horizontal == "end" ?
                                              '右':
                                              '左',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: multiLineList[closestIndex] ?
                                                  const Color(0xFF005F6B) : Colors.grey,
                                                ) ,
                                              ),
                                            ],
                                          ),
                                        if(widget.fromUserBlackBoard)
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                onPressed: () {
                                                  if (multiLineList[closestIndex]) {
                                                    setState(() {
                                                      switch (_vertical) {
                                                        case "top":
                                                          _vertical = "center";
                                                        case "center":
                                                          _vertical = "bottom";
                                                        case "bottom":
                                                          _vertical = "top";
                                                      }
                                                    });
                                                  }
                                                },
                                                icon: Image.asset(
                                                  _vertical == "center" ?
                                                  'assets/images/verticalCenter.png' :
                                                  _vertical == "bottom" ?
                                                  'assets/images/verticalDown.png':
                                                  'assets/images/verticalUp.png',
                                                  height: MediaQuery.of(context).size.height * 0.03,
                                                  color: multiLineList[closestIndex] ?
                                                  const Color(0xFF005F6B) : Colors.grey,
                                                ),
                                              ),
                                              Text(_vertical == "center" ?
                                              '中央' :
                                              _vertical == "bottom" ?
                                              '下':
                                              '上',
                                                style:  TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: multiLineList[closestIndex] ?
                                                  const Color(0xFF005F6B) : Colors.grey,
                                                ) ,
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          if (widget.fromUserBlackBoard)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: const Color(0xFF005F6B)),
                              ),
                              height: MediaQuery.of(context).size.height * 0.1,
                              width: MediaQuery.of(context).size.width * 0.9,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(
                                      top: 5,
                                      bottom: 5,
                                      left: 15,
                                    ),
                                    child: Text("黒板色",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF005F6B),
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: List.generate(colors.length, (index) {
                                      final color = colors[index];
                                      final isSelected = selectBackgroundColor == color;

                                      return Stack(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                selectBackgroundColor = color;
                                                selectTextColor = isLightColor(color) ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
                                                selectBackgroundColor_background = colorToHex(color);
                                                selectBackgroundColor_text = isLightColor(color) ? "#000000" : "#FFFFFF";
                                              });
                                            },
                                            child: Container(
                                              width: 30,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: color,
                                                border: Border.all(
                                                  color: isLightColor(color) ? Colors.black : Colors.white,
                                                  width: 1.0,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              top: 0,
                                              left: 0,
                                              child: Icon(
                                                Icons.check_outlined,
                                                color: isLightColor(color) ? Colors.black : Colors.white,
                                                size: 15,
                                              ),
                                            ),
                                        ],
                                      );
                                    }),
                                  ),
                                ],
                              )
                            ),
                        ],
                      ),
                    )

                  ],
                ),
              ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.07,
                width: MediaQuery.of(context).size.width * 0.8,
                child: FloatingActionButton.extended(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  backgroundColor: const Color(0xFF005F6B),
                  onPressed: () async {
                    if (widget.fromUserBlackBoard) {
                      if (widget.fromDrawing) {
                        widget.addBlackboard(
                          template.fillTextFields(
                              {
                                for (int i = 0; i < textValues.length; i++)
                                  i + 1 : controllers[i].text
                              },
                              fontSize: fontSizeList.isEmpty ? [30] : fontSizeList,
                              highlightedIndex: 99,
                              strokeColor: selectBackgroundColor_text,
                              backgroundColor : selectBackgroundColor_background,
                              widthList: _widthList,
                              heightList: _heightList,
                              horizontal: _horizontal,
                              vertical: _vertical
                          ),commentFromBlackboard,true
                        );
                        Navigator.of(context).popUntil(ModalRoute.withName('/Drawing'));
                      } else {
                        Navigator.push(context,
                            MaterialPageRoute(
                              builder: (context) => CameraWithBlackBoard(
                                folderPath: widget.folderPath,
                                commentFromBlackboard : commentFromBlackboard,
                                fromChecklist: widget.fromChecklist,
                                items_whole: widget.items_whole,
                                projectId: projectId,
                                folderPathTitle: widget.folderPathTitle,
                                folderId: widget.folderId,
                                objectsList: widget.objectsList,
                                imagesByte: imagesByte,
                                imagesFile: imagesFile,
                                takePictureTime: takePictureTime,
                                svgImageUrl: template.fillTextFields(
                                  {
                                    for (int i = 0; i < textValues.length; i++)
                                      i + 1 : controllers[i].text
                                  },
                                  fontSize: fontSizeList.isEmpty ? [30] : fontSizeList,
                                  highlightedIndex: 99,
                                  strokeColor: selectBackgroundColor_text,
                                  backgroundColor : selectBackgroundColor_background,
                                  widthList: _widthList,
                                  heightList: _heightList,
                                  horizontal: _horizontal,
                                  vertical: _vertical
                                ),
                                overViewData: overViewData,
                                onUploadComplete: (uploadFinish,uploadFolder,selectedFolder) {
                                  widget.onUploadComplete(uploadFinish,uploadFolder,selectedFolder);
                                },
                                editingFiles: (String editText, bool add, int total, int approved) {
                                  widget.editingFiles(editText,add,total,approved);
                                },
                                // onUploadToChecklist:(fromAgentFolder, byteList, fileList,folderPath, fileComment,tags) {
                                //   widget.onUploadToChecklist(fromAgentFolder, byteList, fileList,folderPath, fileComment,tags);
                                // },
                                settingFolderForChecklist: (newFolderPathTitle , newFolderId , newObjectList, newFolderPath ) {
                                  widget.settingFolderForChecklist(newFolderPathTitle , newFolderId , newObjectList, newFolderPath);
                                }
                              ),
                            )
                        ).then((value) => setState(() {
                          if (value != null) {
                            setState(() {
                              imagesFile = value['imagesFile'];
                              imagesByte = value['imagesByte'];
                              takePictureTime = value['takePictureTime'];
                            });
                          }
                        }));
                      }
                    } else {

                      final dateFormat = DateFormat('MMddHHmmss');
                      Map<String, dynamic> itemsMap = {};
                      for (int i = 0; i < fieldValues.length; i++) {
                        itemsMap['field${i + 1}'] = {
                          "text": fieldValues[i],
                          "size": "${fontSizeList[i + 1]}"
                        };
                      }

                      // Map<String,dynamic>? responseData = await _httpService.returnMap_post(
                      //     "$apiUrl/api/mobile/$userId/blackboardPresets",
                      //     {
                      //       "name": "新しい黒板${dateFormat.format(DateTime.now())}",
                      //       "items": itemsMap,
                      //       "theme_id": widget.themeId,
                      //       "corporation_id" : corporationId,
                      //       "project_id" : projectId,
                      //       "blackboard_template_id" : widget.templateId
                      //     }, true, true
                      // );
                      //
                      // if (responseData != null) {
                      //
                      //   Navigator.pop(context, {
                      //     'imagesFile': imagesFile,
                      //     'imagesByte': imagesByte,
                      //     'takePictureTime' : takePictureTime,
                      //     'fromUser' : widget.fromUserBlackBoard
                      //   });
                      //
                      //   ToastPage.showToast("黒板プリセットを作成しました");
                      // } else {
                      //   ToastPage.showToast("黒板プリセット作成中エラーが発生しました");
                      // }
                    }
                  } ,
                  label: Row(
                    children: [
                      if (widget.fromUserBlackBoard && !widget.fromDrawing)
                        Image.asset(
                          'assets/images/blackboardWithCamera.png',
                          color: Colors.white,
                          height: MediaQuery.of(context).size.height * 0.03,
                        ),
                      if (!widget.fromUserBlackBoard)
                        const Icon(Icons.add_circle_outline,
                            color: Colors.white
                        ),
                      if (widget.fromUserBlackBoard && widget.fromDrawing)
                        Image.asset(
                          'assets/images/blackboardAddToImage.png',
                          color: Colors.white,
                          height: MediaQuery.of(context).size.height * 0.03,
                        ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child:
                        Text(
                            widget.fromUserBlackBoard ?
                            widget.fromDrawing ? '写真に黒板追加' :
                            '黒板写真撮影' : "プリセット追加",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white
                            )
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          )
      )
    );
  }
}

