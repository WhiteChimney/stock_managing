import 'package:flutter/material.dart';

class MyTemplatePage extends StatefulWidget {
  const MyTemplatePage({super.key});

  @override
  State<MyTemplatePage> createState() => _MyTemplatePageState();
}

class _MyTemplatePageState extends State<MyTemplatePage> {
  List<String> items = List.generate(20, (int i) => '$i');
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
      ),
      body: ReorderableListView(
        children: <Widget>[
          for (String item in items)
            Container(
              key: ValueKey(item),
              height: 100,
              margin: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  borderRadius: BorderRadius.circular(10)),
              child: _generateItems(item),
            )
        ],
        onReorder: (int oldIndex, int newIndex) {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          var child = items.removeAt(oldIndex);
          items.insert(newIndex, child);
          setState(() {});
        },
      ),
    );
  }

  Container _generateItems(String item) {
    return Container(
      child: Row(
        children: [
          Container(
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
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(Icons.format_line_spacing),
          ),
        ],
      ),
    );
  }
}
