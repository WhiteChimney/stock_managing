import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_managing/tools/my_ssh.dart';
import 'package:stock_managing/tools/data_processing.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.pref});

  final SharedPreferences pref;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final textIpController = TextEditingController();
  final textPortController = TextEditingController();
  final textUsernameController = TextEditingController();
  final textPasswordController = TextEditingController();

  bool infoChanged = false;

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
  Widget build(BuildContext context) {
    SshServerInfo serverInfo = loadSshServerInfoFromPref(widget.pref);
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('服务器 IP 地址或域名'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: serverInfo.ip,
                      ),
                      controller: textIpController,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('端口号（默认为 22）'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: serverInfo.port.toString(),
                      ),
                      controller: textPortController,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('用户名'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: serverInfo.username,
                      ),
                      controller: textUsernameController,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('密码'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
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
                    infoChanged = await updateServerInfoInTextfield(serverInfo);
                  },
                  child: Text('保存')),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 100.0),
              child: ElevatedButton(
                  onPressed: () async {
                    var result = await sshTryServer(serverInfo);
                    final snackBar = SnackBar(content: Text(result[1]));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  },
                  child: Text('测试服务器连接情况')),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> updateServerInfoInTextfield(SshServerInfo serverInfo) async {
    bool infoChanged = false;
    if (textIpController.text != '') {
      serverInfo.ip = textIpController.text;
      await widget.pref.setString('ip', serverInfo.ip);
      infoChanged = true;
    } else {
      setStringToTextController(textIpController, serverInfo.ip);
    }
    int? port = int.tryParse(textPortController.text);
    if (port != null) {
      serverInfo.port = port;
      await widget.pref.setInt('port', serverInfo.port);
      infoChanged = true;
    } else {
      setStringToTextController(textPortController, serverInfo.port.toString());
    }
    if (textUsernameController.text != '') {
      serverInfo.username = textUsernameController.text;
      await widget.pref.setString('username', serverInfo.username);
      infoChanged = true;
    } else {
      setStringToTextController(textUsernameController, serverInfo.username);
    }
    if (textPasswordController.text != '') {
      serverInfo.password = textPasswordController.text;
      await widget.pref.setString('password', serverInfo.password);
      infoChanged = true;
    } else {
      setStringToTextController(textPasswordController, serverInfo.password);
    }
    return infoChanged;
  }
}
