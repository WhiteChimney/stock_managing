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
    var widgetsBinding = WidgetsBinding.instance;
    widgetsBinding.addPostFrameCallback((timeStamp) {
      const snackBar = SnackBar(
        content: Text('数据加载中，请稍候……'),
        duration: Duration(seconds: 1),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  void _loadData(String itemId) async {
    var result = await Future.wait([loadItemInfo(widget.itemId)]);
    var itemInfo = result[0];
    json = itemInfo[0];
    picPaths = itemInfo[1];
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
          title: const Text('物品详情'),
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
            icon: const Icon(Icons.arrow_back),
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
                icon: const Icon(Icons.perm_identity),
                border: const UnderlineInputBorder(),
                labelText: widget.itemId,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
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
                icon: const Icon(Icons.bookmark),
                border: const UnderlineInputBorder(),
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
              icon: const Icon(Icons.assignment_outlined),
              border: const OutlineInputBorder(),
              labelText: json[keyList[index]],
            ),
          ),
        ),
      ],
    );
  }

  Image generatePictureWidget(String pic) {
    return Image.file(
      File(pic),
      height: 144,
      errorBuilder:
          (BuildContext context, Object exception, StackTrace? stackTrace) {
        return const Image(
            image: AssetImage('assets/images/image_loading_failed.png'));
      },
    );
  }

  Row generateFilesWidget(String file) {
    return Row(
      children: [
        const Icon(Icons.file_present),
        SizedBox(
          width: MediaQuery.of(context).size.width - 64,
          child: Text(path.basename(file)),
        ),
      ],
    );
  }
}
