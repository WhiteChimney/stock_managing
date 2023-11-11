import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stock_managing/tools/data_processing.dart';
import 'package:stock_managing/tools/my_ssh.dart';
import 'package:stock_managing/tools/my_widgets.dart';

import 'package:stock_managing/tools/server_communication.dart';

class ItemDetailsPage extends StatefulWidget {
  const ItemDetailsPage({super.key, required this.itemId});

  final String itemId;

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  Map<String, dynamic> json = {};
  String tag = '';
  List<String> picPaths = [];
  List<String> filePaths = [];
  List<String> keyList = [];
  bool favorited = false;

  @override
  void initState() {
    super.initState();
    var widgetsBinding = WidgetsBinding.instance;
    widgetsBinding.addPostFrameCallback((timeStamp) {
      if (widget.itemId != '') _loadData(widget.itemId);
    });
  }

  void _loadData(String itemId) async {
    // var snackBar = SnackBar(
    //     content: const Text('数据加载中，请稍候……'),
    //     duration: const Duration(days: 365),
    //     action: SnackBarAction(label: '好', onPressed: () {}));
    // if (!context.mounted) return;
    // ScaffoldMessenger.of(context).showSnackBar(snackBar);
    showModalMessage(context, '数据加载中，请稍候……', false);
    var result = await Future.wait([loadItemInfo(widget.itemId)]);
    var itemInfo = result[0];
    json = itemInfo[0];
    tag = itemInfo[1];
    picPaths = itemInfo[2];
    filePaths = itemInfo[3];
    for (var key in json.keys) {
      keyList.add(key);
    }
    setState(() {});
    if (!context.mounted) return;
    // ScaffoldMessenger.of(context).removeCurrentSnackBar();
    Navigator.pop(context);
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
                  setState(() {
                    favorited = !favorited;
                  });
                },
                icon:
                    Icon(favorited ? Icons.favorite : Icons.favorite_outline)),
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
            child: TextField(
              enabled: false,
              maxLines: 1,
              decoration: InputDecoration(
                icon: const Icon(Icons.class_outlined),
                border: const UnderlineInputBorder(),
                labelText: tag,
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
        onPressed: () async {},
        tooltip: '我要借',
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
          width: MediaQuery.of(context).size.width - 72,
          child: Text(path.basename(file)),
        ),
        IconButton(
          onPressed: () {
            _downloadAndShare(context, file);
          },
          icon: const Icon(Icons.download),
        ),
      ],
    );
  }

  void _downloadAndShare(BuildContext context, String file) async {
    var pref = await loadUserPreferences();
    var serverInfo = loadSshServerInfoFromPref(pref);
    var cacheDir = await getApplicationCacheDirectory();
    var localFile = path.join(cacheDir.path, serverInfo.username, 'stockings',
        'items', widget.itemId, 'files', file);
    var remoteFile =
        '/home/${serverInfo.username}/stockings/items/${widget.itemId}/files/$file';
    var result = await sshConnectServer(serverInfo);
    print('done1');
    if (!result[0]) return;
    var client = result[2];
    result =
        await Future.wait([sftpReceiveFile(client, remoteFile, localFile)]);
    result = result[0];
    if (!result[0]) return;

    if (Platform.isIOS || Platform.isAndroid) {
      if (!context.mounted) return;
      final box = context.findRenderObject() as RenderBox?;

      await Share.shareXFiles(
        [XFile(localFile)],
        subject: file,
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    } else {
      final FileSaveLocation? savePath =
          await getSaveLocation(suggestedName: file);
      if (savePath == null) return;
      await File(localFile).copy(savePath.path);
    }
  }
}
