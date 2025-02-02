import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:object_project/LodingPage.dart';
import 'package:object_project/Pictures/commentClass.dart';
import 'package:object_project/ToastPage.dart';
import '../Pictures/ImagePicker.dart';
import 'dart:ui' as ui;


class CameraWithBlackBoard extends StatefulWidget {
  final List<dynamic> items_whole;
  final String projectId;
  final String folderPathTitle;
  final String folderPath;

  final String folderId;
  final List<dynamic> objectsList;

  final String svgImageUrl;
  final List<Uint8List> imagesByte;
  final List<File> imagesFile;
  final bool fromChecklist;
  final List<String>takePictureTime;
  String commentFromBlackboard;
  final List<dynamic> overViewData;

  late Function(bool,List<dynamic>,List<dynamic>) onUploadComplete;
  late Function(String, bool,int, int) editingFiles;
  // late Function(bool, List<Uint8List>, List<File>,String,List<String>,List<List>) onUploadToChecklist;
  late Function(String, String, List<dynamic>, String) settingFolderForChecklist;

  CameraWithBlackBoard({
    required this.items_whole,
    required this.projectId,
    required this.folderPathTitle,
    required this.folderId,
    required this.objectsList,
    required this.onUploadComplete,
    required this.svgImageUrl,
    required this.editingFiles,
    required this.imagesByte,
    required this.imagesFile,
    required this.fromChecklist,
    // required this.onUploadToChecklist,
    required this.takePictureTime,
    required this.commentFromBlackboard,
    required this.settingFolderForChecklist,
    required this.folderPath,
    required this.overViewData
  });

  @override
  CameraWithBlackBoardState createState() => CameraWithBlackBoardState();
}

class CameraWithBlackBoardState extends State<CameraWithBlackBoard> {
  late CameraController _cameraController;
  var logger = Logger();

  List<Uint8List> imagesByte = [];
  bool isFrontCamera = false;
  double _zoomLevel = 1.0;
  late double boardRatio;

  double boardSizeControlValue = 2.5;
  double boardSizeControl = 2.5;
  Offset blackBoardLocation = Offset.zero;

  int cameraQualityOrder = 0;
  List<String> cameraQualityList = ['HD','FHD','4K'];
  double cameraQualityValue = 1;

  late FlashMode _currentFlashMode;
  int _flashMode = 1; //off,auto,always,torch
  List<String> pictureNames = [];
  List<String> takePictureTime = [];

  double boardUiWidth = 800;
  double boardUiHeight = 600;


  late bool isPortrait;
  late String folderPathTitle = widget.folderPathTitle;

  late List<dynamic> items_whole = widget.items_whole;

  late double CameraControllerSize;

  late int pictureSizeHeight;
  late int pictureSizeWidth;

  late String projectId = widget.projectId;
  List<String> base64Images = [];

  late String folderId;
  late List<dynamic> objectsList;

  late String svgImageUrl;
  final GlobalKey globalKey_takePicture = GlobalKey();
  final currentTime = DateTime.now().millisecondsSinceEpoch;

  bool takePictureLoading = false;

  bool isLoading = true;
  List<File> imagesFile = [];

  double imageRatio = 1;
  bool OrientationPortrait = true;
  DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm');

  static const _minScale = 1.0;
  static const _maxScale = 5.0;
  var _prevScale= _minScale;
  String _currentCameraName = 'com.apple.avfoundation.avcapturedevice.built-in_video:0';
  bool _haveUltraWide = false;

