
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:object_project/Camera/DrawingProvider.dart';
import 'package:object_project/EditScreen.dart';
import 'package:object_project/SnackbarPage.dart';
import 'package:object_project/ToastPage.dart';
import 'package:object_project/blackBoard/BlackBoardList.dart';
import 'package:object_project/models/DotInfo.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;

class ImageDrawing extends StatefulWidget {

  final String imageUrl;
  final String imageThumbnail;
  final String imageName;

  final String folderId;
  final String folderPathTitle;
  final String projectId;
  final List<dynamic> objectsList;

  late Function(List<dynamic>,dynamic) onUploadComplete;
  final bool typeIsFile;

  final bool fromList;
  final Function(bool) onDelete;

  final Uint8List imageByte;
  final File imageFile;
  final Function(File, bool) onEditImage;
  final Map<String,dynamic> editMap;
  late Function(String,String,List<String>,bool) onEditComplete;

  ImageDrawing({
    super.key,
    required this.imageUrl,
    required this.imageName,
    required this.folderId,
    required this.folderPathTitle,
    required this.projectId,
    required this.objectsList,
    required this.onUploadComplete,
    required this.typeIsFile,
    required this.onDelete,
    required this.imageFile,
    required this.onEditImage,
    required this.fromList,
    required this.imageByte,
    required this.imageThumbnail,
    required this.editMap,
    required this.onEditComplete
  });

  @override
  State<ImageDrawing> createState() => _ImageDrawingState();
}

class _ImageDrawingState extends State<ImageDrawing> {

  Offset _textOffset = Offset.zero;
  final GlobalKey _globalKey = GlobalKey();
  late bool fromList;

  late String folderPathTitle;
  late String projectId;
  late String apiUrl;
  late String folderId;
  late List<dynamic> objectsList;

  late String parameterUrl;
  late String postBody;
  late bool typeIsFile;
  List<Uint8List> imagesList = [];

  bool _drawingMode = false;
  bool _textInputMode = false;
  bool _blackboardMode = false;
  TextEditingController editingController = TextEditingController();
  bool painted = false;
  Color selectColor = Colors.black;

  List<String> _textList = [''];
  List<Color> _textListColor = [Colors.transparent];
  List<Color> _textListBorder = [Colors.transparent];
  List<double> _textListSize = [0];
  int _selectedTextIndex = 0;
  bool _imageSaving = false;

  late ImageProvider imageProvider;
  double imageHeight = 0;
  double imageWidth = 0;
  double imageRatio = 0;
  bool isPreview = true;
  String imageName = "";
  bool canDelete = true;
  String createdUserId = "";
  String userId = "";

  static const _minScale = 1.0;
  static const _maxScale = 5.0;

  var _prevScale = _minScale;
  var _scale = _minScale;
  var _offset = Offset.zero;
  var _size = Size.infinite;
  final _key = GlobalKey();
  bool _haveAuthority = false;
  String fileComment = "";

  String svgImage = "";
  Offset blackBoardLocation = Offset.zero;

  double _boardScale = 1.0;
  double _boardUiWidth = 160;
  double _boardUiHeight = 120;

  @override
  void initState() {
    super.initState();

    setState(() {
      typeIsFile = widget.typeIsFile;
      projectId = widget.projectId;
      objectsList = widget.objectsList;
      folderId = widget.folderId;
      folderPathTitle = widget.folderPathTitle;
      fromList = widget.fromList;
      imageName = widget.imageName;
      fileComment = widget.editMap['fileComment'] ?? "";

      if ((widget.editMap['fileMap']['use_report'] != null && widget.editMap['fileMap']['use_report'] != 0)) {
        canDelete = false;
      }

      if (widget.editMap['fileMap']['use_checklist'] != null && widget.editMap['fileMap']['use_checklist'].isNotEmpty) {
        canDelete = false;
      }

      if (widget.editMap['fileMap']['use_report_file'] != null && widget.editMap['fileMap']['use_report_file'].isNotEmpty) {
        canDelete = false;
      }

      createdUserId = widget.editMap['created_by'] ?? "";
      _haveAuthority = widget.editMap['projectRole'].contains('project_images.create');
    });

    _checkImageDimensions();
  }

  Future<void> picturesUpload(String pictureName, File pictureFile) async {

    img.Image? pngImage = img.decodeImage(pictureFile.readAsBytesSync());
    var jpegBytes = img.encodeJpg(pngImage!, quality: 100);
    String base64Image = base64Encode(jpegBytes);

    // Map<String,dynamic> objects = {
    //   "folder_id": folderId,
    //   'name' : pictureName,
    //   postBody : 'data:image/jpeg;base64, $base64Image'
    // };
    //
    // if (fileComment != "") {
    //   objects['comment'] = fileComment;
    // }
    //
    // Map<String,dynamic>? responseData = await _httpService.returnMap_post(
    //     apiUrl + parameterUrl,objects, false,false
    // );
    //
    // if (responseData != null) {
    //
    //   final responseObject = responseData['data'];
    //
    //   widget.onUploadComplete(objectsList,responseObject);
    //
    //   SnackBarPage.showSnackBar(true, '写真の送信', '$folderPathTitleに格納しました');
    // } else {
    //   SnackBarPage.showSnackBar(false, '写真伝送中エラー', '$folderPathTitleに送信中エラー発生');
    // }
  }

