
import 'package:flutter/material.dart';
import 'package:object_project/Documents/DocumentItemScreen.dart';

class AgendaDocuments extends StatefulWidget {
  final Map<String, dynamic> inventoryData;

  AgendaDocuments({
    required this.inventoryData,
  });

  @override
  AgendaDocumentsState createState() => AgendaDocumentsState();
}

class AgendaDocumentsState extends State<AgendaDocuments> {
  late Map<String, dynamic> inventoryData = widget.inventoryData;

  late Map<String, dynamic> documentFolderData;

  @override
  void initState() {
    super.initState();
    documentFolderData = inventoryData['pictureFolders'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: DocumentItemScreen(
          folderPath: '사진',
          documentFolderData: documentFolderData ?? {},
        )
      ),
    );
  }
}

