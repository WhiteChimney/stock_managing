import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_managing/tools/my_ssh.dart';

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

void saveItemInfo (
  String itemId,
  List<String> labelList,
  List<String> contentList,
  List<String> picPaths,
  List<String> filePaths) async {
  if (itemId == '') return;
  
  var cacheDir = await getApplicationCacheDirectory();
  var userDir = path.join(cacheDir.path, 'noland');
  var stockingDir = path.join(userDir, 'stockings');
  var itemsDir = path.join(stockingDir, 'items');
  var jsonDir = path.join(itemsDir, itemId);
  var imgDir = path.join(jsonDir, 'images');
  var fileDir = path.join(jsonDir, 'files');
  await Directory(imgDir).create(recursive: true);
  await Directory(fileDir).create(recursive: true);

  Map<String, dynamic> json = {};
  for (int index = 0; index < labelList.length; index++) {
    json[labelList[index]] = contentList[index];
  }
  var fWrite = File(path.join(jsonDir, '${itemId}.json'));
  await fWrite.writeAsString(jsonEncode(json));

  var fMainJson = File(path.join(stockingDir, 'items.json'));
  var mainJson = {};
  if (!(await fMainJson.exists())) {
    await fMainJson.create();
  } else {
    mainJson = jsonDecode(await fMainJson.readAsString());
  }
  mainJson[itemId] = 'aaa';
  await fMainJson.writeAsString(jsonEncode(mainJson));

  for (int index = 0; index < picPaths.length; index++) {
    var picRead = File(picPaths[index]);
    var picExt = path.extension(picRead.path);
    await picRead.copy(path.join(imgDir, '${itemId}_${index}${picExt}'));
  }

  String itemFileJson = path.join(jsonDir, '${itemId}_files.json');
  var fFileJson = File(itemFileJson);
  Map fileJson = {};
  if (await fFileJson.exists()) {
    fileJson = jsonDecode(await fFileJson.readAsString());
  } 
  int filesCount = fileJson.length;
  for (int index = 0; index < filePaths.length; index++) {
    var fileBasename = path.basename(filePaths[index]);
    if (fileJson.containsValue(fileBasename)) {
      continue;
    } else {
      var fileRead = File(filePaths[index]);
      var fileBase = path.basename(fileRead.path);
      await fileRead.copy(path.join(fileDir, fileBase));
      fileJson[filesCount.toString()] = fileBasename;
      filesCount++;
    }
  }
  await fFileJson.writeAsString(jsonEncode(fileJson));
}

Future<List> loadItemInfo(String itemId) async {
  Map<String, dynamic> json = {};
  List<String> picListFinal = [];
  List<String> fileListFinal = [];

  if (itemId == '') return [json,picListFinal,fileListFinal];

  SharedPreferences pref = await loadUserPreferences();
  SshServerInfo serverInfo = loadSshServerInfoFromPref(pref);
  var cacheDir = await getApplicationCacheDirectory();
  var itemDir =
      path.join(cacheDir.path, serverInfo.username, 'stockings', 'items', itemId);
  String itemJson = path.join(itemDir, '${itemId}.json');
      
  if (!(await File(itemJson).exists())) {
    itemId = '';
    return [json,picListFinal,fileListFinal];
  }
  
  var fJson = File(itemJson);
  json = jsonDecode(await fJson.readAsString());

  var picDir = path.join(itemDir, 'images');
  var picList = Directory(picDir).listSync();

  for (var pic in picList) {
    var mimetype = lookupMimeType(pic.path);
    if (mimetype != null && mimetype.startsWith('image/')) {
      picListFinal.add(pic.path);
    }
  }

  var fileDir = path.join(itemDir, 'files');
  String itemFileJson = path.join(itemDir, '${itemId}_files.json');
  var fFileJson = File(itemFileJson);
  if (await fFileJson.exists()) {
    var fileJson = jsonDecode(await fFileJson.readAsString());
    for (var key in fileJson.keys) {
      fileListFinal.add(path.join(fileDir, fileJson[key]));
    }
  }
  return [json, picListFinal, fileListFinal];
}
