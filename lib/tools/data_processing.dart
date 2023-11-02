import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

void setStringToTextController(var textController, var str) {
  textController.value = textController.value.copyWith(
    text: str.isEmpty ? '' : str,
    selection: TextSelection(baseOffset: str.length, extentOffset: str.length),
    composing: TextRange.empty,
  );
}

void saveItemInfo(
    TextEditingController idController,
    List<TextEditingController> nameControllers,
    List<TextEditingController> contentControllers,
    List<String> picPaths,
    List<String> filePaths) async {
  if (idController.text == '') return;
  var cacheDir = await getApplicationCacheDirectory();
  var userDir = path.join(cacheDir.path, 'noland');
  var stockingDir = path.join(userDir, 'stockings');
  var itemsDir = path.join(stockingDir, 'items');
  var jsonDir = path.join(itemsDir, idController.text);
  var imgDir = path.join(jsonDir, 'images');
  var fileDir = path.join(jsonDir, 'files');
  await Directory(imgDir).create(recursive: true);
  await Directory(fileDir).create(recursive: true);

  print(imgDir);

  String itemId = idController.text;

  for (int index = 0; index < picPaths.length; index++) {
    var picRead = File(picPaths[index]);
    var picExt = path.extension(picRead.path);
    await picRead.copy(path.join(imgDir, '${itemId}_${index}${picExt}'));
  }

  for (int index = 0; index < filePaths.length; index++) {
    var fileRead = File(filePaths[index]);
    var fileBase = path.basename(fileRead.path);
    await fileRead.copy(path.join(fileDir, fileBase));
  }

  Map<String, dynamic> json = {};
  for (int index = 0; index < nameControllers.length; index++) {
    json[nameControllers[index].text] = contentControllers[index].text;
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
}

Future<List> generateItemInfo(String itemId) async {
  var cacheDir = await getApplicationCacheDirectory();
  var itemDir =
      path.join(cacheDir.path, 'noland', 'stockings', 'items', itemId);
  var picDir = path.join(itemDir, 'images');
  var picList = Directory(picDir).listSync();
  List<FileSystemEntity> picListFinal = [];

  for (var pic in picList) {
    var mimetype = lookupMimeType(pic.path);
    print(mimetype);
    if (mimetype != null && mimetype.startsWith('image/')) {
      picListFinal.add(pic);
    }
  }

  var fileDir = path.join(itemDir, 'files');
  var fileList = Directory(fileDir).listSync();
  List<FileSystemEntity> fileListFinal = [];
  for (var file in fileList) {
    if (file is File) {
      fileListFinal.add(file);
    }
  }

  String itemJson = path.join(itemDir, '${itemId}.json');
  var fJson = File(itemJson);
  Map<String, dynamic> json = jsonDecode(await fJson.readAsString());
  print(json);
  List<String> keyList = [];
  for (var key in json.keys) {
    keyList.add(key);
  }

  return [picListFinal, fileListFinal, json, keyList];
}

Future<List> loadItemInfo(
  String itemId,
  // TextEditingController idController,
  // List<TextEditingController> nameControllers,
  // List<TextEditingController> contentControllers,
  // List<String> picPaths,
  // List<String> filePaths
) async {
  TextEditingController idController = TextEditingController();
  List<TextEditingController> nameControllers = [];
  List<TextEditingController> contentControllers = [];
  List<String> picPaths = [];
  List<String> filePaths = [];

  if (itemId == '') {
    setStringToTextController(idController, '');
    return [
      idController,
      nameControllers,
      contentControllers,
      picPaths,
      filePaths
    ];
  }

  var cacheDir = await getApplicationCacheDirectory();
  var userDir = path.join(cacheDir.path, 'noland');
  var stockingDir = path.join(userDir, 'stockings');
  var itemsDir = path.join(stockingDir, 'items');
  var jsonDir = path.join(itemsDir, itemId);
  if (!(await File(jsonDir).exists())) {
    itemId = '';
    setStringToTextController(idController, '');
    return [
      idController,
      nameControllers,
      contentControllers,
      picPaths,
      filePaths
    ];
  }

  var result = await generateItemInfo(itemId);
  
  
  [picListFinal, fileListFinal, json, keyList]

  var imgDir = path.join(jsonDir, 'images');
  var fileDir = path.join(jsonDir, 'files');
  await Directory(imgDir).create(recursive: true);
  await Directory(fileDir).create(recursive: true);

  for (int index = 0; index < picPaths.length; index++) {
    var picRead = File(picPaths[index]);
    var picExt = path.extension(picRead.path);
    await picRead.copy(path.join(imgDir, '${itemId}_${index}${picExt}'));
  }

  for (int index = 0; index < filePaths.length; index++) {
    var fileRead = File(filePaths[index]);
    var fileBase = path.basename(fileRead.path);
    await fileRead.copy(path.join(fileDir, fileBase));
  }

  Map<String, dynamic> json = {};
  for (int index = 0; index < nameControllers.length; index++) {
    json[nameControllers[index].text] = contentControllers[index].text;
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
}
