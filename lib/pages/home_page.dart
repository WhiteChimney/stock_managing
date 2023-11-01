import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stock_managing/tools/my_ssh.dart';
import 'add_item_page.dart';
import 'settings_page.dart';
import 'about_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'item_details_page.dart';
import 'package:mime/mime.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.pref});

  final String title;

  final SharedPreferences pref;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<String, dynamic> itemsInfo = {};
  List<String> itemsId = [];

  @override
  Widget build(BuildContext context) {
    SshServerInfo serverInfo = loadSshServerInfoFromPref(widget.pref);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(onPressed: loadItemsInfo, icon: const Icon(Icons.search)),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Column(
                children: [
                  Text('当前用户'),
                  Text(serverInfo.username),
                ],
              ),
            ),
            ListTile(
              title: Text('设置'),
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => SettingsPage(pref: widget.pref)));
                if (!context.mounted) return;
                widget.pref.reload();
                serverInfo = loadSshServerInfoFromPref(widget.pref);
              },
            ),
            ListTile(
              title: Text('关于'),
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => AboutPage()));
              },
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return generateItemView(index);
              },
              childCount: itemsInfo.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => AddItemPage()));
        },
        tooltip: '添加物品',
        child: const Icon(Icons.add),
      ),
    );
  }

  Container generateItemView(int index) {
    return Container(
        child: ListTile(
      leading: Icon(Icons.file_download_done),
      title: Text(itemsId[index]),
      subtitle: Text(itemsInfo[itemsId[index]]),
      trailing: Icon(Icons.keyboard_arrow_right_outlined),
      onTap: () async {
        List itemInfo = await generateItemInfo(index);
        if (!context.mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ItemDetailsPage(
                  itemId: itemsId[index],
                  picList: itemInfo[0],
                  fileList: itemInfo[1],
                  json: itemInfo[2],
                  keyList: itemInfo[3],
                )));
      },
    ));
  }

  void loadItemsInfo() async {
    var cacheDir = await getApplicationCacheDirectory();
    var fJson =
        File(path.join(cacheDir.path, 'noland', 'stockings', 'items.json'));
    if (!(await fJson.exists())) return;

    itemsInfo = jsonDecode(await fJson.readAsString());
    itemsId.clear();
    for (var key in itemsInfo.keys) {
      itemsId.add(key);
    }
    print(itemsInfo);
    setState(() {});
  }

  Future<List> generateItemInfo(int index) async {
    var cacheDir = await getApplicationCacheDirectory();
    var itemDir = path.join(
        cacheDir.path, 'noland', 'stockings', 'items', itemsId[index]);
    var picDir = path.join(itemDir, 'images');
    var picList = Directory(picDir).listSync();
    List<FileSystemEntity> picListFinal = [];

    for (var pic in picList) {
      var mimetype = lookupMimeType(pic.path);
      print(mimetype);
      if (mimetype != null && mimetype.startsWith('image/')) {
        picListFinal.add(pic);
      }
    }

    var fileDir = path.join(itemDir, 'files');
    var fileList = Directory(fileDir).listSync();
    List<FileSystemEntity> fileListFinal = [];
    for (var file in fileList) {
      if (file is File) {
        fileListFinal.add(file);
      }
    }

    String itemJson = path.join(itemDir, '${itemsId[index]}.json');
    var fJson = File(itemJson);
    Map<String, dynamic> json = jsonDecode(await fJson.readAsString());
    print(json);
    List<String> keyList = [];
    for (var key in json.keys) {
      keyList.add(key);
    }

    return [picListFinal, fileListFinal, json, keyList];
  }
}
