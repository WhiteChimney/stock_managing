import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_managing/tools/my_ssh.dart';
import 'package:stock_managing/tools/text_processing.dart';

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
          onPressed: (){
            Navigator.pop(context);
          },),
        title: const Text('Settings'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      hintText: 'IP',
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
                      hintText: '端口号',
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
                      hintText: '用户名',
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
                      hintText: '密码',
                    ),
                    controller: textPasswordController,
                    ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(onPressed: (){
                if (textIpController.text != '') {
                  serverInfo.ip = textIpController.text;
                } else {
                  setStringToTextController(textIpController, serverInfo.ip);
                }
                int? port = int.tryParse(textPortController.text);
                if (port != null) {
                  serverInfo.port = port;
                } else {
                  setStringToTextController(textPortController, serverInfo.port.toString());
                }
                if (textUsernameController.text != '') {
                  serverInfo.username = textUsernameController.text;
                } else {
                  setStringToTextController(textUsernameController, serverInfo.username);
                }
                if (textPasswordController.text != '') {
                  serverInfo.password = textPasswordController.text;
                } else {
                  setStringToTextController(textPasswordController, serverInfo.password);
                }
              }, child: Text('提交')),
            ),
          ],
        ),
      ),
    );
  }
}