import 'package:flutter/material.dart';

class MyTemplatePage extends StatefulWidget {
  const MyTemplatePage({super.key});

  @override
  State<MyTemplatePage> createState() => _MyTemplatePageState();
}

class _MyTemplatePageState extends State<MyTemplatePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: (){
            Navigator.pop(context);
          },),
        title: const Text('标题在这里！！！'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('感谢 Flutter 开发团队'),
            Text('以及社区的开发人员'),
          ],
        ),
      ),
    );
  }
}