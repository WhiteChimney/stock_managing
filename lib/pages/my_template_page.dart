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
  // controllers 为列表，因为需要排序
  // 其与 controllerKeys 一一对应，key 为象征性的序号

  Map<String, dynamic> templateJson = {};
  List<String> controllerKeys = [];
  List<TextEditingController> controllers = [];
  int keyCount = 0;

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
      var controller = TextEditingController(text: templateJson[key]);
      controllers.add(controller);
      controllerKeys.add(key);
    }
    keyCount = templateJson.length;
    setState(() {});
  }

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
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
          IconButton(
              onPressed: () {
                _saveTemplateItems();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check)),
        ],
      ),
      body: ReorderableListView(
        children: <Widget>[
          for (int index = 0; index < keyCount; index++)
            Container(
              key: ValueKey(controllerKeys[index]),
              height: 100,
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  borderRadius: BorderRadius.circular(10)),
              child: _generateItems(controllers[index]),
            )
        ],
        onReorder: (int oldIndex, int newIndex) {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          var child = controllers.removeAt(oldIndex);
          controllers.insert(newIndex, child);
          var childKey = controllerKeys.removeAt(oldIndex);
          controllerKeys.insert(newIndex, childKey);
          setState(() {});
        },
      ),
      // body: ReorderableListView.builder(
      //   itemCount: controllers.length,
      //   itemBuilder: (context, index) {
      //     return Container(
      //       key: ValueKey(controllers[index].text),
      //       height: 100,
      //       margin: const EdgeInsets.all(8.0),
      //       decoration: BoxDecoration(
      //           color: Theme.of(context).colorScheme.onInverseSurface,
      //           borderRadius: BorderRadius.circular(10)),
      //       child: _generateItems(controllers[index]),
      //     );
      //   },
      //   onReorder: (int oldIndex, int newIndex) {
      //     if (oldIndex < newIndex) {
      //       newIndex -= 1;
      //     }
      //     var child = controllers.removeAt(oldIndex);
      //     controllers.insert(newIndex, child);
      //     setState(() {});
      //   },
      // ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTemplateItem,
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

  void _addTemplateItem() {
    var controller = TextEditingController();
    controllers.add(controller);
    controllerKeys.add(keyCount.toString());
    keyCount++;
    setState(() {});
  }

  void _saveTemplateItems() async {
    Map<String, dynamic> saveTemplateJson = {};
    var indexCount = 0;
    for (var index = 0; index < controllers.length; index++) {
      var text = controllers[index].text;
      if (text.isNotEmpty) {
        saveTemplateJson[indexCount.toString()] = text;
        indexCount++;
      }
    }
    var pref = await loadUserPreferences();
    var serverInfo = loadSshServerInfoFromPref(pref);
    var cacheDir = await getApplicationCacheDirectory();
    var templatePath =
        path.join(cacheDir.path, serverInfo.username, 'template.json');
    await File(templatePath).writeAsString(jsonEncode(saveTemplateJson));
  }
}
