import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_managing/tools/app_provider.dart';
import 'package:stock_managing/tools/my_ssh.dart';

Future<SharedPreferences> loadUserPreferences() async {
  SharedPreferences pref = await SharedPreferences.getInstance();

  if (pref.getInt('themeColor') == null) {
    await pref.setInt('themeColor', 0);
  }

  if (pref.getString('ip') == null) {
    await pref.setString('ip', '127.0.0.1');
  }
  if (pref.getInt('port') == null) await pref.setInt('port', 22);
  if (pref.getString('username') == null) {
    await pref.setString('username', 'guest');
  }
  if (pref.getString('password') == null) {
    await pref.setString('password', 'password');
  }

  return pref;
}

void changeThemeColor(BuildContext context) async {
  var pref = await loadUserPreferences();
  int? colorIndex = pref.getInt('themeColor');
  colorIndex ??= 0;
  colorIndex = (colorIndex + 1) % 100;
  if (!context.mounted) return;
  Provider.of<AppInfoProvider>(context, listen: false).setTheme(colorIndex);
  pref.setInt('themeColor', colorIndex);
}

void setStringToTextController(var textController, var str) {
  textController.value = textController.value.copyWith(
    text: str.isEmpty ? '' : str,
    selection: TextSelection(baseOffset: str.length, extentOffset: str.length),
    composing: TextRange.empty,
  );
}

Future<bool> checkIdValidity(String itemId) async {
  if (itemId.isEmpty) return false;
  var pref = await loadUserPreferences();
  var serverInfo = loadSshServerInfoFromPref(pref);
  var cacheDir = await getApplicationCacheDirectory();
  var mainJsonPath =
      path.join(cacheDir.path, serverInfo.username, 'stockings', 'items.json');
  Map<String, dynamic> mainJson =
      jsonDecode(File(mainJsonPath).readAsStringSync());
  if (mainJson.containsKey(itemId)) {
    return false;
  } else {
    return true;
  }
}

// 以下 zip 函数在 Windows 平台下以 GBK 编码，实现中文名称不乱码
// 别的平台下解压 Windows 平台下压缩的文件时，记得指定编码
// 如 Ubuntu 上，unzip -O GBK zipped.zip
Future<void> zipAsync(String dirToBeZipped, String zippedFile) async {
  await Future.delayed(const Duration(seconds: 0), () {
    var encoder = ZipFileEncoder();
    encoder.zipDirectory(Directory(dirToBeZipped), filename: zippedFile);
  });
}

Future<void> unzipAsync(String zippedFile, String dirToBeZipped) async {
  await Future.delayed(const Duration(seconds: 0), () {
    extractFileToDisk(zippedFile, dirToBeZipped);
  });
}
