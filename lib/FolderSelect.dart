
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class FolderSelect extends StatefulWidget {
  final List<dynamic> picturesItems;
  final Function(List<dynamic>, String, String, String) onFolderSelected;
  final bool fromChecklist;
  final bool fromEdit;
  final String folderId;
  final String projectId;
  final String apiUrl;

  FolderSelect({
    required this.picturesItems,
    required this.onFolderSelected,
    required this.fromChecklist,
    required this.fromEdit,
    required this.folderId,
    required this.projectId,
    required this.apiUrl
  });

  @override
  _FolderSelectState createState() => _FolderSelectState();
}

class _FolderSelectState extends State<FolderSelect> {
  List<dynamic> displayedItems = [];
  List<dynamic> itemPath = [];
  late String folderId = '';
  late String selectFolderTitle = '';
  late List<String> folderData = [];

  List<dynamic> pictureItems_last = [];
  List<List<dynamic>> pictureItems_record = [];
  late List<String> folderNames = [];
  late List<dynamic> pictureItems;
  String folderPath = "";
  final RefreshController _refreshController =  RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    folderNames.insert(0,
      widget.fromChecklist ?
      "保存先フォルダを選択" :
      widget.fromEdit ?
      "移動先フォルダを選択" :
      'フォルダを選択'
    );
    displayedItems = widget.picturesItems;
    pictureItems_record.add(displayedItems);
  }

  Future<void> _refreshData() async {
    // Map<String,dynamic>? responseData = await _httpService.returnMap_get(
    //     "${widget.apiUrl}/api/mobile/projects/${widget.projectId}/pictureFolder/pictures",0,{}
    // );
    //
    // if (responseData != null && mounted) {
    //   setState(() {
    //     pictureItems_record.clear();
    //     folderNames.clear();
    //
    //     displayedItems = responseData['items'] ?? [];
    //     pictureItems_record.add(displayedItems);
    //     folderNames.insert(0,
    //         widget.fromChecklist ?
    //         "保存先フォルダを選択" :
    //         widget.fromEdit ?
    //         "移動先フォルダを選択" :
    //         'フォルダを選択'
    //     );
    //   });
    // }
    _refreshController.refreshCompleted();
  }

  void updateDisplayedItems(
      List<dynamic> newItems,
      String selectPathName,
      String selectPath,
      ) {
    setState(() {
      pictureItems_record.add(newItems);
      folderNames.insert(0,selectPathName);
      folderPath = selectPath;
      displayedItems = newItems;
    });
  }

  void updatePicturesItem({
    required List<dynamic> newPicturesItem
  }) {
    setState(() {
      displayedItems = newPicturesItem;
    });
  }

  void backPicturesItem(String lastTitle){

    pictureItems_record.removeLast();
    folderNames.removeAt(0);

    setState(() {
      pictureItems_last = pictureItems_record.last;
    });

    updatePicturesItem(
      newPicturesItem: pictureItems_record.last,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading:
        IconButton(
          onPressed: () {
            if (folderNames.length < 2) {
              Navigator.pop(context);
            } else {
              backPicturesItem(folderNames.last);
            }
          },
          icon: Row(
            children: [
              const Icon(
                  Icons.arrow_back_ios_new_outlined,
                  color: Color(0xFF005F6B)
              ),
              if (folderNames.length > 1)
                Text(
                  folderNames[1].length > 7 ?
                  folderNames[1] == 'フォルダを選択' ||
                  folderNames[1] == "保存先フォルダを選択" ||
                  folderNames[1] == '移動先フォルダを選択' ? "..." :
                  '${folderNames[1].substring(0, 5)}\n'
                  '${folderNames[1].substring(5, 8)}...' :
                  folderNames[1],
                  style: const TextStyle(
                    color: Color(0xFF005F6B),
                    fontWeight: FontWeight.bold,
                    fontSize: 10
                  ),
                  textAlign: TextAlign.start,
                ),
            ],
          ),
        ),
        title: Text(
          folderNames[0].length > 7  && folderNames.length > 1?
          '${folderNames[0].substring(0, 8)}...' :
          folderNames[0],
          style: const TextStyle(
            color: Color(0xFF005F6B),
            fontWeight: FontWeight.bold,
          ),
        )
      ),
      body: SmartRefresher(
          controller: _refreshController,
          onRefresh: _refreshData,
          header: CustomHeader(
            builder: (context, mode) {
              Widget body =
              const Icon(
                Icons.refresh_outlined,
                color: Color(0xFF005F6B),
                size: 50,
              );
              return SizedBox(
                height: 80.0,
                child: Center(child: body),
              );
            },
          ),
      child:ListView.builder(
        itemCount: displayedItems.length,
        itemBuilder: (context, index) {
          final item = displayedItems[index];
          final itemName = item['name'].toString();
          final String folderCheck = item['items'].toString();
          final itemId = item['id'].toString();

          return Container(
            margin: const EdgeInsets.fromLTRB(4.0,0.0,0.0,8.0),
            alignment: Alignment.center,
            height: MediaQuery.of(context).size.height * 0.1,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.4),
                ),
              ),
            ),
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    alignment: WrapAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/folderIcon.png',
                        color: itemId == widget.folderId ?
                        Colors.grey : const Color(0xFF005F6B),
                        height: 40,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: Text(
                              itemName,
                              style: TextStyle(
                                fontSize: itemName.length > 20 ? 15 : 18,
                                color: itemId == widget.folderId ?
                                Colors.grey : const Color(0xFF005F6B),
                                fontWeight: FontWeight.bold,
                              )
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.2,
                    child: TextButton(
                        onPressed: () {
                          updateDisplayedItems(
                              item['items'],
                              item['name'],
                              item['folder_path']
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(''),
                            Container(
                                alignment: Alignment.center,
                                width: MediaQuery.of(context).size.width * 0.1,
                                height: MediaQuery.of(context).size.height * 0.05,
                                child:
                                const Icon(Icons.arrow_forward_ios_outlined,
                                    color: Color(0xFF005F6B)
                                )
                            )
                          ],
                        )
                    ),
                  )

                ],
              ),
              onTap: () {
                if (displayedItems[index]['id'] != widget.folderId) {
                  selectFolderTitle = displayedItems[index]['name'];
                  folderId = displayedItems[index]['id'];
                  folderPath = displayedItems[index]['folder_path'];
                  itemPath = displayedItems[index]['objects'] ?? [];
                  Navigator.pop(context);
                  widget.onFolderSelected(itemPath,selectFolderTitle,folderId,folderPath);
                }
              },
            ),
          );
        },
      )),
    );
  }

}
