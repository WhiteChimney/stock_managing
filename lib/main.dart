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
        title: 'Flutter Demo Home Page',
        pref: pref,),
    );
  }
}

Future<SharedPreferences> initUserProfile() async {
  SharedPreferences pref = await SharedPreferences.getInstance();

  await pref.setString('ip', '192.168.50.17');
  await pref.setInt('port', 22);
  await pref.setString('username', 'noland');
  await pref.setString('password', 'zxh12345');

  return pref;
}