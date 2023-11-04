import 'package:flutter/material.dart';

import 'package:stock_managing/pages/home_page.dart';
import 'package:stock_managing/tools/prepare_repository.dart';

void initApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await makeSureServerIsReady();
  await makeSureLocalRepositoryIsReady();
}

void main() {
  initApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const MyHomePage(
        title: '主页'
      ),
      routes: {
        '/homePage':(context) => const MyHomePage(title: '主页'),
      },
    );
  }
}
