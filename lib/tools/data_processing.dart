import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> loadUserPreferences () async {
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

void setStringToTextController(var textController, var str) {
  textController.value = textController.value.copyWith(
    text: str.isEmpty ? '' : str,
    selection: TextSelection(baseOffset: str.length, extentOffset: str.length),
    composing: TextRange.empty,
  );
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
