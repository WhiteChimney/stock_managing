import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stock_managing/pages/edit_item_page.dart';
import 'package:stock_managing/pages/item_details_page.dart';
import 'package:stock_managing/tools/my_ssh.dart';
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

  @override
  void initState() {
    super.initState();
    _downloadItemsInfo();
  }

  @override
  Widget build(BuildContext context) {
    // _loadItemsInfo();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(onPressed: () async {
            _downloadItemsInfo();
            }, icon: const Icon(Icons.refresh)),
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
              onTap: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => SettingsPage()));
              },
            ),
            ListTile(
              title: Text('搜索'),
              onTap: () => showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('请输入关键词进行搜索'),
                    content: Text('敬请期待'),
                    actions: <Widget>[
                      TextButton(
                          child: Text(
                            '取消',
                            style: TextStyle(color: Colors.grey),
                          ),
                          onPressed: () {
                            Navigator.pop(context, "取消");
                          }),
                      TextButton(
                        child: Text(
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
              context,
              MaterialPageRoute(
                  builder: (context) => EditItemPage(
                        itemId: '',
                      )));
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
        // List itemInfo = await loadItemInfo(itemsId[index]);
        if (!context.mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ItemDetailsPage(
                  itemId: itemsId[index],
                )));
      },
    ));
  }

  void _downloadItemsInfo() async {
    await downloadJsonFromServer().whenComplete(() {
      setState(() {});
    });
  }
}
