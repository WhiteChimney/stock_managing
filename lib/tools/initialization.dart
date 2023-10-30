import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> initUserProfile() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences pref = await SharedPreferences.getInstance();

  if (pref.getString('ip') == null) {
    await pref.setString('ip', '131theater.tpddns.cn');
  }
  if (pref.getInt('port') == null) await pref.setInt('port', 13117);
  if (pref.getString('username') == null) {
    await pref.setString('username', 'noland');
  }
  if (pref.getString('password') == null) {
    await pref.setString('password', 'zxh12345');
  }

  return pref;
}
