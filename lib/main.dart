import 'package:flutter/material.dart';

import 'package:stock_managing/pages/home_page.dart';
import 'package:stock_managing/tools/data_processing.dart';
import 'package:stock_managing/tools/my_ssh.dart';
import 'package:stock_managing/tools/prepare_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var pref = await loadUserPreferences();
  var serverInfo = loadSshServerInfoFromPref(pref);
  var result = await sshTryServer(serverInfo);
  if (result[0]) {
    await Future.wait([prepareRemoteRepository(), prepareLocalRepository()]);
  }
  runApp(MyApp(result: result));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.result});

  final List result;
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
        useMaterial3: true,
      ),
      home: MyHomePage(title: '主页', serverResult: widget.result),
      routes: {
        '/homePage': (context) =>
            MyHomePage(title: '主页', serverResult: widget.result),
      },
    );
  }
}