  @override
  void initState(){
    super.initState();
    setState(() {
      _initializeCamera(false, 0);
      folderId = widget.folderId;
      objectsList = widget.objectsList;

      svgImageUrl = widget.svgImageUrl;

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
  }

  void showPictureList() {

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
            fromChecklist: widget.fromChecklist,
            reportImagesList : imagesFile,
            takePictureTime: takePictureTime,
            onUploadComplete : (uploadFinish,uploadFolder,selectedFolder) {
              widget.onUploadComplete(uploadFinish,uploadFolder,selectedFolder);
            },
            onEditImagesByte : (editImagesByte,editImagesFile) {
              setState(() {
                imagesByte = editImagesByte;
                imagesFile = editImagesFile;
              });


            },
            onUpdateReport: (List<File> updateFile,
                uploadFolderId, uploadFolderPath,uploadFolderName) {  },
            imagesByte: imagesByte,
            editingFiles: (String editText, bool add, int total, int approved) {
              widget.editingFiles(editText,add,total,approved);
            },
            // onUploadToChecklist: (fromAgentFolder, byteList, fileList,folderPath,fileComment,tags) {
            //   widget.onUploadToChecklist(fromAgentFolder, byteList, fileList,folderPath,fileComment,tags);
            // },
            settingFolderForChecklist: (newFolderPathTitle , newFolderId , newObjectList, newFolderPath ) {
              widget.settingFolderForChecklist(newFolderPathTitle , newFolderId , newObjectList, newFolderPath);
            },
          )
      ),
    );
  }

  Future<CameraDescription> getFrontCamera() async {
    final cameras = await availableCameras();
    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        return camera;
      }
    }
    return cameras.first;
  }

  Future<CameraDescription> getBackCamera(String currentCameraName) async {
    final cameras = await availableCameras();

    if (cameras.length > 2 && !_haveUltraWide) {
      setState(() {
        _haveUltraWide = true;
      });
    }

    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.back
      && camera.name == currentCameraName) {
        return camera;
      }
    }
    return cameras.first;
  }


  void takePictureAndCrop(CameraController controller) async {
    if (imagesByte.length >= 20) {
      ToastPage.showToast('送信可能な写真枚を超えました');
    } else {
      setState(() {
        takePictureLoading = true;
      });

      final XFile takePicture = await controller.takePicture();
      final imageByte = await takePicture.readAsBytes();

      _cameraController.setZoomLevel(_zoomLevel);
      final originalImage = img.decodeImage(imageByte);
      if (originalImage == null) {
        throw Exception("Failed to decode image");
      }

      final cropHeight = (originalImage.width * 4 / 3).toInt();
      final startY = ((originalImage.height - cropHeight) / 2).toInt();
      final croppedImage_vertical = img.copyCrop(originalImage, x :0, y:startY, width : originalImage.width, height: cropHeight);

      final cropWidth = (originalImage.height * 4 / 3).toInt();
      final startX = ((originalImage.width - cropWidth) / 2).toInt();
      final croppedImage = img.copyCrop(originalImage, x :startX, y:0, width : cropWidth, height: originalImage.height);

      Uint8List imageJpeg;

      if(isPortrait) {
        imageJpeg = Uint8List.fromList(img.encodeJpg(croppedImage_vertical));
      } else {
        imageJpeg = Uint8List.fromList(img.encodeJpg(croppedImage));
      }

      if (svgImageUrl != "") {

        if (isPortrait) {
          setState((){
            boardRatio = CameraControllerSize/MediaQuery.of(context).size.width;
          });
        }
        else {
          setState((){
            boardRatio = CameraControllerSize/MediaQuery.of(context).size.height;
          });
        }

        var takePictureUiImage = await decodeImageFromList(imageJpeg);

        final pictureInfo = await vg.loadPicture(SvgStringLoader(svgImageUrl),null);
        final blackboardUiImage = await pictureInfo.picture.toImage(
            pictureSizeWidth,
            pictureSizeHeight
        );

        var resizedBoardUiImage = await resizeImageWithBlackboard(blackboardUiImage,
            ((boardUiWidth * 1.2) / boardSizeControl )* boardRatio * cameraQualityValue,
            ((boardUiHeight * 1.2)/ boardSizeControl ) * boardRatio * cameraQualityValue
        );

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        Paint paint = Paint()
          ..filterQuality = FilterQuality.high;

        if ( isFrontCamera != false ) {
          canvas.scale(-1, 1);
          canvas.drawImage(takePictureUiImage, Offset(-takePictureUiImage.width.toDouble(), 0), paint);
          canvas.scale(-1, 1);
          if ( isPortrait) {
            canvas.drawImage(resizedBoardUiImage, Offset(
                blackBoardLocation.dx, blackBoardLocation.dy)
                * boardRatio, paint);
          } else {
            canvas.drawImage(resizedBoardUiImage, Offset(
                blackBoardLocation.dx, blackBoardLocation.dy)
                * boardRatio, paint);
          }

        } else {
          canvas.drawImage(takePictureUiImage, Offset.zero, paint);
          if ( isPortrait) {
            canvas.drawImage(resizedBoardUiImage, Offset(
                blackBoardLocation.dx, blackBoardLocation.dy)
                * boardRatio, paint);
          } else {
            canvas.drawImage(resizedBoardUiImage, Offset(
                blackBoardLocation.dx, blackBoardLocation.dy)
                * boardRatio, paint);
          }

        }

        final picture = recorder.endRecording();
        var mergedImage = await picture.toImage(pictureSizeWidth, pictureSizeHeight);
        if ( isPortrait) {
          mergedImage = await picture.toImage(pictureSizeHeight,pictureSizeWidth);
        }
        var mergedBytes = await mergedImage.toByteData(format: ui.ImageByteFormat.png);
        var mergedImageBytes = mergedBytes?.buffer.asUint8List();

        if (mergedImageBytes != null) {

          img.Image? pngImage = img.decodeImage(mergedImageBytes);
          var jpegBytes = img.encodeJpg(pngImage!, quality: 100);


          setState(() {
            takePictureLoading = false;
            imagesByte.add(jpegBytes);
            takePictureTime.add(formatter.format(DateTime.now()));
            pictureNames.add('merged_$currentTime.jpeg');
          });

          savePictureToGallery(jpegBytes);
        } else {
          setState(() {
            takePictureLoading = false;
          });
          ToastPage.showToast('画像合成中にエラーが発生しました');
        }

      } else {

        setState(() {
          takePictureLoading = false;
          imagesByte.add(imageJpeg);
          takePictureTime.add(DateTime.now().toString());
          pictureNames.add('picture_$currentTime.jpeg');
        });

        savePictureToGallery(imageJpeg);
      }
    }
  }

  Future<Uint8List> resizeImage(Uint8List imageBytes, int targetWidth, int targetHeight) async {
    img.Image image = img.decodeImage(imageBytes)!;
    img.Image resizedImage = img.copyResize(
        image, width: targetWidth, height: targetHeight,
        interpolation:  img.Interpolation.linear
    );
    return Uint8List.fromList(img.encodePng(resizedImage));
  }

  Future<ui.Image> resizeImageWithBlackboard(ui.Image image, double width, double height) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    double imageWidth = image.width.toDouble();
    double imageHeight = image.height.toDouble();
    canvas.drawImageRect(
        image,
        Rect.fromLTRB(0, 0, imageWidth, imageHeight),
        Rect.fromLTRB(0, 0, width, height),
        Paint()
    );

    final picture = pictureRecorder.endRecording();
    return picture.toImage(width.toInt() , height.toInt(),);
  }

  void _initializeCamera( bool isFrontCamera, int cameraQualityOrder) async {
    final frontCamera = await getFrontCamera();
    var wideCamera = await getBackCamera(_currentCameraName);

    if ( !isFrontCamera ) {
      switch(cameraQualityOrder) {
        case 0 :
          setState(() {
            cameraQualityValue = 1;
          });
          _cameraController = CameraController(
            wideCamera,
            ResolutionPreset.high,
            enableAudio: false,
            imageFormatGroup: ImageFormatGroup.jpeg,
          );

        case 1 :
          setState(() {
            cameraQualityValue = 1.5;
          });
          _cameraController = CameraController(
            wideCamera,
            ResolutionPreset.veryHigh,
            enableAudio: false,
            imageFormatGroup: ImageFormatGroup.jpeg,
          );

        case 2 :
          setState(() {
            cameraQualityValue = 3;
          });
          _cameraController = CameraController(
            wideCamera,
            ResolutionPreset.ultraHigh,
            enableAudio: false,
            imageFormatGroup: ImageFormatGroup.jpeg,
          );

      }
    } else {
      switch(cameraQualityOrder) {
        case 0 :
          setState(() {
            cameraQualityValue = 1;
          });
          _cameraController = CameraController(
            frontCamera,
            ResolutionPreset.high,
            enableAudio: false,
            imageFormatGroup: ImageFormatGroup.jpeg,
          );
        case 1 :
          setState(() {
            cameraQualityValue = 1.5;
          });
          _cameraController = CameraController(
            frontCamera,
            ResolutionPreset.veryHigh,
            enableAudio: false,
            imageFormatGroup: ImageFormatGroup.jpeg,
          );
        case 2 :
          setState(() {
            cameraQualityValue = 3;
          });
          _cameraController = CameraController(
            frontCamera,
            ResolutionPreset.ultraHigh,
            enableAudio: false,
            imageFormatGroup: ImageFormatGroup.jpeg,
          );
      }
    }

    try {
      await _cameraController.initialize();

      setState(() async {
        pictureSizeWidth = (( (_cameraController.value.previewSize!.height/3) * 4)).toInt();
        pictureSizeHeight = _cameraController.value.previewSize!.height.toInt();
        CameraControllerSize = _cameraController.value.previewSize!.height;
      });
    } on CameraException catch (e) {
      logger.e("error: $e");
    }


    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _cameraController.dispose();
  }

  void savePictureToGallery(Uint8List picture) async {
    await ImageGallerySaver.saveImage(
      Uint8List.fromList(picture),
      quality: 100 ,
      isReturnImagePathOfIOS: true,
    );

    commentClass().addComment(widget.commentFromBlackboard);

    // if (widget.fromChecklist && widget.projectId == "") {
    //   widget.onUploadToChecklist(false,[picture],[],"",[],[]);
    //   Navigator.pop(context);
    // }
  }

  @override
  Widget build(BuildContext context) {

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _currentFlashMode = _cameraController.value.flashMode;

    return isLoading ? LoadingPage(loadingMessage: "カメラ準備中...") :
    OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {

          if (!takePictureLoading) {
            isPortrait = orientation == Orientation.portrait;

            if (isPortrait) {
              imageRatio = MediaQuery.of(context).size.height/MediaQuery.of(context).size.width;
              boardUiHeight = MediaQuery.of(context).size.height * (3/16) * 2.45;
              boardUiWidth = MediaQuery.of(context).size.width * (4/3);

              if(OrientationPortrait) {
                double dyMaxLocation_init = MediaQuery.of(context).size.width * (4/3)
                    - (boardUiHeight/boardSizeControl);

                blackBoardLocation = Offset(0, dyMaxLocation_init);
                OrientationPortrait = false;
              }


            } else {
              imageRatio = MediaQuery.of(context).size.width/MediaQuery.of(context).size.height;
              boardUiHeight = MediaQuery.of(context).size.width * (3/16) * 2.45;
              boardUiWidth = MediaQuery.of(context).size.height * (4/3);

              if (!OrientationPortrait) {
                double dyMaxLocation_init = MediaQuery.of(context).size.height
                    - (boardUiHeight/boardSizeControl);

                blackBoardLocation = Offset(0,  dyMaxLocation_init);
                OrientationPortrait = true;
              }
            }
          }

          return PopScope(
              canPop: false,
              child: Scaffold(
                  body: takePictureLoading ?
                  Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                          const Text(
                            "写真処理中...",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      ),
                    ),
                  ) :
                  isPortrait ?
                  Container(
                    color: Colors.black,
                    child: Stack(
                      children: [
                        GestureDetector(
                          child:
                          Center(
                            child : Stack(
                              alignment: Alignment.center,
                              children: [
                                if(_cameraController.value.isInitialized)
                                  CameraPreview(_cameraController),
                                Center(
                                  child: AspectRatio(
                                    aspectRatio: 3 / 4,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (svgImageUrl != '')
                                  Positioned (
                                    width: boardUiWidth / boardSizeControl,
                                    height: boardUiHeight / boardSizeControl,
                                    top: blackBoardLocation.dy
                                        + ((MediaQuery.of(context).size.height -
                                            (MediaQuery.of(context).size.width * (4/3)))/2),
                                    left: blackBoardLocation.dx,
                                    child: GestureDetector(
                                      onPanUpdate: (details) {
                                        setState(() {
                                          final newLocation = blackBoardLocation + details.delta;

                                          final dxMaxLocation = MediaQuery.of(context).size.width
                                              - (boardUiWidth/boardSizeControl);

                                          final dyMaxLocation = MediaQuery.of(context).size.width * (4/3)
                                              - (boardUiHeight/boardSizeControl);

                                          if ( 0 <= newLocation.dx &&
                                              dxMaxLocation >= newLocation.dx &&
                                              0 <= newLocation.dy &&
                                              dyMaxLocation >= newLocation.dy
                                          ) {
                                            blackBoardLocation = newLocation;
                                          }
                                        });
                                      },

                                      child: AspectRatio(
                                        aspectRatio: boardUiWidth/boardUiHeight,
                                        child: SvgPicture.string(
                                          svgImageUrl,
                                          fit: BoxFit.contain,
                                          alignment: Alignment.center,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          onDoubleTap: () {
                            setState(() {
                              if (_zoomLevel > 4.4) {
                                _zoomLevel = 1.0;
                                _cameraController.setZoomLevel(_zoomLevel);
                              } else {
                                if (_haveUltraWide && _zoomLevel > 1.4 &&
                                    _currentCameraName == 'com.apple.avfoundation.avcapturedevice.built-in_video:5') {
                                  _zoomLevel = 1.0;
                                  _currentCameraName = 'com.apple.avfoundation.avcapturedevice.built-in_video:0';
                                  _initializeCamera(isFrontCamera, cameraQualityOrder);
                                } else {
                                  _zoomLevel += 0.5;
                                }
                                _cameraController.setZoomLevel(_zoomLevel);
                              }
                            });
                          },
                          onScaleStart: (details) {
                            setState(() {
                              _prevScale = _zoomLevel;
                            });
                          },
                          onScaleUpdate: (ScaleUpdateDetails details) {

                            final newScale = clampDouble(
                                _prevScale * details.scale,
                                _minScale, _maxScale
                            );

                            setState(() {
                              if(!_haveUltraWide ||
                                  _currentCameraName == 'com.apple.avfoundation.avcapturedevice.built-in_video:0' ||
                                  newScale < 1.99
                              ) {
                                _zoomLevel = newScale;
                              }
                            });
                            _cameraController.setZoomLevel(_zoomLevel);
                          },
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black,
                            padding: const EdgeInsets.only(bottom: 12),
                            height: (MediaQuery.of(context).size.height - (MediaQuery.of(context).size.width * (4/3)))/2,
                            child:  Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: <Widget>[
                                    IconButton(
                                      onPressed: () {
                                        if (imagesByte.toString() != "[]" && widget.svgImageUrl == "") {
                                          showDialog (
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                  'クラウドに保存されていない写真があります。戻りますか？',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF005F6B))
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
                                          Navigator.pop(context, {
                                            'imagesFile': imagesFile,
                                            'imagesByte': imagesByte,
                                            'takePictureTime' : takePictureTime,
                                          });
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.arrow_back_ios_outlined,
                                        color: Colors.white,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        setState(() async {
                                          if (_flashMode < 3) {
                                            _flashMode++;
                                          } else {
                                            _flashMode = 0;
                                          }

                                          switch(_flashMode) {
                                            case 0 :
                                              _currentFlashMode = FlashMode.off;
                                              await _cameraController.setFlashMode(
                                                FlashMode.off,
                                              );
                                            case 1 :
                                              _currentFlashMode = FlashMode.auto;
                                              await _cameraController.setFlashMode(
                                                FlashMode.auto,
                                              );
                                            case 2 :
                                              _currentFlashMode = FlashMode.always;
                                              await _cameraController.setFlashMode(
                                                FlashMode.always,
                                              );
                                            default :
                                              _currentFlashMode = FlashMode.torch;
                                              await _cameraController.setFlashMode(
                                                FlashMode.torch,
                                              );
                                          }
                                        });

                                      },
                                      child: Icon(
                                        _flashMode == 0 ?
                                        Icons.flash_off_outlined :
                                        _flashMode == 1 ?
                                        Icons.flash_auto_outlined :
                                        _flashMode == 2 ?
                                        Icons.flash_on_outlined :
                                        Icons.highlight_outlined,
                                        color:  Colors.white,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _zoomLevel = 1.0;
                                          if (_haveUltraWide && !isFrontCamera) {
                                            _currentCameraName = _currentCameraName ==
                                                'com.apple.avfoundation.avcapturedevice.built-in_video:0'
                                                ? 'com.apple.avfoundation.avcapturedevice.built-in_video:5'
                                                : 'com.apple.avfoundation.avcapturedevice.built-in_video:0';
                                            _initializeCamera(isFrontCamera, cameraQualityOrder);
                                          }
                                        });
                                      },
                                      child: Text(
                                        _haveUltraWide && _currentCameraName ==
                                            'com.apple.avfoundation.avcapturedevice.built-in_video:5' ?
                                        '${(_zoomLevel/2).toDouble().toStringAsFixed(1)}x' :
                                        '${_zoomLevel.toDouble().toStringAsFixed(1)}x',
                                        style: TextStyle(
                                          color: _zoomLevel > 1.0 ?
                                          Colors.yellowAccent :
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (widget.svgImageUrl != '')
                                      IconButton(
                                        onPressed: () {
                                         {
                                           setState(() {
                                             if (svgImageUrl == '') {
                                               svgImageUrl = widget.svgImageUrl;
                                             } else {
                                               svgImageUrl = '';
                                             }
                                           });
                                          }
                                        },
                                        icon:
                                        Container(
                                          color: Colors.transparent,
                                          child: Icon(
                                          svgImageUrl == '' ?
                                          Icons.photo_camera_back :
                                          Icons.photo_camera_outlined,
                                          size: 30,
                                          color: Colors.white,
                                          )
                                        )
                                      ),
                                    TextButton(
                                      child: Text(
                                        cameraQualityList[cameraQualityOrder],
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() async {
                                          switch(cameraQualityOrder) {
                                            case 0 :
                                              cameraQualityOrder ++;
                                            case 1 :
                                              cameraQualityOrder ++;
                                            case 2 :
                                              cameraQualityOrder = 0;
                                          }
                                          _initializeCamera(isFrontCamera, cameraQualityOrder);

                                          _flashMode = 0;
                                          _currentFlashMode = FlashMode.off;
                                          await _cameraController.setFlashMode(
                                            FlashMode.off,
                                          );
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            )
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black,
                            height: (MediaQuery.of(context).size.height - (MediaQuery.of(context).size.width * (4/3)))/2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.7,
                                  height: (MediaQuery.of(context).size.height * 0.02) * imageRatio,
                                  child: RotatedBox(
                                    quarterTurns: 0,
                                    child: svgImageUrl != '' ? Slider(
                                      value: boardSizeControlValue,
                                      min: 1.5,
                                      max: 3.5,
                                      activeColor: Colors.white,
                                      inactiveColor: Colors.white30,
                                      onChanged: (value) async {
                                        setState(() {
                                          boardSizeControlValue = value;
                                          boardSizeControl = 5.0 - value;

                                          final maxX = MediaQuery.of(context).size.width;
                                          final maxY =  MediaQuery.of(context).size.width * (4/3);

                                          final scale = 1 / boardSizeControl;
                                          final rightX = blackBoardLocation.dx + boardUiWidth * scale;
                                          final bottomY = blackBoardLocation.dy + boardUiHeight * scale;

                                          final overflowX = rightX - maxX;
                                          final overflowY = bottomY - maxY;

                                          blackBoardLocation -= Offset(
                                              overflowX > 0 ? overflowX : 0,
                                              overflowY > 0 ? overflowY : 0
                                          );

                                          blackBoardLocation == Offset(
                                            !isPortrait ? blackBoardLocation.dx : 0,
                                            !isPortrait ? blackBoardLocation.dy : 0,
                                          );
                                        });
                                      },
                                    ) : Text(""),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                        icon: Icon(
                                          Icons.flip_camera_android_outlined,
                                          color: Colors.white,
                                          size: (MediaQuery.of(context).size.height * 0.025) * imageRatio,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _zoomLevel = 1.0;
                                            _currentCameraName = 'com.apple.avfoundation.avcapturedevice.built-in_video:0';
                                            isFrontCamera = !isFrontCamera;
                                            _initializeCamera(isFrontCamera, cameraQualityOrder);
                                          });
                                        }
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        if (takePictureLoading) {
                                          ToastPage.showToast('撮影した写真を処理中です');
                                        } else {
                                          takePictureAndCrop(_cameraController);
                                        }
                                      },
                                      child: Icon(
                                        Icons.camera_outlined,
                                        color: Colors.white,
                                        size: (MediaQuery.of(context).size.height * 0.04) * imageRatio,
                                      ),
                                    ),

                                    if (widget.projectId == "" && widget.folderPathTitle == "")
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child : SizedBox(
                                          width: MediaQuery.of(context).size.width * 0.1
                                        ),
                                      ),
                                    if (widget.projectId != "" && widget.folderPathTitle != "")
                                      TextButton(
                                        onPressed:
                                        imagesByte.isNotEmpty && !takePictureLoading ?showPictureList : null,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Container(
                                              padding: const EdgeInsets.all(8.0),
                                              decoration: const BoxDecoration(
                                                color: Colors.blue,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '${imagesByte.length + imagesFile.length}',
                                                style: TextStyle(
                                                  fontSize: (MediaQuery.of(context).size.height * 0.01) * imageRatio,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Text('次へ',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                  fontSize: (MediaQuery.of(context).size.height * 0.01) * imageRatio,
                                                )
                                            )
                                          ],
                                        ),
                                      ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ) :
                  Container(
                    color: Colors.black,
                    child: Stack(
                      children: [
                        GestureDetector(
                          child: Center(
                              child : Stack(
                                alignment: Alignment.center,
                                children: [
                                  if(_cameraController.value.isInitialized)
                                    CameraPreview(_cameraController),
                                  Center(
                                    child: AspectRatio(
                                      aspectRatio: 4 / 3,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (svgImageUrl != '')
                                    Positioned (
                                      width: boardUiWidth / boardSizeControl,
                                      height: boardUiHeight / boardSizeControl,
                                      top: blackBoardLocation.dy,
                                      left: blackBoardLocation.dx + (MediaQuery.of(context).size.width - (MediaQuery.of(context).size.height * (4/3)))/2,
                                      child: GestureDetector(
                                        onPanUpdate: (details) {
                                          setState(() {
                                            final newLocation = blackBoardLocation + details.delta;

                                            final dyMaxLocation = MediaQuery.of(context).size.height
                                                - (boardUiHeight/boardSizeControl);
                                            final dxMaxLocation = MediaQuery.of(context).size.height * (4/3)
                                                - (boardUiWidth/boardSizeControl);

                                            if ( 0 <= newLocation.dx &&
                                                dxMaxLocation >= newLocation.dx &&
                                                0 <= newLocation.dy &&
                                                dyMaxLocation >= newLocation.dy
                                            ) {
                                              blackBoardLocation = newLocation;
                                            }
                                          });
                                        },
                                        child: AspectRatio(
                                          aspectRatio: boardUiWidth/boardUiHeight,
                                          child: SvgPicture.string(
                                            svgImageUrl,
                                            fit: BoxFit.contain,
                                            alignment: Alignment.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                          ),
                          onDoubleTap: () {
                            setState(() {
                              if (_zoomLevel > 4.4) {
                                _zoomLevel = 1.0;
                                _cameraController.setZoomLevel(_zoomLevel);
                              } else {
                                if (_haveUltraWide && _zoomLevel > 1.4 &&
                                    _currentCameraName == 'com.apple.avfoundation.avcapturedevice.built-in_video:5') {
                                  _zoomLevel = 1.0;
                                  _currentCameraName = 'com.apple.avfoundation.avcapturedevice.built-in_video:0';
                                  _initializeCamera(isFrontCamera, cameraQualityOrder);
                                } else {
                                  _zoomLevel += 0.5;
                                }
                                _cameraController.setZoomLevel(_zoomLevel);
                              }
                            });
                          },
                          onScaleStart: (details) {
                            setState(() {
                              _prevScale = _zoomLevel;
                            });
                          },
                          onScaleUpdate: (ScaleUpdateDetails details) {

                            final newScale = clampDouble(
                                _prevScale * details.scale,
                                _minScale, _maxScale
                            );

                            setState(() {
                              if(!_haveUltraWide ||
                                _currentCameraName == 'com.apple.avfoundation.avcapturedevice.built-in_video:0' ||
                                newScale < 1.99
                              ) {
                                _zoomLevel = newScale;
                              }
                            });
                            _cameraController.setZoomLevel(_zoomLevel);
                          },
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                              color: Colors.black,
                              padding: const EdgeInsets.only(right: 12),
                              width: (MediaQuery.of(context).size.width - (MediaQuery.of(context).size.height * (4/3)))/2,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: <Widget>[
                                      IconButton(
                                        onPressed: () {
                                          if (imagesByte.toString() != "[]" && widget.svgImageUrl == "") {
                                            showDialog (
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text(
                                                    'クラウドに保存されていない写真があります。戻りますか？',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF005F6B))
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
                                            Navigator.pop(context, {
                                              'imagesFile': imagesFile,
                                              'imagesByte': imagesByte,
                                              'takePictureTime' : takePictureTime,
                                            });
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.arrow_back_ios_outlined,
                                          color: Colors.white,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () async {
                                          setState(() async {
                                            if (_flashMode < 3) {
                                              _flashMode++;
                                            } else {
                                              _flashMode = 0;
                                            }

                                            switch(_flashMode) {
                                              case 0 :
                                                _currentFlashMode = FlashMode.off;
                                                await _cameraController.setFlashMode(
                                                  FlashMode.off,
                                                );
                                              case 1 :
                                                _currentFlashMode = FlashMode.auto;
                                                await _cameraController.setFlashMode(
                                                  FlashMode.auto,
                                                );
                                              case 2 :
                                                _currentFlashMode = FlashMode.always;
                                                await _cameraController.setFlashMode(
                                                  FlashMode.always,
                                                );
                                              default :
                                                _currentFlashMode = FlashMode.torch;
                                                await _cameraController.setFlashMode(
                                                  FlashMode.torch,
                                                );
                                            }
                                          });

                                        },
                                        child: Icon(
                                          _flashMode == 0 ?
                                          Icons.flash_off_outlined :
                                          _flashMode == 1 ?
                                          Icons.flash_auto_outlined :
                                          _flashMode == 2 ?
                                          Icons.flash_on_outlined :
                                          Icons.highlight_outlined,
                                          color:  Colors.white,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _zoomLevel = 1.0;
                                            if (_haveUltraWide && !isFrontCamera) {
                                              _currentCameraName = _currentCameraName ==
                                                  'com.apple.avfoundation.avcapturedevice.built-in_video:0'
                                                  ? 'com.apple.avfoundation.avcapturedevice.built-in_video:5'
                                                  : 'com.apple.avfoundation.avcapturedevice.built-in_video:0';
                                              _initializeCamera(isFrontCamera, cameraQualityOrder);
                                            }
                                          });
                                        },
                                        child: Text(
                                          _haveUltraWide && _currentCameraName ==
                                              'com.apple.avfoundation.avcapturedevice.built-in_video:5' ?
                                          '${(_zoomLevel/2).toDouble().toStringAsFixed(1)}x' :
                                          '${_zoomLevel.toDouble().toStringAsFixed(1)}x',
                                          style: TextStyle(
                                            color: _zoomLevel > 1.0 ?
                                            Colors.yellowAccent :
                                            Colors.white,
                                          ),
                                        ),
                                      ),
                                      if (widget.svgImageUrl != '')
                                        IconButton(
                                            onPressed: () {
                                              {
                                                setState(() {
                                                  if (svgImageUrl == '') {
                                                    svgImageUrl = widget.svgImageUrl;
                                                  } else {
                                                    svgImageUrl = '';
                                                  }
                                                });
                                              }
                                            },
                                            icon:
                                            Container(
                                              color: Colors.transparent,
                                              child: Icon(
                                                svgImageUrl == '' ?
                                                Icons.photo_camera_back :
                                                Icons.photo_camera_outlined,
                                                size: 30,
                                                color: Colors.white,
                                              ),
                                            )
                                        ),
                                      TextButton(
                                        child: Text(
                                          cameraQualityList[cameraQualityOrder],
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                        onPressed: () {
                                          setState(() async {
                                            switch(cameraQualityOrder) {
                                              case 0 :
                                                cameraQualityOrder ++;
                                              case 1 :
                                                cameraQualityOrder ++;
                                              case 2 :
                                                cameraQualityOrder = 0;
                                            }
                                            _initializeCamera(isFrontCamera, cameraQualityOrder);

                                            _flashMode = 0;
                                            _currentFlashMode = FlashMode.off;
                                            await _cameraController.setFlashMode(
                                              FlashMode.off,
                                            );
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              )
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            color: Colors.black,
                            width: (MediaQuery.of(context).size.width - (MediaQuery.of(context).size.height * (4/3)))/2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.7,
                                  width: (MediaQuery.of(context).size.width * 0.02) * imageRatio,
                                  child: RotatedBox(
                                      quarterTurns: -1,
                                      child: svgImageUrl != '' ? Slider(
                                        value: boardSizeControlValue,
                                        min: 1.5,
                                        max: 3.5,
                                        activeColor: Colors.white,
                                        inactiveColor: Colors.white30,
                                        onChanged: (value) async {
                                          setState(() {
                                            boardSizeControlValue = value;
                                            boardSizeControl = 5.0 - value;

                                            final maxX = MediaQuery.of(context).size.height * (4/3);
                                            final maxY = MediaQuery.of(context).size.height;

                                            final scale = 1 / boardSizeControl;
                                            final rightX = blackBoardLocation.dx + boardUiWidth * scale;
                                            final bottomY = blackBoardLocation.dy + boardUiHeight * scale;

                                            final overflowX = rightX - maxX;
                                            final overflowY = bottomY - maxY;

                                            blackBoardLocation -= Offset(
                                                overflowX > 0 ? overflowX : 0,
                                                overflowY > 0 ? overflowY : 0
                                            );
                                          });
                                        },
                                      ) : const Text("")
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                        icon: Icon(
                                          Icons.flip_camera_android_outlined,
                                          color: Colors.white,
                                          size: (MediaQuery.of(context).size.width * 0.025) * imageRatio,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _zoomLevel = 1.0;
                                            _currentCameraName = 'com.apple.avfoundation.avcapturedevice.built-in_video:0';
                                            isFrontCamera = !isFrontCamera;
                                            _initializeCamera(isFrontCamera, cameraQualityOrder);
                                          });
                                        }
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        if (takePictureLoading) {
                                          ToastPage.showToast('撮影した写真を処理中です');
                                        } else {
                                          takePictureAndCrop(_cameraController);
                                        }
                                      },
                                      child: Icon(
                                        Icons.camera_outlined,
                                        color: Colors.white,
                                        size: (MediaQuery.of(context).size.width * 0.04) * imageRatio,
                                      ),
                                    ),
                                    if (widget.projectId == "" && widget.folderPathTitle == "")
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child : SizedBox(
                                            height: MediaQuery.of(context).size.height * 0.1
                                        ),
                                      ),
                                    if (widget.projectId != "" && widget.folderPathTitle != "")
                                      TextButton(
                                        onPressed: imagesByte.isNotEmpty && !takePictureLoading ? showPictureList : null,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Container(
                                              padding: const EdgeInsets.all(8.0),
                                              decoration: const BoxDecoration(
                                                color: Colors.blue,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '${imagesByte.length + imagesFile.length}',
                                                style: TextStyle(
                                                  fontSize: (MediaQuery.of(context).size.width * 0.01) * imageRatio,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Text('次へ',
                                              style: TextStyle(
                                                color: Colors.white,
                                              fontSize: (MediaQuery.of(context).size.width * 0.01) * imageRatio
                                              )
                                            )
                                          ],
                                        ),
                                      ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
              )
          );
        }
    );
  }
}


