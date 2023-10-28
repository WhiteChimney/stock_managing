import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String sshResult = 'not connected';

  String sshReturn = 'not started';

  late SSHClient client1;

  Future<String> tryServer() async {
    final socket = await SSHSocket.connect(
      // '192.168.50.17', 
      'lqcc301.ddns.net',
      // '210.45.114.213',
      // 22,
      30109,
      );

    final client = SSHClient(
      socket,
      // username: 'noland',
      // identities: [
        // ...SSHKeyPair.fromPem(await File('C:/Users/79082/.ssh/id_ecdsa').readAsString())
      // ],
      username: 'root',
      onPasswordRequest: () => 'zxh12345ZXH',
    );

    String? result;
    try {
      final uptime = await client.run('uptime');
      result = utf8.decode(uptime);
      client.close();
      await client.done;
    } catch (err) {
      result = err.toString();
    }


    return result;
  }

  Future<List> connectServer() async {
    final socket = await SSHSocket.connect(
      '192.168.50.17', 22
      );

    final client = SSHClient(
      socket,
      username: 'noland',
      identities: [
        ...SSHKeyPair.fromPem(await File('C:/Users/79082/.ssh/id_ecdsa').readAsString())
      ],
    );

    String? result;
    try {
      await client.run('uptime');
      result = 'successfully connected';
    } catch (err) {
      result = err.toString();
    }
    return [result,client];
  }

  Future<String> sendCommand(String command, SSHClient client) async {
    String ? result;
    try {
      final msg = await client.run(command);
      result = utf8.decode(msg);
    } catch (err) {
      result = err.toString();
    }
    return result;
  }
  
  Future<String> disconnectServer(SSHClient client) async {
    String ? result;
    try {
      client.close();
      await client.done;
      result = 'successfully closed.';
    } catch (err) {
      result = err.toString();
    }
    return result;
  }
  
  Future<String> receiveTestFile(SSHClient client) async {
    String ? result;
    try {
      final sftp = await client.sftp();
      final file = await sftp.open('/home/noland/test.txt');
      final content = await file.readBytes();
      result = latin1.decode(content);
    } catch (err) {
      result = err.toString();
    }
    return result;
  }

  Future<String> saveToLocal() async {
    String ? result;
    try {
      final directory = await getApplicationCacheDirectory();
      var file = File('${directory.path}/test.txt');
      String content = sshReturn;
      print(content);
      file.writeAsString(content);
      result = directory.path;
    } catch (err) {
      result = err.toString();
    }
    return result;
  }

  var myController = TextEditingController();
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: (){}, 
            icon: const Icon(Icons.search)
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Column(
              children: [
                Text('当前用户'),
                Text('Noland'),
              ],
            ),),
            ListTile(
              title: Text('设置'), 
              onTap: (){
                print('用户想要设置');
              },
            ),
            ListTile(title: Text('关于'),
              onTap: (){
                print('用户想要关于');
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
                String res = await tryServer();
                setState(() {
                  sshResult = res;
                });
              },
              child: Text('test')
            ),
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
                    String res = await sendCommand(myController.text,client1);
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
                child: Text('receive')
                ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () async {
                  String res = await saveToLocal();
                  print(res);
                }, 
                child: Text('save')
                ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){},
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
