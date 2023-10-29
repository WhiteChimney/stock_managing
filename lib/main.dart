import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: MyHomePage(
        title: '主页',
        pref: pref,),
    );
  }
}

Future<SharedPreferences> initUserProfile() async {
  SharedPreferences pref = await SharedPreferences.getInstance();

  if (pref.getString('ip') == null) await pref.setString('ip', '131theater.tpddns.cn');
  if (pref.getInt('port') == null) await pref.setInt('port', 13117);
  if (pref.getString('username') == null) await pref.setString('username', 'noland');
  if (pref.getString('password') == null) await pref.setString('password', 'zxh12345');

  return pref;
}