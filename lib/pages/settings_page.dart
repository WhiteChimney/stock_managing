import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stock_managing/tools/my_ssh.dart';
import 'package:stock_managing/tools/data_processing.dart';
import 'package:stock_managing/tools/prepare_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final textIpController = TextEditingController();
  final textPortController = TextEditingController();
  final textUsernameController = TextEditingController();
  final textPasswordController = TextEditingController();

  bool infoChanged = false;
  late SharedPreferences pref;
  SshServerInfo serverInfo = SshServerInfo(
    '127.0.0.1',
    22,
    'guest',
    'password',
  );

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    textIpController.dispose();
    textPortController.dispose();
    textUsernameController.dispose();
    textPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    pref = await loadUserPreferences();
    serverInfo = loadSshServerInfoFromPref(pref);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, infoChanged);
          },
        ),
        title: const Text('Settings'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('服务器 IP 地址或域名'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: serverInfo.ip,
                        ),
                        controller: textIpController,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('端口号（默认为 22）'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: serverInfo.port.toString(),
                        ),
                        controller: textPortController,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('用户名'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: serverInfo.username,
                        ),
                        controller: textUsernameController,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('密码'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: serverInfo.password,
                        ),
                        controller: textPasswordController,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton(
                    onPressed: () async {
                      infoChanged =
                          await updateServerInfoInTextfield(serverInfo);
                      await Future.wait(
                          [clearLocalRepository(), prepareLocalRepository()]);
                    },
                    child: const Text('保存')),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 100.0),
                child: ElevatedButton(
                    onPressed: () async {
                      var result = await sshTryServer(serverInfo);
                      final snackBar = SnackBar(
                          content: Text(result[1]),
                          duration: const Duration(seconds: 5),
                          action:
                              SnackBarAction(label: '关闭', onPressed: () {}));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    },
                    child: const Text('测试服务器连接情况')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> updateServerInfoInTextfield(SshServerInfo serverInfo) async {
    bool infoChanged = false;
    if (textIpController.text != '') {
      serverInfo.ip = textIpController.text;
      await pref.setString('ip', serverInfo.ip);
      infoChanged = true;
    } else {
      setStringToTextController(textIpController, serverInfo.ip);
    }
    int? port = int.tryParse(textPortController.text);
    if (port != null) {
      serverInfo.port = port;
      await pref.setInt('port', serverInfo.port);
      infoChanged = true;
    } else {
      setStringToTextController(textPortController, serverInfo.port.toString());
    }
    if (textUsernameController.text != '') {
      serverInfo.username = textUsernameController.text;
      await pref.setString('username', serverInfo.username);
      infoChanged = true;
    } else {
      setStringToTextController(textUsernameController, serverInfo.username);
    }
    if (textPasswordController.text != '') {
      serverInfo.password = textPasswordController.text;
      await pref.setString('password', serverInfo.password);
      infoChanged = true;
    } else {
      setStringToTextController(textPasswordController, serverInfo.password);
    }
    return infoChanged;
  }
}
