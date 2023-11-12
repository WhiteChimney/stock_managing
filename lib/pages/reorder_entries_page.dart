import 'package:flutter/material.dart';

class ReorderEntriesPage extends StatefulWidget {
  const ReorderEntriesPage({super.key, required this.originalEntries});

  final List<String> originalEntries;

  @override
  State<ReorderEntriesPage> createState() => _ReorderEntriesPageState();
}

class _ReorderEntriesPageState extends State<ReorderEntriesPage> {
  List<String> entries = [];
  List<int> originalOrders = [];

  @override
  void initState() {
    entries = widget.originalEntries;
    for (int i = 0; i < entries.length; i++) {
      originalOrders.add(i);
    }
    super.initState();
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
        title: const Text('条目顺序调整'),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.pop(context, originalOrders);
              },
              icon: const Icon(Icons.check)),
        ],
      ),
      body: ReorderableListView(
        children: <Widget>[
          for (int index = 0; index < entries.length; index++)
            Container(
              key: ValueKey('$index'),
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  borderRadius: BorderRadius.circular(10)),
              child: _generateItems(entries[index]),
            )
        ],
        onReorder: (int oldIndex, int newIndex) {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          var child = entries.removeAt(oldIndex);
          entries.insert(newIndex, child);
          var order = originalOrders.removeAt(oldIndex);
          originalOrders.insert(newIndex, order);
          setState(() {});
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: (){},
      //   tooltip: '添加条目',
      //   child: const Icon(Icons.add),
      // ),
    );
  }

  Row _generateItems(String entry) {
    return Row(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width - 72,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(entry),
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
