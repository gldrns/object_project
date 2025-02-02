import 'package:flutter/material.dart';
import '../Pictures/PictureItemScreen.dart';

class AgendaPictures extends StatefulWidget {
  final Map<String, dynamic> inventoryData;
  final String projectId;
  late Function(bool) resetEditList;
  late Function(String,bool,int,int) editingFiles;
  late Function(bool) reload;
  final String fromNotification_folderId;
  final List<dynamic> fromNotification_itemId;

  AgendaPictures({
    required this.inventoryData,
    required this.projectId,
    required this.resetEditList,
    required this.editingFiles,
    required this.reload,
    required this.fromNotification_folderId,
    required this.fromNotification_itemId
  });

  @override
  AgendaPicturesState createState() => AgendaPicturesState();
}

class AgendaPicturesState extends State<AgendaPictures> {
  late Map<String, dynamic> inventoryData = widget.inventoryData;
  late String projectId = widget.projectId;

  late Map<String, dynamic> pictureFolderData;
  late List<dynamic> overViewData;

  @override
  void initState() {
    super.initState();
    pictureFolderData = inventoryData['pictureFolders'];
    overViewData = inventoryData['projectOverView'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: PictureItemScreen(
          folderPath: '写真',
          pictureFolderData: pictureFolderData ?? {},
          projectId: projectId,
          fromChecklist : false,
          reload: widget.reload,
          resetEditList: (bool resetList) {
            widget.resetEditList(resetList);
          },
          editingFiles: (String editText, bool add, int total, int approved) {
            widget.editingFiles(editText, add, total, approved);
          },
          onUploadToChecklist: (fromAgentFolder, idList, folderPath,fileComment,tags) {  },
          fromNotification_folderId: widget.fromNotification_folderId,
          fromNotification_itemId: widget.fromNotification_itemId,
        )
      ),
    );
  }
}
