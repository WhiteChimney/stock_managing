import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:stock_managing/tools/data_processing.dart';
import 'package:stock_managing/tools/my_ssh.dart';

class MyTemplatePage extends StatefulWidget {
  const MyTemplatePage({super.key});

  @override
  State<MyTemplatePage> createState() => _MyTemplatePageState();
}

class _MyTemplatePageState extends State<MyTemplatePage> {
  Map<String, dynamic> templateJson = {};
  List<TextEditingController> controllers = [];
  @override
  void initState() {
    super.initState();
    _getTemplate();
  }

  void _getTemplate() async {
    var pref = await loadUserPreferences();
    var serverInfo = loadSshServerInfoFromPref(pref);
    var cacheDir = await getApplicationCacheDirectory();
    var templatePath =
        path.join(cacheDir.path, serverInfo.username, 'template.json');
    if (!File(templatePath).existsSync()) {
      File(templatePath).createSync(recursive: true);
      File(templatePath).writeAsStringSync(jsonEncode(templateJson));
    } else {
      templateJson = jsonDecode(File(templatePath).readAsStringSync());
    }
    controllers.clear();
    for (var key in templateJson.keys) {
      var controller = TextEditingController();
      setStringToTextController(controller, templateJson[key]);
      controllers.add(controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('模板设置'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.check)),
        ],
      ),
      body: ReorderableListView(
        children: <Widget>[
          for (var controller in controllers)
            Container(
              key: ValueKey(controller.text),
              height: 100,
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  borderRadius: BorderRadius.circular(10)),
              child: _generateItems(controller),
            )
        ],
        onReorder: (int oldIndex, int newIndex) {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          var child = controllers.removeAt(oldIndex);
          controllers.insert(newIndex, child);
          setState(() {});
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: '添加条目',
        child: const Icon(Icons.add),
      ),
    );
  }

  Row _generateItems(TextEditingController controller) {
    return Row(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width - 72,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              maxLines: 1,
              decoration: const InputDecoration(
                icon: Icon(Icons.edit_note),
                border: UnderlineInputBorder(),
                hintText: '条目名称',
              ),
              controller: controller,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.format_line_spacing),
        ),
      ],
    );
  }
}
