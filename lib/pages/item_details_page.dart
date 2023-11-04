import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import 'package:stock_managing/pages/edit_item_page.dart';
import 'package:stock_managing/tools/server_communication.dart';

class ItemDetailsPage extends StatefulWidget {
  const ItemDetailsPage({super.key, required this.itemId});

  final String itemId;

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  Map<String, dynamic> json = {};
  List<String> picPaths = [];
  List<String> filePaths = [];
  List<String> keyList = [];

  @override
  void initState() {
    super.initState();
    if (widget.itemId != '') _loadData(widget.itemId);
  }

  void _loadData(String itemId) async {
    var itemInfo = await loadItemInfo(widget.itemId);
    json = itemInfo[0];
    picPaths = itemInfo[1];
    print(picPaths);
    filePaths = itemInfo[2];
    for (var key in json.keys) {
      keyList.add(key);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text('物品详情'),
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => EditItemPage(
                            itemId: widget.itemId,
                          )));
                },
                icon: const Icon(Icons.edit)),
          ],
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          )),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: TextField(
              enabled: false,
              maxLines: 1,
              decoration: InputDecoration(
                icon: Icon(Icons.perm_identity),
                border: UnderlineInputBorder(),
                labelText: widget.itemId,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 200,
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: picPaths.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: generatePictureWidget(picPaths[index]),
                    );
                  }),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return generateFilesWidget(filePaths[index]);
              },
              childCount: filePaths.length,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return generateEntryWidget(index);
              },
              childCount: keyList.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: '点个赞吧',
        child: const Icon(Icons.thumb_up),
      ),
    );
  }

  Column generateEntryWidget(int index) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            enabled: false,
            maxLines: 1,
            decoration: InputDecoration(
                icon: Icon(Icons.bookmark),
                border: UnderlineInputBorder(),
                labelText: keyList[index]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            enabled: false,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              icon: Icon(Icons.assignment_outlined),
              border: OutlineInputBorder(),
              labelText: json[keyList[index]],
            ),
          ),
        ),
      ],
    );
  }

  Image generatePictureWidget(String pic) {
    print('generating pic: ${pic}');
    return Image.file(
      File(pic),
      height: 144,
      errorBuilder:
          (BuildContext context, Object exception, StackTrace? stackTrace) {
        print('error occurred');
        return Image(
            image: AssetImage('assets/images/image_loading_failed.png'));
      },
    );
  }

  Row generateFilesWidget(String file) {
    return Row(
      children: [
        Icon(Icons.file_present),
        SizedBox(
          child: Text(path.basename(file)),
          width: MediaQuery.of(context).size.width - 64,
        ),
      ],
    );
  }
}
