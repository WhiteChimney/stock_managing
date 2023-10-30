import 'package:flutter/material.dart';
import 'package:stock_managing/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_managing/tools/initialization.dart';

void main() async {
  SharedPreferences pref = await initUserProfile();
  runApp(MyApp(pref: pref));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.pref});

  final SharedPreferences pref;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: MyHomePage(
        title: '主页',
        pref: pref,
      ),
    );
  }
}
