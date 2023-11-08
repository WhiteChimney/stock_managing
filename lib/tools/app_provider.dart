import 'package:flutter/material.dart';

class AppInfoProvider with ChangeNotifier {
  int _themeColor = 0;

  int get themeColor => _themeColor;

  setTheme(int themeColor) {
    _themeColor = themeColor;
    notifyListeners();
  }
}