  void inputText() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テキストを入力',
            style: TextStyle(
              color: Color(0xFF005F6B),
              fontWeight: FontWeight.bold,
            )
        ),
        content: TextField(
          style: const TextStyle(
              color: Color(0xFF005F6B),
              fontWeight: FontWeight.bold
          ),
          controller: editingController,
          decoration: const InputDecoration(
            hintText: 'ここに入力してください',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (editingController.text.isNotEmpty) {
                  _textList.add(editingController.text.toString());
                  _textListColor.add(Colors.black);
                  _textListBorder.add(Colors.transparent);
                  _textListSize.add(30);
                  _selectedTextIndex = _textList.length -1;
                  Navigator.pop(context);
                } else {
                  ToastPage.showToast('テキストを入力してください');
                }
              });
            },
            child: const Text('決定',
                style: TextStyle(
                  color: Color(0xFF005F6B),
                  fontWeight: FontWeight.bold,
                )
            ),
          )
        ],
      ),
    );
  }

  void editText(String text, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テキストを入力',
            style: TextStyle(
              color: Color(0xFF005F6B),
              fontWeight: FontWeight.bold,
            )
        ),
        content: TextField(
          style: const TextStyle(
              color: Color(0xFF005F6B),
              fontWeight: FontWeight.bold
          ),
          controller: editingController,
          decoration: const InputDecoration(
            hintText: 'ここに入力してください',
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _textList[index] = "";
                    _textListBorder[index] = Colors.transparent;
                  });
                  Navigator.pop(context);
                },
                child: const Text('削除',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    )
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _textList[index] = editingController.text;
                  });
                  Navigator.pop(context);
                },
                child: const Text('決定',
                    style: TextStyle(
                      color: Color(0xFF005F6B),
                      fontWeight: FontWeight.bold,
                    )
                ),
              ),
            ],
          )

        ],
      ),
    );
  }

  void savePictureToGallery(bool uploadPicture,bool fromList) async {

    setState(() {
      _imageSaving = true;
    });

    RenderRepaintBoundary boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
    var image = await boundary.toImage(pixelRatio: 4);
    var imageBytes = await image.toByteData(format: ImageByteFormat.png);
    var pngBytes = imageBytes?.buffer.asUint8List();

    final saveImage = await ImageGallerySaver.saveImage(
      Uint8List.fromList(pngBytes!),
      quality: 100,
      name: widget.imageName,
      isReturnImagePathOfIOS: true,
    );


    if (saveImage != null) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      Directory tempDir = await getTemporaryDirectory();
      File compressedFile = File('${tempDir.path}/eidt_image$currentTime.png');
      await compressedFile.writeAsBytes(pngBytes);

      if (fromList) {
        if (uploadPicture) {
          picturesUpload('edit_image$currentTime.png',compressedFile);
          ToastPage.showToast('写真をデバイスに保存しました');
          Navigator.pop(context);

        } else {
          setState(() {
            _imageSaving = false;
          });
          ToastPage.showToast('写真をデバイスに保存しました');
          Navigator.pop(context);
        }
      } else {
        setState(() {
          widget.onEditImage(compressedFile, uploadPicture);
          _imageSaving = false;
        });
        ToastPage.showToast('写真をデバイスに保存しました');
        Navigator.pop(context, fileComment);
      }
    } else {
      setState(() {
        _imageSaving = false;
      });
      ToastPage.showToast('写真保存失敗');
    }
  }

  Future<void> _checkImageDimensions() async {

    final prefs = await SharedPreferences.getInstance();
    apiUrl = prefs.getString('apiUrl') ?? '';

    setState(() {
      apiUrl = prefs.getString('apiUrl') ?? '';
      userId = prefs.getString('id') ?? '';
    });

    if (fromList) {
      imageProvider = NetworkImage(widget.imageUrl);
    } else if (widget.typeIsFile) {
      imageProvider = FileImage(widget.imageFile);
    } else {
      imageProvider = MemoryImage(widget.imageByte);
    }

    final imageStream = imageProvider.resolve(const ImageConfiguration());
    final completer = Completer<void>();
    imageStream.addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        final myImage = info.image;
        setState(() {
          imageHeight = myImage.height.toDouble();
          imageWidth = myImage.width.toDouble();
          imageRatio = (imageHeight/imageWidth);
        });

        completer.complete();
      }),
    );
    await completer.future;
  }

  Offset _fitBoundary({required Offset targetOffset, required double scale, required Size boxSize}) {
    final newOffsetX = clampDouble(
      targetOffset.dx,
      (1 / scale - 1) * boxSize.width / 2,
      (1 - 1 / scale) * boxSize.width / 2,
    );
    final newOffsetY = clampDouble(
      targetOffset.dy,
      (1 / scale - 1) * boxSize.height / 2,
      (1 - 1 / scale) * boxSize.height / 2,
    );

    return Offset(newOffsetX, newOffsetY);
  }


  @override
  Widget build(BuildContext context) {
    var drawingProvider = Provider.of<DrawingProvider>(context);

    double appBarHeight = AppBar().preferredSize.height;
    double bottomNavigationBarHeight = kBottomNavigationBarHeight;

    double bodyHeight = MediaQuery.of(context).size.width * (4 / 3);
    double remainingHeight = MediaQuery.of(context).size.height -
        appBarHeight -
        bottomNavigationBarHeight -
        bodyHeight;

    bool doubleRatio = ((MediaQuery.of(context).size.height/MediaQuery.of(context).size.width) > 2);

    double remainingHeight_SE = MediaQuery.of(context).size.height -
        appBarHeight -
        bottomNavigationBarHeight -
        MediaQuery.of(context).size.width;

    if (typeIsFile) {
      setState(() {
        parameterUrl = '/api/mobile/projects/$projectId/documentFolder/documents';
        postBody = 'file_data';
      });
    } else {
      setState(() {
        parameterUrl = '/api/mobile/projects/$projectId/pictureFolder/pictures';
        postBody = 'image';
      });
    }

    return PopScope(
        canPop: false,
        child:
        Scaffold(
          appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: fromList ? Text(
                imageName,
                style: const TextStyle(
                    color: Color(0xFF005F6B),
                    fontWeight: FontWeight.bold,
                    fontSize: 15
                ),
              ) :
              Column(
                children: [
                  const Text("設定フォルダ",
                    style: TextStyle(
                        color: Color(0xFF005F6B),
                        fontWeight: FontWeight.bold,
                        fontSize: 15
                    ),
                  ),
                  Text(folderPathTitle,
                    style: const TextStyle(
                        color: Color(0xFF005F6B),
                        fontWeight: FontWeight.bold,
                        fontSize: 15
                    ),
                  )
                ],
              ),
              leading:
              IconButton(
                onPressed: () {
                  if (isPreview) {
                    Navigator.pop(context);
                  } else {
                    if (_imageSaving) {
                      ToastPage.showToast("写真保存中です");
                    } else {
                      if (_textList.length > 1 || painted || svgImage != '') {
                        showDialog (
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text(
                                '編集した内容を破棄しますか？',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF005F6B))
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
                                  setState(() {
                                    isPreview = true;
                                    _drawingMode = false;
                                    _textInputMode = false;
                                    _blackboardMode = false;
                                    _imageSaving = false;
                                    _offset = Offset.zero;
                                    _scale = 1.0;
                                    _boardScale = 1.0;
                                    _textList = [''];
                                    _textListColor = [Colors.transparent];
                                    _textListBorder = [Colors.transparent];
                                    _textListSize = [0];
                                    _selectedTextIndex = 0;
                                    svgImage = '';
                                    drawingProvider.eraseAll();
                                    painted = false;
                                  });
                                },
                                child: const Text('破棄',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color:  Colors.redAccent
                                    )
                                ),
                              )
                            ],
                          ),
                        );
                      } else {
                        setState(() {
                          isPreview = true;
                          _drawingMode = false;
                          _textInputMode = false;
                          _blackboardMode = false;
                          _offset = Offset.zero;
                          _scale = 1.0;
                          _boardScale = 1.0;
                        });
                      }
                    }

                  }
                },
                icon: const Icon(
                    Icons.arrow_back_ios_new_outlined,
                    color: Color(0xFF005F6B)
                ),
              )
          ),
          body: Container(
            color: Colors.white,
            child: Center(
              child: ClipRect(
                child: Transform(
                    key: _key,
                    transform: Matrix4.identity()..scale(_scale)..translate(_offset.dx, _offset.dy, 0),
                    alignment: Alignment.center,
                    child: Container(
                      color: Colors.white,
                      height:
                      MediaQuery.of(context).size.width > imageWidth ?
                      imageWidth * imageRatio :
                      imageWidth > imageHeight ? MediaQuery.of(context).size.width * imageRatio :
                      MediaQuery.of(context).size.width * 4/3,
                      width:
                      MediaQuery.of(context).size.width > imageWidth ?
                      imageWidth :
                      imageRatio > 1.3 ?
                      (MediaQuery.of(context).size.width * 4/3)/imageRatio
                          : MediaQuery.of(context).size.width,
                      child:  GestureDetector(
                          onDoubleTap: () {
                            if (!_drawingMode && !_textInputMode && !_blackboardMode) {
                              setState(() {
                                if (_scale >= 5.0) {
                                  _offset = Offset.zero;
                                  _scale = 1.0;
                                } else {
                                  _scale += 0.5;
                                }
                              });
                            }
                          },
                          onScaleStart: (details) {
                            if (details.pointerCount == 2) {
                              setState(() {
                                _prevScale = _scale;
                                _size = _key.currentContext!.size!;
                              });
                            } else {
                              if (_drawingMode) {
                                if(drawingProvider.eraseMode){
                                  drawingProvider.erase(details.localFocalPoint);
                                } else {
                                  drawingProvider.drawStart(details.localFocalPoint);
                                }
                              } else {
                                setState(() {
                                  _prevScale = _scale;
                                  _size = _key.currentContext!.size!;
                                });
                              }
                            }

                          },
                          onScaleUpdate: (details) {
                            if (details.pointerCount == 2) {

                              final newScale = clampDouble(_prevScale * details.scale, _minScale, _maxScale);

                              final newOffset = _fitBoundary(
                                targetOffset: _offset + details.focalPointDelta / newScale,
                                scale: _scale,
                                boxSize: _size,
                              );

                              setState(() {
                                _scale = newScale;
                                _offset = newOffset;
                              });

                            }
                            else if (details.pointerCount == 1 && !_blackboardMode) {
                              if (_textInputMode) {
                                setState(() {
                                  double newOffsetX = (_textOffset.dx + details.focalPoint.dx).clamp(
                                      -MediaQuery.of(context).size.width,
                                      MediaQuery.of(context).size.width
                                  );
                                  double newOffsetY = (_textOffset.dy + details.focalPoint.dy).clamp(
                                      -MediaQuery.of(context).size.width * (4/3),
                                      MediaQuery.of(context).size.width * (4/3)
                                  );

                                  _textOffset = Offset(newOffsetX, newOffsetY);
                                });
                              } else {
                                if (_drawingMode) {
                                  if(drawingProvider.eraseMode){
                                    drawingProvider.erase( details.localFocalPoint);
                                  } else {
                                    drawingProvider.drawing( details.localFocalPoint);
                                    if (details.focalPoint != Offset.zero) {
                                      painted = true;
                                    }
                                  }
                                } else {
                                  setState(() {

                                    final newOffset = _fitBoundary(
                                      targetOffset: _offset + details.focalPointDelta / _scale,
                                      scale: _scale,
                                      boxSize: _size,
                                    );

                                    setState(() {
                                      _offset = newOffset;
                                    });
                                  });
                                }
                              }
                            }
                          },
                          child:
                          RepaintBoundary(
                              key: _globalKey,
                              child : Stack(
                                children: [
                                  if (isPreview && fromList)
                                    Center(
                                      child:  Image.network(
                                        widget.imageUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (BuildContext context,
                                            Widget child,
                                            ImageChunkEvent? loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          } else {
                                            return Image.network(
                                              width: MediaQuery.of(context).size.width,
                                              widget.imageThumbnail,
                                              fit: BoxFit.cover,
                                            );
                                          }
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.error);
                                        },
                                      ),
                                    ),
                                  if (!isPreview || !fromList)
                                    Center(
                                      child: Image(image: imageProvider,
                                        fit: BoxFit.cover,
                                        alignment: Alignment.center,
                                      ) ,
                                    ),
                                  if (svgImage != '')
                                    Positioned (
                                      width: _boardUiWidth * _boardScale,
                                      height: _boardUiHeight * _boardScale,
                                      top: blackBoardLocation.dy,
                                      left: blackBoardLocation.dx,
                                      child: GestureDetector(
                                        onPanUpdate: (details) {
                                          setState(() {
                                            final newLocation = blackBoardLocation + details.delta;
                                            blackBoardLocation = newLocation;
                                          });
                                        },

                                        child: AspectRatio(
                                          aspectRatio: 3/4,
                                          child: SvgPicture.string(
                                            svgImage,
                                            fit: BoxFit.contain,
                                            alignment: Alignment.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (_textList != [''] && !isPreview)
                                    _customText(),
                                  if (!isPreview)
                                    CustomPaint(
                                      painter: DrawingPainter(drawingProvider.lines),
                                    ),
                                ],
                              )
                          )
                      ),
                    )
                ),
              ),
            ),
          ),
          bottomNavigationBar: Container(
              height:
              doubleRatio ?
              remainingHeight :
              remainingHeight_SE,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withOpacity(0.4),
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (isPreview)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if ((widget.editMap['projectRole'].contains('project_images.update') || !fromList)
                            || (createdUserId == "" || (userId != "" && createdUserId == userId))
                        )
                          Column(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            EditScreen(
                                              items_whole : widget.editMap['items_whole'] ?? [],
                                              projectId: widget.editMap['projectId'],
                                              fileId: widget.editMap['fileId'] ?? "",
                                              fileName: widget.editMap['fileName'] ?? "",
                                              fileUrl: widget.editMap['fileUrl'] ?? "",
                                              folderPathTitle: widget.editMap['folderPathTitle'] ?? "",
                                              folderPathList: widget.editMap['folderPath'] ?? "",
                                              editImage: widget.editMap['editImage'] ?? false,
                                              fromItemScreen: widget.editMap['fromItemScreen'] ?? false,
                                              fileByte: widget.editMap['fileByte'] ?? Uint8List(0),
                                              typeIsFile: widget.editMap['typeIsFile'] ?? false,
                                              file: widget.editMap['file'] ?? File(''),
                                              pictureFolderData: widget.editMap['pictureFolderData'] ?? {}.cast<String, dynamic>(),
                                              fileMap: widget.editMap['fileMap'] ?? {}.cast<String, dynamic>(),
                                              fileComment: fileComment,
                                              tagsList: widget.editMap['tagsList'] ?? [],
                                              // projectRole: widget.editMap['projectRole'] ?? [],
                                              onEditComplete: (String editName,String editComment,
                                                  List<String> editTags, bool moveFile) {
                                                setState(() {
                                                  if (editName != "" && editName != imageName) {
                                                    imageName = editName;
                                                  }
                                                  fileComment = editComment;
                                                });

                                                widget.onEditComplete(editName,editComment,editTags,moveFile);
                                              },
                                              folderId: folderId,
                                              canMove: canDelete,
                                            )
                                    ),
                                  );
                                },
                                icon:  Image.asset(
                                  'assets/images/editImageIcon.png',
                                  color: const Color(0xFF005F6B),
                                  height: MediaQuery.of(context).size.height * 0.04,
                                  width: MediaQuery.of(context).size.width * 0.08,
                                ),
                              ),
                              const Text('詳細を編集',
                                style:  TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF005F6B),
                                    fontSize: 12
                                ),
                              ),
                            ],
                          ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    isPreview = false;
                                  });
                                },
                                icon: Image.asset(
                                  'assets/images/drawingImageIcon.png',
                                  color: const Color(0xFF005F6B),
                                  height: MediaQuery.of(context).size.height * 0.04,
                                  width: MediaQuery.of(context).size.width * 0.1,
                                )
                            ),
                            const Text('イメージ編集',
                              style:  TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF005F6B),
                                  fontSize: 11
                              ) ,
                            ),
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () async{
                                final response = await http.get(Uri.parse(widget.imageUrl));

                                if (response.statusCode == 200) {
                                  await ImageGallerySaver.saveImage(
                                      Uint8List.fromList(response.bodyBytes),
                                      name: widget.imageName
                                  );

                                  ToastPage.showToast('写真をダウンロードしました');
                                } else {
                                  ToastPage.showToast('ダウンロードに失敗しました');
                                }
                              },
                              icon: Image.asset(
                                'assets/images/downloadImageIcon.png',
                                color: const Color(0xFF005F6B),
                                height: MediaQuery.of(context).size.height * 0.04,
                                width: MediaQuery.of(context).size.width * 0.08,
                              ),

                            ),
                            const Text('ダウンロード',
                              style:  TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF005F6B),
                                  fontSize: 11
                              ) ,
                            ),

                          ],
                        ),
                        if(((widget.editMap['projectRole'].contains('project_images.destroy') || !fromList)
                            || (createdUserId == "" || (userId != "" && createdUserId == userId))) && canDelete)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    showDialog (
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(
                                            '$imageNameを削除します。\nよろしいですか',
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
                                              widget.onDelete(true);
                                              Navigator.pop(context);
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
                                  icon: Image.asset(
                                    'assets/images/deleteImageIcon.png',
                                    height: MediaQuery.of(context).size.height * 0.04,
                                    width: MediaQuery.of(context).size.width * 0.08,
                                  ),
                                ),
                                const Text('削除',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11
                                    )
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  if (!isPreview)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.08,
                          width: MediaQuery.of(context).size.width * 0.2,
                          child: InkWell(
                            child: FloatingActionButton.extended(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              backgroundColor: _drawingMode ?
                              const Color(0xFF005F6B) : Colors.white,
                              onPressed: () {
                                setState(() {
                                  _drawingMode = !_drawingMode;
                                  _textInputMode = false;
                                  _blackboardMode = false;
                                  selectColor = Colors.black;
                                  if (_textListBorder.any((color) => color != Colors.transparent)) {
                                    setState(() {
                                      _textListBorder.fillRange(0, _textListBorder.length, Colors.transparent);
                                    });
                                  }
                                });
                              },
                              label: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/pencil.png',
                                    color: !_drawingMode ?
                                    const Color(0xFF005F6B) : Colors.white,
                                    height: MediaQuery.of(context).size.height * 0.04,
                                  ),
                                  Text('ペン',
                                    style:  TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: !_drawingMode ?
                                      const Color(0xFF005F6B) : Colors.white,
                                    ) ,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.08,
                          width: MediaQuery.of(context).size.width * 0.2,
                          child: InkWell(
                            onLongPress: () {
                              setState(() {
                                editingController.text.isEmpty;
                              });
                            },
                            child: FloatingActionButton.extended(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              backgroundColor: _textInputMode ?
                              const Color(0xFF005F6B) : Colors.white,
                              onPressed: () {
                                setState(() {
                                  _drawingMode = false;
                                  _blackboardMode = false;
                                  _textInputMode = !_textInputMode;
                                  editingController.text = "";
                                  if (_textListBorder.any((color) => color != Colors.transparent)) {
                                    setState(() {
                                      _textListBorder.fillRange(0, _textListBorder.length, Colors.transparent);
                                    });
                                  }
                                  if (_textInputMode) {
                                    inputText();
                                  }
                                });
                              },
                              label: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/solarText.png',
                                    color: !_textInputMode ?
                                    const Color(0xFF005F6B) : Colors.white,
                                    height: MediaQuery.of(context).size.height * 0.04,
                                  ),
                                  Text('テキスト',
                                    style:  TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: !_textInputMode ?
                                      const Color(0xFF005F6B) : Colors.white,
                                    ) ,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.08,
                          width: MediaQuery.of(context).size.width * 0.2,
                          child: InkWell(
                            onLongPress: () {
                              setState(() {
                                editingController.text.isEmpty;
                              });
                            },
                            child: FloatingActionButton.extended(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              backgroundColor: _blackboardMode ?
                              const Color(0xFF005F6B) : Colors.white,
                              onPressed: () {
                                if (_blackboardMode) {
                                  setState(() {
                                    _blackboardMode = false;
                                    svgImage = '';
                                  });
                                } else {
                                  setState(() {
                                    _blackboardMode = true;
                                    _drawingMode = false;
                                    _textInputMode = false;
                                  });

                                  if (svgImage == '') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              BlackBoardList(
                                                folderPath: widget.editMap["folderPath"] ?? "",
                                                fromChecklist: false,
                                                fromDrawing: true,
                                                items_whole: widget.editMap["items_whole"] ?? [],
                                                projectId: projectId,
                                                folderPathTitle: folderPathTitle,
                                                folderId: folderId,
                                                objectsList: widget.objectsList,
                                                overViewData : widget.editMap["overViewData"] ?? [],
                                                // projectRole: widget.editMap["projectRole"] ?? "",
                                                addBlackboard: (String svgString, String comment, bool add) {
                                                  if (add) {
                                                    setState(() {
                                                      svgImage = svgString;
                                                      fileComment = comment;
                                                    });
                                                  }
                                                },
                                                onUploadComplete : (uploadFinish, uploadFolder, selectedFolder) async {},
                                                editingFiles: (String svgString, bool add, int total, int approved) {},
                                                // onUploadToChecklist:(fromAgentFolder, byteList, fileList,folderPath,fileComment,tags,fileComment_camera,tags_camera) {},
                                                settingFolderForChecklist: (newFolderPathTitle , newFolderId , newObjectList, newFolderPath) {  },
                                              )
                                      ),
                                    ).then((value) {
                                      if (svgImage == '') {
                                        setState(() {
                                          _blackboardMode = false;
                                        });
                                      }
                                    });
                                  }
                                }
                              },
                              label: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/blackboardAddToImage.png',
                                    color: !_blackboardMode ?
                                    const Color(0xFF005F6B) : Colors.white,
                                    height: MediaQuery.of(context).size.height * 0.04,
                                  ),
                                  Text('黒板追加',
                                    style:  TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: !_blackboardMode ?
                                      const Color(0xFF005F6B) : Colors.white,
                                    ) ,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.08,
                          width: MediaQuery.of(context).size.width * 0.2,
                          child: FloatingActionButton.extended(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            backgroundColor: const Color(0xFF005F6B),
                            onPressed: () {
                              if (_imageSaving) {
                                ToastPage.showToast("写真保存中です");
                              } else {
                                if (_textListBorder.any((color) => color != Colors.transparent)) {
                                  setState(() {
                                    _textListBorder.fillRange(0, _textListBorder.length, Colors.transparent);
                                  });
                                  Future.delayed(const Duration(milliseconds: 100), () {
                                    savePictureToGallery(_haveAuthority,fromList);
                                  });
                                } else {
                                  savePictureToGallery(_haveAuthority,fromList);
                                }
                              }
                            },
                            label: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _imageSaving ?
                                Image.asset(
                                  'assets/images/imageSavingIcon.png',
                                  height: MediaQuery.of(context).size.height * 0.04,
                                ) .animate().rotate(
                                  duration: GetNumUtils(5).seconds,
                                  begin: 0.0,
                                  end: 1.0,
                                ).then():
                                fromList ?
                                _haveAuthority ?
                                Image.asset(
                                  'assets/images/cloudUpload.png',
                                  color: Colors.white,
                                  height: MediaQuery.of(context).size.height * 0.04,
                                ) :
                                Image.asset(
                                  'assets/images/toDeviceIcon.png',
                                  color: Colors.white,
                                  height: MediaQuery.of(context).size.height * 0.04,
                                ) : Image.asset(
                                  'assets/images/addToListIcon.png',
                                  color: Colors.white,
                                  height: MediaQuery.of(context).size.height * 0.04,
                                ),
                                Text( _imageSaving ? '保存中' :
                                fromList ?
                                _haveAuthority ?
                                '保存' : 'デバイスに保存' : 'リストに追加',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: fromList && _haveAuthority  ? 15 : 10
                                  ) ,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  if(_drawingMode && !_textInputMode && !_blackboardMode && !isPreview)
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.05,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Stack(
                            children: [
                              _colorWidget(Colors.black),
                              if (selectColor == Colors.black && !drawingProvider.eraseMode)
                                const Positioned(
                                  bottom: 0,
                                  right: 0,
                                  top: 0,
                                  left: 0,
                                  child: Icon(
                                    Icons.check_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          Stack(
                            children: [
                              _colorWidget(Colors.red),
                              if (selectColor == Colors.red && !drawingProvider.eraseMode)
                                const Positioned(
                                  bottom: 0,
                                  right: 0,
                                  top: 0,
                                  left: 0,
                                  child: Icon(
                                    Icons.check_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          Stack(
                            children: [
                              _colorWidget(Colors.yellow),
                              if (selectColor == Colors.yellow && !drawingProvider.eraseMode)
                                const Positioned(
                                  bottom: 0,
                                  right: 0,
                                  top: 0,
                                  left: 0,
                                  child: Icon(
                                    Icons.check_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          Stack(
                            children: [
                              _colorWidget(Colors.green),
                              if (selectColor == Colors.green && !drawingProvider.eraseMode)
                                const Positioned(
                                  bottom: 0,
                                  right: 0,
                                  top: 0,
                                  left: 0,
                                  child: Icon(
                                    Icons.check_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          Stack(
                            children: [
                              _colorWidget(Colors.blue),
                              if (selectColor == Colors.blue && !drawingProvider.eraseMode)
                                const Positioned(
                                  bottom: 0,
                                  right: 0,
                                  top: 0,
                                  left: 0,
                                  child: Icon(
                                    Icons.check_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          Stack(
                            children: [
                              _colorWidget(Colors.white),
                              if (selectColor == Colors.white && !drawingProvider.eraseMode)
                                const Positioned(
                                  bottom: 0,
                                  right: 0,
                                  top: 0,
                                  left: 0,
                                  child: Icon(
                                    Icons.check_outlined,
                                    color: Colors.black,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              drawingProvider.changeEraseMode();
                            },
                            child: Image.asset(
                              drawingProvider.eraseMode ?
                              'assets/images/eraser_check.png' : 'assets/images/eraser.png',
                              height: MediaQuery.of(context).size.height * 0.05,
                            ),

                          )
                        ],
                      ),
                    ),
                  if((!_drawingMode && !_textInputMode) ||_blackboardMode || isPreview)
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.05,
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('-',
                                style:  TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF005F6B),
                                )
                            ),
                            Slider(
                              value: _blackboardMode ? _boardScale : _scale,
                              activeColor: const Color(0xFF005F6B),
                              inactiveColor: Colors.black12,
                              onChanged: (details) {

                                if (_blackboardMode) {
                                  setState(() {
                                    _boardScale = details;
                                  });
                                } else {

                                  final newScale = clampDouble(_prevScale , _minScale, _maxScale);

                                  final newOffset = _fitBoundary(
                                    targetOffset: _offset / newScale,
                                    scale: _scale,
                                    boxSize: _size,
                                  );

                                  setState(() {
                                    _scale = details;
                                    _offset = newOffset;
                                  });
                                }
                              },
                              min: _blackboardMode ? 0.5 :_minScale,
                              max: _blackboardMode ? 2.5 : _maxScale ,
                            ),
                            const Text('+',
                                style:  TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF005F6B),
                                )
                            ),
                            Text(_blackboardMode ? 'x${_boardScale.toStringAsFixed(2)}' :'x${_scale.toStringAsFixed(2)}',
                                style:  const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF005F6B),
                                )
                            )
                          ],
                        )
                    ),
                  if(!_drawingMode && _textInputMode)
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.05,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Stack(
                            children: [
                              _textColorWidget(Colors.black),
                              if (
                              _textListColor != [] &&
                                  _textListColor[_selectedTextIndex] == Colors.black
                              )
                                const Positioned(
                                  top: 0,
                                  left: 0,
                                  bottom: 0,
                                  right: 0,
                                  child: Icon(
                                    Icons.check_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          Stack(
                            children: [
                              _textColorWidget(Colors.red),
                              if (
                              _textListColor != [] &&
                                  _textListColor[_selectedTextIndex] == Colors.red)
                                const Positioned(
                                  top: 0,
                                  left: 0,
                                  bottom: 0,
                                  right: 0,
                                  child: Icon(
                                    Icons.check_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          Stack(
                            children: [
                              _textColorWidget(Colors.yellow),
                              if (
                              _textListColor != [] &&
                                  _textListColor[_selectedTextIndex] == Colors.yellow)
                                const Positioned(
                                  top: 0,
                                  left: 0,
                                  bottom: 0,
                                  right: 0,
                                  child: Icon(
                                    Icons.check_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          Stack(
                            children: [
                              _textColorWidget(Colors.green),
                              if (
                              _textListColor != [] &&
                                  _textListColor[_selectedTextIndex] == Colors.green)
                                const Positioned(
                                  top: 0,
                                  left: 0,
                                  bottom: 0,
                                  right: 0,
                                  child: Icon(
                                    Icons.check_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          Stack(
                            children: [
                              _textColorWidget(Colors.blue),
                              if (
                              _textListColor != [] &&
                                  _textListColor[_selectedTextIndex] == Colors.blue)
                                const Positioned(
                                  bottom: 0,
                                  right: 0,
                                  top: 0,
                                  left: 0,
                                  child: Icon(
                                    Icons.check_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          Stack(
                            children: [
                              _textColorWidget(Colors.white),
                              if (
                              _textListColor != [] &&
                                  _textListColor[_selectedTextIndex] == Colors.white)
                                const Positioned(
                                  bottom: 0,
                                  right: 0,
                                  top: 0,
                                  left: 0,
                                  child: Icon(
                                    Icons.check_outlined,
                                    color: Colors.black,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              setState(() {
                                if (_textListSize != [] &&
                                    _textListSize[_selectedTextIndex] > 10
                                ) {
                                  _textListSize[_selectedTextIndex] -= 5;
                                }
                              });
                            },
                            child: Center(
                              child: Image.asset(
                                'assets/images/textSmallerIcon.png',
                                height: MediaQuery.of(context).size.height * 0.03,
                              ),
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              setState(() {
                                if (_textListSize != []) {
                                  _textListSize[_selectedTextIndex] += 5;
                                }
                              });
                            },
                            child: Center(
                              child: Image.asset(
                                'assets/images/textBiggerIcon.png',
                                height: MediaQuery.of(context).size.height * 0.03,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                ],
              )
          ),
        )
    );
  }

  Widget _customText() {
    return Stack(
      children: _textList.asMap().entries.map((entry) {
        final index = entry.key;
        final text = entry.value;
        return DraggableText(
          key : ValueKey(index),
          text: text,
          index: index,
          textColor: _textListColor,
          textBorder: _textListBorder,
          textSize: _textListSize,
          selectedTextIndex: _selectedTextIndex,
          onTap: () {
            setState(() {
              _drawingMode = false;
              _textInputMode = true;
              _selectedTextIndex = index;
              editingController.text = text;
              _textListColor = _textListColor;
              _textListSize = _textListSize;
              if (_textListBorder.any((color) => color != Colors.transparent)) {
                setState(() {
                  _textListBorder.fillRange(0, _textListBorder.length, Colors.transparent);
                });
              }
              _textListBorder[index] = Colors.black;
            });
          },
          onLongPress: () {
            setState(() {
              _drawingMode = false;
              _textInputMode = true;
              _selectedTextIndex = index;
              editingController.text = text;
              _textListColor = _textListColor;
              _textListSize = _textListSize;
              if (_textListBorder.any((color) => color != Colors.transparent)) {
                setState(() {
                  _textListBorder.fillRange(0, _textListBorder.length, Colors.transparent);
                });
              }
              _textListBorder[index] = Colors.black;
              editText(text, index);
            });
          },
        );
      }).toList(),
    );
  }


  Widget _colorWidget(Color color) {
    var p = Provider.of<DrawingProvider>(context);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        p.changeColor = color;
        setState(() {
          selectColor = color;
        });
        if (p.eraseMode) {
          p.changeEraseMode();
        }
      },
      child: Stack(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: color != Colors.white ? color : Colors.black,
                width: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textColorWidget(Color color) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        setState(() {
          if (_textListColor != []) {
            _textListColor[_selectedTextIndex] = color;
          }
        });
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: color != Colors.white ? color : Colors.black,
            width: 1.0,
          ),
        ),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter{
  DrawingPainter(this.lines);
  final List<List<DotInfo>> lines;

  @override
  void paint(Canvas canvas, Size size) {
    for(var oneLine in lines){
      Color? color;
      double? size;
      var l = <Offset>[];
      var p = Path();
      for(var oneDot in oneLine){
        color ??= oneDot.color;
        size ??= oneDot.size;
        l.add(oneDot.offset);
      }
      p.addPolygon(l, false);
      canvas.drawPath(p, Paint()
        ..color = color!
        ..strokeWidth=size!
        ..strokeCap=StrokeCap.round
        ..style=PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return true;
  }

}

class DraggableText extends StatefulWidget {
  final String text;
  final int index;
  final int selectedTextIndex;
  final List<Color> textColor;
  final List<Color> textBorder;
  final List<double> textSize;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const DraggableText({
    Key? key,
    required this.text,
    required this.index,
    required this.selectedTextIndex,
    required this.textColor,
    required this.textBorder,
    required this.textSize,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  DraggableTextState createState() => DraggableTextState();
}

class DraggableTextState extends State<DraggableText> {
  Offset position = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onPanUpdate: (details) {
          setState(() {
            position += details.delta;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.textBorder[widget.index],
              width: 1.0,
              style: BorderStyle.solid,
            ),
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              color: widget.textColor[widget.index],
              fontSize: widget.textSize[widget.index],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}