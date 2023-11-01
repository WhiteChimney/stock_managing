import 'package:flutter/material.dart';
import 'dart:io';

class ItemDetailsPage extends StatefulWidget {
  const ItemDetailsPage(
      {super.key,
      required this.itemId,
      required this.picList,
      required this.fileList,
      required this.json,
      required this.keyList});

  final String itemId;
  final List<FileSystemEntity> picList;
  final List<FileSystemEntity> fileList;
  final Map<String, dynamic> json;
  final List<String> keyList;

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text('物品详情'),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.edit)),
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
            child: SizedBox(
              height: 200,
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.picList.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: generatePictureWidget(widget.picList[index]),
                      // child: Container(),
                    );
                  }),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return generateFilesWidget(widget.fileList[index]);
              },
              childCount: widget.fileList.length,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return generateEntryWidget(index);
              },
              childCount: widget.keyList.length,
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
                labelText: widget.keyList[index]),
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
              labelText: widget.json[widget.keyList[index]],
            ),
          ),
        ),
      ],
    );
  }

  Container generatePictureWidget(FileSystemEntity pic) {
    print('generating pics');
    return Container(
      child: Image.file(
        File(pic.path),
        height: 144,
        errorBuilder:
            (BuildContext context, Object exception, StackTrace? stackTrace) {
          print('error occurred');
          return Image(
              image: AssetImage('assets/images/image_loading_failed.png'));
        },
      ),
    );
  }

  Row generateFilesWidget(FileSystemEntity file) {
    return Row(
      children: [
        Icon(Icons.file_present),
        SizedBox(
          child: Text(file.path),
          width: MediaQuery.of(context).size.width - 64,
        ),
      ],
    );
  }
}
