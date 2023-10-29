import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:stock_managing/tools/my_ssh.dart';
import 'add_item.dart';
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
  String sshResult = 'not connected';

  String sshReturn = 'not started';

  late SSHClient client1;

  var myController = TextEditingController();
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

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
                  Text('Noland'),
                ],
              ),
            ),
            ListTile(
              title: Text('设置'),
              onTap: () {
                print('用户想要设置');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context)=>SettingsPage(pref: widget.pref))
                );
              },
            ),
            ListTile(
              title: Text('关于'),
              onTap: () {
                print('用户想要关于');
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
            Text(sshResult),
            ElevatedButton(
                onPressed: () async {
                  String res = await tryServer(serverInfo);
                  setState(() {
                    sshResult = res;
                  });
                },
                child: Text('test')),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Text(sshReturn),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter a command to be sent',
                ),
                controller: myController,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    var res = await connectServer();
                    setState(() {
                      sshReturn = res[0];
                      client1 = res[1];
                    });
                  },
                  child: Text('connect'),
                ),
                ElevatedButton(
                  child: Text('disconnect'),
                  onPressed: () async {
                    String res = await disconnectServer(client1);
                    setState(() {
                      sshReturn = res;
                    });
                  },
                ),
                ElevatedButton(
                  child: Text('send'),
                  onPressed: () async {
                    String res = await sendCommand(myController.text, client1);
                    setState(() {
                      sshReturn = res;
                    });
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                  onPressed: () async {
                    String res = await receiveTestFile(client1);
                    setState(() {
                      sshReturn = res;
                    });
                  },
                  child: Text('receive')),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                  onPressed: () async {
                    String res = await saveToLocal(sshReturn);
                    print(res);
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
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
