import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:stock_managing/pages/home_page.dart';
import 'package:stock_managing/tools/app_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<MaterialAccentColor> themeColorList = [
    Colors.amberAccent,
    Colors.blueAccent,
    Colors.cyanAccent,
    Colors.deepOrangeAccent,
    Colors.deepPurpleAccent,
    Colors.greenAccent,
    Colors.indigoAccent,
    Colors.lightBlueAccent,
    Colors.lightGreenAccent,
    Colors.limeAccent,
    Colors.orangeAccent,
    Colors.pinkAccent,
    Colors.purpleAccent,
    Colors.redAccent,
    Colors.tealAccent,
    Colors.yellowAccent
  ];

  MaterialAccentColor _themeColor = Colors.blueAccent;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [ChangeNotifierProvider.value(value: AppInfoProvider())],
        child: Consumer<AppInfoProvider>(
          builder: (context, appInfo, _) {
            int colorKey = appInfo.themeColor % themeColorList.length;
            _themeColor = themeColorList[colorKey];
            return MaterialApp(
              title: 'Flutter Demo',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: _themeColor),
                useMaterial3: true,
              ),
              home: const MyHomePage(title: '主页'),
              // routes: {
              // '/homePage': (context) =>
              // MyHomePage(title: '主页', serverResult: widget.result),
              // },
            );
          },
        ));
  }
}
