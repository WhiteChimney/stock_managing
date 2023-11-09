import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stock_managing/pages/about_page.dart';
import 'package:stock_managing/pages/edit_item_page.dart';
import 'package:stock_managing/pages/item_details_page.dart';
import 'package:stock_managing/pages/my_template_page.dart';
import 'package:stock_managing/pages/settings_page.dart';
import 'package:stock_managing/tools/app_provider.dart';
import 'package:stock_managing/tools/data_processing.dart';
import 'package:stock_managing/tools/my_ssh.dart';
import 'package:stock_managing/tools/prepare_repository.dart';
import 'package:stock_managing/tools/server_communication.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<String, dynamic> itemsInfo = {};
  List<String> itemsId = [];
  SshServerInfo serverInfo = SshServerInfo(
    '127.0.0.1',
    22,
    'guest',
    'password',
  );
  late SharedPreferences pref;
  bool alerted = false;

  @override
  void initState() {
    super.initState();
    _initThemeColor();
    var widgetsBinding = WidgetsBinding.instance;
    widgetsBinding.addPostFrameCallback((timeStamp) {
      _sshServerTest();
    });
  }

  void _initThemeColor() async {
    var pref = await loadUserPreferences();
    int colorIndex = pref.getInt('themeColor')!;
    if (!context.mounted) return;
    Provider.of<AppInfoProvider>(context, listen: false).setTheme(colorIndex);
  }

  void _sshServerTest() async {
    var snackBar = SnackBar(
        content: const Text('测试与服务器的连接情况……'),
        duration: const Duration(days: 365),
        action: SnackBarAction(label: '关闭', onPressed: () {}));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    var pref = await loadUserPreferences();
    var serverInfo = loadSshServerInfoFromPref(pref);
    var res = await Future.wait([sshTryServer(serverInfo)]);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    var result = res[0];
    if (result[0]) {
      const snackBar2 =
          SnackBar(content: Text('服务器连接正常！'), duration: Duration(seconds: 2));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar2);
      await Future.wait([prepareRemoteRepository(), prepareLocalRepository()]);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      _downloadItemsInfo();
    } else {
      if (!context.mounted) return;
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('服务器连接失败！'),
              content: Text(result[1]),
              actions: <Widget>[
                TextButton(
                    child: const Text(
                      '取消',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onPressed: () {
                      Navigator.pop(context, "取消");
                    }),
                TextButton(
                  child: const Text(
                    '前往设置',
                    style: TextStyle(color: Colors.blue),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const SettingsPage()));
                  },
                ),
              ],
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
              onPressed: () async {
                _downloadItemsInfo();
              },
              icon: const Icon(Icons.refresh)),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Column(
                children: [
                  const Text('当前用户'),
                  Text(serverInfo.username),
                ],
              ),
            ),
            ListTile(
              title: const Text('服务器设置'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const SettingsPage()));
              },
            ),
            ListTile(
              title: const Text('搜索'),
              onTap: () => showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('请输入关键词进行搜索'),
                      content: const Text('敬请期待'),
                      actions: <Widget>[
                        TextButton(
                            child: const Text(
                              '取消',
                              style: TextStyle(color: Colors.grey),
                            ),
                            onPressed: () {
                              Navigator.pop(context, "取消");
                            }),
                        TextButton(
                          child: const Text(
                            '确定',
                            style: TextStyle(color: Colors.blue),
                          ),
                          onPressed: () {
                            Navigator.pop(context, "确定");
                          },
                        ),
                      ],
                    );
                  }),
            ),
            ListTile(
              title: const Text('模板设置'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const MyTemplatePage()));
              },
            ),
            ListTile(
              title: const Text('切换主题'),
              onTap: () {
                changeThemeColor(context);
              },
            ),
            ListTile(
              title: const Text('关于'),
              onTap: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AboutPage()));
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
              context,
              MaterialPageRoute(
                  builder: (context) => const EditItemPage(
                        itemId: '',
                      )));
        },
        tooltip: '添加物品',
        child: const Icon(Icons.add),
      ),
    );
  }

  Dismissible generateItemView(int index) {
    return Dismissible(
      key: Key(itemsId[index]),
      background: Container(
        color: Colors.green,
        child: const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 16),
            child: Icon(Icons.edit),
          ),
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        child: const Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.delete),
          ),
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => EditItemPage(
                    itemId: itemsId[index],
                  )));
          return false;
        } else {
          bool delete = true;
          final snackbarController = ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${itemsId[index]}已删除'),
              action:
                  SnackBarAction(label: '撤销', onPressed: () => delete = false),
            ),
          );
          await snackbarController.closed;
          return delete;
        }
      },
      onDismissed: (_) async {
        await Future.wait([deleteItem(itemsId[index])]);
        _downloadItemsInfo();
      },
      child: ListTile(
        leading: const Icon(Icons.file_download_done),
        title: Text(itemsId[index]),
        subtitle: Text(itemsInfo[itemsId[index]]),
        trailing: const Icon(Icons.keyboard_arrow_right_outlined),
        onTap: () async {
          // List itemInfo = await loadItemInfo(itemsId[index]);
          if (!context.mounted) return;
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ItemDetailsPage(
                    itemId: itemsId[index],
                  )));
        },
      ),
    );
  }

  void _downloadItemsInfo() async {
    var snackBar = SnackBar(
        content: const Text('数据更新中……'),
        duration: const Duration(days: 365),
        action: SnackBarAction(label: '关闭', onPressed: () {}));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    pref = await loadUserPreferences();
    serverInfo = loadSshServerInfoFromPref(pref);
    var result = await downloadJsonFromServer();
    var mainJsonPath = result[1];
    itemsInfo = jsonDecode(File(mainJsonPath).readAsStringSync());
    itemsId.clear();
    for (var key in itemsInfo.keys) {
      itemsId.add(key);
    }
    setState(() {});
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    snackBar = SnackBar(
        content: const Text('更新成功！'),
        duration: const Duration(seconds: 1),
        action: SnackBarAction(label: '关闭', onPressed: () {}));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
