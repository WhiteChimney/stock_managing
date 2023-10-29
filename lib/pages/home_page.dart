import 'package:flutter/material.dart';
import 'package:stock_managing/tools/my_ssh.dart';
import 'add_item_page.dart';
import 'settings_page.dart';
import 'about_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.pref});

  final String title;

  final SharedPreferences pref;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  // var myController = TextEditingController();
  // @override
  // void dispose() {
  //   // Clean up the controller when the widget is disposed.
  //   myController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {

    SshServerInfo serverInfo = loadSshServerInfoFromPref(widget.pref);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
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
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context)=>SettingsPage(pref: widget.pref))
                );
                if (!context.mounted) return;
                widget.pref.reload();
                serverInfo = loadSshServerInfoFromPref(widget.pref);
              },
            ),
            ListTile(
              title: Text('关于'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context)=>AboutPage())
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                  onPressed: () {
                    print('to be done.');
                  },
                  child: Text('save')),
            ),
          ],
        ),
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
}
